%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "Tree.h"
#include "Symbol.h"
#include "Error.h"
#include "Convert.h"

int yylex(void);
void yyerror(char*);

extern FILE* yyin;
extern FILE* yyout;
extern int lineno;
struct TreeNode* root;
char *infile_path,*outfile_path;
%}

%union {
	int value;
	char* name;
	struct TreeNode* node;
};

//终结符
%token <name> TYPE MAIN IF ELSE WHILE RETURN ID
%token <value> NUM
%token <value> PRN_L PRN_R ARR_L ARR_R BRC_L BRC_R COMMA EOL

//非终结符
%type <node> Goal BeforeList MainFunc FuncDefn FuncDecl ParamDeclList
%type <node> FuncDeclStmtList VarDefn VarDecl Stmt StmtList Expr ParamList
%type <node> Type Integer Identifier

//运算符号，优先级从上到下递增
%right <name> ASSIGN
%left <name> OR
%left <name> AND
%left <name> ISEQUAL
%left <name> CMP
%left <name> ADDSUB
%left <name> MULDIV
%right <name> NOT

%%

Goal	: BeforeList MainFunc { //BeforeList为main之前语句形成的串的最右端
		struct TreeNode* tmp_node=$1;
		$$=new_treenode(lineno,TN_GOAL,NULL,CN_GOAL);
		tmp_node=to_left(tmp_node,$$,0);
		$$->child[0]=tmp_node;
		$$->child[1]=$2; 
		$2->parent=$$;
		$2->child_idx=1;
		root=$$;
	}
	;

BeforeList	: BeforeList VarDefn { //main函数之前的变量、函数声明、实现从前到后串成一串
		if($1!=NULL)
			$1->sibling_r=$2;
		$2->sibling_l=$1;
		$$=$2;
	}
	| BeforeList FuncDefn {
		if($1!=NULL)
			$1->sibling_r=$2;
		$2->sibling_l=$1;
		$$=$2;
	}
	| BeforeList FuncDecl {
		if($1!=NULL)
			$1->sibling_r=$2;
		$2->sibling_l=$1;
		$$=$2;
	}
	|  { $$=NULL; }
	;

MainFunc	: Type MAIN PRN_L PRN_R BRC_L FuncDeclStmtList BRC_R {
		struct TreeNode* tmp_node=new_treenode($1->lineno, TN_IDENTIFIER, strdup("main"),CN_IDENTIFIER);
		$$=new_treenode(lineno,TN_FUNCDEFN,NULL,CN_FUNCDEFN);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0; //TYPE为int
		$$->child[1]=tmp_node; tmp_node->parent=$$; tmp_node->child_idx=1; //函数名称Identifier，这里是"main"
		$$->child[2]=NULL; //main函数参数表为空
		tmp_node=$6;
		tmp_node=to_left(tmp_node,$$,3);
		$$->child[3]=tmp_node; //函数内部语句串
		set_death($3,lineno);
		new_symnode($1->lineno,S_FUNC,"main",$$); //"main"加到符号表
		if ($6==NULL)
			new_errnode(WARN_NO_RETURN,$$,NULL,NULL);
		else{
			for(tmp_node=$6;tmp_node->sibling_r!= NULL;tmp_node = tmp_node->sibling_r);
			if(tmp_node->type!=TN_STMT_RETURN)
				new_errnode(WARN_NO_RETURN,$$,NULL,NULL);
		}
	}
	;

