# CPSC 599.82 - Retrogames
# Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
# MAKEFILE - GENERAL USE

DASM ?= dasm
LISTING ?= 0
FILES ?= $(wildcard *.s $(wildcard *.asm))
PRGS = $(patsubst %.asm,%.prg, $(patsubst %.s,%.prg,$(filter %.s %.asm,$(FILES))))
LSTNGS = $(PRGS:%.prg=%.lst)

all: check-vars compile 
	

compile: $(PRGS)


%.prg: %.s
ifeq ($(LISTING),1)
	$(DASM) $< -o$@ -l$*.lst
else
	$(DASM) $< -o$@
endif


%.prg: %.asm
ifeq ($(LISTING),1)
	$(DASM) $< -o$@ -l$*.lst
else
	$(DASM) $< -o$@
endif



clean:
	rm -rf $(PRGS) $(LSTNGS)


check-vars:
ifndef FILES
	$(error FILES is undefined. Pass in a list of files)
endif
ifneq ($(LISTING),1)
ifneq ($(LISTING),0)
	$(error Invalid LISTING. LISTING can either be 1 or 0)
endif
endif


.PHONY: clean check-vars
