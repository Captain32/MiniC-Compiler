#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "Tree.h"

void init_tree()
{
    treenode_num=0;
}

struct TreeNode* new_treenode(int lineno,int type,char *name,int n_child) //new一个树节点，lineno行号，type节点类型，name节点名称(若有)，n_child节点子节点数
{
    struct TreeNode* newnode=(struct TreeNode*)malloc(sizeof(struct TreeNode));
    newnode->idx=treenode_num++;
    newnode->lineno=lineno;
    newnode->type=type;
    newnode->val=-1;
    newnode->name=name;
    newnode->n_child=n_child;
    newnode->child_idx=-1;
    newnode->parent=NULL;
    for(int i=0;i<MAX_CN;i++)
        newnode->child[i]=NULL;
    newnode->sibling_l=NULL;
    newnode->sibling_r=NULL;
    return newnode;
}

struct TreeNode* to_left(struct TreeNode* curnode,struct TreeNode* parent,int child_idx) //从curnode到最左兄弟，设置为parent的第child_idx个子节点
{
    while(curnode!=NULL){
        curnode->parent=parent;
        curnode->child_idx=child_idx;
        if(curnode->sibling_l==NULL) break;
        curnode=curnode->sibling_l;
    }
    return curnode;
}

void print_treenode(struct TreeNode* arg_node, char* arg_prefix, FILE* f)
{
	char* prefix;
    prefix=strdup(arg_prefix);
	switch(arg_node->type)
	{
	case TN_GOAL: fprintf(f, "%s[*]Root(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_FUNCDEFN: fprintf(f, "%s[*]FuncDefn(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_FUNCDECL: fprintf(f, "%s[*]FuncDecl(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_VARDEFN: fprintf(f, "%s[*]VarDefn(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_VARDECL: fprintf(f, "%s[*]VarDecl(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_STMT_BLOCK: fprintf(f, "%s[*]StmtBlock(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_STMT_IF: fprintf(f, "%s[*]StmtIf(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_STMT_WHILE: fprintf(f, "%s[*]StmtWhile(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_STMT_VARASSN: fprintf(f, "%s[*]StmtVarAssn(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_STMT_ARRASSN: fprintf(f, "%s[*]StmtArrAssn(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_STMT_VARDEFN: fprintf(f, "%s[*]StmtVarDefn(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_STMT_RETURN: fprintf(f, "%s[*]StmtReturn(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_EXPR_BIARITH: fprintf(f, "%s[*]ExprBiArith(%s)(%d) at L%d", prefix, arg_node->name, arg_node->idx, arg_node->lineno); break;
	case TN_EXPR_BILOGIC: fprintf(f, "%s[*]ExprBiLogic(%s)(%d) at L%d", prefix, arg_node->name, arg_node->idx, arg_node->lineno); break;
	case TN_EXPR_ARR: fprintf(f, "%s[*]ExprArr(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_EXPR_INTEGER: fprintf(f, "%s[*]ExprInt(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_EXPR_IDENTIFIER: fprintf(f, "%s[*]ExprId(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_EXPR_UNI: fprintf(f, "%s[*]ExprUni(%s)(%d) at L%d", prefix, arg_node->name, arg_node->idx, arg_node->lineno); break;
	case TN_EXPR_CALL: fprintf(f, "%s[*]ExprCall(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	case TN_TYPE: fprintf(f, "%s[*]Type(%s)(%d) at L%d", prefix, arg_node->name, arg_node->idx, arg_node->lineno); break;
	case TN_INTEGER: fprintf(f, "%s[*]Int(%d)(%d) at L%d", prefix, arg_node->val, arg_node->idx, arg_node->lineno); break;
	case TN_IDENTIFIER: fprintf(f, "%s[*]Id(%s)(%d) at L%d", prefix, arg_node->name, arg_node->idx, arg_node->lineno); break;
	case TN_INIT: fprintf(f, "%s[!]UNKNOWN(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	default: fprintf(f, "%s[!]UNKNOWN(%d) at L%d", prefix, arg_node->idx, arg_node->lineno); break;
	}

	fprintf(f,"\n");
}

void print_tree(struct TreeNode *arg_node, int depth, FILE* f)
{
	char* prefix;
	char prefix_unit[6]="    ";
	struct TreeNode *tmp_node;
	if (arg_node==NULL)
		return;
    prefix = (char*)malloc(sizeof(char)*depth*4+10);
    memset(prefix, 0, sizeof(char)*depth*4+10);
    for (int i=0;i<depth;i++)
        strcat(prefix,prefix_unit);
    print_treenode(arg_node,prefix,f);
	for (int i=0;i<arg_node->n_child;i++){
		fprintf(f,"%s  %d's child%d\n",prefix,arg_node->idx,i+1);
		tmp_node=arg_node->child[i];
		if(tmp_node==NULL){
			fprintf(f,"%s    NONE\n",prefix);
			continue;
		}
		while(tmp_node!=NULL){
			print_tree(tmp_node,depth+1,f);
			tmp_node=tmp_node->sibling_r;
		}
	}
	free(prefix);
}
