asm('
&label("outc");
&out(ptr("bp", 0));
&pop(reg "A");
&ret;
');

sub outc(n: int) : void;

sub main() : void {
    outc(70);
	return 1+1;
}
