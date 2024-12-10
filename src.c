#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
 
 
typedef struct {
    int *variabile;
    int size;
} Clauza;
 
typedef struct {
    Clauza *clauze;
    int nr_clauze;
    int nr_variabile_total;
} Formula;
 
typedef struct {
    int *raspuns;
} Raspuns;
 
int copied[1000];  // vector in care se vor pune toti literalii proveniti din unit propagation
int copy_index = 0;
 
int compare_clauses(const void *a, const void *b) {
    Clauza *clause1 = (Clauza *)a;
    Clauza *clause2 = (Clauza *)b;
    return clause1->size < clause2->size;  // ordine crescatoare
}
 
void sort_clauses_by_size(Formula *formula) {
    qsort(formula->clauze, formula->nr_clauze, sizeof(Clauza), compare_clauses);
}
 
int get_index(Formula *formula, int *raspuns) {
    for(int i = 0; i < formula->nr_clauze; i++) {
        Clauza clauza = formula->clauze[i];
        for(int j = 0; j < clauza.size; j++) {  // se cauta primul literal care nu e initializat
            if (clauza.variabile[j] > 0 && raspuns[clauza.variabile[j] - 1] == 0) 
                return clauza.variabile[j] - 1;
            if (clauza.variabile[j] < 0 && raspuns[-clauza.variabile[j] - 1] == 0) 
                return -clauza.variabile[j] - 1;  
        }
    }
    return -1;  // daca s au asignat toate se returneaza -1
}
 
int find_unitary(Formula *formula, Raspuns *rezolvare) {
    int nr = 0;
    for(int i = 0; i < formula->nr_clauze; i++) {
        Clauza clauza = formula->clauze[i];
        int found = 0;
        int not_init = 0;
        int index = 0;
        for(int j = 0; j < clauza.size; j++) {
            if (clauza.variabile[j] > 0 && rezolvare->raspuns[clauza.variabile[j] - 1] == 1 
                || clauza.variabile[j] < 0 && rezolvare->raspuns[-clauza.variabile[j] - 1] == -1) {
                found = 1;  // clauza e adevarata
                break;
            }
            if (clauza.variabile[j] > 0 && rezolvare->raspuns[clauza.variabile[j] - 1] == 0) {
                not_init++;
                index = clauza.variabile[j];
            }
                
            if (clauza.variabile[j] < 0 && rezolvare->raspuns[-clauza.variabile[j] - 1] == 0) {
                not_init++;
                index = clauza.variabile[j];
            }
                
        }
        
        if (found == 0 && not_init == 1) {  // am gasit clauza unitara 
            return index;  // se returneaza literarul pe care o sa l atribui,
        }  
    }
    return -1;  // nu exista clauze unitare
}

int verify(Formula *formula, int *raspuns);

int unitpropagation(Formula *formula, Raspuns *rezolvare) {
    while(1) {
        int index = find_unitary(formula, rezolvare);  // se obtine literalul pentru unit propagation
 
        if (index != -1) {
 
            if (index > 0) {
                copied[copy_index++] = index - 1;   // se copiaza literalul adaugat prin unit propagation
                rezolvare->raspuns[index - 1] = 1;
            }
 
            if (index < 0) {
                copied[copy_index++] = -index - 1;  // se copiaza literalul adaugat prin unit propagation
                rezolvare->raspuns[-index -1] = -1;
            }
            int value = verify(formula, rezolvare->raspuns);  // se verifica daca s a falsificat formula
            if(value != 2)
                return value;
 
        } else {
            int value = verify(formula, rezolvare->raspuns); // se verifica daca s a falsificat formula
            return value;
        }
    }
}
 
