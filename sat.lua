local function compare_clauses(a, b)
    return a.size < b.size  -- ordine crescatoare
end

local function sort_clauses_by_size(formula)
    table.sort(formula.clauze, compare_clauses)
end

local function get_index(formula, raspuns)
    for i = 1, formula.nr_clauze do
        local clauza = formula.clauze[i]
        for j = 1, clauza.size do  -- se cauta primul literal care nu e initializat
            if clauza.variabile[j] > 0 and raspuns[clauza.variabile[j]] == 0 then
                return clauza.variabile[j]
            end
            if clauza.variabile[j] < 0 and raspuns[-clauza.variabile[j]] == 0 then
                return -clauza.variabile[j]
            end
        end
    end
    return -1  -- daca s au asignat toate se returneaza -1
end

local function find_unitary(formula, rezolvare)
    for i = 1, formula.nr_clauze do
        local clauza = formula.clauze[i]
        local found = false
        local not_init = 0
        local index = 0
        for j = 1, clauza.size do
            if (clauza.variabile[j] > 0 and rezolvare.raspuns[clauza.variabile[j]] == 1) or
               (clauza.variabile[j] < 0 and rezolvare.raspuns[-clauza.variabile[j]] == -1) then
                found = true  -- clauza e adevarata
                break
            end
            if clauza.variabile[j] > 0 and rezolvare.raspuns[clauza.variabile[j]] == 0 then
                not_init = not_init + 1
                index = clauza.variabile[j]
            end
            if clauza.variabile[j] < 0 and rezolvare.raspuns[-clauza.variabile[j]] == 0 then
                not_init = not_init + 1
                index = clauza.variabile[j]
            end
        end
        if not found and not_init == 1 then  -- am gasit clauza unitara 
            return index  -- se returneaza literarul pe care o sa l atribui
        end
    end
    return -1  -- nu exista clauze unitare
end

local function verify(formula, raspuns)
    local nr = 0
    for i = 1, formula.nr_clauze do
        local clauza = formula.clauze[i]
        local found = false
        local not_init = 0
        for j = 1, clauza.size do
            if (clauza.variabile[j] > 0 and raspuns[clauza.variabile[j]] == 1) or
               (clauza.variabile[j] < 0 and raspuns[-clauza.variabile[j]] == -1) then
                found = true
                nr = nr + 1
                break
            end
            if clauza.variabile[j] > 0 and raspuns[clauza.variabile[j]] == 0 then
                not_init = not_init + 1
            end
            if clauza.variabile[j] < 0 and raspuns[-clauza.variabile[j]] == 0 then
                not_init = not_init + 1
            end
        end
        if not found and not_init == 0 then  -- daca o clauza e falsa si totul e initializat
            return -1
        end
    end
    if nr == formula.nr_clauze then  -- toate clauzele sunt adevarate
        return 1
    end
    return 2  -- momentan unele clauze nu se pot decide
end

local copied = {}  -- vector in care se vor pune toti literalii proveniti din unit propagation
local copy_index = 0

local function unitpropagation(formula, rezolvare)
    while true do
        local index = find_unitary(formula, rezolvare)  -- se obtine literalul pentru unit propagation
        if index ~= -1 then
            if index > 0 then
                copied[copy_index + 1] = index
                copy_index = copy_index + 1  -- se copiaza literalul adaugat prin unit propagation
                rezolvare.raspuns[index] = 1
            elseif index < 0 then
                copied[copy_index + 1] = -index
                copy_index = copy_index + 1  -- se copiaza literalul adaugat prin unit propagation
                rezolvare.raspuns[-index] = -1
            end
            local value = verify(formula, rezolvare.raspuns)  -- se verifica daca s a falsificat formula
            if value ~= 2 then
                return value
            end
        else
            local value = verify(formula, rezolvare.raspuns)  -- se verifica daca s a falsificat formula
            return value
        end
    end
end

local function DPLL(formula, rezolvare)
    local unitprop_res = unitpropagation(formula, rezolvare)  -- se face uni propagationul
    if unitprop_res == 1 then  -- daca s a returnat 1 inseamna ca s a gasit o formula
        return unitprop_res
    end
    if unitprop_res == -1 then  -- daca s a falsificat din unit propagation se revine la forma de dinainte de aplicare a metodei
        for i = 1, copy_index do
            rezolvare.raspuns[copied[i]] = 0
        end
        copy_index = 0
        return -1  -- se intoarce cu un nivel inapoi
    end
    local literal = get_index(formula, rezolvare.raspuns)  -- se ia urmatorul literal disponibil
    rezolvare.raspuns[literal] = 1  -- il consideram adevarat
    local res = DPLL(formula, rezolvare)
    if res == 1 then  -- s a gasit o formula
        return 1
    end
    rezolvare.raspuns[literal] = -1  -- daca nu s a gasit o formula schimbam valoarea literalului
    local res1 = DPLL(formula, rezolvare)
    if res1 == -1 then
        rezolvare.raspuns[literal] = 0  -- se reseteaza literalii pentru a continua backtrackingul
    end
    return res1
end

local function read_formula(input_file)
    local formula = {}
    formula.nr_variabile_total = tonumber(input_file:read("*n"))
    formula.nr_clauze = tonumber(input_file:read("*n"))
    formula.clauze = {}
    for i = 1, formula.nr_clauze do
        local aux = { variabile = {} }
        local curr = tonumber(input_file:read("*n"))
        aux.size = 0
        while curr ~= 0 do
            aux.variabile[aux.size + 1] = curr
            aux.size = aux.size + 1
            curr = tonumber(input_file:read("*n"))
        end
        formula.clauze[i] = aux
    end
    return formula
end

local function write_result(output_file, result, rezolvare, formula)
    if result == -1 then
        output_file:write("s UNSATISFIABLE")
    else
        output_file:write("s SATISFIABLE\nv ")
        for i = 1, formula.nr_variabile_total do
            if rezolvare.raspuns[i] >= 0 then
                output_file:write(i .. " ")
            else
                output_file:write(-i .. " ")
            end
        end
        output_file:write("0")
    end
end

local function main()
    local input_filename = arg[1]
    local output_filename = arg[2]

    local input_file = io.open(input_filename, "r")
    local output_file = io.open(output_filename, "w")

    local buffer = input_file:read("*l")
    while buffer:sub(1, 1) == "c" or buffer:sub(1, 1) ~= "p" do  -- skip la comentarii
        buffer = input_file:read("*l")
    end

    -- Read the "p cnf" line
    local _, _, nr_variabile_total, nr_clauze = buffer:find("p cnf%s+(%d+)%s+(%d+)")
    local formula = {
        nr_variabile_total = tonumber(nr_variabile_total),
        nr_clauze = tonumber(nr_clauze),
        clauze = {}
    }

    -- Read the clauses
    for i = 1, formula.nr_clauze do
        local aux = { variabile = {}, size = 0 }
        for num in input_file:read("*l"):gmatch("%S+") do
            local curr = tonumber(num)
            if curr == 0 then break end
            aux.size = aux.size + 1
            aux.variabile[aux.size] = curr
        end
        formula.clauze[i] = aux
    end

    local rezolvare = { raspuns = {} }
    for i = 1, formula.nr_variabile_total do
        rezolvare.raspuns[i] = 0
    end

    sort_clauses_by_size(formula)  -- sortare clauze dupa marimea lor
    local result = DPLL(formula, rezolvare)
    write_result(output_file, result, rezolvare, formula)

    input_file:close()
    output_file:close()
end

main()