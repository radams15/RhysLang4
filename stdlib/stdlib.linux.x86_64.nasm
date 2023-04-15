putc:
	PROLOGUE
	push rdi ; arg 1 - char
	mov rax, 1 ; write
	mov rdi, 1 ; stdout
	mov rsi, rsp ; char ptr = rsp as arg 1 at top of stack.
	mov rdx, 1 ; length
	syscall
	EPILOGUE
	
open:
	PROLOGUE
	push rdi
	push rsi
	push rdx
	
	mov rax, 2
	mov rdi, [rbp-8] ; file name
	mov rsi, [rbp-16] ; flags
	mov rdx, 777 ; mode 777 - r/w/e all
	syscall
	EPILOGUE
	
close:
	PROLOGUE
	push rdi
	
	mov rax, 3
	mov rdi, [rbp-8] ; file handle
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
	push rdx
	mov rax, 1 ; write
	mov rdi, [rbp-8] ; fh
	mov rsi, [rbp-16] ; message
	mov rdx, [rbp-24] ; length
	syscall
	EPILOGUE