FuncDefn	: Type Identifier PRN_L PRN_R BRC_L FuncDeclStmtList BRC_R { //无参数函数，与main函数类似
		struct TreeNode* tmp_node;
		$$=new_treenode($1->lineno,TN_FUNCDEFN,NULL,CN_FUNCDEFN);
		$$->child[0] = $1; $1->parent = $$; $1->child_idx = 0;
		$$->child[1] = $2; $2->parent = $$; $2->child_idx = 1;
		$$->child[2] = NULL;
		tmp_node=$6;
		tmp_node=to_left(tmp_node,$$,3);
		$$->child[3]=tmp_node;
		set_death($3,lineno);
		new_symnode($1->lineno,S_FUNC,$2->name,$$);
		if ($6==NULL)
			new_errnode(WARN_NO_RETURN,$$,NULL,NULL);
		else{
			for(tmp_node=$6;tmp_node->sibling_r!= NULL;tmp_node=tmp_node->sibling_r);
			if(tmp_node->type!=TN_STMT_RETURN)
				new_errnode(WARN_NO_RETURN,$$,NULL,NULL);
		}
	}
	| Type Identifier PRN_L ParamDeclList PRN_R BRC_L FuncDeclStmtList BRC_R { //有参数函数
		struct TreeNode* tmp_node;
		$$=new_treenode($1->lineno,TN_FUNCDEFN,NULL,CN_FUNCDEFN);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$2; $2->parent=$$; $2->child_idx=1;
		tmp_node=$4;
		tmp_node=to_left(tmp_node,$$,2);
		$$->child[2]=tmp_node;
		tmp_node=$7;
		tmp_node=to_left(tmp_node,$$,3);
		$$->child[3]=tmp_node;
		set_death($3,lineno);
		new_symnode($1->lineno,S_FUNC,$2->name,$$);
		if($7==NULL)
			new_errnode(WARN_NO_RETURN,$$,NULL,NULL);
		else{
			for(tmp_node=$7;tmp_node->sibling_r!=NULL;tmp_node=tmp_node->sibling_r);
			if(tmp_node->type!=TN_STMT_RETURN)
				new_errnode(WARN_NO_RETURN,$$,NULL,NULL);
		}
	}
	;

FuncDecl	: Type Identifier PRN_L PRN_R EOL { //无参数函数声明，只有实现了函数体才能调用，所以函数声明的Identifier无需加入符号表
		$$=new_treenode(lineno,TN_FUNCDECL,NULL,CN_FUNCDECL);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$2; $2->parent=$$; $2->child_idx=1;
		$$->child[2]=NULL;
		if(strcmp($1->name,"int")==0&&(strcmp($2->name,"getint")==0||strcmp($2->name,"getchar")==0)) //getint()、getchar()特殊处理，需加入符号表
			new_symnode($1->lineno,S_FUNC,$2->name,$$);
	}
	| Type Identifier PRN_L ParamDeclList PRN_R EOL { //有参数函数声明
		struct TreeNode* tmp_node;
		$$=new_treenode(lineno,TN_FUNCDECL,NULL,CN_FUNCDECL);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$2; $2->parent=$$; $2->child_idx=1;
		tmp_node=$4;
		tmp_node=to_left(tmp_node,$$,2);
		$$->child[2]=tmp_node;
		if(strcmp($1->name,"int")==0&&(strcmp($2->name,"putint")==0||strcmp($2->name,"putchar")==0)
		   &&(strcmp($4->child[0]->name,"int")==0&&$4->child[2]==NULL)&&$4->sibling_r==NULL){ //putint(int n)、putchar(int c)特殊处理，需加入符号表
			set_death($3,lineno);
			new_symnode($1->lineno,S_FUNC,$2->name,$$);
		}
		else
			free_symnodes($3,lineno);
	}
	;

ParamDeclList	: VarDecl	{ $$=$1; } //参数表，所有参数连成一个串，与BeforeList类似
	| ParamDeclList COMMA VarDecl {
		$1->sibling_r=$3;
		$3->sibling_l=$1;
		$$=$3;
	}
	;

FuncDeclStmtList	: FuncDeclStmtList Stmt	{ //函数内部的语句与函数声明序列，串成一个串，与BeforeList类似
		if($1!=NULL)
			$1->sibling_r=$2;
		$2->sibling_l=$1;
		$$=$2;
	}
	| FuncDeclStmtList FuncDecl {
		if($1!=NULL)
			$1->sibling_r=$2;
		$2->sibling_l=$1;
		$$=$2;
		new_errnode(WARN_FUNCDECL_IN_BODY,$2,NULL,NULL);
	}
	|  { $$=NULL; }
	;

