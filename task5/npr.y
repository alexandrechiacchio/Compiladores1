%{
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <cstring>

using namespace std;

#define YYDEBUG 1

int linha = 1, coluna = 0;

struct Atributos {
  vector<string> c; // Código

  int linha = 0, coluna = 0;

  // Só para argumentos e parâmetros
  int contador = 0;

  // Só para valor default de argumento
  vector<string> valor_default;

  void clear() {
    c.clear();
    valor_default.clear();
    linha = 0;
    coluna = 0;
    contador = 0;
  }
};

enum TipoDecl { Let = 1, Const, Var };
map<TipoDecl, string> nomeTipoDecl = {
  { Let, "let" },
  { Const, "const" },
  { Var, "var" }
};

struct Simbolo {
  TipoDecl tipo;
  int linha;
  int coluna;
  int n_args;
};

int in_func = 0;

// Tabela de símbolos - agora é uma pilha
vector< map< string, Simbolo > > ts = { map< string, Simbolo >{} };
vector<string> funcoes;

vector<string> declara_var( TipoDecl tipo, string nome, int linha, int coluna );
void checa_in_func();
void checa_simbolo( string nome, bool modificavel );

#define YYSTYPE Atributos

extern "C" int yylex();
int yyparse();
void yyerror(const char *);

vector<string> concatena( vector<string> a, vector<string> b ) {
  a.insert( a.end(), b.begin(), b.end() );
  return a;
}

vector<string> operator+( vector<string> a, vector<string> b ) {
  return concatena( a, b );
}

vector<string> operator+( vector<string> a, string b ) {
  a.push_back( b );
  return a;
}

vector<string> operator+( string a, vector<string> b ) {
  return vector<string>{ a } + b;
}

vector<string> resolve_enderecos( vector<string> entrada ) {
  map<string,int> label;
  vector<string> saida;
  for( int i = 0; i < entrada.size(); i++ )
    if( entrada[i][0] == ':' )
        label[entrada[i].substr(1)] = saida.size();
    else
      saida.push_back( entrada[i] );

  for( int i = 0; i < saida.size(); i++ )
    if( label.count( saida[i] ) > 0 )
        saida[i] = to_string(label[saida[i]]);

  return saida;
}

string gera_label( string prefixo ) {
  static int n = 0;
  return prefixo + "_" + to_string( ++n ) + ":";
}

int instruction_count;
void print( vector<string> codigo ) {
  for( string i : codigo){
    cout << i << " ";
  }
  cout << endl;
}


%}
%define parse.error verbose
%token ID IF ELSE LET CONST VAR PRINT FOR WHILE FUNCTION RETURN ASM SETA
%token CDOUBLE CSTRING CINT CBOOL
%token AND OR ME_IG MA_IG DIF IGUAL
%token MAIS_IGUAL MAIS_MAIS
%token PARENTESES_FUNCAO

%left ','
%nonassoc MAIS_IGUAL

%right '='  SETA':'
%left OR
%left AND
%nonassoc IGUAL DIF
%nonassoc '<' '>' ME_IG MA_IG
%left '+' '-'
%left '*' '/' '%'
%right MAIS_MAIS
%right '[' '('
%left '.'

%%

FIM : S  	{ $$.c = resolve_enderecos(  $1.c + "." + funcoes ); print( $$.c ); }
    ;

S : CMDs
  ;

CMDs : CMDs CMD  { $$.c = $1.c + $2.c; };
     |           { $$.clear(); }
     ;

CMD : CMD_LET ';'
    | CMD_VAR ';'
    | CMD_CONST ';'
    | CMD_IF_ELSE
    | CMD_IF
    | PRINT E ';'
      { $$.c = $2.c + "println" + "#"; }
    | CMD_FOR
    | CMD_WHILE
    | CMD_FUNC
    | CMD_RET ';'
    | CMD_ASM ';'
    | E PP1s
      { $$.c = $1.c + "^"; };
    | '{' EMPILHA_TS CMDs '}' PPs
      { $$.c = "<{" + $3.c + "}>";
        ts.pop_back(); }
    ;


PP1s : ';' PPs
     ;

PPs : PP PPs
    | { $$.clear(); }
    ;

PP : ';'
   ;

CMD_ASM : E ASM { $$.c = $1.c + $2.c + "^"; }
        ;

EMPILHA_TS : { ts.push_back( map< string, Simbolo >{} ); }
           ;

