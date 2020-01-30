%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include"eeyore.tab.h"
#define MAXTOKENLEN 100
char tokenString[MAXTOKENLEN+1];
int val;
%}


digit       [0-9]
number      {digit}+
label       l{number}
letter      [a-zA-Z_]
identifier  {letter}({letter}|{digit})*
variable    [Ttp]{number}
function    f_{identifier}
whitespace  [ \t\n]+

%option yylineno

%%
"if"	      {return IF;}
"var"         {return VAR;}
"return"      {return RETURN;} 
"goto"	      {return GOTO;}
"call"        {return CALL;}
"end"	      {return END;}
"param"	      {return PARAM;}
"!="          {return NE;} 
"=="          {return EQ;} 
"="           {return ASSIGN;} 
"+"           {return ADD;}
"-"           {return SUB;}
"*"           {return MUL;}
"/"           {return DIV;}
"%"           {return MOD;}
"&&"          {return AND;}
"||"          {return OR;}
">"           {return G;}
"<"           {return L;}
"!"           {return NOT;}
":"           {return yytext[0];}
"["           {return yytext[0];}
"]"           {return yytext[0];}
{label}       {strcpy(tokenString,yytext); return LABEL; }
{number}      {val=atoi(yytext);return INTEGER;}
{variable}    {strcpy(tokenString,yytext); return ID;}
{function}    {strcpy(tokenString,yytext); return FUNC; }
{whitespace}  {}
"//"[^\n]*    {}
%%

int yywrap()
{
	return 1;
}

void yyerror(char *message)
{
    printf("%d %s\n",yylineno,message);
    exit(0);
}

