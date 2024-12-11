#$$$$ Uncomment me for C

# .PHONY: build run

# # Define your C source file and output binary name
# SRC = sat.c
# OUT = sat

# # Rule to build the C source file
# build:
# 	@gcc -O3 -march=native -o $(OUT) $(SRC)

# # Rule to run the compiled binary with input and output redirection
# run:
# 	@./$(OUT) $(INPUT) $(OUTPUT)



#$$$$ Uncomment me for Lua

# .PHONY: build run

# # Define your C source file and output binary name
# SRC = sat.lua

# # Rule to build the C source file
# build:
	
# # Rule to run the compiled binary with input and output redirection
# run:
# 	@lua $(SRC) $(INPUT) $(OUTPUT)



#$$$$ Uncomment me for Ruby

# .PHONY: build run

# # Define your C source file and output binary name
# SRC = sat.rb

# # Rule to build the C source file
# build:
	
# # Rule to run the compiled binary with input and output redirection
# run:
# 	@ruby $(SRC) $(INPUT) $(OUTPUT)



#$$$$ Uncomment me for Perl
# .PHONY: build run

# # Define your C source file and output binary name
# SRC = sat.pl

# # Rule to build the C source file
# build:
	
# # Rule to run the compiled binary with input and output redirection
# run:
# 	@perl sat.pl $(INPUT) $(OUTPUT)
