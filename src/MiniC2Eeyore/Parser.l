%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "y.tab.h"

void yyerror(char*);
int lineno = 1;
%}

%%

[ \t]+
[\n]	{ lineno++; }

"int"	{ yylval.name = strdup(yytext); return TYPE; }
"main"	{ yylval.name = strdup(yytext); return MAIN; }
"if"	{ yylval.name = strdup(yytext); return IF; }
"else"	{ yylval.name = strdup(yytext); return ELSE; }
"while"	{ yylval.name = strdup(yytext); return WHILE; }
"return"	{ yylval.name = strdup(yytext); return RETURN; }
[a-zA-Z_]([a-zA-Z0-9_])*	{ yylval.name = strdup(yytext); return ID; }
[0-9]+	{ yylval.value = atoi(yytext); return NUM; }

"="	{ yylval.name = strdup(yytext); return ASSIGN; }
"||"	{ yylval.name = strdup(yytext); return OR; }
"&&"	{ yylval.name = strdup(yytext); return AND; }
"=="	{ yylval.name = strdup(yytext); return ISEQUAL; }
"!="	{ yylval.name = strdup(yytext); return ISEQUAL; }
"<"	{ yylval.name = strdup(yytext); return CMP; }
">"	{ yylval.name = strdup(yytext); return CMP; }
"+"	{ yylval.name = strdup(yytext); return ADDSUB; }
"-"	{ yylval.name = strdup(yytext); return ADDSUB; }
"*"	{ yylval.name = strdup(yytext); return MULDIV; }
"/"	{ yylval.name = strdup(yytext); return MULDIV; }
"%"	{ yylval.name = strdup(yytext); return MULDIV; }
"!"	{ yylval.name = strdup(yytext); return NOT; }

"("	{ yylval.value = lineno; return PRN_L; }
")"	{ yylval.value = lineno; return PRN_R; }
"["	{ yylval.value = lineno; return ARR_L; }
"]"	{ yylval.value = lineno; return ARR_R; }
"{"	{ yylval.value = lineno; return BRC_L; }
"}"	{ yylval.value = lineno; return BRC_R; }
","	{ yylval.value = lineno; return COMMA; }
";"	{ yylval.value = lineno; return EOL; }

"//"[^\n]* //注释

. {
	char msg[50] = "unrecognized input ";
	strcat(msg, yytext);
	yyerror(msg);
}

%%

int yywrap()
{
	return 1;
}
