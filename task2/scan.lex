%{
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <map>

using namespace std;

int token;

string lexema;

void OP();
void P();
void A();
void E();
void E_linha();
void T();
void T_linha();
void H();
void H_linha();
void FACT();
void FACT_linha();
void F();
void casa( int );
void ARGS();
void ARGFST();
void ARGSREST();



enum { CDOUBLE = 256, CSTR, ID, PRINT, FUNC };

map<int,string> nome_tokens = {
  { CDOUBLE, "double" },
  { CSTR, "string" },
  { ID, "nome de identificador" },
  { PRINT, "print"}
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

"print"     {lexema = yytext; return ( PRINT ); }
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

void OP(){
  switch (token){
    case PRINT:
      P();
      casa(';');
      /* cout << '\n'; */
      OP();
      break;
    case CDOUBLE:
    case CSTR:
    case ID:
      A();
      casa(';');
      /* cout << '\n'; */
      OP();
      break;
  }
}

void P(){
  casa( PRINT );
  E();
  print("print #");
}

void A() {
// Guardamos o lexema pois a função 'casa' altera o seu valor.
  string temp = lexema;
  casa( ID ); print( temp );
  casa( '=' );
  E();
  print( "= ^" );
}

void E() {
  T();
  E_linha();
}

void ARGS(){
  ARGFST();
  ARGSREST();
}

void ARGFST(){
  E();
}

void ARGSREST(){
  switch ( token ){
    case ',':
      casa( ',' );
      E();
      ARGSREST();
      break;
  }

}

void E_linha() {
  switch( token ) {
    case '+' : casa( '+' ); T(); print( "+"); E_linha(); break;
    case '-' : casa( '-' ); T(); print( "-"); E_linha(); break;
  }
}

void T() {
  H();
  T_linha();
}

void T_linha() {
  switch( token ) {
    case '*' : casa( '*' ); H(); print( "*"); T_linha(); break;
    case '/' : casa( '/' ); H(); print( "/"); T_linha(); break;
  }
}

void H(){
  switch ( token ){
    case '-': print("0"); casa ( '-' ); H(); print( "-" ); break;
    case '+': casa ( '+' ); H(); break;
    default:
    FACT();
    H_linha();
  }
}

void H_linha(){
  switch (token){
    case '^': casa ( '^' ); FACT(); H_linha(); print("power #"); break;
  }
}

void FACT(){
  F();
  FACT_linha();
}

void FACT_linha(){
  switch (token) {
    case '!': casa ( '!' ); FACT_linha(); print("fat #");  break;
  }
}

void F() {
  string temp = lexema;
  char next_char = yyinput();
  while(next_char == ' ' or next_char == '\t') next_char = yyinput();
  unput(next_char);
  switch( token ) {
    case ID : {
      if (next_char == '('){
        yyinput();
        casa(ID);
        ARGS();
        casa (')');
        print(temp + " #");
        break;
      } else {
        casa( ID ); print( temp + " @" ); }
        break;
      }
    case CDOUBLE : {
      casa( CDOUBLE ); print( temp ); }
      break;
    case CSTR:{
      casa ( CSTR ); print( temp ); }
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
  OP();
  cout << '\n';

  /* if( token == 0 )
    cout << "\nSintaxe ok!" << endl;
  else {
    cout << "Caracteres encontrados após o final do programa:" << endl;
    while( token != 0 ){
      cout << lexema << " " << token << "\n";
      casa (token);
    }
  } */

  return 0;
}