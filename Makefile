# Makefile for PlantUML PNGs + README.md -> PDF
# README.md in root, PDF published in doc/

# Folder containing .puml files
SRC_DIR := doc

# Find all .puml files in the folder
PUML_FILES := $(wildcard $(SRC_DIR)/*.puml)

# Corresponding PNG files
PNG_FILES := $(PUML_FILES:.puml=.png)

# README.md and output PDF
README_MD := README.md
README_PDF := $(SRC_DIR)/README.pdf

# Default target: generate PNGs and PDF
all: $(PNG_FILES) $(README_PDF)

# Rule: generate PNG from PUML
$(SRC_DIR)/%.png: $(SRC_DIR)/%.puml
	plantuml -tpng $<

# Rule: generate PDF from README.md
$(README_PDF): $(README_MD)
	pandoc $< -o $@

# Clean generated files
clean:
	rm -f $(PNG_FILES) $(README_PDF)
