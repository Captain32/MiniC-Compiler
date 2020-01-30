all : tigger

tigger : flex bison
	g++ -o tigger eeyore.tab.c lex.yy.c -g

flex : eeyore.l bison
	flex eeyore.l

bison : eeyore.y
	bison eeyore.y -d

clean:
	rm eeyore.tab.h eeyore.tab.c lex.yy.c tigger
