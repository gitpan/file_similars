#! /usr/bin/env perl
# -*- perl -*- 

# @Author: Tong SUN, (c)2001-2003, all right reserved
# @Version: $Date: 2008/10/31 16:00:47 $ $Revision: 1.5 $
# @HomeURL: http://xpt.sourceforge.net/

# {{{ LICENSE: 
# 
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose and without fee is hereby granted, provided
# that the above copyright notices appear in all copies and that both those
# copyright notices and this permission notice appear in supporting
# documentation, and that the names of author not be used in advertising or
# publicity pertaining to distribution of the software without specific,
# written prior permission.  Tong Sun makes no representations about the
# suitability of this software for any purpose.  It is provided "as is"
# without express or implied warranty.
#
# TONG SUN DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL ADOBE
# SYSTEMS INCORPORATED AND DIGITAL EQUIPMENT CORPORATION BE LIABLE FOR ANY
# SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
# RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
# CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# 
# }}} 


# ============================================================== &us ===
# ............................................................. Uses ...

# -- global modules
use strict;			# !
use integer;			# !

use Getopt::Long;
use File::Searcher::Similars;

# ============================================================== &gv ===
# .................................................. Global Varibles ...
#
my $fc_level=0;

# == Brief Usage Explaining

die <<"!W/!SUBS!" unless @ARGV;

fileSimilars.pl - Similar files locator

Usage:
 fileSimilars.pl [--level=1] [dir(s)...]

!W/!SUBS!

# == Command Line Parameter Handling

GetOptions(
    "level:i"	=> \$fc_level,
    ) || die;

File::Searcher::Similars->init($fc_level, \@ARGV);
similarity_check_name();

# {{{ POD:

=head1 NAME

fileSimilars - Similar files locator

=head1 SYNOPSIS

  [perl -S] fileSimilars.pl [--level=1] [dirs...]

Similar-sized and similar-named files are picked as suspicious candidates of
duplicated files.

=head1 DESCRIPTION

=head2 Basic Usage

Nothing descirbes better than actual outputs. Here is an example of suspicious
duplicated files:

  $ fileSimilars.pl -l 1 test
  ## =========
	     3 'CardLayoutTest.java' 'test/'
	     5 'TestLayout.java' 'test/'

  ## =========
	     4 'Python Standard Library.chm'              'test/'
	     4 'GNU - Python Standard Library (2001).chm' 'test/'
	     5 'GNU - 2001 - Python Standard Library.rar' 'test/'

The first column is the size of the file, 2nd the name, and 3rd the path.
fileSimilars will pick similar-sized and similar-named files as suspicious
candidates of duplicated files. Suspicious duplicated files are shown in
groups. The motto for the listing is that, I would rather the program
overkills (wrongly picking out suspicious ones) than neglects something that
would cause me otherwise years to notice.

By default, fileSimilars.pl assumes that similar files within the B<same
folder> are OK. Hence you will not get duplicate warnings for generated
files (like .o, .class or .aux, and .dvi files) or other file series.

Once you are sure that there are no duplications across different folders
and want fileSimilars.pl to scoop deeper and further into same folder,
specify the --level=1 command line switch (or -l 1). This is very good to
eliminate similar mp3 files within the same folder, or downloaded files from
big sites where different packaging methods are used, e.g.:

  ## =========
         66138 jdc-src.tar.gz  .../ftp.ora.com/published/oreilly/java/javadc
        147904 jdc-src.zip     .../ftp.ora.com/published/oreilly/java/javadc

=head2 Advanced Usages

The command line parameters can be a list of dir names or file names.

The command line parameter can also be a '-', a special case in which
file information is read from stdin: 

  find /path/you/want \( -type f -o -type l \) -follow -printf "%p\t%s\n" | fileSimilars.pl -

You can change the find (or fileSimilars) parameters; cache or filter the
find result, but the find output format has to be as shown.

=head1 AUTHOR

 @Author:  SUN, Tong <suntong at cpan.org>
 @HomeURL: http://xpt.sourceforge.net/

=head1 SEE ALSO

File::Compare(3), File::Find::Duplicates(3)

perl(1). 

=head1 COPYRIGHT

Copyright (c) 1997-2008 Tong SUN. All rights reserved.

=head1 TODO

=cut

# }}}

