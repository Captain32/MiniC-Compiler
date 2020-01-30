all : riscv64

riscv64 : flex bison
	gcc -o $@ y.tab.c lex.yy.c

flex : tigger.l bison
	flex tigger.l

bison : tigger.y
	bison tigger.y -d -y

clean:
	rm y.tab.h y.tab.c lex.yy.c riscv64
