def compare(a, b)
  a[:size] <=> b[:size]  # ordine crescatoare
end

def sort_by_size(formula)
  formula[:clauses].sort! { |a, b| compare(a, b) }
end

def idx(formula, answer)
  count_vars = Hash.new(0)  # dictionar pentru a numara de cate ori apare fiecare variabila
  formula[:clauses].each do |clause| 
    clause[:vars].each do |var|
      count_vars[var.abs] += 1 if answer[var.abs] == 0 # daca variabila nu e initializata
    end
  end
  count_vars.max_by { |_, count| count }[0] # se returneaza variabila care apare de cele mai multe ori
end

def unifind(formula, solve)  # se cauta clauza unitare
  formula[:clauses].each do |clause| 
    found = false 
    un_init = 0
    index = 0
    clause[:vars].each do |var|
      if (var > 0 && solve[:answer][var] == 1) || (var < 0 && solve[:answer][-var] == -1) 
        found = true  # clauza e adevarata
        break
      end
      if var > 0 && solve[:answer][var] == 0 
        un_init += 1
        index = var
      elsif var < 0 && solve[:answer][-var] == 0
        un_init += 1
        index = var
      end
    end
    return index if !found && un_init == 1  # am gasit clauza unitara 
  end
  -1  # nu exista clauze unitare
end

def check(formula, answer)  # se verifica daca formula e adevarata
  nr = 0
  formula[:clauses].each do |clause|
    found = false
    un_init = 0
    clause[:vars].each do |var|  
      if (var > 0 && answer[var] == 1) || (var < 0 && answer[-var] == -1) # daca variabila e adevarata
        found = true
        nr += 1
        break
      end
      un_init += 1 if var > 0 && answer[var] == 0  # daca variabila nu e initializata
      un_init += 1 if var < 0 && answer[-var] == 0 
    end
    return -1 if !found && un_init == 0  # daca o clauza e falsa si totul e initializat
  end
  return 1 if nr == formula[:clauses_cnt]  # toate clauzele sunt adevarate
  2  # nu pot decide momentan
end

$cpy = []  # vectori pentru a copia literalii adaugati prin unit propagation
$cpy_idx = 0

def unitpropagation(formula, solve) 
  loop do
    index = unifind(formula, solve)  # se obtine literalul pentru unit propagation
    if index != -1
      if index > 0
        $cpy[$cpy_idx] = index
        $cpy_idx += 1  # se copiaza literalul adaugat prin unit propagation
        solve[:answer][index] = 1
      elsif index < 0
        $cpy[$cpy_idx] = -index
        $cpy_idx += 1  # se copiaza literalul adaugat prin unit propagation
        solve[:answer][-index] = -1
      end
      value = check(formula, solve[:answer])  # se verifica daca s a falsificat formula
      return value if value != 2
    else
      value = check(formula, solve[:answer])
      return value
    end
  end
end

def DPLL(formula, solve)
  unitprop_res = unitpropagation(formula, solve)  # se face unitpropagation
  return unitprop_res if unitprop_res == 1  # daca s a returnat 1 inseamna ca s a gasit o formula
  if unitprop_res == -1  # daca s a falsificat din unit propagation se revine la forma de dinainte de aplicare a metodei
    $cpy_idx.times do |i|
      solve[:answer][$cpy[i]] = 0
    end
    $cpy_idx = 0
    return -1  # se intoarce cu un nivel inapoi
  end
  literal = idx(formula, solve[:answer])  # se ia urmatorul literal disponibil
  solve[:answer][literal] = 1  # il consideram adevarat
  res = DPLL(formula, solve)
  return 1 if res == 1  # s a gasit o formula
  solve[:answer][literal] = -1  # daca nu s a gasit o formula schimbam valoarea literalului
  restmp = DPLL(formula, solve)
  if restmp == -1
    solve[:answer][literal] = 0  # se reseteaza literalii pentru a continua backtrackingul
  end
  restmp
end

def read_formula(input_file)  # citirea formulei din fisier
  formula = {}
  formula[:vars_cnt] = input_file.gets.to_i
  formula[:clauses_cnt] = input_file.gets.to_i
  formula[:clauses] = []
  formula[:clauses_cnt].times do
    aux = { vars: [], size: 0 }
    loop do
      curr = input_file.gets.to_i
      break if curr == 0
      aux[:vars] << curr
      aux[:size] += 1
    end
    formula[:clauses] << aux
  end
  formula
end

def write_result(output_file, result, solve, formula) # scrierea rezultatului in fisier
  if result == -1
    output_file.puts "s UNSATISFIABLE"
  else
    output_file.print "s SATISFIABLE\nv "
    formula[:vars_cnt].times do |i|
      if solve[:answer][i + 1] >= 0
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
  _, vars_cnt, clauses_cnt = buffer.match(/p cnf\s+(\d+)\s+(\d+)/).to_a # citesc numarul de variabile si clauze
  formula = {
    vars_cnt: vars_cnt.to_i,
    clauses_cnt: clauses_cnt.to_i,
    clauses: []
  }

  # Read the clauses
  formula[:clauses_cnt].times do
    aux = { vars: [], size: 0 }
    input_file.gets.split.each do |num|
      curr = num.to_i
      break if curr == 0
      aux[:vars] << curr
      aux[:size] += 1
    end
    formula[:clauses] << aux
  end

  solve = { answer: Array.new(formula[:vars_cnt] + 1, 0) }  # vector pentru a retine valorile variabilelor

  sort_by_size(formula)  # sortare clauses dupa marimea lor
  result = DPLL(formula, solve) # se apeleaza functia DPLL
  write_result(output_file, result, solve, formula) # se scrie rezultatul in fisier

  input_file.close
  output_file.close
end

main