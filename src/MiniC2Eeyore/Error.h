#ifndef __ERROR_H__
#define __ERROR_H__

#include "Symbol.h"
#include "Tree.h"

//以下为错误类型
#define EW_INIT			0
#define ERR_CONFLICT_VAR	1
#define ERR_CONFLICT_FUNC	2
#define ERR_WRONG_ASSN		3
#define ERR_WRONG_PARAM		4
#define ERR_UNDEFINED_VAR	5
#define ERR_UNDEFINED_FUNC	6
#define ERR_WRONG_CALL		7
#define ERR_WRONG_EXPR		8
#define WARN_MIXED_EXPR		9
#define WARN_NO_RETURN		10
#define WARN_FUNCDECL_IN_BODY	11

int error_num;

struct ErrNode
{
	int idx; //编号
	int type; //错误类型
	struct TreeNode* node; //对应的错误树节点
	struct SymNode* sym1; //sym1与sym2用于名称冲突时存放两个冲突符号
	struct SymNode* sym2;
	struct ErrNode* next; //下一个
	struct ErrNode* prev; //上一个
};

struct ErrNode *err_head; //错误链表头
struct ErrNode *err_tail; //错误链表尾

void init_error();
struct ErrNode* new_errnode(int, struct TreeNode*, struct SymNode*, struct SymNode*);
int find_var(int, struct TreeNode*);
int find_conflict();
int find_func(struct TreeNode*);
void find_wrong_call(struct TreeNode*);
void print_ew();

#endif
