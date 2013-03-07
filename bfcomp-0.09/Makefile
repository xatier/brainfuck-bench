
CFLAGS = -O2 -Wall -ggdb

all: bfa bfc bfrun hanoi.bf

bfa: bfa.c

bfrun: bfrun.c

bfc: bfc.c bfc_parser.tab.c bfc_scanner.c

bfc_parser.tab.c: bfc_parser.y
	bison -d bfc_parser.y

bfc_scanner.c: bfc_scanner.l

%.bf: %.bfa bfa
	./bfa < $< > $@

%.bfa: %.bfc builtins.bfc bfc
	./bfc < $< > $@

clean:
	rm -f bfc_parser.tab.c bfc_parser.tab.h bfc_scanner.c
	rm -f bfa bfc bfrun hanoi.bf hanoi.bfa num.bf num.bfa
	rm -f bfc_parser.output

