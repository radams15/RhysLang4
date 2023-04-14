asm ('
%include "stdlib.nasm"
');

sub putc(char: int) : void;
sub exit(code: int) : void;

sub cstr(char: str) : ptr {
	asm ('
	push rdi
	mov rdi, [rbp-8]
	add rdi, 1
	mov rax, rdi
	pop rdi
	');
}

sub strlen(char: str) : int {
	asm ('
	push rdi
	mov rdi, [rbp-8]
	xor rax, rax
	mov al, [rdi]
	pop rdi
	');
}

sub write(char: ptr, len: int) : void {
	asm ('
	mov rax, 1 ; write
	mov rdi, 1 ; stdout
	mov rsi, [rbp-8] ; message
	mov rdx, [rbp-16] ; length
	syscall
	');
}

sub print(data: str) : void {
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
	
	print(name);
	print(name2);
	print("\n");
	putc(10);
	
	exit(strlen(name2));
}
