%include stdlib

struct File {
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
	
	sub write(this: File, to_write: str) : int {
		return fwrite(this.fd, to_write);
	}
	
	sub close() : void {
		fclose(this.fd);
	}
}

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
