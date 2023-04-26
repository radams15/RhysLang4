%include stdlib

struct File {
	my name: str;
	my fd: int;
		
	sub new(new_fd: int) : File {
		this.fd = new_fd;
	}
	
	static sub open(name: str, mode: int) : File {
		my fd = fopen(name, mode);
		
		return File(fd);
	}
	
	sub write(to_write: str) : int {
		return 4;
	}
}

sub main() : void {
	my file: File = alloc(sizeof(File));
	file.name = 'rhys adams';
	
	#puts('hello world!\n');
	puts(file.name);
	
	exit(0);
}
