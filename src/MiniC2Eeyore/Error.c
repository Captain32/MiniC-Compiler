#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "Error.h"
#include "Symbol.h"
#include "Tree.h"

void init_error()
{
    error_num=-1;
    err_tail=err_head=new_errnode(EW_INIT,NULL,NULL,NULL);
}

struct ErrNode* new_errnode(int type, struct TreeNode* tnode, struct SymNode* snode1, struct SymNode* snode2) //new一个新错误节点，放到链表尾，type错误类型，tnode对应树节点，snode1、snode2冲突符号节点
{
    struct ErrNode* newnode=(struct ErrNode*)malloc(sizeof(struct ErrNode));
    newnode->idx=error_num++;
    newnode->type=type;
    newnode->node=tnode;
    newnode->sym1=snode1;
    newnode->sym2=snode2;
    newnode->next=NULL;
    newnode->prev=NULL;
    if(err_head!=NULL){
        newnode->prev=err_tail;
        err_tail->next=newnode;
    }
    err_tail=newnode;
    return newnode;
}

int find_var(int type,struct TreeNode* node) //查找node对应的符号节点，并检查类型是否与type一致
{
	struct SymNode* sym=get_symnode(node->lineno,node->name);
	if(sym==NULL){
		new_errnode(ERR_UNDEFINED_VAR,node,NULL,NULL);
		return 0;
	}
	else if(sym->type!=type){
		new_errnode(ERR_WRONG_ASSN,node,NULL,NULL);
		return 0;
	}
	else return 1;
}

int find_conflict() //查找是否有名称冲突
{
	if(sym_head->next==NULL) //符号表空
		return 0;
	if(sym_head->next->next==NULL) //符号表只有1个符号
		return 0;
	for(struct SymNode* i=sym_head->next->next;i!=NULL;i=i->next)
		for(struct SymNode* j=sym_head->next;j!=NULL&&j!=i;j=j->next)
			if(strcmp(i->name,j->name)==0){
				if(i->die_line==j->die_line //只有在同一作用域时die_line才会一样
                   &&(i->type==S_INT||i->type==S_ARR)
                   &&(j->type==S_INT||j->type==S_ARR)){
					new_errnode(ERR_CONFLICT_VAR, NULL, i, j);
					return 1;
				}
				else if(i->type==S_FUNC||j->type==S_FUNC){ //函数die_line为-1(全局)，只要重名就会冲突
					new_errnode(ERR_CONFLICT_FUNC,NULL,i,j);
					return 1;
				}
			}
	return 0;
}

int find_func(struct TreeNode* tnode) //tnode代表了一个函数调用节点，检查正确性
{
	struct SymNode* sym=get_symnode(tnode->child[0]->lineno,tnode->child[0]->name);
	struct TreeNode *formal,*actual;
	if(sym==NULL){ //函数名不在符号表
		new_errnode(ERR_UNDEFINED_FUNC,tnode->child[0],NULL,NULL);
		return 0;
	}
	else if(sym->type!=S_FUNC){ //函数名在符号表但并不是函数
		new_errnode(ERR_WRONG_CALL,tnode->child[0],NULL,NULL);
		return 0;
	}
	for(formal=sym->node->child[2],actual=tnode->child[1];formal!=NULL&&actual!=NULL;formal=formal->sibling_r,actual=actual->sibling_r){ //对于参数序列一一比对
        if(actual->type==TN_INTEGER){ //调用给的参数是数字常量
            if(formal->child[2]==NULL) continue; //函数定义给的参数不是数组(即int型变量)，允许数字常量调用
            else{
                new_errnode(ERR_WRONG_PARAM,tnode,NULL,NULL);
                return 0;
            }
        }
		struct SymNode* tmp=get_symnode(actual->lineno,actual->name);
		if(tmp==NULL){ //调用参数(变量or数组)不在符号表
			new_errnode(ERR_WRONG_PARAM,tnode,sym,NULL);
			return 0;
		}
		if((formal->child[2]==NULL&&tmp->type!=S_INT)||(formal->child[2]!=NULL&&tmp->type!=S_ARR)){ //需要变量对应变量，数组对应数组
			new_errnode(ERR_WRONG_PARAM,tnode,sym,NULL);
			return 0;
		}
	}
	if(formal!=NULL||actual!=NULL){ //调用多给参数或少给参数
		new_errnode(ERR_WRONG_PARAM,tnode,sym,NULL);
		return 0;
	}
	return 1;
}

void find_wrong_call(struct TreeNode* tnode) //递归查找函数调用错误
{
	if(tnode==NULL)
		return;
	if(tnode->type==TN_EXPR_CALL&&find_func(tnode)==0)
		print_ew();
	find_wrong_call(tnode->sibling_r);
	for(int i=0;i<tnode->n_child;i++)
		find_wrong_call(tnode->child[i]);
}

void print_ew()
{
	struct ErrNode* ew=err_head->next;
	struct TreeNode* tmp_node;
	while(ew!=NULL)
	{
		switch(ew->type)
		{
		case ERR_CONFLICT_VAR: //变量or数组名冲突
			fprintf(stderr,"ERROR@L%d&L%d: conflict variables %s & %s\n",ew->sym1->born_line,ew->sym2->born_line,ew->sym1->name,ew->sym2->name);
			exit(-2);
		case ERR_CONFLICT_FUNC: //函数名冲突
			fprintf(stderr,"ERROR@L%d&L%d: conflict function(s) %s & %s\n",ew->sym1->born_line,ew->sym2->born_line,ew->sym1->name,ew->sym2->name);
			exit(-2);
		case ERR_WRONG_ASSN: //错误赋值，类型不匹配
			fprintf(stderr, "ERROR@L%d: wrong assignment\n", ew->node->lineno);
			exit(-2);
		case ERR_WRONG_CALL: //调用的函数名不是函数
			fprintf(stderr, "ERROR@L%d: wrong function call\n", ew->node->lineno);
			exit(-2);
		case ERR_WRONG_PARAM: //调用函数的参数错误
			fprintf(stderr, "ERROR@L%d: wrong actual parameters\n", ew->node->lineno);
			exit(-2);
		case ERR_UNDEFINED_VAR: //未定以的变量or数组
			fprintf(stderr, "ERROR@L%d: undefined variable %s\n", ew->node->lineno, ew->node->name);
			exit(-2);
		case ERR_UNDEFINED_FUNC: //未定义的函数
			fprintf(stderr, "ERROR@L%d: undefined function %s\n", ew->node->lineno, ew->node->name);
			exit(-2);
		case ERR_WRONG_EXPR: //if、if-else、while中的判断expr不合规
			fprintf(stderr, "ERROR@L%d: wrong expression type in condition\n", ew->node->lineno);
			exit(-2);
		case WARN_MIXED_EXPR: //逻辑型运算与算术型运算混合
			fprintf(stderr, "WARNING@L%d: mixed expression type\n", ew->node->lineno);
			break;
		case WARN_NO_RETURN: //函数没用返回语句
			fprintf(stderr, "WARNING@L%d: missing return\n", ew->node->lineno);
			break;
		case WARN_FUNCDECL_IN_BODY: //函数内部的函数声明
			fprintf(stderr, "WARNING@L%d: function declaration (%s) in function body (%s)\n",ew->node->lineno,ew->node->child[1]->name,ew->node->parent->child[1]->name);
			break;
		default: ew->type=EW_INIT; break;
		}
		ew=ew->next;
	}
}

