%include stdlib

sub crlf() : void {
	putc(10);
	putc(13);
}

sub main() : void {
	my name = 'rhys';
	my name2 = 'adams';

	my fh = fopen('test.txt', 2);
	fwrite(fh, 'hello world!\r\n');
	fclose(fh);
	
	my ptr = 0;
	while(1) {
		ptr = alloc(10);
	}
	
	my c = 65;
	while(c < 122) {
		putc(c);
		c = c+1;
	}

	putc(_heap);

	puts('\n');
	puts(name);
	puts(name2);
	
	exit(0);
}
