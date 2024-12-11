def compare_clauses(a, b)
  a[:size] <=> b[:size]  # ordine crescatoare
end

def sort_clauses_by_size(formula)
  formula[:clauze].sort! { |a, b| compare_clauses(a, b) }
end

def get_index(formula, raspuns)
  # Use a heuristic to select the next variable
  variable_count = Hash.new(0)
  formula[:clauze].each do |clauza|
    clauza[:variabile].each do |var|
      variable_count[var.abs] += 1 if raspuns[var.abs] == 0
    end
  end
  variable_count.max_by { |_, count| count }[0]
end

def find_unitary(formula, rezolvare)
  formula[:clauze].each do |clauza|
    found = false
    not_init = 0
    index = 0
    clauza[:variabile].each do |var|
      if (var > 0 && rezolvare[:raspuns][var] == 1) || (var < 0 && rezolvare[:raspuns][-var] == -1)
        found = true  # clauza e adevarata
        break
      end
      if var > 0 && rezolvare[:raspuns][var] == 0
        not_init += 1
        index = var
      elsif var < 0 && rezolvare[:raspuns][-var] == 0
        not_init += 1
        index = var
      end
    end
    return index if !found && not_init == 1  # am gasit clauza unitara 
  end
  -1  # nu exista clauze unitare
end

def verify(formula, raspuns)
  nr = 0
  formula[:clauze].each do |clauza|
    found = false
    not_init = 0
    clauza[:variabile].each do |var|
      if (var > 0 && raspuns[var] == 1) || (var < 0 && raspuns[-var] == -1)
        found = true
        nr += 1
        break
      end
      not_init += 1 if var > 0 && raspuns[var] == 0
      not_init += 1 if var < 0 && raspuns[-var] == 0
    end
    return -1 if !found && not_init == 0  # daca o clauza e falsa si totul e initializat
  end
  return 1 if nr == formula[:nr_clauze]  # toate clauzele sunt adevarate
  2  # momentan unele clauze nu se pot decide
end

$copied = []  # vector in care se vor pune toti literalii proveniti din unit propagation
$copy_index = 0

def unitpropagation(formula, rezolvare)
  loop do
    index = find_unitary(formula, rezolvare)  # se obtine literalul pentru unit propagation
    if index != -1
      if index > 0
        $copied[$copy_index] = index
        $copy_index += 1  # se copiaza literalul adaugat prin unit propagation
        rezolvare[:raspuns][index] = 1
      elsif index < 0
        $copied[$copy_index] = -index
        $copy_index += 1  # se copiaza literalul adaugat prin unit propagation
        rezolvare[:raspuns][-index] = -1
      end
      value = verify(formula, rezolvare[:raspuns])  # se verifica daca s a falsificat formula
      return value if value != 2
    else
      value = verify(formula, rezolvare[:raspuns])  # se verifica daca s a falsificat formula
      return value
    end
  end
end

def DPLL(formula, rezolvare)
  unitprop_res = unitpropagation(formula, rezolvare)  # se face uni propagationul
  return unitprop_res if unitprop_res == 1  # daca s a returnat 1 inseamna ca s a gasit o formula
  if unitprop_res == -1  # daca s a falsificat din unit propagation se revine la forma de dinainte de aplicare a metodei
    $copy_index.times do |i|
      rezolvare[:raspuns][$copied[i]] = 0
    end
    $copy_index = 0
    return -1  # se intoarce cu un nivel inapoi
  end
  literal = get_index(formula, rezolvare[:raspuns])  # se ia urmatorul literal disponibil
  rezolvare[:raspuns][literal] = 1  # il consideram adevarat
  res = DPLL(formula, rezolvare)
  return 1 if res == 1  # s a gasit o formula
  rezolvare[:raspuns][literal] = -1  # daca nu s a gasit o formula schimbam valoarea literalului
  res1 = DPLL(formula, rezolvare)
  if res1 == -1
    rezolvare[:raspuns][literal] = 0  # se reseteaza literalii pentru a continua backtrackingul
  end
  res1
end

def read_formula(input_file)
  formula = {}
  formula[:nr_variabile_total] = input_file.gets.to_i
  formula[:nr_clauze] = input_file.gets.to_i
  formula[:clauze] = []
  formula[:nr_clauze].times do
    aux = { variabile: [], size: 0 }
    loop do
      curr = input_file.gets.to_i
      break if curr == 0
      aux[:variabile] << curr
      aux[:size] += 1
    end
    formula[:clauze] << aux
  end
  formula
end

def write_result(output_file, result, rezolvare, formula)
  if result == -1
    output_file.puts "s UNSATISFIABLE"
  else
    output_file.print "s SATISFIABLE\nv "
    formula[:nr_variabile_total].times do |i|
      if rezolvare[:raspuns][i + 1] >= 0
        output_file.print "#{i + 1} "
      else
        output_file.print "-#{i + 1} "
      end
    end
    output_file.puts "0"
  end
end

def main
  input_filename = ARGV[0]
  output_filename = ARGV[1]

  input_file = File.open(input_filename, "r")
  output_file = File.open(output_filename, "w")

  buffer = input_file.gets
  while buffer[0] == 'c' || buffer[0] != 'p'  # skip la comentarii
    buffer = input_file.gets
  end

  # Read the "p cnf" line
  _, nr_variabile_total, nr_clauze = buffer.match(/p cnf\s+(\d+)\s+(\d+)/).to_a
  formula = {
    nr_variabile_total: nr_variabile_total.to_i,
    nr_clauze: nr_clauze.to_i,
    clauze: []
  }

  # Read the clauses
  formula[:nr_clauze].times do
    aux = { variabile: [], size: 0 }
    input_file.gets.split.each do |num|
      curr = num.to_i
      break if curr == 0
      aux[:variabile] << curr
      aux[:size] += 1
    end
    formula[:clauze] << aux
  end

  rezolvare = { raspuns: Array.new(formula[:nr_variabile_total] + 1, 0) }

  sort_clauses_by_size(formula)  # sortare clauze dupa marimea lor
  result = DPLL(formula, rezolvare)
  write_result(output_file, result, rezolvare, formula)

  input_file.close
  output_file.close
end

main