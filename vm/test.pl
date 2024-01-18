#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use 5.030_000;

use lib '../lib';

use Asm;

mov reg('A'), 1;
in reg('A', 1);
&xor(reg('A', 1), reg('A', 1), 0x20);
out reg('A', 1);

open FH, '>out.rba';
select FH;

dump_asm;

close FH;