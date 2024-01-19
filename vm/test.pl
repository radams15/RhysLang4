#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use 5.030_000;

use lib '../lib';

use Asm;

&push(5);

mov reg('A'), 1;
in ptr('A');
&xor(ptr('A'), ptr('A'), 0x20);

&stackat(reg('B'), 1);
&add(ptr('A'), ptr('A'), ptr('B'));

out ptr('A');

open FH, '>out.rba';
select FH;

dump_asm;

close FH;