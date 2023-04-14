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
	push rdi ; arg 1
	mov rdi, [rbp-8] ; return code
	mov rax, 60 ; set syscall 60
	syscall
	EPILOGUE

cstr:
	PROLOGUE
	push rdi ; arg 1
	push rdi
	mov rdi, [rbp-8]
	add rdi, 1
	mov rax, rdi
	pop rdi
	EPILOGUE

strlen:
	PROLOGUE
	push rdi ; arg 1
	push rdi
	mov rdi, [rbp-8]
	xor rax, rax
	mov al, [rdi]
	pop rdi
	EPILOGUE

write:
	PROLOGUE
	push rdi ; arg 1
	push rsi ; arg 2
	mov rax, 1 ; write
	mov rdi, 1 ; stdout
	mov rsi, [rbp-8] ; message
	mov rdx, [rbp-16] ; length
	syscall
	EPILOGUE
