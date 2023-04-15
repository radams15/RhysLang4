org 100h ; IMPORTANT

putc:
	PROLOGUE
	push di ; arg 1 - char
	mov bx, sp ; char ptr = sp as arg 1 at top of stack.
	mov dx, [bx] ; can only index bx so have to move sp to bx then index.
	mov ah, 02h ; ah=02 - print char
	int 21h
	EPILOGUE

exit:
	PROLOGUE
	push di ; arg 1
	mov ax, [bp-4] ; return code
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
