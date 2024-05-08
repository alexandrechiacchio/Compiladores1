%{
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <map>

using namespace std;

int token;

void P();
void A();
void R();
void L();
void V();
void VS();
void T();
void casa( int );

enum { tk_int = 256, tk_char, tk_double, tk_id, tk_cte_int };

map<int,string> nome_tokens = {
  { tk_int, "int" },
  { tk_char, "char" },
  { tk_double, "double" },
  { tk_id, "nome de identificador" },
  { tk_cte_int, "constante inteira" }
};

%}

DIGITO  [0-9]
LETRA   [A-Za-z_]
DOUBLE  {DIGITO}+("."{DIGITO}+)?
ID      {LETRA}({LETRA}|{DIGITO})*
STR   \"([^\"\n\\]|(\\\")|\"\"|"\\\\")+\"

%%

"\t"       { coluna += 4; }
" "        { coluna++; }
"\n"     { linha++; coluna = 1; }

{DOUBLE}   { return token( CDOUBLE ); }
{STR}     { return token( CSTR ); }


{ID}       { return token( ID ); }

.          { return token( *yytext ); }

%%

int next_token() {
  return yylex();
}

string nome_token( int token ) {
  if( nome_tokens.find( token ) != nome_tokens.end() )
    return nome_tokens[token];
  else {
    string r;
    
    r = token;
    return r;
  }
}

void P() {
  if( token == '*' ) {
    casa( '*' );
    P();
  }
}

void A() {
  if( token == '[' ) {
    casa( '[' );
    casa( tk_cte_int );
    casa( ']' );
    A();
  }
}

void R() {
  if( token == ',' ) {
    casa( ',' );
    P();
    casa( tk_id );
    A();
    R();
  }
}

void L() {
  P();
  casa( tk_id );
  A();
  R();
}

void T() {
  switch( token ) {
    case tk_int : casa( tk_int ); break;
    case tk_char : casa( tk_char ); break;
    case tk_double : casa( tk_double ); break;
    
    default:
      cout << "Tipo esperado "  
	   << " , encontrado: " << nome_token( token ) << endl;
    exit( 1 );
  }
}

void V() {
  T();  
  L(); 
  casa( ';' );
}


void casa( int esperado ) {
  if( token == esperado )
    token = next_token();
  else {
      cout << "Esperado " << nome_token( esperado ) 
	   << " , encontrado: " << nome_token( token ) << endl;
    exit( 1 );
  }
}

void VS() {
  switch( token ) { // verificando o próximo símbolo da entrada
    case tk_int:
    case tk_char:
    case tk_double:
      V();
      VS();
      break;
  }
}

int main() {
  token = next_token();
  VS();
  
  if( token == 0 )
    cout << "Sintaxe ok!" << endl;
  else
    cout << "Caracteres encontrados após o final do programa" << endl;
  
  return 0;
}