ANON_FUNC : FUNCTION { in_func++; }

             '(' LISTA_PARAMs ')' '{' CMDs '}'
           {
             string lbl_endereco_funcao = gera_label( "func_" + $5.c[0] );
             string definicao_lbl_endereco_funcao = ":" + lbl_endereco_funcao;


             $$.c = vector<string>{"{}"} + "'&funcao'" + lbl_endereco_funcao + "[<=]";
            funcoes = funcoes + definicao_lbl_endereco_funcao + $4.c + $7.c +
                       "undefined" + "@" + "'&retorno'" + "@"+ "~";
             ts.pop_back();
             in_func--;
           }
         ;

CMD_FUNC : FUNCTION ID { declara_var( Var, $2.c[0], $2.linha, $2.coluna ); in_func++;}
             '(' LISTA_PARAMs ')' '{' CMDs '}' PPs
           {

             string lbl_endereco_funcao = gera_label( "func_" + $2.c[0] );
             string definicao_lbl_endereco_funcao = ":" + lbl_endereco_funcao;


             $$.c = $2.c + "&" + $2.c + "{}"  + "=" + "'&funcao'" +
                    lbl_endereco_funcao + "[=]" + "^";
            funcoes = funcoes + definicao_lbl_endereco_funcao + $5.c + $8.c +
                       "undefined" + "@" + "'&retorno'" + "@"+ "~";
             ts.pop_back();
             in_func--;
           }
         ;

LISTA_PARAMs : PARAMs
           | { ts.push_back( map< string, Simbolo >{} ); $$.clear(); }
           ;

PARAMs : PARAMs ',' PARAM
       { // a & a arguments @ 0 [@] = ^

          declara_var( Let, $3.c[0], $3.linha, $3.coluna );
          $$.c = $1.c + $3.c + "&" + $3.c + "arguments" + "@" + to_string( $1.contador ) + "[@]" + "=" + "^";

          if( $3.valor_default.size() > 0 ) {
            string lbl_fim = gera_label( "fim_default" );
            string definicao_fim = ":" + lbl_fim;
            string lbl_set_default = gera_label ("set_default" );
            string definicao_set_default = ":" + lbl_set_default;
            $$.c =  $$.c + "arguments" + "@" + to_string( $1.contador ) + "[@]" + "undefined" + "@" + "==" + lbl_set_default + "?" +
                    lbl_fim + "#" +
                    definicao_set_default +
                    $3.c + $3.valor_default + "=" + "^" +
                    definicao_fim;
          }
          $$.contador = $1.contador + $3.contador;
       }
     | PARAM
       { // a & a arguments @ 0 [@] = ^
          ts.push_back( map< string, Simbolo >{} );

          declara_var( Let, $1.c[0], $1.linha, $1.coluna );

          $$.c = $1.c + "&" + $1.c + "arguments" + "@" + "0" + "[@]" + "=" + "^";

          if( $1.valor_default.size() > 0 ) {
            string lbl_fim = gera_label( "fim_default" );
            string definicao_fim = ":" + lbl_fim;
            string lbl_set_default = gera_label ("set_default" );
            string definicao_set_default = ":" + lbl_set_default;

            $$.c =  $$.c + "arguments" + "@" + "0" + "[@]" + "undefined" + "@" + "==" + lbl_set_default + "?" +
                    lbl_fim + "#" +
                    definicao_set_default +
                    $1.c + $1.valor_default + "=" + "^" +
                    definicao_fim;
          }
          $$.contador = $1.contador;
       }
     ;

PARAM : ID
      {
        $$.c = $1.c;
        $$.contador = 1;
        $$.valor_default.clear();

      }
    | ID '=' E
      { // Código do IF
        $$.c = $1.c;
        $$.contador = 1;
        $$.valor_default = $3.c;

      }
    /* | ID '=' {} */
    ;

CMD_RET : RETURN E
          { checa_in_func(); $$.c = $2.c + "\'&retorno\'" + "@" + "~"; }
        | RETURN OBJECT
          { checa_in_func(); $$.c = $2.c + "\'&retorno\'" + "@" + "~"; }
        ;

CMD_FOR : FOR '(' PRIM_E ';' E ';' E ')' CMD
        { string lbl_fim_for = gera_label( "fim_for" );
          string lbl_condicao_for = gera_label( "condicao_for" );
          string lbl_comando_for = gera_label( "comando_for" );
          string definicao_lbl_fim_for = ":" + lbl_fim_for;
          string definicao_lbl_condicao_for = ":" + lbl_condicao_for;
          string definicao_lbl_comando_for = ":" + lbl_comando_for;

          $$.c = $3.c + definicao_lbl_condicao_for +
                 $5.c + lbl_comando_for + "?" + lbl_fim_for + "#" +
                 definicao_lbl_comando_for + $9.c +
                 $7.c + "^" + lbl_condicao_for + "#" +
                 definicao_lbl_fim_for;
        }
        ;

