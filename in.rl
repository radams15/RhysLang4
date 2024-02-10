sub putc(val: int) : void {
    asm('
		&mov(reg("A"), ptr("BP", +3)); # a = val
		&intr(1);
    ');
}

sub print(val: str) : void {
    asm('
	    &mov(reg("B"), 1); # B = count@write = 1 char
	    
		&mov(reg("C"), ptr("BP", +3));
		
		&label("print.top");
		&comp(ptr("C"), 0);
		&brz("print.end");
		
		&mov(reg("A"), reg("C"));
		&intr(2);
		&op_inc(reg("C"));
		&br("print.top");
		
		&label("print.end");
	');
}

sub main() : void {
	my a = 66;
	my b = 54;
	putc(a);
	putc(b);
	
	print('Hello, World\n');
	if(a <= 1) {
	    print('Howdy, Planet\n');
	}
	return 1+1;
}
