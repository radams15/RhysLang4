%if DOS %if x86_16 %include stdlib/dos.x86_16
%if LINUX %if x86_64 %include stdlib/linux.x86_64

my _heap_end = _heap;

# puts - print string to STDOUT
# data (str) : text to output
sub puts(data: str) : void {
	my i = 1;
	my len = strlen(data);
	
	while(i < len+1) {
		putc(data[i]);
		i = i + 1;
	}
	
%if DOS putc(13); # \r
	putc(10); # \n
}

sub alloc(size: int) : ptr {
	my out = _heap_end;
	_heap_end = _heap_end - size;
	
	return out;
}