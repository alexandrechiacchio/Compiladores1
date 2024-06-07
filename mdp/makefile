all: interpretador
	./interpretador

debug: interpretador
	./interpretador debug

debug2file: interpretador
	./interpretador debug > out.txt

clean:
	rm -f lex.yy.mdp.c lex.yy.mdp.o interpretador out.txt

interpretador: lex.yy.mdp.o var_object.cc mdp.h mdp.cc
	 g++ -Wall -std=c++17 lex.yy.mdp.o mdp.cc -ll -lfl -o interpretador

lex.yy.mdp.o: lex.yy.mdp.c
	g++ -Wall -std=c++17 -c lex.yy.mdp.c -Wregister

lex.yy.mdp.c: mdp.l
	lex -olex.yy.mdp.c mdp.l

