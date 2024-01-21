asm('
&label("outc");
&out(66);
&ret;
');

sub outc() : void;

sub main() : void {
    outc();
    outc();
    outc();
    outc();
    
	return 1+1;
}
