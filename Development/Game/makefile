# CPSC 599.82 - Retrogames
# Shankar Ganesh, Abhinav Saxena, Scott Peters, Naznin Shishir
# MAKEFILE - GENERAL USE

DASM ?= dasm
LISTING ?= 1
FILES ?= $(wildcard *.s)
PRGS = $(FILES:game.s=game.prg)
LSTNGS = $(FILES:game.s=game.lst)

all: check-vars compile
	

compile: $(PRGS)

rivers:
ifeq ($(LISTING),1)
	dasm rivers.s -orivers.prg -lrivers.lst
else
	dasm rivers.s -orivers.prg
endif

%.prg: %.s
ifeq ($(LISTING),1)
	$(DASM) $< -o$@ -l$*.lst
else
	$(DASM) $< -o$@
endif

clean:
	rm -rf *.prg *.lst


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
