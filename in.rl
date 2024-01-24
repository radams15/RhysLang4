asm('
&label("outc");
&enter;
&out(ptr("bp", +3));
&leave;
&ret;
');

sub outc(n: int) : void;

sub print(val: str) : void {
	asm('
		&mov(reg("A"), ptr("BP", +3));
		&out(ptr("A", 2));
	');
}

sub hello() : void {
	outc(104);
	outc(101);
	outc(108);
	outc(108);
	outc(111);
	outc(10);
}

sub main() : void {
	print('Hello, World');
	print('Howdy, Planet');
	return 1+1;
}