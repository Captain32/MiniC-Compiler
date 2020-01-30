#ifndef __TREE_H__
#define __TREE_H__

#include <stdio.h>

//以下为treenode类型
#define TN_INIT			0
#define TN_GOAL 		1
#define TN_FUNCDEFN		2
#define TN_FUNCDECL		3
#define TN_VARDEFN		4
#define TN_VARDECL		5
#define TN_STMT_BLOCK	6
#define TN_STMT_IF		7
#define TN_STMT_WHILE	8
#define TN_STMT_VARASSN	9
#define TN_STMT_ARRASSN	10
#define TN_STMT_VARDEFN	11
#define TN_STMT_RETURN	12
#define TN_EXPR_BIARITH	13
#define TN_EXPR_BILOGIC	14
#define TN_EXPR_UNI		15
#define TN_EXPR_INTEGER	16
#define TN_EXPR_IDENTIFIER	17
#define TN_EXPR_ARR		18
#define TN_EXPR_CALL	19
#define TN_TYPE			20
#define TN_INTEGER		21
#define TN_IDENTIFIER	22

#define MAX_CN	5

//以下为不同类型treenode的子节点数
#define CN_INIT			0
#define CN_GOAL			2
#define CN_FUNCDEFN		4
#define CN_FUNCDECL		3
#define CN_VARDEFN		3
#define CN_VARDECL		3
#define CN_STMT_BLOCK	1
#define CN_STMT_IF		3
#define CN_STMT_WHILE	2
#define CN_STMT_VARASSN	2
#define CN_STMT_ARRASSN	3
#define CN_STMT_VARDEFN	1
#define CN_STMT_RETURN	1
#define CN_EXPR_BIARITH	2
#define CN_EXPR_BILOGIC	2
#define CN_EXPR_UNI		1
#define CN_EXPR_INTEGER	1
#define CN_EXPR_IDENTIFIER	1
#define CN_EXPR_ARR		2
#define CN_EXPR_CALL	2
#define CN_TYPE			0
#define CN_INTEGER		0
#define CN_IDENTIFIER	0

int treenode_num; //树节点数

struct TreeNode
{
	int idx; //编号
	int lineno; //所在行号
	int type; //节点类型
	int val; //值(对于数字常量)
	char* name; //节点名称
	int n_child; //节点子节点数(由类型决定)
	int child_idx; //本节点在父节点的数组中的索引
	struct TreeNode* parent; //父节点
	struct TreeNode* child[MAX_CN]; //子节点数组
	struct TreeNode* sibling_l; //左兄弟
	struct TreeNode* sibling_r; //右兄弟
};

void init_tree();
struct TreeNode* new_treenode(int,int,char*,int);
void free_treenode(struct TreeNode*);
struct TreeNode* to_left(struct TreeNode*,struct TreeNode*,int);
void print_treenode(struct TreeNode*, char*, FILE*);
void print_tree(struct TreeNode*, int, FILE*);

#endif