CMD_WHILE : WHILE '(' E ')' CMD
        { string lbl_fim_while = gera_label( "fim_while" );
          string lbl_condicao_while = gera_label( "condicao_while" );
          string lbl_comando_while = gera_label( "comando_while" );
          string definicao_lbl_fim_while = ":" + lbl_fim_while;
          string definicao_lbl_condicao_while = ":" + lbl_condicao_while;
          string definicao_lbl_comando_while = ":" + lbl_comando_while;

          $$.c = definicao_lbl_condicao_while +
                 $3.c + lbl_comando_while + "?" + lbl_fim_while + "#" +
                 definicao_lbl_comando_while + $5.c + lbl_condicao_while + "#" +
                 definicao_lbl_fim_while;
        }
        ;

PRIM_E : CMD_LET
       | CMD_VAR
       | CMD_CONST
       | E
         { $$.c = $1.c + "^"; }
       ;

CMD_LET : LET LET_VARs { $$.c = $2.c; }
        ;

LET_VARs : LET_VAR ',' LET_VARs { $$.c = $1.c + $3.c; }
         | LET_VAR
         ;

LET_VAR : ID
          { $$.c = declara_var( Let, $1.c[0], $1.linha, $1.coluna ); }
        | ID '=' E
          {
            $$.c = declara_var( Let, $1.c[0], $1.linha, $1.coluna ) +
                   $1.c + $3.c + "=" + "^"; }
        | ID '=' OBJECT
          {
            $$.c = declara_var( Let, $1.c[0], $1.linha, $1.coluna ) +
                   $1.c + $3.c + "=" + "^"; }
        | ID '=' '{' '}'
          {
            $$.c = declara_var( Let, $1.c[0], $1.linha, $1.coluna ) +
                   $1.c + "{}" + "=" + "^"; }
        | ID '=' ANON_FUNC
          {
            $$.c = declara_var( Let, $1.c[0], $1.linha, $1.coluna ) +
                   $1.c + $3.c + "=" + "^"; }
        ;

CMD_VAR : VAR VAR_VARs { $$.c = $2.c; }
        ;

VAR_VARs : VAR_VAR ',' VAR_VARs { $$.c = $1.c + $3.c; }
         | VAR_VAR
         ;

VAR_VAR : ID
          { $$.c = declara_var( Var, $1.c[0], $1.linha, $1.coluna ); }
        | ID '=' E
          {  $$.c = declara_var( Var, $1.c[0], $1.linha, $1.coluna ) +
                    $1.c + $3.c + "=" + "^"; }
        | ID '=' '{' '}'
          {
            $$.c = declara_var( Var, $1.c[0], $1.linha, $1.coluna ) +
                   $1.c + "{}" + "=" + "^"; }
        ;

CMD_CONST: CONST CONST_VARs { $$.c = $2.c; }
         ;

CONST_VARs : CONST_VAR ',' CONST_VARs { $$.c = $1.c + $3.c; }
           | CONST_VAR
           ;

CONST_VAR : ID '=' E
            { $$.c = declara_var( Const, $1.c[0], $1.linha, $1.coluna ) +
                     $1.c + $3.c + "=" + "^"; }
        | ID '=' '{' '}'
          {
            $$.c = declara_var( Const, $1.c[0], $1.linha, $1.coluna ) +
                   $1.c + "{}" + "=" + "^"; }
          ;

CMD_IF_ELSE : IF '(' E ')' CMD ELSE CMD
         { string lbl_true = gera_label( "lbl_true" );
           string lbl_fim_if = gera_label( "lbl_fim_if" );
           string definicao_lbl_true = ":" + lbl_true;
           string definicao_lbl_fim_if = ":" + lbl_fim_if;

            $$.c = $3.c +                       // Codigo da expressão
                   lbl_true + "?" +             // Código do IF
                   $7.c + lbl_fim_if + "#" +    // Código do False
                   definicao_lbl_true + $5.c +  // Código do True
                   definicao_lbl_fim_if         // Fim do IF
                   ;
         }
       ;

CMD_IF : IF '(' E ')' CMD
         { string lbl_true = gera_label( "lbl_true" );
           string lbl_fim_if = gera_label( "lbl_fim_if" );
           string definicao_lbl_true = ":" + lbl_true;
           string definicao_lbl_fim_if = ":" + lbl_fim_if;

            $$.c = $3.c +                       // Codigo da expressão
                   lbl_true + "?" +             // Código do IF
                   lbl_fim_if + "#" +    // Código do False
                   definicao_lbl_true + $5.c +  // Código do True
                   definicao_lbl_fim_if         // Fim do IF
                   ;
         }
       ;



