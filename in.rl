sub print(val: str) : void {
	asm('
		&mov(reg("C"), ptr("BP", +3));
		&mov(reg("B"), 0);
		
		&label("print.top");
		&comp(ptr("C"), 0);
		&brz("print.end");
		
		&mov(reg("A"), ptr("C"));
		&intr(1);
		#&out(ptr("C"));
		&op_inc(reg("C"));
		&br("print.top");
		
		&label("print.end");
	');
}

sub main() : void {
	print('Hello, World\n');
	print('Howdy, Planet\n');
	return 1+1;
}
