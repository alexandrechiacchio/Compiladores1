all: saida entrada.txt
	./saida < entrada.txt

tst: saida
	./saida

lex.yy.c: scan.lex
	lex scan.lex

saida: lex.yy.c lex.yy.c
	g++ -Wall -std=c++17 lex.yy.c -o saida -lfl

clean:
	rm saida lex.yy.c