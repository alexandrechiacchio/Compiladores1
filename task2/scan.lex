%{
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <map>

using namespace std;

int token;

string lexema;

void A();
void E();
void E_linha();
void T();
void T_linha();
void F();
void casa( int );


enum { CDOUBLE = 256, CSTR, ID };

map<int,string> nome_tokens = {
  { CDOUBLE, "double" },
  { CSTR, "string" },
  { ID, "nome de identificador" }
};

void print(string s){
  cout << s << " ";
}

%}

DIGITO  [0-9]
LETRA   [A-Za-z_]
DOUBLE  {DIGITO}+("."{DIGITO}+)?
ID      {LETRA}({LETRA}|{DIGITO})*
STR   \"([^\"\n\\]|(\\\")|\"\"|"\\\\")+\"
WS	[ \n\r\t]

%%

{WS}	

{DOUBLE}   { lexema = yytext; return ( CDOUBLE ); }
{STR}     { lexema = yytext; return ( CSTR ); }


{ID}       { lexema = yytext; return ( ID ); }

.          { lexema = yytext; return ( *yytext ); }

%%

int next_token() {
  return yylex();
}

inline void erro( string msg ) {
  cout << msg << endl;
  exit( 0 ); 
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

void A() {
// Guardamos o lexema pois a função 'casa' altera o seu valor.
  string temp = lexema; 
  casa( ID );
  print( temp );
  casa( '=' );
  E();
  print( "= ^" );
}

void E() {
  T();
  E_linha();
}

void E_linha() {
  switch( token ) {
    case '+' : casa( '+' ); T(); print( "+"); E_linha(); break;
    case '-' : casa( '-' ); T(); print( "-"); E_linha(); break;
  }
}

void T() {
  F();
  T_linha();
}

void T_linha() {
  switch( token ) {
    case '*' : casa( '*' ); F(); print( "*"); T_linha(); break;
    case '/' : casa( '/' ); F(); print( "/"); T_linha(); break;
  }
}

void F() {
  switch( token ) {
    case ID : {
      string temp = lexema;
      casa( ID ); print( temp + "@" ); } 
      break;
    case CDOUBLE : {
      string temp = lexema;
      casa( CDOUBLE ); print( temp ); }
      break;
    case '(': 
      casa( '(' ); E(); casa( ')' ); break;
    default:
      erro( "Operando esperado, encontrado " + lexema );
  }
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


int main() {
  token = next_token();
  A();
  
  if( token == 0 )
    cout << "Sintaxe ok!" << endl;
  else
    cout << "Caracteres encontrados após o final do programa" << endl;
  
  return 0;
}