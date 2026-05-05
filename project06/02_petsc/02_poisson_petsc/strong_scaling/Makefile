# Robust PETSc Makefile for the benchmark version of the 2D Poisson solver.
# It works with either:
#   1) a PETSc module exposing PETSc through pkg-config, or
#   2) PETSC_DIR / PETSC_ROOT pointing to an installation containing petsc.pc.

EXE = poisson2d_benchmark
SRC = poisson2d_benchmark.c
OBJ = $(SRC:.c=.o)

PETSC_DIR ?= $(PETSC_ROOT)
PETSC_ARCH ?=

# First try a PETSc module through pkg-config. Different installations use
# different names, so we try PETSc first and then petsc.
PETSC_PKG := $(shell pkg-config --exists PETSc 2>/dev/null && echo PETSc || \
                     pkg-config --exists petsc 2>/dev/null && echo petsc || true)

# If pkg-config did not find PETSc globally, fall back to the explicit petsc.pc
# constructed from PETSC_DIR and PETSC_ARCH.
ifeq ($(PETSC_PKG),)
  ifneq ($(strip $(PETSC_DIR)),)
    ifneq ($(strip $(PETSC_ARCH)),)
      PETSC_PC := $(PETSC_DIR)/$(PETSC_ARCH)/lib/pkgconfig/petsc.pc
    else
      PETSC_PC := $(PETSC_DIR)/lib/pkgconfig/petsc.pc
    endif
    PETSC_PKG := $(PETSC_PC)
  endif
endif

ifeq ($(strip $(PETSC_PKG)),)
  $(error Could not find PETSc. Load the PETSc module or set PETSC_DIR/PETSC_ROOT and PETSC_ARCH correctly)
endif

# Stop immediately if the chosen pkg-config target is invalid.
ifeq ($(shell pkg-config --exists $(PETSC_PKG) 2>/dev/null; echo $$?),1)
  $(error pkg-config cannot find PETSc target '$(PETSC_PKG)'. Check PETSC_DIR/PETSC_ARCH/PKG_CONFIG_PATH)
endif

CC := $(shell pkg-config --variable=ccompiler $(PETSC_PKG))
ifeq ($(strip $(CC)),)
  CC := mpicc
endif

CPPFLAGS := $(shell pkg-config --cflags-only-I $(PETSC_PKG))
CFLAGS   := $(shell pkg-config --variable=cflags_extra $(PETSC_PKG)) \
            $(shell pkg-config --cflags-only-other $(PETSC_PKG)) \
            -O3 -Wall
LDFLAGS  := $(shell pkg-config --libs-only-L --libs-only-other $(PETSC_PKG))
LDFLAGS  += $(patsubst -L%, $(shell pkg-config --variable=ldflag_rpath $(PETSC_PKG))%, \
             $(shell pkg-config --libs-only-L $(PETSC_PKG)))
LDLIBS   := $(shell pkg-config --libs-only-l $(PETSC_PKG)) -lm

.PHONY: all clean print

all: $(EXE)

$(EXE): $(OBJ)
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

clean:
	$(RM) $(EXE) $(OBJ)

print:
	@echo PETSC_ROOT=$(PETSC_ROOT)
	@echo PETSC_DIR=$(PETSC_DIR)
	@echo PETSC_ARCH=$(PETSC_ARCH)
	@echo PKG_CONFIG_PATH=$(PKG_CONFIG_PATH)
	@echo PETSC_PKG=$(PETSC_PKG)
	@echo CC=$(CC)
	@echo CPPFLAGS=$(CPPFLAGS)
	@echo CFLAGS=$(CFLAGS)
	@echo LDFLAGS=$(LDFLAGS)
	@echo LDLIBS=$(LDLIBS)