VarDefn	: Type Identifier EOL { //变量定义
		$$=new_treenode(lineno,TN_VARDEFN,NULL,CN_VARDEFN);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$2; $2->parent=$$; $2->child_idx=1;
		$$->child[2]=NULL;
		new_symnode($1->lineno,S_INT,$2->name,$$);
	}
	| Type Identifier ARR_L Integer ARR_R EOL { //数组定义
		$$=new_treenode(lineno,TN_VARDEFN,NULL,CN_VARDEFN);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$2; $2->parent=$$; $2->child_idx=1;
		$$->child[2]=$4; $4->parent=$$; $4->child_idx=2;
		new_symnode($1->lineno,S_ARR,$2->name,$$);
	}
	;

VarDecl	: Type Identifier { //变量声明
		$$=new_treenode(lineno,TN_VARDECL,NULL,CN_VARDECL);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$2; $2->parent=$$; $2->child_idx=1;
		$$->child[2]=NULL;
		new_symnode($1->lineno,S_INT,$2->name,$$);
	}
	| Type Identifier ARR_L Integer ARR_R { //数组[integer]声明
		$$=new_treenode(lineno,TN_VARDECL,NULL,CN_VARDECL);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$2; $2->parent=$$; $2->child_idx=1;
		$$->child[2]=$4; $4->parent=$$; $4->child_idx=2;
		new_symnode($1->lineno,S_ARR,$2->name,$$);
	}
	| Type Identifier ARR_L ARR_R { //数组[]声明
		$$=new_treenode(lineno,TN_VARDECL,NULL,CN_VARDECL);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$2; $2->parent=$$; $2->child_idx=1;
		struct TreeNode* tmp_node=new_treenode(lineno,TN_INTEGER,NULL,CN_INTEGER);
		tmp_node->val=-1; //标记[]中没有长度数字，该参数可以为任意长度数组
		$$->child[2]=tmp_node; tmp_node->parent=$$; tmp_node->child_idx=2;
		new_symnode($1->lineno,S_ARR,$2->name,$$);
	}
	;

