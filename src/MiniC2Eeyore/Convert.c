#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "Convert.h"
#include "Tree.h"
#include "Symbol.h"

extern FILE* yyout;

void init_convert()
{
	Tnum=0;
	tnum=0;
    lnum=0;
	pnum=0;
}

int convert_eeyore(struct TreeNode* tnode, char* pre_tab) //递归将语法树转为eeyore代码，pre_tab为前缀tab
{
	char* next_tab;
	struct TreeNode* tmp_node;
	struct SymNode* tmp_sym;
	int tmp,left_index,right_index,label_true,label_false,label_merge,label_judge;

	if(tnode==NULL)
		return -1;
	next_tab=(char*)malloc(sizeof(char)*(strlen(pre_tab)+10));
	strcpy(next_tab,pre_tab);
	strcat(next_tab,"\t"); //子结构的前缀tab
	switch(tnode->type)
	{
	case TN_GOAL:
		for(tmp_node=tnode->child[0];tmp_node!=NULL;tmp_node=tmp_node->sibling_r) //BeforeMain序列
			convert_eeyore(tmp_node,pre_tab);
		convert_eeyore(tnode->child[1], pre_tab); //main函数，进入TN_FUNCDEFN
		free(next_tab);
		return -1;
	case TN_FUNCDEFN:
		fprintf(yyout, "\n");
		pnum=0; //每个函数的参数独立编号
		for(tmp_node=tnode->child[2],tmp=0;tmp_node!=NULL;tmp_node=tmp_node->sibling_r,tmp++) //参数表
			convert_eeyore(tmp_node,next_tab); //进入TN_VARDECL
		fprintf(yyout,"%sf_%s [%d]",pre_tab,tnode->child[1]->name,tmp); //函数名f_name [参数个数]
		fprintf(yyout, "\n");
		pnum=0;
		for(tmp_node=tnode->child[3];tmp_node!= NULL;tmp_node=tmp_node->sibling_r) //函数体
			convert_eeyore(tmp_node,next_tab);
		fprintf(yyout,"%send f_%s\n\n",pre_tab,tnode->child[1]->name); //函数结束end f_name
	case TN_FUNCDECL:
        free(next_tab);
        return -1;
	case TN_VARDEFN:
		if(tnode->child[2]==NULL){ //变量
			fprintf(yyout,"%svar T%d",pre_tab,Tnum);
			tmp_sym=get_symnode(tnode->lineno,tnode->child[1]->name);
		}
		else{ //数组
			fprintf(yyout,"%svar %d T%d",pre_tab,tnode->child[2]->val*4,Tnum);
			tmp_sym=get_symnode(tnode->lineno,tnode->child[1]->name);
		}
		fprintf(yyout, "\n");
		tmp_sym->eeyore_idx=Tnum++;
		tmp_sym->eeyore_type='T';
		free(next_tab);
		return -1;
	case TN_VARDECL:
		tmp_sym=get_symnode(tnode->lineno,tnode->child[1]->name);
		tmp_sym->eeyore_idx=pnum++;
		tmp_sym->eeyore_type='p'; //变量声明用于参数表，类型为p
		free(next_tab);
		return -1;
	case TN_STMT_BLOCK:
        fprintf(yyout, "\n");
		for(tmp_node=tnode->child[0];tmp_node!=NULL;tmp_node=tmp_node->sibling_r)
			convert_eeyore(tmp_node,pre_tab);
		free(next_tab);
		return -1;
	case TN_STMT_IF:
		label_true=lnum++;
		label_merge=lnum++;
		label_false=lnum++;
		left_index=convert_eeyore(tnode->child[0],pre_tab); //先将expr转换，每个expr都会将结果赋值给tn，n为返回值
		fprintf(yyout,"%sif t%d != 0 goto l%d",pre_tab,left_index,label_true);
		fprintf(yyout,"\n");
		fprintf(yyout,"%sgoto l%d\n",pre_tab,label_false);
		fprintf(yyout,"l%d:\n",label_true);
		for(tmp_node=tnode->child[1];tmp_node!=NULL;tmp_node=tmp_node->sibling_r) //true(if段)
			convert_eeyore(tmp_node,next_tab);
		fprintf(yyout,"%sgoto l%d\n",next_tab,label_merge); //goto lmerge
		fprintf(yyout,"l%d:\n",label_false);
		for(tmp_node=tnode->child[2];tmp_node!=NULL;tmp_node=tmp_node->sibling_r) //false(else段)
			convert_eeyore(tmp_node,next_tab);
		fprintf(yyout,"l%d:\n",label_merge);
		free(next_tab);
		return -1;
	case TN_STMT_WHILE:
		label_judge=lnum++;
		label_true=lnum++;
		label_merge=lnum++;
		fprintf(yyout,"l%d:\n",label_judge);
		left_index=convert_eeyore(tnode->child[0],pre_tab); //expr，处理与if语句类似
		fprintf(yyout,"%sif t%d != 0 goto l%d\n",pre_tab,left_index,label_true);
		fprintf(yyout,"%sgoto l%d\n",pre_tab,label_merge);
		fprintf(yyout,"l%d:\n",label_true);
		for (tmp_node=tnode->child[1];tmp_node!=NULL;tmp_node=tmp_node->sibling_r) //循环体
			convert_eeyore(tmp_node,next_tab);
		fprintf(yyout,"%sgoto l%d\n",next_tab,label_judge); //跳转至判断expr
		fprintf(yyout,"l%d:\n",label_merge);
		free(next_tab);
		return -1;
	case TN_STMT_VARASSN:
		left_index=convert_eeyore(tnode->child[1], pre_tab); //expr转换，每个expr都会将结果赋值给tn，n为返回值
		tmp_sym=get_symnode(tnode->child[0]->lineno,tnode->child[0]->name);
		fprintf(yyout,"%s%c%d = t%d\n",pre_tab,tmp_sym->eeyore_type,tmp_sym->eeyore_idx,left_index);
		free(next_tab);
		return -1;
	case TN_STMT_ARRASSN:
		left_index=convert_eeyore(tnode->child[1],pre_tab); //索引expr计算
		right_index=convert_eeyore(tnode->child[2],pre_tab); //等号右侧expr计算
		tmp=tnum++;
		fprintf(yyout,"%svar t%d\n",pre_tab,tmp); //用于存索引*4
		fprintf(yyout,"%st%d = t%d * 4\n",pre_tab,tmp,left_index);
		tmp_sym=get_symnode(tnode->child[0]->lineno,tnode->child[0]->name);
		fprintf(yyout,"%s%c%d [t%d] = t%d",pre_tab,tmp_sym->eeyore_type,tmp_sym->eeyore_idx,tmp,right_index);
        fprintf(yyout, "\n");
		free(next_tab);
		return -1;
	case TN_STMT_VARDEFN:
		convert_eeyore(tnode->child[0],pre_tab);
		free(next_tab);
		return -1;
	case TN_STMT_RETURN:
		left_index=convert_eeyore(tnode->child[0],pre_tab);
		fprintf(yyout,"%sreturn t%d",pre_tab,left_index);
		fprintf(yyout,"\n");
		free(next_tab);
		return -1;
	case TN_EXPR_BIARITH:
	case TN_EXPR_BILOGIC:
		left_index=convert_eeyore(tnode->child[0], pre_tab); //左expr
		right_index=convert_eeyore(tnode->child[1], pre_tab); //右expr
		tmp=tnum++;
		fprintf(yyout,"%svar t%d\n",pre_tab,tmp);
		fprintf(yyout,"%st%d = t%d %s t%d",pre_tab,tmp,left_index,tnode->name,right_index); //左op右
		fprintf(yyout,"\n");
		free(next_tab);
		return tmp;
	case TN_EXPR_ARR:
		tmp_sym=get_symnode(tnode->child[0]->lineno,tnode->child[0]->name);
		left_index=convert_eeyore(tnode->child[1],pre_tab); //索引expr
		right_index=tnum++;
		fprintf(yyout,"%svar t%d\n",pre_tab,right_index);
		fprintf(yyout,"%st%d = t%d * 4\n",pre_tab,right_index,left_index);
		tmp=tnum++;
		fprintf(yyout,"%svar t%d\n",pre_tab,tmp);
		fprintf(yyout,"%st%d = %c%d [t%d]",pre_tab,tmp,tmp_sym->eeyore_type,tmp_sym->eeyore_idx,right_index);
        fprintf(yyout,"\n");
		free(next_tab);
		return tmp;
	case TN_EXPR_INTEGER:
		tmp=tnum++;
		fprintf(yyout,"%svar t%d\n",pre_tab,tmp);
		fprintf(yyout,"%st%d = %d",pre_tab,tmp,tnode->child[0]->val);
		fprintf(yyout,"\n");
		free(next_tab);
		return tmp;
	case TN_EXPR_IDENTIFIER:
		tmp_sym=get_symnode(tnode->child[0]->lineno,tnode->child[0]->name);
		tmp=tnum++;
		fprintf(yyout,"%svar t%d\n",pre_tab,tmp);
		fprintf(yyout,"%st%d = %c%d",pre_tab,tmp,tmp_sym->eeyore_type,tmp_sym->eeyore_idx);
        fprintf(yyout,"\n");
		free(next_tab);
		return tmp;
	case TN_EXPR_UNI:
		right_index=convert_eeyore(tnode->child[0], pre_tab);
		tmp=tnum++;
		fprintf(yyout,"%svar t%d\n",pre_tab,tmp);
		fprintf(yyout,"%st%d = %s t%d",pre_tab,tmp,tnode->name,right_index);
		fprintf(yyout,"\n");
		free(next_tab);
		return tmp;
	case TN_EXPR_CALL:
		tmp=tnum++;
		fprintf(yyout,"%svar t%d\n",pre_tab,tmp);
		for(tmp_node=tnode->child[1];tmp_node!=NULL;tmp_node=tmp_node->sibling_r){
            if(tmp_node->type==TN_INTEGER){ //整数常量
                fprintf(yyout,"%sparam %d\n",pre_tab,tmp_node->val);
                continue;
            }
			tmp_sym=get_symnode(tmp_node->lineno,tmp_node->name);
			fprintf(yyout,"%sparam %c%d\n",pre_tab,tmp_sym->eeyore_type,tmp_sym->eeyore_idx);
		}
		fprintf(yyout,"%st%d = call f_%s",pre_tab,tmp,tnode->child[0]->name);
		fprintf(yyout,"\n");
		free(next_tab);
		return tmp;
	case TN_TYPE:
	case TN_INTEGER:
	case TN_IDENTIFIER: free(next_tab); return -1;
	case TN_INIT:
	default:
		fprintf(stderr, "ERROR: Unknown parse tree node\n");
		exit(-2);
	}
}
