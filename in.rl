asm('
&label("outc");
&out(70);
');

sub outc() : void;

sub main() : void {
    outc();
    
	return 1+1;
}
