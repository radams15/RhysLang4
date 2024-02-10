sub puti(val: int) : void {
    asm('
		&mov(reg("A"), ptr("BP", +3)); # a = val
		&intr(4);
    ');
}

sub putc(val: int) : void {
    asm('
		&mov(reg("A"), ptr("BP", +3)); # a = val
		&intr(1);
    ');
}

sub strlen(val: str) : int {
    asm('
        &mov(reg("A"), ptr("BP", +3));
        &mov(reg("A"), ptr("A")); # dereference A (index 0)
    ');
}

sub print(val: str) : void {
    my len = strlen(val);
    my i=0;
    
    while(i<len) {
        putc(val[i]);
        
        i = i+1;
    }
}

sub main() : void {
	print('Hello, World\n');
	print('test\n');
	
	return 1+1;
}
