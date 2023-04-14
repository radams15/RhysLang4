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

sub putc(char: int) : void {
	asm ('
	mov rax, 1 ; write
	mov rdi, 1 ; stdout
	mov rsi, rsp ; message ptr = rsp as at top of stack.
	mov rdx, 1 ; length
	syscall
	');
}

sub print(data: str) : void {
	write(cstr(data), strlen(data));
}

sub exit(code: int) : void {
	asm ('
	mov rdi, [rbp-8] ; zero rdi (rdi hold return value)
	mov rax, 0x3c ; set syscall number to 60 (0x3c hex)
	syscall
	');
}

sub hello(name: str): int {
	my age = 5;
	
	return age;
}

sub main(): void {
	my name = 'rhys';
	my name2 = 'adams';
	
	my letter3 = name2[2];
	
	putc(letter3);
	
	print(name);
	print(" ");
	print(name2);
	putc(10);
	
	exit(strlen(name));
}
