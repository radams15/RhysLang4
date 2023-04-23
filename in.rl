#%include stdlib

struct File {
	my fd: int;
	
	static sub open(name: str, mode: int) : int {
		my fd = fopen(name, mode);
		my out = alloc(sizeof(File));
		
		#out.fd = fd;
		
		return out;
	}
	
	sub write(to_write: str) : int {
		
	}
}

sub main() : void {
	my ptr: ptr = alloc(0);
	
	ptr = alloc(10);
	
	puts('hello world!\n');
	
	exit(0);
}
