#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use 5.030_000;

use lib '../lib';

use Asm;

&push(5);

mov reg('A'), 1;
in reg('A', 1);
&xor(reg('A', 1), reg('A', 1), 0x20);

&stackat(reg('B'), 1);
&add(reg('A', 1), reg('A', 1), reg('B', 1));

out reg('A', 1);

open FH, '>out.rba';
select FH;

dump_asm;

close FH;