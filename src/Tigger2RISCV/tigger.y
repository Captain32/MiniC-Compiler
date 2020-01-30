%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int stk = 0;
int yylex(void);
extern void yyerror(char*);
extern FILE* yyin;
extern FILE* yyout;
extern int lineno;
%}

%union {
    int val;
    char* str;
};

%token <str>    ARR_L   ARR_R   VAR
%token <str>    MALLOC  IF  GOTO    CALL
%token <str>    STORE   LOAD    LOADADDR
%token <str>    RETURN  END COLON   ASSIGN
%token <str>    OP  REG LABEL   FUNC
%token <val>    INTEGER

%%

goal: goal func_decl
    | goal global_var_decl
    | { }
    ;

global_var_decl: VAR ASSIGN INTEGER {
        fprintf(yyout,"\t.global %s\n",$1);
        fprintf(yyout,"\t.section .sdata\n");
        fprintf(yyout,"\t.align 2\n");
        fprintf(yyout,"\t.type %s, @object\n",$1);
        fprintf(yyout,"\t.size %s, 4\n",$1);
        fprintf(yyout,"%s:\n",$1);
        fprintf(yyout,"\t.word %d\n",$3);
    }
    | VAR ASSIGN MALLOC INTEGER {
        fprintf(yyout,"\t.comm %s, %d, 4\n",$1,$4*4);
    }
    ;

func_decl: func_begin func_body func_end { }
    ;

func_begin: FUNC ARR_L INTEGER ARR_R ARR_L INTEGER ARR_R {
        stk=($6/4+1)*16;
        fprintf(yyout,"\t.text\t\n");
        fprintf(yyout,"\t.align 2\n");
        fprintf(yyout,"\t.global %s\n",$1+2);
        fprintf(yyout,"\t.type %s, @function\n",$1+2);
        fprintf(yyout,"%s:\n",$1+2);
        if(stk<2048){
            fprintf(yyout,"\taddi sp, sp, %d\n",-stk);
            fprintf(yyout,"\tsw ra, %d(sp)\n",stk-4);
        }
        else{
            fprintf(yyout,"\tli s11, %d\n",stk);
            fprintf(yyout,"\tsub sp, sp, s11\n");
            fprintf(yyout,"\tadd s11, sp, s11\n");
            fprintf(yyout,"\tsw ra, %d(s11)\n",-4);
        }
    }
    ;

func_end: END FUNC {
        fprintf(yyout,"\t.size %s, .-%s\n",$2+2,$2+2);
    }
    ;

