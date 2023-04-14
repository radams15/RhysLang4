asm ('%include "stdlib.nasm"');

sub putc(char: int) : void;
sub exit(code: int) : void;
sub cstr(char: str) : ptr;
sub strlen(char: str) : int;

sub close(fd: int) : int;
sub open(file: str, mode: int) : int;
sub write(fd: int, char: ptr, len: int) : void;

sub puts(data: str) : void {
	write(1, cstr(data), strlen(data));
}

sub hello(name: str): int {
	my age = 5;
	
	return age;
}

sub main(): void {
	my name = 'rhys\n';
	my name2 = 'adams';
	
	my out = open(cstr('out.txt'), 110);
	write(out, cstr(name), strlen(name));
	close(out);
	
	my letter3 = name2[2];
	
	putc(letter3);
	
	puts(name);
	puts(name2);
	puts("\n");
	putc(10);
	
	exit(strlen(name2));
}
