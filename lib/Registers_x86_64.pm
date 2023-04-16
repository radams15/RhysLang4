package Registers_x86_64;

my %DATASIZES = (
	INT => 8,
	PTR => 8,
);

my %REGISTERS = (
	AX => 'rax',
	AH => 'ah',
	AL => 'al',
	BX => 'rbx',
	BH => 'bh',
	BL => 'bl',
	CX => 'rcx',
	CH => 'ch',
	CL => 'cl',
	DX => 'rdx',
	DH => 'dh',
	DL => 'dl',
	SI => 'rsi',
	DI => 'rdi',
	SP => 'rsp',
	BP => 'rbp',
	CS => 'cs',
	DS => 'ds',
	SS => 'ss',
	ES => 'es',
);

sub registers { \%REGISTERS }
sub datasizes { \%DATASIZES }

1;
