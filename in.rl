asm('
&label("outc");
&enter;
&out(ptr("bp", +3));
&leave;
&ret;
');

sub outc(n: int) : void;

sub main() : void {
	outc(70);
	outc(71);
	outc(72);
	return 1+1;
}