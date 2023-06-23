%include stdlib

sub main() : void {
	my file = File.open("test.txt", 2);
	
	my i = 10;
	while(i>0) {
	    file.write("Hello world!\n");
	    i = i-1;
	}

	file.close();
	
	puts('Done!\n');
	
	exit(0);
}