Stmt	: BRC_L StmtList BRC_R { //新的block
		struct TreeNode* tmp_node;
		$$=new_treenode(lineno,TN_STMT_BLOCK,NULL,CN_STMT_BLOCK);
		tmp_node=$2;
		tmp_node=to_left(tmp_node,$$,0);
		$$->child[0] = tmp_node;
		set_death($1, lineno);
	}
	| IF PRN_L Expr PRN_R Stmt { //if无else语句
		$$=new_treenode(lineno,TN_STMT_IF,NULL,CN_STMT_IF);
		$$->child[0]=$3; $3->parent=$$; $3->child_idx=0;
		$$->child[1]=$5; $5->parent=$$; $5->child_idx=1;
		$$->child[2]=NULL;
		set_death($2,lineno);
		if($3->type!=TN_EXPR_BILOGIC
		  &&!($3->type==TN_EXPR_UNI&&strcmp($3->name,"!") == 0) //非语句
		  &&$3->type!=TN_EXPR_IDENTIFIER //单个变量
		  &&$3->type!=TN_EXPR_ARR //单个数组元素
		  &&$3->type!=TN_EXPR_CALL){ //单个函数调用
			new_errnode(ERR_WRONG_EXPR,$3,NULL,NULL);
			print_ew();
		}
	}
	| IF PRN_L Expr PRN_R Stmt ELSE Stmt { //if-else语句
		$$=new_treenode(lineno,TN_STMT_IF,NULL,CN_STMT_IF);
		$$->child[0]=$3; $3->parent=$$; $3->child_idx=0;
		$$->child[1]=$5; $5->parent=$$; $5->child_idx=1;
		$$->child[2]=$7; $7->parent=$$; $7->child_idx=2;
		set_death($2,$7->lineno-1);
		set_death($7->lineno,lineno);
		if($3->type!=TN_EXPR_BILOGIC
		  &&!($3->type==TN_EXPR_UNI&&strcmp($3->name,"!") == 0)
		  &&$3->type!=TN_EXPR_IDENTIFIER
		  &&$3->type!=TN_EXPR_ARR
		  &&$3->type!=TN_EXPR_CALL){
			new_errnode(ERR_WRONG_EXPR,$3,NULL,NULL);
			print_ew();
		}
	}
	| WHILE PRN_L Expr PRN_R Stmt { //while语句
		$$=new_treenode(lineno,TN_STMT_WHILE,NULL,CN_STMT_WHILE);
		$$->child[0]=$3; $3->parent=$$; $3->child_idx=0;
		$$->child[1]=$5; $5->parent=$$; $5->child_idx=1;
		set_death($2,lineno);
		if($3->type!=TN_EXPR_BILOGIC
		  &&!($3->type==TN_EXPR_UNI&&strcmp($3->name,"!") == 0)
		  &&$3->type!=TN_EXPR_IDENTIFIER
		  &&$3->type!=TN_EXPR_ARR
		  &&$3->type!=TN_EXPR_CALL){
			new_errnode(ERR_WRONG_EXPR,$3,NULL,NULL);
			print_ew();
		}
	}
	| Identifier ASSIGN Expr EOL { //变量赋值语句
		$$=new_treenode(lineno,TN_STMT_VARASSN,NULL,CN_STMT_VARASSN);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$3; $3->parent=$$; $3->child_idx=1;
		if($3->type==TN_EXPR_BILOGIC||($3->type==TN_EXPR_UNI&&strcmp($3->name,"!")==0))
			new_errnode(WARN_MIXED_EXPR,$3,NULL,NULL);
		if(find_var(S_INT,$1)==0)
			print_ew();
	}
	| Identifier ARR_L Expr ARR_R ASSIGN Expr EOL { //数组元素赋值语句
		$$=new_treenode(lineno,TN_STMT_ARRASSN,NULL,CN_STMT_ARRASSN);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$3; $3->parent=$$; $3->child_idx=1;
		$$->child[2]=$6; $6->parent=$$; $6->child_idx=2;
		if($3->type==TN_EXPR_BILOGIC||($3->type==TN_EXPR_UNI&&strcmp($3->name,"!")==0))
			new_errnode(WARN_MIXED_EXPR,$3,NULL,NULL);
		if($6->type==TN_EXPR_BILOGIC||($6->type==TN_EXPR_UNI&&strcmp($6->name,"!")==0))
			new_errnode(WARN_MIXED_EXPR,$6,NULL,NULL);
		if(find_var(S_ARR,$1)==0)
			print_ew();
	}
	| VarDefn { //变量、数组定义语句
		$$=new_treenode(lineno,TN_STMT_VARDEFN,NULL,CN_STMT_VARDEFN);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
	}
	| RETURN Expr EOL { //return语句
		$$=new_treenode(lineno,TN_STMT_RETURN,NULL,CN_STMT_RETURN);
		$$->child[0]=$2; $2->parent=$$; $2->child_idx=0;
		if($2->type==TN_EXPR_BILOGIC||($2->type==TN_EXPR_UNI&&strcmp($2->name,"!")==0))
			new_errnode(WARN_MIXED_EXPR,$2,NULL,NULL);
	}
	;

StmtList	: StmtList Stmt	{ //语句串成一串，与BeforeList类似
		if($1!=NULL)
			$1->sibling_r=$2;
		$2->sibling_l=$1;
		$$=$2;
	}
	|  { $$=NULL; }
	;

