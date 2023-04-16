%include stdlib

sub crlf() : void {
	putc(10);
	putc(13);
}

sub main() : void {
	my name = 'rhys';
	my name2 = 'adams';
	
	puts(name);
	crlf();
	crlf();
	puts(name2);
	crlf();
	
	exit(1);
}
