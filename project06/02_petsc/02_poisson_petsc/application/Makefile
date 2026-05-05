# PETSc Makefile for the 2D Poisson solver

PETSC_DIR  ?= $(PETSC_ROOT)
PETSC_ARCH ?=

petsc.pc := $(PETSC_DIR)/$(PETSC_ARCH)/lib/pkgconfig/petsc.pc
PACKAGES := $(petsc.pc)

CC := $(shell pkg-config --variable=ccompiler $(PACKAGES))

CFLAGS_OTHER := $(shell pkg-config --cflags-only-other $(PACKAGES))
CFLAGS := $(shell pkg-config --variable=cflags_extra $(PACKAGES)) $(CFLAGS_OTHER) -Wall
CPPFLAGS := $(shell pkg-config --cflags-only-I $(PACKAGES))

LDFLAGS := $(shell pkg-config --libs-only-L --libs-only-other $(PACKAGES))
LDFLAGS += $(patsubst -L%, $(shell pkg-config --variable=ldflag_rpath $(PACKAGES))%, $(shell pkg-config --libs-only-L $(PACKAGES)))

LDLIBS := $(shell pkg-config --libs-only-l $(PACKAGES)) -lm

poisson2d: poisson2d.o
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)

poisson2d.o: poisson2d.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

clean:
	$(RM) poisson2d *.o

print:
	@echo PETSC_DIR=$(PETSC_DIR)
	@echo PETSC_ARCH=$(PETSC_ARCH)
	@echo petsc.pc=$(petsc.pc)
	@echo CC=$(CC)
	@echo CFLAGS=$(CFLAGS)
	@echo CPPFLAGS=$(CPPFLAGS)
	@echo LDFLAGS=$(LDFLAGS)
	@echo LDLIBS=$(LDLIBS)
