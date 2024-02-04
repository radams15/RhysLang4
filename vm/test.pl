#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use 5.030_000;

use lib '../lib';

use Asm;

&raw('name', 'world', 5);

&label('_start');
&enter;
&call('main');
&leave;
&halt;

&label("print");
    &enter;
    &mov(reg("B"), 1); # B = count@write = 1 char

    &mov(reg("C"), ptr("BP", +3));

    &label("print.top");
    &comp(ptr("C"), 0);
    &brz("print.end");

    &mov(reg("A"), reg("C"));
    &intr(2);
    &op_inc(reg("C"));
    &br("print.top");

    &label("print.end");
    &leave;
    &ret

&label('main');
&enter;

&op_push('name');
&call('print');
&op_pop(reg 'A');

&leave;
&ret;

open FH, '>out.rba';
select FH;

dump_asm;

close FH;