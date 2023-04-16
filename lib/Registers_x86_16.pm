package Registers_x86_16;

use Exporter 'import';

our @EXPORT_OK = qw/ %DATASIZES %REGISTERS /;

our %DATASIZES = (
	INT => 2,
	PTR => 2,
);

our %REGISTERS = (
	AX => 'ax',
	AH => 'ah',
	AL => 'al',
	BX => 'bx',
	BH => 'bh',
	BL => 'bl',
	CX => 'cx',
	CH => 'ch',
	CL => 'cl',
	DX => 'dx',
	DH => 'dh',
	DL => 'dl',
	SI => 'si',
	DI => 'di',
	SP => 'sp',
	BP => 'bp',
	CS => 'cs',
	DS => 'ds',
	SS => 'ss',
	ES => 'es',
);

sub registers { \%REGISTERS }
sub datasizes { \%DATASIZES }

1;
