package Registers;

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
	CS => 'rcs',
	DS => 'rds',
	SS => 'rss',
	ES => 'res',
);

sub registers { \%REGISTERS }
sub datasizes { \%DATASIZES }

1;
