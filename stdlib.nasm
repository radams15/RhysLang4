putc:
	PROLOGUE
	push rdi ; arg 1 - char
	mov rax, 1 ; write
	mov rdi, 1 ; stdout
	mov rsi, rsp ; char ptr = rsp as arg 1 at top of stack.
	mov rdx, 1 ; length
	syscall
	EPILOGUE

exit:
	PROLOGUE
	push rdi ; arg 1 - char
	mov rdi, [rbp-8] ; return code
	mov rax, 60 ; set syscall 60
	syscall
	EPILOGUE