LVALUEPROP : E '[' E ']' { $$.c = $1.c + $3.c; }
           | E '.' ID { $$.c = $1.c + $3.c; }
           ;

LIST  : '[' LISTVALS ']'
        { $$.c = "[]" + $2.c; }
      | '[' ']'
        { $$.c = vector<string>{"[]"}; }
      ;

LISTVALS  : LISTVALS ',' LISTVAL
            { $$.c = $1.c + to_string($1.contador + 1) + $3.c + "[<=]" ; $$.contador = $1.contador+1; }
          | LISTVAL
            { $$.c = vector<string>{"0"} + $1.c + "[<=]";}
          ;

LISTVAL : E
        | '{' '}' { $$.c = vector<string>{"{}"}; }
        | OBJECT
        ;

LISTA_ARGS : ARGS {$$.contador = $1.contador; }
           | { $$.clear(); }
           ;

ARGS : ARG ',' ARGS   { $$.c = $1.c + $3.c; $$.contador = $3.contador+1; }
      | ARG  { $$.contador++; }
      ;

ARG : E
    | '{' '}' { $$.c = vector<string> {"{}"}; }
    ;

E : ID '=' '{' '}'
    { checa_simbolo( $1.c[0], true ); $$.c = $1.c + "{}" + "="; }
  | ID '=' E
    { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $3.c + "="; }
  | ID '=' OBJECT
    { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $3.c + "="; }
  | ID '=' ANON_FUNC
    { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $3.c + "="; }
  | LVALUEPROP '=' E
    { $$.c = $1.c + $3.c + "[=]"; }
  | LVALUEPROP '=' '{' '}'
    { $$.c = $1.c + "{}" + "[=]"; }
  | LVALUEPROP '=' OBJECT
    { $$.c = $1.c + $3.c + "[=]"; }
  | LVALUEPROP '=' ANON_FUNC
    { $$.c = $1.c + $3.c + "[=]"; }
  | E '<' E
    { $$.c = $1.c + $3.c + $2.c; }
  | E IGUAL E
    { $$.c = $1.c + $3.c + $2.c; }
  | E '>' E
    { $$.c = $1.c + $3.c + $2.c; }
  | E '+' E
    { $$.c = $1.c + $3.c + $2.c; }
  | E '-' E
    { $$.c = $1.c + $3.c + $2.c; }
  | '-' E
    { $$.c = "0" + $2.c + $1.c; }
  | E '*' E
    { $$.c = $1.c + $3.c + $2.c; }
  | E '/' E
    { $$.c = $1.c + $3.c + $2.c; }
  | E '%' E
    { $$.c = $1.c + $3.c + $2.c; }
  | E AND E
    { $$.c = $1.c + $3.c + $2.c; }
  | E OR E
    { $$.c = $1.c + $3.c + $2.c; }
  | E MA_IG E
    { $$.c = $1.c + $3.c + $2.c; }
  | E ME_IG E
    { $$.c = $1.c + $3.c + $2.c; }
  | E DIF E
    { $$.c = $1.c + $3.c + $2.c; }
  | ID MAIS_IGUAL E
    { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $1.c + "@" + $3.c + "+" + "="; }
  | LVALUEPROP MAIS_IGUAL E
    { $$.c = $1.c + $1.c + "[@]" + $3.c + "+" + "[=]"; }
  | ID MAIS_MAIS
    { checa_simbolo( $1.c[0], true ); $$.c = $1.c + "@" + $1.c + $1.c + "@" + "1" + "+" + "=" + "^"; }
  | LVALUEPROP MAIS_MAIS
    { $$.c = $1.c + $1.c + "[@]" + "1" + "+" + "[=]"; }
  | CDOUBLE
  | CINT
  | CSTRING
  | CBOOL
  | ID
    { checa_simbolo( $1.c[0], false ); $$.c = $1.c + "@"; }
  | LVALUEPROP
    { $$.c = $1.c + "[@]"; }
  | LIST
  | '(' E ')'
    { $$.c = $2.c; }
  | '(' '{' '}' ')'
    { $$.c = vector<string>{"{}"}; }
  | E '(' LISTA_ARGS ')'
    { $$.c = $3.c + to_string($3.contador) + $1.c + "$"; }
  | ARROW_FUNC
  ;



OBJECT  :'{' LISTA_CAMPOS '}'
          { $$.c = vector<string>{"{}"} + $2.c; }
        ;

