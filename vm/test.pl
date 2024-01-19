#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use 5.030_000;

use lib '../lib';

use Asm;

&push(1);
&push(2);
&push(3);

mov reg('A'), 1;
in ptr('A');
&xor(ptr('A'), ptr('A'), 0x20);

mov(ptr('B'), ptr('bp', -1));

&add(ptr('A'), ptr('A'), ptr('B'));

out ptr('A');

open FH, '>out.rba';
select FH;

dump_asm;

close FH;