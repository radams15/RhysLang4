asm ('
putc:
	PROLOGUE
	push di
	mov bx, sp ; char ptr = di as arg 1.
	mov dx, [bx] ; can only index bx so have to move sp to bx then index.
	mov ah, 02h ; ah=02 - print char
	int 21h
	EPILOGUE

exit:
	PROLOGUE
	mov ax, di ; return code
	xor ah, ah
	mov ah, 4Ch ; exit call
	int 21h
	EPILOGUE

cstr:
	PROLOGUE
	push di
	add di, 1
	mov ax, di
	pop di
	EPILOGUE

strlen:
	PROLOGUE
	push di
	xor ax, ax
	mov al, [di]
	pop di
	EPILOGUE
	
_fopen_read:
    PROLOGUE
    mov dx, di ; file name

    mov ah, 0x3D ; open read
    mov al, 0 ; ??
    int 0x21

    EPILOGUE
    
_fcreate:
    PROLOGUE
    mov dx, di ; file name

    mov cx, 0 ; write 0 bytes to file.
    mov ah, 0x3c ; create
    ;mov al, 0x2 ; ??
    int 0x21

    EPILOGUE
    
_fwrite:
    PROLOGUE
    mov bx, dx ; fh
	mov dx, si ; data
    mov cx, di ; length
    
    mov ah, 0x40 ; write
    int 0x21
    EPILOGUE
    
fclose:
    PROLOGUE
	mov bx, di ; fh

    mov ah, 0x3e ; close
    int 0x21
    EPILOGUE
');

sub putc(char: int) : void;
sub exit(code: int) : void;
sub cstr(char: str) : ptr;
sub strlen(char: str) : int;

sub _fcreate(name: ptr) : int;
sub _fopen_read(name: ptr) : int;
sub _fwrite(fh: int, data: ptr, length: int) : int;
sub fclose(fh: int) : void;

sub puts():void;

# fopen - opens a file
# name (str) : file name to open
# mode (enum): 1 - read
#              2 - write
# returns - file handle (int)
sub fopen(name: str, mode: int) : int {
	my cname = cstr(name);
	my fh = 0;
	
	if(mode == 2) {
		fh = _fcreate(cname);
	}

	if(mode == 1) {
		fh = _fopen_read(cname);
	}

	return fh;
}

# fwrite - writes to a file
# fh (str)   : file handle to write to
# data (str) : data to write
sub fwrite(fh: int, data: str) : void {
	_fwrite(fh, cstr(data), strlen(data));
}
