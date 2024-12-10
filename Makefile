.PHONY: build run

# Define your C source file and output binary name
SRC = src.c
OUT = src

# Rule to build the C source file
build:
	@gcc -O3 -march=native -o $(OUT) $(SRC)

# Rule to run the compiled binary with input and output redirection
run:
	@./$(OUT) $(INPUT) $(OUTPUT)

