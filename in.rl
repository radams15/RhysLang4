%include stdlib

sub main() : void {
	puts('Hello, World');
	puts('test2');
	
	my i = getc();
	putc(i);
	
	puts('\n\n');
	
	puti(malloc(100));
	puti(malloc(100));
	puti(malloc(100));
	
	return 1+1;
}
