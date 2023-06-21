%include stdlib

struct File {
	my name: str;
	my fd: int;
	
	static sub new(new_fd: int) : File {
	    my out: File = alloc(sizeof(File));
		out.fd = new_fd;
		
		return out;
	}
	
	static sub open(name: str, mode: int) : File {
		my fd = fopen(name, mode);
		
		return File.new(fd);
	}
	
	sub write(to_write: str) : int {
		return fwrite(this.fd, to_write);
	}
}

sub main() : void {
	my file = File.open("test.txt", 2);
	
	my i = 10;
	while(i>0) {
	    file.write(file, "Hello world!\n");
	    i = i-1;
	}
	#fclose(file);
	
	#puts('hello world!\n');
	#puts(file.name);
	
	exit(0);
}
