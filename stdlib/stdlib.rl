sub strlen(val: str) : int {
    asm('
        &mov(reg("A"), ptr("BP", +3));
        &mov(reg("A"), ptr("A")); # dereference A (index 0)
    ');
}

sub malloc(size: int) : ptr {
	my out = _heap_top;
	_heap_top = _heap_top + size;
	
	return out;
}

%include stdio
