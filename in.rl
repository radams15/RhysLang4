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
		&mov(reg("B"), 0);
		
		&label("print.top");
		&comp(ptr("A"), 0);
		&brz("print.end");
		
		&out(ptr("A"));
		&op_inc(reg("A"));
		&br("print.top");
		
		&label("print.end");
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
	print('Hello, World\n');
	print('Howdy, Planet\n');
	return 1+1;
}