asm ('%include "stdlib.nasm"');

sub putc(char: int) : void;
sub exit(code: int) : void;
sub cstr(char: str) : ptr;
sub strlen(char: str) : int;
sub write(char: ptr, len: int) : void;

sub puts(data: str) : void {
	write(cstr(data), strlen(data));
}

sub hello(name: str): int {
	my age = 5;
	
	return age;
}

sub main(): void {
	my name = 'rhys\n';
	my name2 = 'adams';
	
	my letter3 = name2[2];
	
	putc(letter3);
	
	puts(name);
	puts(name2);
	puts("\n");
	putc(10);
	
	exit(strlen(name2));
}
