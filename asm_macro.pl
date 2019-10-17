#!/usr/bin/perl -w
# ----------------------------------------------------------------------------
# Copyright 2019 by T.Zoerner (tomzo at users.sf.net)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# ----------------------------------------------------------------------------
#
# This script generates assembly code for the "aes" and "vdi"
# macros that were originally implemented using GST assembler.
# See original macros in src/f_sys.s
#
# Invocation examples:
#           aes       107 1 1 0 0 3       ;wind_update
#           aes       110 0 1 1 0 rscname ;rsrc_load
#           aes       25 16 7 1 0 %110000 0 0 0 0 0 0 0 0 0 0 0 0 0 \
#                     70 0 msg_buff       ;evt_multi
#           aes       104 2 5 0 0 !(a4) 10  ;wind_get
#           vdi       100 0 11 1 1 1 1 1 1 1 1 1 1 2
#           vdi       25 0 1 !frpinsel+20

use strict;

sub moove
{
  my ($len, $src, $dst) = @_;
  if ($src !~ /^0$/)
  {
    if ($src =~ /^\!(.*)/)
    {
      $src = $1;
    }
    else
    {
      $src = "#$src";
    }
    return "          move.$len $src,$dst\n";
  }
  else
  {
    return "          clr.$len $dst\n";
  }
}

while (<>)
{
  if (/^\s+aes\s+([^;\n]+)/)
  {
    # params: code sintin sintout saddrin saddrout
    my ($code, $sintin, $sintout, $saddrin, $saddrout, @rest) = split(/\s+/, $1);
    die "aes: not enough parameters, $ARGV line $.\n" unless defined $saddrout;
    print ";$_".
          "          ;expanding macro ----------\n".
          "          move.w #$code,CONTRL+0(a6)\n".
          moove("l", sprintf("\$%x", ($sintin<<16)+$sintout),"CONTRL+2(a6)") .
          moove("l", sprintf("\$%x", ($saddrin<<16)+$saddrout),"CONTRL+6(a6)");
    my $rest_idx = 0;
    for (my $idx = 0; $idx < $sintin; ++$idx)
    {
      #die "aes: missing INT parameter in  $ARGV line $.\n" unless defined $rest[$rest_idx];
      last if !defined $rest[$rest_idx];
      print moove("w",$rest[$rest_idx],"INTIN+".($idx*2)."(a6)");
      ++$rest_idx;
    }
    for (my $idx = 0; $idx < $saddrin; ++$idx)
    {
      #die "aes: missing ADDR parameter in $ARGV line $.\n" unless defined $rest[$rest_idx];
      last if !defined $rest[$rest_idx];
      print moove("l",$rest[$rest_idx],"ADDRIN+".($idx*4)."(a6)");
      ++$rest_idx;
    }
    print "          bsr aescall\n".
          "          ;endm ---------------------\n";
  }
  elsif (/^\s+vdi\s+([^;\n]+)/)
  {
    # params: code,sptsin,sintin
    my ($code, $sptsin, $sintin, @rest) = split(/\s+/, $1);
    die "vdi: not enough parameters, $ARGV line $.\n" unless defined $sintin;
    print ";         $_".
          "          ;expanding macro ----------\n".
          "          move.l #".sprintf("\$%x", $code<<16)."+$sptsin,CONTRL+0(a6)\n".
          moove("w",$sintin,"CONTRL+6(a6)");
    my $rest_idx = 0;
    for (my $idx = 0; $idx < $sptsin*2; $idx += 2)
    {
      #die "vdi: missing INT parameter in $ARGV line $.\n" unless defined $rest[$rest_idx] && defined $rest[$rest_idx+1];
      last if !defined $rest[$rest_idx];
      print moove("w",$rest[$idx],"PTSIN+".($idx*2)."(a6)") .
            moove("w",$rest[$idx+1],"PTSIN+".(($idx+1)*2)."(a6)");
      $rest_idx += 2;
    }
    if ($sintin =~ /^\d+$/)
    {
      for (my $idx = 0; $idx < $sintin; ++$idx)
      {
        #die "vdi: missing ADDR parameter in $ARGV line $.\n" unless defined $rest[$rest_idx];
        last if !defined $rest[$rest_idx];
        print moove("w",$rest[$rest_idx],"INTIN+".($idx*2)."(a6)");
        ++$rest_idx;
      }
    }
    print "          bsr vdicall\n".
          "          ;endm ---------------------\n";
  }
  elsif (/^ *end\b/i)
  {
    print ";$_";
  }
  else
  {
    print;
  }
}
