#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use 5.030_000;

use lib '../lib';

use Asm;

&label('_start');
&enter;
&call('main');
&leave;
&halt;

&label("outc");
&enter;
&out(ptr('bp', +3));
&leave;
&ret;

&label('main');
&enter;
&op_push(66);
&call('outc');
&op_pop(reg 'A');

&mov(reg('A'), 1);
&comp(reg('A'), 1); # a-1 == 0?
&brnz('main');

&op_push(67);
&call('outc');
&op_pop(reg 'A');

&op_push(68);
&call('outc');
&op_pop(reg 'A');

&leave;
&ret;

open FH, '>out.rba';
select FH;

dump_asm;

close FH;