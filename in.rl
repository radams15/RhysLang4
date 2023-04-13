sub putc(char: int) : void {
	asm ('
push rbp
add eax, 6
ret');
}

sub hello(name: str): int {
	my age = 5;
	
	return age;
}

sub main(): void {
	my name = 'rhys';
	my name2 = 'adams';
	
	putc(66);
	
	hello(name2);
}
