BUILD_DIR := build
SRC_DIR := src

BISON := bison
FLEX := flex
CC := gcc
CFLAGS := -Wall -Wextra -std=gnu11

EXEEXT := $(if $(findstring Windows_NT,$(OS)),.exe,)
TARGET := $(BUILD_DIR)/minic$(EXEEXT)
PARSER_C := $(BUILD_DIR)/compiler.tab.c
PARSER_H := $(BUILD_DIR)/compiler.tab.h
LEXER_C := $(BUILD_DIR)/lexer.yy.c

.PHONY: all clean run test help

all: $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(PARSER_C) $(PARSER_H): $(SRC_DIR)/compiler.y | $(BUILD_DIR)
	$(BISON) -d -o $(PARSER_C) $<

$(LEXER_C): $(SRC_DIR)/compiler.l $(PARSER_H) | $(BUILD_DIR)
	$(FLEX) -o $@ $<

$(TARGET): $(PARSER_C) $(LEXER_C)
	$(CC) $(CFLAGS) -I$(BUILD_DIR) $(PARSER_C) $(LEXER_C) -o $@

run: $(TARGET)
	./$(TARGET) examples/valid.txt

test: $(TARGET)
	./$(TARGET) -q examples/valid.txt
	-./$(TARGET) examples/type_error.txt
	-./$(TARGET) examples/multiple_errors.txt

clean:
	rm -rf $(BUILD_DIR)

help:
	@echo "Available commands:"
	@echo "  make        Build the compiler"
	@echo "  make run    Build and run examples/valid.txt"
	@echo "  make test   Run valid and invalid example programs"
	@echo "  make clean  Remove generated files"
