all: out input.txt
	./out < input.txt

tst: out
	./out

out: lex.yy.c npr.tab.c
	g++ npr.tab.c -o out -lfl -Wregister

lex.yy.c: npr.l
	lex npr.l

npr.tab.c: npr.y
	bison npr.y

clean:
	rm -f lex.yy.c npr.tab.c out