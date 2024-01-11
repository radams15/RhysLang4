asm ('
write:
	push bp
	mov bp, sp
	
	push rdx
	push rsi ; arg 1
	push rdi ; arg 2
	mov rax, 1 ; write
	mov rdi, [rbp-8] ; fh
	mov rsi, [rbp-16] ; message
	mov rdx, [rbp-24] ; length
	syscall
	
	mov sp, bp
	pop bp
	ret
');

sub write(fd: int, char: ptr, len: int) : void;

sub main() : void {
    write(1, 'hello world\n', 14);
}
