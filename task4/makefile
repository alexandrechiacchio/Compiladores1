all: out input.txt
	./out < input.txt

tst: out
	./out

out: lex.yy.c npr.tab.c
	g++-9 npr.tab.c -o out -lfl -w

lex.yy.c: npr.l
	flex npr.l

npr.tab.c: npr.y
	bison npr.y

clean:
	rm -f lex.yy.c npr.tab.c out npr.output