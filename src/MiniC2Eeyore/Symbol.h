#ifndef __SYMBOL_H__
#define __SYMBOL_H__

#include <stdio.h>
#include "Tree.h"

//符号表条目类型
#define S_INIT	0 //头节点无类型
#define S_INT	1 //变量
#define S_ARR	2 //数组
#define S_FUNC	3 //函数

int symbol_num; //符号数

struct SymNode
{
	int idx; //编号
	int type; //符号类型
	int born_line; //生效行
	int die_line; //失效行，-1则代表永不失效
	char* name; //符号名
	char eeyore_type; //eeyore代码中的类型(T、t、f、p)
	int eeyore_idx; //eeyore代码对应的类型中的编号
	struct TreeNode *node; //对应语法树中的树节点
	struct SymNode *next; //前一个符号
	struct SymNode *prev; //后一个符号
};

struct SymNode *sym_head; //符号链表头
struct SymNode *sym_tail; //符号链表尾

void init_symtable();
struct SymNode* new_symnode(int,int,char*,struct TreeNode*);
struct SymNode* get_symnode(int,char*);
void free_symnode(struct SymNode*);
void free_symnodes(int,int);
void set_death(int,int);
void print_symtab(FILE*);

#endif
