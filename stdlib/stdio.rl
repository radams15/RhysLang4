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

sub getc() : int {
    my out: int;
    
    asm('
        &intr(0);
        &mov(ptr("BP"), reg("A"));
    ');
    
    return out;
}

# puts - print string to STDOUT
# data (str) : text to output
sub puts(data: str) : void {
	my i = 0;
	my len = strlen(data);
	
	while(i < len) {
		putc(data[i]);
		i = i + 1;
	}

%if DOS putc(13); # \r
	putc(10); # \n
}
