#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "Symbol.h"

void init_symtable()
{
    symbol_num=-1;
    sym_tail=sym_head=new_symnode(-1,S_INIT,strdup(""),NULL);
}

struct SymNode* new_symnode(int line,int type,char *name,struct TreeNode* tnode) //new一个新符号节点，放到链表尾，line行号，type符号类型，name符号名，tnode对应树节点
{
    struct SymNode* newnode=(struct SymNode*)malloc(sizeof(struct SymNode));
    newnode->idx=symbol_num++;
    newnode->type=type;
    newnode->born_line=line;
    newnode->die_line=-1;
    if(name==NULL) name=strdup("");
    newnode->name=strdup(name);
    newnode->eeyore_type='N';
    newnode->eeyore_idx=-1;
    newnode->node=tnode;
    newnode->next=NULL;
    newnode->prev=NULL;
    if(sym_head!=NULL){
        newnode->prev=sym_tail;
        sym_tail->next=newnode;
    }
    sym_tail=newnode;
    return newnode;
}

struct SymNode* get_symnode(int line, char* name) //获得符号表中在line行生效名为name的符号节点
{
    struct SymNode* resnode=NULL;
    for(struct SymNode* tmpnode=sym_head->next;tmpnode!=NULL;tmpnode=tmpnode->next){
        if(strcmp(tmpnode->name,name)==0&&tmpnode->born_line<=line&&(tmpnode->die_line>=line||tmpnode->die_line==-1)){ //需要出生于line前，死于line后，或者永远不死(-1)
            if(resnode==NULL||resnode->born_line<tmpnode->born_line) //取出生最晚的
                resnode=tmpnode;
        }
    }
    return resnode;
}

void free_symnode(struct SymNode* snode) //释放符号节点
{
    if(snode==sym_head) return;
    free(snode->name);
    snode->prev->next=snode->next;
    if(snode==sym_tail)
        sym_tail=snode->prev;
    else
        snode->next->prev=snode->prev;
    free(snode);
}

void free_symnodes(int born_line,int die_line) //用于不需要保存的函数声明的参数列表中符号的释放
{
    for(struct SymNode* tmpnode=sym_head->next;tmpnode!=NULL;tmpnode=tmpnode->next){
        if(tmpnode->born_line>=born_line&&tmpnode->born_line<=die_line&&tmpnode->die_line<0){
            struct SymNode* delnode=tmpnode;
            tmpnode=tmpnode->prev;
            free_symnode(delnode);
        }
    }
}

void set_death(int born_line,int die_line) //将出生于[born_line,die_line]之间的符号，且die_line仍为-1(尚未初始化)的符号失效行设为die_line
{
    for(struct SymNode* tmpnode=sym_head->next;tmpnode!=NULL;tmpnode=tmpnode->next){
        if(tmpnode->born_line>=born_line&&tmpnode->born_line<=die_line&&tmpnode->die_line<0)
            tmpnode->die_line=die_line;
    }
}

void print_symtab(FILE* f) //打印符号表
{
	struct SymNode* sym = sym_head->next;
	char str[4][8]={"ERR","INT","ARR","FUNC"};
	while(sym != NULL)
	{
		fprintf(f,"%d\t[%s] \t%-12s\tL%d~L%d\t%c%d\n",sym->idx,str[sym->type],sym->name,sym->born_line,sym->die_line,sym->eeyore_type,sym->eeyore_idx);
		sym = sym->next;
	}
}