func_body   : func_body REG ASSIGN REG OP REG {   // rd = rs1 op rs2
        if(!strcmp($5,"+"))
            fprintf(yyout,"\tadd %s, %s, %s\n",$2,$4,$6);
        else if(!strcmp($5,"-"))
            fprintf(yyout,"\tsub %s, %s, %s\n",$2,$4,$6);
        else if(!strcmp($5,"*"))
            fprintf(yyout,"\tmul %s, %s, %s\n",$2,$4,$6);
        else if(!strcmp($5,"/"))
            fprintf(yyout,"\tdiv %s, %s, %s\n",$2,$4,$6);
        else if(!strcmp($5,"%"))
            fprintf(yyout,"\trem %s, %s, %s\n",$2,$4,$6);
        else if(!strcmp($5,"&&")){
            fprintf(yyout,"\tand %s, %s, %s\n",$2,$4,$6);
            fprintf(yyout,"\tsnez %s, %s\n",$2,$2);
        }
        else if(!strcmp($5,"||")){
            fprintf(yyout,"\tor %s, %s, %s\n",$2,$4,$6);
            fprintf(yyout,"\tsnez %s, %s\n",$2,$2);
        }
        else if(!strcmp($5,"==")){
            fprintf(yyout,"\txor %s, %s, %s\n",$2,$4,$6);
            fprintf(yyout,"\tseqz %s, %s\n",$2,$2);
        }
        else if(!strcmp($5,"!=")){
            fprintf(yyout,"\txor %s, %s, %s\n",$2,$4,$6);
            fprintf(yyout,"\tsnez %s, %s\n",$2,$2);
        }
        else if(!strcmp($5,"<"))
            fprintf(yyout,"\tslt %s, %s, %s\n",$2,$4,$6);
        else if(!strcmp($5,">"))
            fprintf(yyout,"\tslt %s, %s, %s\n",$2,$6,$4);
    }
    | func_body REG ASSIGN REG OP INTEGER {
        if($6<2048){
            if(!strcmp($5,"+"))
                fprintf(yyout,"\taddi %s, %s, %d\n",$2,$4,$6);
            else if(!strcmp($5,"<"))
                fprintf(yyout,"\tslti %s, %s, %d\n",$2,$4,$6);
        }
        else{
            fprintf(yyout,"\tli s11, %d\n",$6);
            if(!strcmp($5,"+"))
                fprintf(yyout,"\tadd %s, %s, s11\n",$2,$4);
            else if(!strcmp($5,"<"))
                fprintf(yyout,"\tslt %s, %s, s11\n",$2,$4);
        }
    }
    | func_body REG ASSIGN OP REG {
        if(!strcmp($4,"-"))
            fprintf(yyout,"\tsub %s, x0, %s\n",$2,$5);
        else if(!strcmp($4,"!"))
            fprintf(yyout,"\tseqz %s, %s\n",$2,$5);
    }
    | func_body REG ASSIGN REG {
        fprintf(yyout,"\tmv %s, %s\n",$2,$4);
    }
    | func_body REG ASSIGN INTEGER {
        fprintf(yyout,"\tli %s, %d\n",$2,$4);
    }
    | func_body REG ARR_L INTEGER ARR_R ASSIGN REG {
        if($4<2048){
            fprintf(yyout,"\tsw %s, %d(%s)\n",$7,$4,$2);
        }
        else{
            fprintf(yyout,"\tli s11, %d\n",$4);
            fprintf(yyout,"\tadd s11, s11, %s\n",$2);
            fprintf(yyout,"\tsw %s, (s11)\n",$7);
        }
    }
    | func_body REG ASSIGN REG ARR_L INTEGER ARR_R {
        if($6<2048){
            fprintf(yyout,"\tlw %s, %d(%s)\n",$2,$6,$4);
        }
        else{
            fprintf(yyout,"\tli s11, %d\n",$6);
            fprintf(yyout,"\tadd s11, s11, %s\n",$4);
            fprintf(yyout,"\tlw %s, (s11)\n",$2);
        }
    }
    | func_body IF REG OP REG GOTO LABEL {
        if(!strcmp($4,"<"))
            fprintf(yyout,"\tblt %s, %s, .%s\n",$3,$5,$7);
        else if(!strcmp($4,">"))
            fprintf(yyout,"\tbgt %s, %s, .%s\n",$3,$5,$7);
        else if(!strcmp($4,"!="))
            fprintf(yyout,"\tbne %s, %s, .%s\n",$3,$5,$7);
        else if(!strcmp($4,"=="))
            fprintf(yyout,"\tbeq %s, %s, .%s\n",$3,$5,$7);
        else if(!strcmp($4,"<="))
            fprintf(yyout,"\tble %s, %s, .%s\n",$3,$5,$7);
        else if(!strcmp($4,">="))
            fprintf(yyout,"\tble %s, %s, .%s\n",$5,$3,$7);
    }
    | func_body GOTO LABEL {
        fprintf(yyout,"\tj .%s\n",$3);
    }
    | func_body LABEL COLON {
        fprintf(yyout,"\t.%s:\n",$2);
    }
    | func_body CALL FUNC {
        fprintf(yyout,"\tcall %s\n",$3+2);
    }
    | func_body STORE REG INTEGER {
        if($4*4<2048){
            fprintf(yyout,"\tsw %s, %d(sp)\n",$3,$4*4);
        }
        else{
            fprintf(yyout,"\tli s11, %d\n",$4*4);
            fprintf(yyout,"\tadd s11, s11, sp\n");
            fprintf(yyout,"\tsw %s, (s11)\n",$3);
        }
    }
    | func_body LOAD INTEGER REG {
        if($3*4<2048){
            fprintf(yyout,"\tlw %s, %d(sp)\n",$4,$3*4);
        }
        else{
            fprintf(yyout,"\tli s11, %d\n",$3*4);
            fprintf(yyout,"\tadd s11, s11, sp\n");
            fprintf(yyout,"\tlw %s, (s11)\n",$4);
        }
    }
    | func_body LOAD VAR REG {
        fprintf(yyout,"\tlui %s, %%hi(%s)\n",$4,$3);
        fprintf(yyout,"\tlw %s, %%lo(%s)(%s)\n",$4,$3,$4);
    }
    | func_body LOADADDR INTEGER REG {
        if($3*4<2048){
            fprintf(yyout,"\taddi %s, sp, %d\n",$4,$3*4);
        }
        else{
            fprintf(yyout,"\tli s11, %d\n",$3*4);
            fprintf(yyout,"\tadd %s, sp, s11\n",$4);
        }
    }
    | func_body LOADADDR VAR REG {
        fprintf(yyout,"\tlui %s, %%hi(%s)\n",$4,$3);
        fprintf(yyout,"\taddi %s, %s, %%lo(%s)\n",$4,$4,$3);
    }
    | func_body RETURN {
        if(stk<2048){
            fprintf(yyout,"\tlw ra, %d(sp)\n",stk-4);
            fprintf(yyout,"\taddi sp, sp, %d\n",stk);
        }
        else{
            fprintf(yyout,"\tli s11, %d\n",stk);
            fprintf(yyout,"\tadd s11, sp, s11\n");
            fprintf(yyout,"\tlw ra, %d(s11)\n",-4);
            fprintf(yyout,"\tmv sp, s11\n");
        }
        
        fprintf(yyout,"\tjr ra\n");
    }
    | { }
    ;

%%

int main(int argc,char **argv)
{
    if (argc > 1) 
    {
    	FILE *infile;
    	infile=fopen(argv[1],"r");
    	if(!infile) 
    	{
       		fprintf(stderr,"could not open %s\n",argv[1]);
       		exit(1);
    	}
    	yyin=infile; 
    }
    yyparse();
    return 0;
}