Expr	: Expr OR Expr { //expr || expr
		$$=new_treenode(lineno,TN_EXPR_BILOGIC,strdup($2),CN_EXPR_BILOGIC);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$3; $3->parent=$$; $3->child_idx=1;
		if(($1->type!=TN_EXPR_BILOGIC&&$1->type!=TN_EXPR_UNI&&($1->type==TN_EXPR_UNI&&strcmp($1->name,"!")!=0))
		 ||($3->type!=TN_EXPR_BILOGIC&&$3->type!=TN_EXPR_UNI&&($3->type==TN_EXPR_UNI&&strcmp($3->name,"!")!=0)))
			new_errnode(WARN_MIXED_EXPR,$$,NULL,NULL);
	}
	| Expr AND Expr { //expr && expr
		$$=new_treenode(lineno,TN_EXPR_BILOGIC,strdup($2),CN_EXPR_BILOGIC);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$3; $3->parent=$$; $3->child_idx=1;
		if(($1->type!=TN_EXPR_BILOGIC&&$1->type!=TN_EXPR_UNI&&($1->type==TN_EXPR_UNI&&strcmp($1->name,"!")!=0))
		 ||($3->type!=TN_EXPR_BILOGIC&&$3->type!=TN_EXPR_UNI&&($3->type==TN_EXPR_UNI&&strcmp($3->name,"!")!=0)))
			new_errnode(WARN_MIXED_EXPR,$$,NULL,NULL);
	}
	| Expr ISEQUAL Expr { //expr != expr或expr == expr
		$$=new_treenode(lineno,TN_EXPR_BILOGIC,strdup($2),CN_EXPR_BILOGIC);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$3; $3->parent=$$; $3->child_idx=1;
		if(($1->type!=TN_EXPR_BILOGIC&&$1->type!=TN_EXPR_UNI&&($1->type==TN_EXPR_UNI&&strcmp($1->name,"!")!=0))
		 ||($3->type!=TN_EXPR_BILOGIC&&$3->type!=TN_EXPR_UNI&&($3->type==TN_EXPR_UNI&&strcmp($3->name,"!")!=0)))
			new_errnode(WARN_MIXED_EXPR,$$,NULL,NULL);
	}
	| Expr CMP Expr { //expr < expr或expr > expr
		$$=new_treenode(lineno,TN_EXPR_BILOGIC,strdup($2),CN_EXPR_BILOGIC);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$3; $3->parent=$$; $3->child_idx=1;
		if(($1->type!=TN_EXPR_BILOGIC&&$1->type!=TN_EXPR_UNI&&($1->type==TN_EXPR_UNI&&strcmp($1->name,"!")!=0))
		 ||($3->type!=TN_EXPR_BILOGIC&&$3->type!=TN_EXPR_UNI&&($3->type==TN_EXPR_UNI&&strcmp($3->name,"!")!=0)))
			new_errnode(WARN_MIXED_EXPR,$$,NULL,NULL);
	}
	| Expr ADDSUB Expr { //expr + expr或expr - expr
		$$=new_treenode(lineno,TN_EXPR_BIARITH,strdup($2),CN_EXPR_BIARITH);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$3; $3->parent=$$; $3->child_idx=1;
		if($1->type==TN_EXPR_BILOGIC||($1->type==TN_EXPR_UNI&&strcmp($1->name,"!")==0)
		 ||$3->type==TN_EXPR_BILOGIC||($3->type==TN_EXPR_UNI&&strcmp($3->name,"!")==0))
			new_errnode(WARN_MIXED_EXPR,$$,NULL,NULL);
	}
	| Expr MULDIV Expr { //expr * expr或expr / expr
		$$=new_treenode(lineno,TN_EXPR_BIARITH,strdup($2),CN_EXPR_BIARITH);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$3; $3->parent=$$; $3->child_idx=1;
		if($1->type==TN_EXPR_BILOGIC||($1->type==TN_EXPR_UNI&&strcmp($1->name,"!")==0)
		 ||$3->type==TN_EXPR_BILOGIC||($3->type==TN_EXPR_UNI&&strcmp($3->name,"!")==0))
			new_errnode(WARN_MIXED_EXPR,$$,NULL,NULL);
	}
	| Identifier ARR_L Expr ARR_R { //数组访问
		$$=new_treenode(lineno,TN_EXPR_ARR,NULL,CN_EXPR_ARR);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=$3; $3->parent=$$; $3->child_idx=1;
		if($3->type==TN_EXPR_BILOGIC||($3->type==TN_EXPR_UNI&&strcmp($3->name,"!")==0))
			new_errnode(WARN_MIXED_EXPR,$$,NULL,NULL);
		if(find_var(S_ARR,$1)==0)
			print_ew();
	}
	| Integer { //数字
		$$=new_treenode(lineno,TN_EXPR_INTEGER,NULL,CN_EXPR_INTEGER);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
	}
	| Identifier { //变量
		$$=new_treenode(lineno,TN_EXPR_IDENTIFIER,NULL,CN_EXPR_IDENTIFIER);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		if(find_var(S_INT,$1)==0)
			print_ew();
	}
	| ADDSUB Expr { //取相反数，- expr
		$$=new_treenode(lineno,TN_EXPR_UNI,strdup($1),CN_EXPR_UNI);
		$$->child[0]=$2; $2->parent=$$; $2->child_idx=0;
		if($2->type==TN_EXPR_BILOGIC||($2->type==TN_EXPR_UNI&&strcmp($2->name,"!")==0))
			new_errnode(WARN_MIXED_EXPR,$$,NULL,NULL);
	}
	| NOT Expr { //逻辑取反，! expr
		$$=new_treenode(lineno,TN_EXPR_UNI,strdup($1),CN_EXPR_UNI);
		$$->child[0]=$2; $2->parent=$$; $2->child_idx=0;
		if($2->type!=TN_EXPR_BILOGIC&&$2->type!=TN_EXPR_UNI&&($2->type==TN_EXPR_UNI&&strcmp($2->name,"!")!=0))
			new_errnode(WARN_MIXED_EXPR,$$,NULL,NULL);
	}
	| Identifier PRN_L PRN_R { //无参数函数调用
		$$=new_treenode(lineno,TN_EXPR_CALL,NULL,CN_EXPR_CALL);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		$$->child[1]=NULL;
	}
	| Identifier PRN_L ParamList PRN_R { //有参数函数调用
		struct TreeNode *tmp_node;
		$$=new_treenode(lineno,TN_EXPR_CALL,NULL,CN_EXPR_CALL);
		$$->child[0]=$1; $1->parent=$$; $1->child_idx=0;
		tmp_node=$3;
		tmp_node=to_left(tmp_node,$$,1);
		$$->child[1] = tmp_node;
	}
	| PRN_L Expr PRN_R { $$=$2; } //(expr)括号最高优先级
	;

