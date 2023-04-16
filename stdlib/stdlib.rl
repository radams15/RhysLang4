%if DOS %if x86_16 %echo asm ('%include "stdlib/stdlib.dos.x86_16.nasm"');
%if LINUX %if x86_64 %echo asm ('%include "stdlib/stdlib.linux.x86_64.nasm"');

sub putc(char: int) : void;
sub exit(code: int) : void;
sub cstr(char: str) : ptr;
sub strlen(char: str) : int;

sub close(fd: int) : int;
sub open(file: str, mode: int) : int;
sub write(fd: int, char: ptr, len: int) : void;

sub puts(data: str) : void {
	my i = 1;
	my len = strlen(data);
	
	while(i < len) {
		putc(data[i]);
		i = i + 1;
	}
}
