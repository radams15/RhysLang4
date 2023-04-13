package Registers;

use Exporter 'import';

our @EXPORT_OK = qw/ %DATASIZES %REGISTERS /;

our %DATASIZES = (
	INT => 4,
	PTR => 4,
);

our %REGISTERS = (
	AX => 'eax',
	AH => 'ah',
	AL => 'al',
	BX => 'ebx',
	BH => 'bh',
	BL => 'bl',
	CX => 'ecx',
	CH => 'ch',
	CL => 'cl',
	DX => 'edx',
	DH => 'dh',
	DL => 'dl',
	SI => 'esi',
	DI => 'edi',
	SP => 'esp',
	BP => 'ebp',
	CS => 'ecs',
	DS => 'eds',
	SS => 'ess',
	ES => 'ees',
);

sub registers { \%REGISTERS }
sub datasizes { \%DATASIZES }

1;
