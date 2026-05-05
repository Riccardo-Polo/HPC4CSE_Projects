# Robust PETSc Makefile for the benchmark version of the 2D Poisson solver.
# It supports both PETSc installations exposed through pkg-config and PETSc
# installations exposing PETSC_DIR/PETSC_ARCH.

EXE = poisson2d_benchmark
SRC = poisson2d_benchmark.c
OBJ = $(SRC:.c=.o)

PETSC_DIR ?= $(PETSC_ROOT)
PETSC_ARCH ?=

# Try common pkg-config names first.
PETSC_PKG := $(shell pkg-config --exists PETSc 2>/dev/null && echo PETSc || true)
ifeq ($(strip $(PETSC_PKG)),)
  PETSC_PKG := $(shell pkg-config --exists petsc 2>/dev/null && echo petsc || true)
endif

# If PETSc is not visible globally through pkg-config, construct the explicit
# path to petsc.pc from PETSC_DIR/PETSC_ARCH.
ifeq ($(strip $(PETSC_PKG)),)
  ifneq ($(strip $(PETSC_DIR)),)
    ifneq ($(strip $(PETSC_ARCH)),)
      PETSC_PC := $(PETSC_DIR)/$(PETSC_ARCH)/lib/pkgconfig/petsc.pc
    else
      PETSC_PC := $(PETSC_DIR)/lib/pkgconfig/petsc.pc
    endif
    ifneq ($(wildcard $(PETSC_PC)),)
      PETSC_PKG := $(PETSC_PC)
    endif
  endif
endif

ifeq ($(strip $(PETSC_PKG)),)
  $(error Could not find PETSc. Load a PETSc module, or set PETSC_DIR/PETSC_ROOT and PETSC_ARCH correctly)
endif

# Validate the selected pkg-config target.
PETSC_OK := $(shell pkg-config --exists $(PETSC_PKG) 2>/dev/null && echo yes || echo no)
ifeq ($(PETSC_OK),no)
  $(error pkg-config cannot use PETSc target '$(PETSC_PKG)'. Check PETSC_DIR/PETSC_ARCH/PKG_CONFIG_PATH)
endif

CC_FROM_PETSC := $(shell pkg-config --variable=ccompiler $(PETSC_PKG))
CC := $(if $(strip $(CC_FROM_PETSC)),$(CC_FROM_PETSC),mpicc)

CPPFLAGS += $(shell pkg-config --cflags-only-I $(PETSC_PKG))
CFLAGS   += -O3 -Wall $(shell pkg-config --variable=cflags_extra $(PETSC_PKG)) \
            $(shell pkg-config --cflags-only-other $(PETSC_PKG))
LDFLAGS  += $(shell pkg-config --libs-only-L --libs-only-other $(PETSC_PKG))
LDFLAGS  += $(patsubst -L%, $(shell pkg-config --variable=ldflag_rpath $(PETSC_PKG))%, \
             $(shell pkg-config --libs-only-L $(PETSC_PKG)))
LDLIBS   += $(shell pkg-config --libs-only-l $(PETSC_PKG)) -lm

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
	@echo PETSC_OK=$(PETSC_OK)
	@echo CC=$(CC)
	@echo CPPFLAGS=$(CPPFLAGS)
	@echo CFLAGS=$(CFLAGS)
	@echo LDFLAGS=$(LDFLAGS)
	@echo LDLIBS=$(LDLIBS)
