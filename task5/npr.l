%{
int token( int tk );

%}

D  	    [0-9]
L   	[A-Za-z_]
INT	    {D}+
DOUBLE  {D}+"."{D}+([Ee][+\-]?{D}+)?
ID      {L}({L}|{D})*
CSTR   \"([^\"\n\\]|(\\\")|\"\"|"\\\\")+\"
CSTR2   \'([^\'\n\\]|(\\\')|\'\'|'\\\\')+\'


%%

"\t"       { coluna += 4; }
" "        { coluna++; }
"\n"	   { linha++; coluna = 0; }

{DOUBLE}   { return token( CDOUBLE ); }
{INT}	   { return token( CINT ); }

"&&"	   { return token( AND ); }
"||"	   { return token( OR ); }
"<="	   { return token( ME_IG ); }
">="	   { return token( MA_IG ); }
"!="	   { return token( DIF ); }
"=="	   { return token( IGUAL ); }

"+="       { return token( MAIS_IGUAL ); }
"++"       { return token( MAIS_MAIS ); }

"let"      { return token( LET ); }
"const"    { return token( CONST ); }
"var"      { return token( VAR ); }
"if"       { return token( IF ); }
"else"     { return token( ELSE ); }
  /* "print"    { return token( PRINT ); } */
"for"      { return token( FOR ); }
"while"      { return token( WHILE ); }
"function" { return token( FUNCTION ); }
"return" { return token( RETURN ); }
"true"|"false" { return token (CBOOL); }

"asm{".*"}"  { return token(ASM); }

{CSTR}|{CSTR2} { return token ( CSTRING ); }
{ID}       { return token( ID ); }

.          { return token( *yytext ); }

%%


vector<string> tokeniza(string s){
  vector<string> ret;
  int last = 4;
  for(int i = 4; i<s.size()-1; i++){
    if(s[i] == ' '){
      ret.push_back(s.substr(last, i-last));
      last = i+1;
    }
  }
  ret.push_back(s.substr(last, s.size()-1-last));
  return ret;
}

int token( int tk ) {
  yylval.c = vector<string>{ yytext };
  if(tk == ASM){
    yylval.c = tokeniza(yylval.c[0]);
  }
  coluna += strlen( yytext );

  yylval.linha = linha;
  yylval.coluna = coluna;

  return tk;
}