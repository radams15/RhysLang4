sub print(val: str) : void {
	asm('
	    &mov(reg("B"), 1); # B = count@write = 1 char
	    
		&mov(reg("C"), ptr("BP", +3));
		
		&label("print.top");
		&comp(ptr("C"), 0);
		&brz("print.end");
		
		&mov(reg("A"), reg("C"));
		&intr(2);
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