LISTA_CAMPOS  : CAMPOS
              ;

CAMPOS  : CAMPOS ',' CAMPO { $$.c = $1.c + $3.c; }
        | CAMPO
        ;

CAMPO : ID ':' E { $$.c = $1.c + $3.c + "[<=]"; }
      | ID ':' OBJECT { $$.c = $1.c + $3.c + "[<=]"; }
      ;


ARROW_FUNC  : ID SETA { in_func++; } E
              { string lbl_funcao = gera_label( "funcao" );
                string define_lbl_funcao = ":" + lbl_funcao;

                ts.push_back( map< string, Simbolo >{} );

                $$.c = vector<string>{ "{}" } + "'&funcao'" + lbl_funcao + "[<=]";
                funcoes = funcoes + define_lbl_funcao +
                declara_var( Let, $1.c[0], $1.linha, $1.coluna ) +
                $1.c + "arguments" + "@" + "0" + "[@]" + "=" + "^" +
                $4.c + "'&retorno'" + "@"+ "~";

                ts.pop_back();
                in_func--;
              }
            | ID SETA EMPILHA_TS { in_func++; }  '{' CMDs '}'
            {  string lbl_funcao = gera_label( "funcao" );
              string define_lbl_funcao = ":" + lbl_funcao;

              $$.c = vector<string>{ "{}" } + "'&funcao'" + lbl_funcao + "[<=]";

              funcoes = funcoes + define_lbl_funcao +
              declara_var( Let, $1.c[0], $1.linha, $1.coluna ) +
              $1.c + "arguments" + "@" + "0" + "[@]" + "=" + "^" +
              $6.c + "undefined" + "@" + "'&retorno'" + "@"+ "~";

              ts.pop_back();
              in_func--;
            }
            | '(' PARENTESES_FUNCAO SETA E
              { string lbl_funcao = gera_label( "funcao" );
                string define_lbl_funcao = ":" + lbl_funcao;

                $$.c = vector<string>{ "{}" } + "'&funcao'" + lbl_funcao + "[<=]";
                funcoes = funcoes + define_lbl_funcao +
                $4.c + "'&retorno'" + "@"+ "~";

              }
            | '(' PARAMs PARENTESES_FUNCAO SETA E
              {

                string lbl_funcao = gera_label( "funcao" );
                string define_lbl_funcao = ":" + lbl_funcao;

                $$.c = vector<string>{ "{}" } + "'&funcao'" + lbl_funcao + "[<=]";
                funcoes = funcoes + define_lbl_funcao +
                $2.c +
                $5.c + "'&retorno'" + "@"+ "~";

                ts.pop_back();
              }
            /* | '(' PARENTESES_FUNCAO SETA EMPILHA_TS '{' CMDs '}'
            | '(' PARAMs PARENTESES_FUNCAO SETA EMPILHA_TS'{' CMDs '}' */
            ;


%%

#include "lex.yy.c"

vector<string> declara_var( TipoDecl tipo, string nome, int linha, int coluna ) {
  /* cerr << "insere_simbolo( " << tipo << ", " << nome << ", " << linha << ", " << coluna << ")" << endl; */
  auto& topo = ts.back();


  if( topo.count( nome ) == 0 ) {
    topo[nome] = Simbolo{ tipo, linha, coluna };
    return vector<string>{ nome, "&" };
  }
  else if( tipo == Var && topo[nome].tipo == Var ) {
    topo[nome] = Simbolo{ tipo, linha, coluna };
    return vector<string>{};
  }
  else {
    cerr << "Erro: a variável '" << nome << "' já foi declarada na linha " << topo[nome].linha << "." << endl;
    exit( 1 );
  }
}

void checa_in_func(){
  if(!in_func){
    cerr << "Erro: Não é permitido 'return' fora de funções." << endl;
    exit(1);
  }
}

void checa_simbolo( string nome, bool modificavel ) {
  for( int i = ts.size() - 1; i >= 0; i-- ) {
    auto& atual = ts[i];

    if( atual.count( nome ) > 0 ) {
      if( modificavel && atual[nome].tipo == Const ) {
        cerr << "Variavel '" << nome << "' não pode ser modificada." << endl;
        exit( 1 );
      }
      else return;
    }
  }
  if(in_func == 0){ cerr << "Erro: a variável '" << nome << "' não foi declarada." << endl;
              exit( 1 );
  }
}

void yyerror( const char* st ) {
   cerr << st << endl;
   cerr << "Proximo a: " << yytext << endl;
   exit( 1 );
}

int main( int argc, char* argv[] ) {
  /* yydebug = 1; */
  yyparse();
  return 0;
}