int verify(Formula *formula, int *raspuns) {
    int nr = 0;
    
    for(int i = 0; i < formula->nr_clauze; i++) {
        Clauza clauza = formula->clauze[i];
        int found = 0;
        int not_init = 0;
        for(int j = 0; j < clauza.size; j++) {
            if (clauza.variabile[j] > 0 && raspuns[clauza.variabile[j] - 1] == 1 
                || clauza.variabile[j] < 0 && raspuns[-clauza.variabile[j] - 1] == -1) {
                found = 1;
                nr++;
                break;
            }
 
            if (clauza.variabile[j] > 0 && raspuns[clauza.variabile[j] - 1] == 0)
                not_init++;
            
            if (clauza.variabile[j] < 0 && raspuns[-clauza.variabile[j] - 1] == 0)
                not_init++;
        }
 
        if(found == 0 && not_init == 0)  // daca o clauza e falsa si totul e initializat
            return -1;
    }
 
    if(nr == formula->nr_clauze)  // toate clauzele sunt adevarate
        return 1;
 
    return 2;  // momentan unele clauze nu se pot decide   
}
 
int DPLL(Formula *formula, Raspuns *rezolvare) {
    int unitprop_res = unitpropagation(formula, rezolvare);  // se face uni propagationul
    if (unitprop_res == 1) {   // daca s a returnat 1 inseamna ca s a gasit o formula
        return unitprop_res;
    }
    if (unitprop_res == -1) {  // daca s a falsificat din unit propagation se revine la forma de dinainte de aplicare a metodei
        for(int i = 0; i < copy_index; i++)
            rezolvare->raspuns[copied[i]] = 0;
        copy_index = 0;
        return -1;  // se intoarce cu un nivel inapoi
    }
 
    int literal = get_index(formula, rezolvare->raspuns);   // se ia urmatorul literal disponibil
    rezolvare->raspuns[literal] = 1;  // il consideram adevarat
    int res = DPLL(formula, rezolvare);
    if(res == 1)   // s a gasit o formula
        return 1;
 
    rezolvare->raspuns[literal] = -1;   // daca nu s a gasit o formula schimbam valoarea literalului
    int res1 = DPLL(formula, rezolvare);
    if(res1 == -1) {
        rezolvare->raspuns[literal] = 0;  // se reseteaza literalii pentru a continua backtrackingul
    }
 
    return res1;
}
 
int main(int argc, char *argv[]) {
    FILE *input_file = fopen(argv[1], "r");
    FILE *output_file = fopen(argv[2], "w");
    char buffer[100];
    fscanf(input_file, "%s", buffer);
    while(strcmp(buffer,"p") != 0) {  // skip la comentarii
        fscanf(input_file, "%s", buffer);
    }
    fscanf(input_file, "%s", buffer);
    Formula formula;
    fscanf(input_file, "%d %d", &formula.nr_variabile_total, &formula.nr_clauze);
    formula.clauze = malloc(formula.nr_clauze * sizeof(Clauza));
    for(int i = 0; i < formula.nr_clauze; i++) {
        Clauza *aux = &formula.clauze[i];
        aux->variabile = calloc(formula.nr_variabile_total, sizeof(int));
        int curr;
        fscanf(input_file, "%d", &curr);
        aux->size = 0;
        while(curr != 0) {
            aux->variabile[aux->size] = curr;
            aux->size++;
            fscanf(input_file, "%d", &curr);
        }
    }
    
    Raspuns *rezolvare = malloc(sizeof(Raspuns));
    rezolvare->raspuns = calloc(formula.nr_variabile_total, sizeof(int));
    sort_clauses_by_size(&formula);  // sortare clauze dupa marimea lor
    int result = DPLL(&formula, rezolvare);
    if (result == -1)
        fprintf(output_file,"s UNSATISFIABLE");
    else {
        fprintf(output_file,"s SATISFIABLE\nv ");
        for(int i = 0; i < formula.nr_variabile_total; i++) {
            if (rezolvare->raspuns[i] >= 0)
                fprintf(output_file, "%d ", i + 1);
            else 
                fprintf(output_file, "%d ", -(i + 1));
        }
        fprintf(output_file,"0");
    }
 
}
