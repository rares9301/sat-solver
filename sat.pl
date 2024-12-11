use strict;
use warnings;
use IO::Handle;

sub compare_clauses {
    my ($a, $b) = @_;
    return $a->{size} <=> $b->{size};  # ordine crescatoare
}

sub sort_clauses_by_size {
    my ($formula) = @_;
    @{$formula->{clauze}} = sort { compare_clauses($a, $b) } @{$formula->{clauze}};
}

sub get_index {
    my ($formula, $raspuns) = @_;
    my %variable_count;
    for my $clauza (@{$formula->{clauze}}) {
        for my $var (@{$clauza->{variabile}}) {
            $variable_count{abs($var)}++ if $raspuns->[abs($var)] == 0;
        }
    }
    my ($max_var) = sort { $variable_count{$b} <=> $variable_count{$a} } keys %variable_count;
    return $max_var;
}

sub find_unitary {
    my ($formula, $rezolvare) = @_;
    for my $clauza (@{$formula->{clauze}}) {
        my $found = 0;
        my $not_init = 0;
        my $index = 0;
        for my $var (@{$clauza->{variabile}}) {
            if (($var > 0 && $rezolvare->{raspuns}->[$var] == 1) || ($var < 0 && $rezolvare->{raspuns}->[-$var] == -1)) {
                $found = 1;  # clauza e adevarata
                last;
            }
            if ($var > 0 && $rezolvare->{raspuns}->[$var] == 0) {
                $not_init++;
                $index = $var;
            }
            if ($var < 0 && $rezolvare->{raspuns}->[-$var] == 0) {
                $not_init++;
                $index = $var;
            }
        }
        return $index if !$found && $not_init == 1;  # am gasit clauza unitara 
    }
    return -1;  # nu exista clauze unitare
}

sub verify {
    my ($formula, $raspuns) = @_;
    my $nr = 0;
    for my $clauza (@{$formula->{clauze}}) {
        my $found = 0;
        my $not_init = 0;
        for my $var (@{$clauza->{variabile}}) {
            if (($var > 0 && $raspuns->[$var] == 1) || ($var < 0 && $raspuns->[-$var] == -1)) {
                $found = 1;
                $nr++;
                last;
            }
            $not_init++ if $var > 0 && $raspuns->[$var] == 0;
            $not_init++ if $var < 0 && $raspuns->[-$var] == 0;
        }
        return -1 if !$found && $not_init == 0;  # daca o clauza e falsa si totul e initializat
    }
    return 1 if $nr == $formula->{nr_clauze};  # toate clauzele sunt adevarate
    return 2;  # momentan unele clauze nu se pot decide
}

my @copied;  # vector in care se vor pune toti literalii proveniti din unit propagation
my $copy_index = 0;

sub unitpropagation {
    my ($formula, $rezolvare) = @_;
    while (1) {
        my $index = find_unitary($formula, $rezolvare);  # se obtine literalul pentru unit propagation
        if ($index != -1) {
            if ($index > 0) {
                $copied[$copy_index] = $index;
                $copy_index++;  # se copiaza literalul adaugat prin unit propagation
                $rezolvare->{raspuns}->[$index] = 1;
            } elsif ($index < 0) {
                $copied[$copy_index] = -$index;
                $copy_index++;  # se copiaza literalul adaugat prin unit propagation
                $rezolvare->{raspuns}->[-$index] = -1;
            }
            my $value = verify($formula, $rezolvare->{raspuns});  # se verifica daca s a falsificat formula
            return $value if $value != 2;
        } else {
            my $value = verify($formula, $rezolvare->{raspuns});  # se verifica daca s a falsificat formula
            return $value;
        }
    }
}

sub DPLL {
    my ($formula, $rezolvare) = @_;
    my $unitprop_res = unitpropagation($formula, $rezolvare);  # se face uni propagationul
    return $unitprop_res if $unitprop_res == 1;  # daca s a returnat 1 inseamna ca s a gasit o formula
    if ($unitprop_res == -1) {  # daca s a falsificat din unit propagation se revine la forma de dinainte de aplicare a metodei
        for my $i (0 .. $copy_index - 1) {
            $rezolvare->{raspuns}->[$copied[$i]] = 0;
        }
        $copy_index = 0;
        return -1;  # se intoarce cu un nivel inapoi
    }
    my $literal = get_index($formula, $rezolvare->{raspuns});  # se ia urmatorul literal disponibil
    $rezolvare->{raspuns}->[$literal] = 1;  # il consideram adevarat
    my $res = DPLL($formula, $rezolvare);
    return 1 if $res == 1;  # s a gasit o formula
    $rezolvare->{raspuns}->[$literal] = -1;  # daca nu s a gasit o formula schimbam valoarea literalului
    my $res1 = DPLL($formula, $rezolvare);
    if ($res1 == -1) {
        $rezolvare->{raspuns}->[$literal] = 0;  # se reseteaza literalii pentru a continua backtrackingul
    }
    return $res1;
}

sub read_formula {
    my ($input_file) = @_;
    my $formula = {};
    $formula->{nr_variabile_total} = <$input_file> + 0;
    $formula->{nr_clauze} = <$input_file> + 0;
    $formula->{clauze} = [];
    for my $i (1 .. $formula->{nr_clauze}) {
        my $aux = { variabile => [], size => 0 };
        while (my $curr = <$input_file> + 0) {
            last if $curr == 0;
            push @{$aux->{variabile}}, $curr;
            $aux->{size}++;
        }
        push @{$formula->{clauze}}, $aux;
    }
    return $formula;
}

sub write_result {
    my ($output_file, $result, $rezolvare, $formula) = @_;
    if ($result == -1) {
        print $output_file "s UNSATISFIABLE";
    } else {
        print $output_file "s SATISFIABLE\nv ";
        for my $i (1 .. $formula->{nr_variabile_total}) {
            if ($rezolvare->{raspuns}->[$i] >= 0) {
                print $output_file "$i ";
            } else {
                print $output_file "-$i ";
            }
        }
        print $output_file "0";
    }
}

sub main {
    my $input_filename = $ARGV[0];
    my $output_filename = $ARGV[1];

    open my $input_file, '<', $input_filename or die "Could not open '$input_filename' $!";
    open my $output_file, '>', $output_filename or die "Could not open '$output_filename' $!";

    # Enable autoflush for faster I/O
    $input_file->autoflush(1);
    $output_file->autoflush(1);

    my $buffer = <$input_file>;
    while ($buffer =~ /^c/ || $buffer !~ /^p/) {  # skip la comentarii
        $buffer = <$input_file>;
    }

    # Read the "p cnf" line
    my ($nr_variabile_total, $nr_clauze) = $buffer =~ /p cnf\s+(\d+)\s+(\d+)/;
    my $formula = {
        nr_variabile_total => $nr_variabile_total + 0,
        nr_clauze => $nr_clauze + 0,
        clauze => []
    };

    # Read the clauses
    for my $i (1 .. $formula->{nr_clauze}) {
        my $aux = { variabile => [], size => 0 };
        my $line = <$input_file>;
        for my $num (split ' ', $line) {
            my $curr = $num + 0;
            last if $curr == 0;
            push @{$aux->{variabile}}, $curr;
            $aux->{size}++;
        }
        push @{$formula->{clauze}}, $aux;
    }

    my $rezolvare = { raspuns => [(0) x ($formula->{nr_variabile_total} + 1)] };

    sort_clauses_by_size($formula);  # sortare clauze dupa marimea lor
    my $result = DPLL($formula, $rezolvare);
    write_result($output_file, $result, $rezolvare, $formula);

    close $input_file;
    close $output_file;
}

main();