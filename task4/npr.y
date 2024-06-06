%{
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <cstring>

using namespace std;

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

%token ID IF ELSE LET CONST VAR PRINT FOR WHILE FUNCTION RETURN ASM
%token CDOUBLE CSTRING CINT
%token AND OR ME_IG MA_IG DIF IGUAL
%token MAIS_IGUAL MAIS_MAIS

%right '=' MAIS_IGUAL
%nonassoc AND OR
%nonassoc IGUAL DIF
%nonassoc '<' '>' ME_IG MA_IG
%left '+' '-'
%left '*' '/' '%'
%right MAIS_MAIS
%nonassoc '[' '('
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
    | '{' CMDs '}' PPs
      { $$.c = $2.c; }
    ;

PP1s : ';' PPs
     ;

PPs : PP PPs
    | { $$.clear(); }
    ;

PP : ';'
   ;

CMD_ASM : E ASM { $$.c = $1.c + $2.c; }
        ;

EMPILHA_TS : { ts.push_back( map< string, Simbolo >{} ); }
           ;

CMD_FUNC : FUNCTION ID { declara_var( Var, $2.c[0], $2.linha, $2.coluna ); }

             '(' EMPILHA_TS LISTA_PARAMs ')' '{' CMDs '}'
           {
             string lbl_endereco_funcao = gera_label( "func_" + $2.c[0] );
             string definicao_lbl_endereco_funcao = ":" + lbl_endereco_funcao;


             $$.c = $2.c + "&" + $2.c + "{}"  + "=" + "'&funcao'" +
                    lbl_endereco_funcao + "[=]" + "^";
            funcoes = funcoes + definicao_lbl_endereco_funcao + $6.c + $9.c +
                       "undefined" + "@" + "'&retorno'" + "@"+ "~";
             ts.pop_back();
           }
         ;

LISTA_PARAMs : PARAMs
           | { $$.clear(); }
           ;

PARAMs : PARAMs ',' PARAM
       { // a & a arguments @ 0 [@] = ^
         $$.c = $1.c + $3.c + "&" + $3.c + "arguments" + "@" + to_string( $1.contador )
                + "[@]" + "=" + "^";

         if( $3.valor_default.size() > 0 ) {
           // Gerar código para testar valor default.
         }
         $$.contador = $1.contador + $3.contador;
       }
     | PARAM
       { // a & a arguments @ 0 [@] = ^
         $$.c = $1.c + "&" + $1.c + "arguments" + "@" + "0" + "[@]" + "=" + "^";

         if( $1.valor_default.size() > 0 ) {
           // Gerar código para testar valor default.
         }
         $$.contador = $1.contador;
       }
     ;

PARAM : ID
      { $$.c = $1.c;
        $$.contador = 1;
        $$.valor_default.clear();
        declara_var( Let, $1.c[0], $1.linha, $1.coluna );
      }
    | ID '=' E
      { // Código do IF
        $$.c = $1.c;
        $$.contador = 1;
        $$.valor_default = $3.c;
        declara_var( Let, $1.c[0], $1.linha, $1.coluna );
      }
    ;

CMD_RET : RETURN E { $$.c = $2.c + "\'&retorno\'" + "@" + "~"; }
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
        | ID '=' '{' '}'
          {
            $$.c = declara_var( Let, $1.c[0], $1.linha, $1.coluna ) +
                   $1.c + "{}" + "=" + "^"; }
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

LVALUE : ID
       ;

LVALUEPROP : E '[' E ']' { $$.c = $1.c + $3.c; }
           | E '.' ID { $$.c = $1.c + $3.c; }
           ;

LIST  : '[' LISTVALS ']' { $$.c = $1.c + $2.c + $3.c; }
      | '[' ']' { $$.c = vector<string>{"[]"}; }
      ;

LISTVALS : LISTVAL ',' LISTVALS   { $$.c = $1.c + $3.c; }
         | LISTVAL
         ;

LISTVAL : E
        ;

E : LVALUE '=' '{' '}'
    { checa_simbolo( $1.c[0], true ); $$.c = $1.c + "{}" + "="; }
  | LVALUE '=' E
    { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $3.c + "="; }
  | LVALUEPROP '=' E
     {$$.c = $1.c + $3.c + "[=]"; }
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
  | LVALUE MAIS_IGUAL E
    { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $1.c + "@" + $3.c + "+" + "="; }
  | LVALUEPROP MAIS_IGUAL E
    { $$.c = $1.c + $1.c + "[@]" + $3.c + "+" + "[=]"; }
  | LVALUE MAIS_MAIS
    { checa_simbolo( $1.c[0], true ); $$.c = $1.c + "@" + $1.c + $1.c + "@" + "1" + "+" + "=" + "^"; }
  | LVALUEPROP MAIS_MAIS
    { $$.c = $1.c + $1.c + "[@]" + "1" + "+" + "[=]"; }
  | CDOUBLE
  | CINT
  | CSTRING
  | LVALUE
    { checa_simbolo( $1.c[0], false ); $$.c = $1.c + "@"; }
  | LVALUEPROP
    { $$.c = $1.c + "[@]"; }
  | LIST
  | '(' E ')'
    { $$.c = $2.c; }
  | '(' '{' '}' ')'
    { $$.c = vector<string>{"{}"}; }
  | LVALUE '(' LISTVALS ')'
    { checa_simbolo( $1.c[0], false ); $$.c = $3.c + $1.c + "@" + "$"; }
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
    cerr << "Erro: a variável '" << nome << "' ja foi declarada na linha " << topo[nome].linha << "." << endl;
    exit( 1 );
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
    cerr << "Erro: a variável '" << nome << "' não foi declarada." << endl;
    exit( 1 );
}

void yyerror( const char* st ) {
   cerr << st << endl;
   cerr << "Proximo a: " << yytext << endl;
   exit( 1 );
}

int main( int argc, char* argv[] ) {
  yyparse();
  return 0;
}