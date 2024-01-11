asm ('
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
	push rsi
	push rdi
	
	mov rax, 2
	mov rdi, [rbp-8] ; file name
	mov rsi, [rbp-16] ; flags
	mov rdx, 488 ; mode - r/w/e user - S_IRWXU
	syscall
	EPILOGUE
	
fclose:
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
	push rdx
	push rsi ; arg 1
	push rdi ; arg 2
	mov rax, 1 ; write
	mov rdi, [rbp-8] ; fh
	mov rsi, [rbp-16] ; message
	mov rdx, [rbp-24] ; length
	syscall
	EPILOGUE
');

sub putc(char: int) : void;
sub exit(code: int) : void;
sub cstr(char: str) : ptr;
sub strlen(char: str) : int;

sub open(file: str, mode: int) : int;
sub write(fd: int, char: ptr, len: int) : void;

# fopen - opens a file
# name (str)  : file name to open
# mode (enum) : 1 - read
#               2 - read/write (new file)
# returns - file handle (int)
sub fopen(name: str, mode: int) : int {
	my modecode = 0;
	if(mode == 1) {
		modecode = 64;
	}
	if(mode == 2) {
		modecode = 66;
	}
	
	return open(cstr(name), modecode);
}

# fwrite - writes to a file
# fh (str)   : file handle to write to
# data (str) : data to write
sub fwrite(fh: int, data: str) : void {
	write(fh, cstr(data), strlen(data));
}

# fclose - closes a file
# fh (str)   : file handle to close
sub fclose(fh: int) : void;
