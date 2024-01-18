#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use 5.030_000;

use lib '../lib';

use Asm;

mov reg('A'), 1;
mov reg('A', 1), 65;
out reg('A', 1);
out reg('A');

open FH, '>out.rba';
select FH;

dump_asm;

close FH;