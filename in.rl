%include stdlib

sub main() : void {
	my ptr = 0;
	ptr = alloc(10);
	ptr = alloc(10);
	ptr = alloc(10);
	
	puts('hello world!\n');
	
	exit(0);
}
