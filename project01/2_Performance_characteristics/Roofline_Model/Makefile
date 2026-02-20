PYTHON = python3
SCRIPT = plot_roofline.py
OUTDIR = images
OUTFILES = $(OUTDIR)/roofline_phase1.pdf \
           $(OUTDIR)/roofline_phase2.pdf

# Default target
all: $(OUTFILES)

# Generate plots
$(OUTFILES): $(SCRIPT)
	@echo "Generating roofline plots "
	@mkdir -p $(OUTDIR)
	@$(PYTHON) $(SCRIPT)

# Remove generated files
clean:
	@echo "Cleaning generated plots..."
	@rm -rf $(OUTDIR)

.PHONY: all clean