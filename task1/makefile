all: out input.txt
	./out < input.txt

lex.yy.c: scan.lex
	lex scan.lex

out: lex.yy.c main.cc
	g++ -Wall -std=c++17 main.cc -o out -lfl

tracelex: scan.lex
	lex -t scan.lex

trace: tracelex main.cc
	g++ -Wall -std=c++17 main.cc -o out -lfl

clean:
	rm out lex.yy.c