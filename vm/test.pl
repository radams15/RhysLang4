#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use 5.030_000;

use lib '../lib';

use Asm;

&label('_start');
&br('main');
&halt;

&label("outc");
&out(ptr('bp', 0));
&pop(reg 'A');
&ret;

&label('main');
&push(66);
&call('outc');
&pop(reg 'A');

&ret;

open FH, '>out.rba';
select FH;

dump_asm;

close FH;