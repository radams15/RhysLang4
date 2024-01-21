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

raw('hello', 'Hello world!', 13);
raw('hello1', 'Howdy!', 7);

#in reg('A');
mov(reg('A'), ord('A'));
#&xor(reg('A'), reg('A'), 0x20);

mov(reg('B'), ptr('bp', -1));

&add(reg('A'), reg('A'), reg('B'));

mov(reg('B'), 'hello');

#out reg('A');
#out ptr('B');

out ptr('bp', -1);
out ptr('bp', -2);
out ptr('bp', -3);

&halt;

open FH, '>out.rba';
select FH;

dump_asm;

close FH;