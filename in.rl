%include stdlib

sub main() : void {
	my ptr: ptr = alloc(0);
	
	ptr = alloc(10);
	
	puts('hello world!\n');
	
	exit(0);
}
