all: out input.txt
	./out < input.txt

tst: out
	./out

lex.yy.c: scan.lex
	lex scan.lex

out: lex.yy.c lex.yy.c
	g++ -Wall -std=c++17 lex.yy.c -o out -lfl

clean:
	rm out lex.yy.c