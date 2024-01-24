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
&push(66);
&call('outc');
&pop(reg 'A');

&push(67);
&call('outc');
&pop(reg 'A');

&push(68);
&call('outc');
&pop(reg 'A');

&leave;
&ret;

open FH, '>out.rba';
select FH;

dump_asm;

close FH;