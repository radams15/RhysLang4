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