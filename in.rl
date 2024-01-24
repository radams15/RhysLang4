asm('
&label("outc");
&enter;
&out(ptr("bp", +3));
&leave;
&ret;
');

sub outc(n: int) : void;

sub hello() : void {
	outc(104);
	outc(101);
	outc(108);
	outc(108);
	outc(111);
	outc(10);
}

sub main() : void {
	hello();
	return 1+1;
}