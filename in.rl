sub putc(val: int) : void {
    asm('
		&mov(reg("A"), ptr("BP", +3)); # a = val
		&intr(1);
    ');
}

sub print1(val: str) : void {
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

sub print(val: str) : void {
    my i=5;
    
    if(5>10) {
        putc(44);
    }
}

sub main() : void {
	print('Hello, World\n');
	
	return 1+1;
}