ParamList	: Identifier { $$=$1; } //调用函数时的参数列表，串成一串，与BeforeList类似
	| Integer { $$=$1; }
	| ParamList COMMA Identifier {
		$1->sibling_r=$3;
		$3->sibling_l=$1;
		$$=$3;
	}
	| ParamList COMMA Integer {
		$1->sibling_r=$3;
		$3->sibling_l=$1;
		$$=$3;
	}
	;

Type	: TYPE { $$=new_treenode(lineno,TN_TYPE,strdup($1),CN_TYPE); } //类型，其实只有"int"
	;

Integer	: NUM { //数字
		$$=new_treenode(lineno,TN_INTEGER,NULL,CN_INTEGER);
		$$->val=$1;
	}
	;

Identifier	: ID { $$=new_treenode(lineno,TN_IDENTIFIER,strdup($1),CN_IDENTIFIER); } //名称
	;

%%

void yyerror(char* s)
{
	fprintf(stderr,"ERROR@L%d: %s\n",lineno,s);
	exit(-2);
}

int main(int argc,char** argv)
{
	infile_path=NULL;
	outfile_path=NULL;
	for(int i=1;i<argc;i++)
	{
		if(strcmp(argv[i],"-T")==0)
			continue;
		if(strcmp(argv[i],"-S")==0)
			continue;
		if(strcmp(argv[i],"-I")==0){
			if (i+1>=argc){
				printf("No input file\n");
				return -1;
			}
			yyin=fopen(argv[i+1],"r");
			if (yyin==NULL){
				printf("Cannot open file: %s\n",argv[i+1]);
				return -1;
			}
			i++;
			infile_path=argv[i];
			continue;
		}
		if(strcmp(argv[i],"-O")==0)
		{
			if (i+1>=argc){
				printf("No output file\n");
				return -1;
			}
			yyout=fopen(argv[i+1],"w");
			if (yyout==NULL){
				printf("Cannot open file: %s\n",argv[i+1]);
				return -1;
			}
			i++;
			outfile_path=argv[i];
			continue;
		}
		printf("Unknown option: %s\n",argv[i]);
		return -1;
	}
	init_tree();
	init_symtable();
	init_error();
	init_convert();
	yyparse();
	find_wrong_call(root);
	find_conflict();
	print_ew();
	convert_eeyore(root,"");
	for(int i=1;i<argc;i++){
		if(strcmp(argv[i],"-T")==0){
			printf("\nMiniC parse tree\n");
			print_tree(root,0,stdout);
		}
		if(strcmp(argv[i],"-S")==0)
		{
			printf("\nSymbol table\n");
			print_symtab(stdout);
		}
	}
	fclose(yyin);
	fclose(yyout);
	return 0;
}
