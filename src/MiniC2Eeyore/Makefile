all:	eeyore

eeyore:	Parser.l Parser.y Tree.h Tree.c Symbol.h Symbol.c Error.h Error.c Convert.h Convert.c
	bison -d -y Parser.y
	flex Parser.l
	gcc -c Tree.h Tree.c Symbol.h Symbol.c Error.h Error.c Convert.h Convert.c y.tab.h y.tab.c lex.yy.c
	gcc Tree.o Symbol.o Error.o Convert.o y.tab.o lex.yy.o -o $@ -lm

clean:
	rm -rf eeyore *.o lex.yy.* y.tab.* *.gch null.Parser
