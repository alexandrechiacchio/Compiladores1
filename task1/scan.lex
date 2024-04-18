/* Coloque aqui definições regulares */
%{

#include <iostream>

using namespace std;

string lexema;



string remove_double_quote_string_operators(string s){
	string ret;
	for(size_t i = 0; i<s.size(); i++){
		if(	!(s[i] == '\\' and (s[i+1] == '\"' or s[i+1] == '\'')) and
			!(s[i] == '\"' and s[i+1] == '\"'))
			ret += s[i];
	}
	return ret;
}

string remove_single_quote_string_operators(string s){
	string ret;
	for(size_t i = 0; i<s.size(); i++){
		if(	!(s[i] == '\\' and (s[i+1] == '\"' or s[i+1] == '\'')) and
			!(s[i] == '\'' and s[i+1] == '\''))
			ret += s[i];
	}
	return ret;
}

%}


WS	[ \n\r\t]
DIGIT  [0-9]
CHAR   [A-Za-z]
NUM     {DIGIT}+
UNDERLINE   "_"
ID      ({CHAR}|{UNDERLINE}|[$])({CHAR}|{DIGIT}|{UNDERLINE})*


%Start EXPR
%%
	/* Padrões e ações. Nesta seção, comentários devem ter um tab antes */

{WS}					{ /* ignora espaços, tabs e '\n' */ }


	/* Todas as palavras reservadas devem aparecer antes do padrão do ID */
[fF][oO][rR]												{ lexema = yytext; return _FOR; }
[iI][fF]													{ lexema = yytext; return _IF; }
">="														{ lexema = yytext; return _MAIG; }
"<="														{ lexema = yytext; return _MEIG; }
"=="														{ lexema = yytext; return _IG; }
"!="														{ lexema = yytext; return _DIF; }

	/* _COMENTARIO, meu deus como isso demorou*/
("//".*)|"/*"([^*]*[*]+[^*/])*[^*]*[*]+"/" 					{ lexema = yytext; return _COMENTARIO; }

	/* _STRING */
\"([^"]|\\\"|\"\")*\"										{ lexema = yytext; lexema = remove_double_quote_string_operators(lexema.substr(1, lexema.size()-2)); return _STRING; }
\'([^']|\\\'|\'\')*\'										{ lexema = yytext; lexema = remove_single_quote_string_operators(lexema.substr(1, lexema.size()-2)); return _STRING; }
	/* _STRING2 */
(`|"}")([^&`{]|[$[^{]]|[^$][{])*`							{ lexema = yytext; lexema = lexema.substr(1, lexema.size()-2); return _STRING2;  }
`([^`$]*[$]+[^{])*[^$`]*[$]+"{" 							{ lexema = yytext; BEGIN EXPR;
																if(lexema.back() == '{') unput('{'), unput('$');
																lexema = lexema.substr(1, lexema.size()-3);
																return _STRING2;
															}
	/* _EXPR */
"${"{ID} 													{ lexema = yytext; lexema = lexema.substr(2, lexema.size()-2); return _EXPR; }

	/* _INT */
{NUM}														{ lexema = yytext; return _INT; }
	/* _FLOAT */
{NUM}([.]{NUM})?([eE][+-]?{NUM})? 							{ lexema = yytext; return _FLOAT; }
	/* _ID */
{ID}				{ lexema = yytext; return _ID; }
	/* _ID error */
({CHAR}|{UNDERLINE}|[$])({CHAR}|{DIGIT}|{UNDERLINE}|[$])*	{ lexema = yytext; cout << "Erro: Identificador invalido: " << lexema << '\n'; }

  /* Essa deve ser a última regra. Dessa forma qualquer caractere isolado será retornado pelo seu código ascii. */
.       													{ lexema = yytext; return yytext[0]; }
%%

/* Não coloque nada aqui - a função main é automaticamente incluída na hora de avaliar e dar a nota. */