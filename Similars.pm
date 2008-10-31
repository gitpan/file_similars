package File::Searcher::Similars;

# @Author: Tong SUN, (c)2001-2003, all right reserved
# @Version: $Date: 2008/10/31 16:07:34 $ $Revision: 1.27 $
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

# {{{ POD, Intro:

=head1 NAME

File::Searcher::Similars - Fast similar-files finder

=head1 SYNOPSIS

  use File::Searcher::Similars;

  File::Searcher::Similars->init(0, \@ARGV);
  similarity_check_name();

Similar-sized and similar-named files are picked as suspicious candidates of
duplicated files.

Please note that this version is deprecated. Future versions are released
as File::Find::Similars.

=head1 DESCRIPTION

Extremely fast file similarity checker. It uses advanced soundex vector
algorithm to determine the similarity between files. Generally it means that
if there are n files, each having approximately m words, the degree of
calculation is merely

  O(n^2 * m)

which is over hundreds times faster than any existing file fingerprinting
technology.

The self-test output will help you understand what the module do and what
would you expect from the outcome.

  $ make test
  PERL_DL_NONLAZY=1 /usr/bin/perl "-Iblib/lib" "-Iblib/arch" test.pl
  1..4
  # Running under perl version 5.010000 for linux
  # Current time local: Wed Oct 29 11:35:06 2008
  # Current time GMT:   Wed Oct 29 15:35:06 2008
  # Using Test.pm version 1.25
  # Testing File::Searcher::Similars version 1.23
  
  == Testing 1, files under test/ subdir:
  
    9 test/(eBook) GNU - Python Standard Library 2001.pdf
    3 test/CardLayoutTest.java
    5 test/GNU - 2001 - Python Standard Library.pdf
    4 test/GNU - Python Standard Library (2001).rar
    9 test/LayoutTest.java
    3 test/PopupTest.java
    2 test/Python Standard Library.zip
    5 test/TestLayout.java
  ok 1
  
  Note:
  
  - The fileSimilars.pl script will pick out similar files from them in next test.
  - Let's assume that the number represent the file size in KB.
  
  == Testing 2 result should be:
  
  ## =========
             3 'CardLayoutTest.java' 'test/'
             5 'TestLayout.java' 'test/'
  
  ## =========
             4 'GNU - Python Standard Library (2001).rar' 'test/'
             5 'GNU - 2001 - Python Standard Library.pdf' 'test/'
  ok 2
  
  Note:
  
  - There are 2 groups of similar files picked out by the script.
    The second group makes more sense.
  - The similar files are picked because their file names looks similar.
  - However, the file size plays an important role as well.
  - There are 2 files in the second similar files group.
  - The file 'Python Standard Library.zip' is not considered to be similar to
    the group because its size is not similar to the group.
  
  == Testing 3, if Python.zip is bigger, result should be:
  
  ## =========
             3 'CardLayoutTest.java' 'test/'
             5 'TestLayout.java' 'test/'
  
  ## =========
             4 'Python Standard Library.zip' 'test/'
             4 'GNU - Python Standard Library (2001).rar' 'test/'
             5 'GNU - 2001 - Python Standard Library.pdf' 'test/'
  ok 3
  
  Note:
  
  - There are 3 files in the second similar files group.
  - The file 'Python Standard Library.zip' is now in the 2nd similar files
    group because its size is now similar to the group.
  
  == Testing 4, if Python.zip is even bigger, result should be:
  
  ## =========
             3 'CardLayoutTest.java' 'test/'
             5 'TestLayout.java' 'test/'
  
  ## =========
             4 'GNU - Python Standard Library (2001).rar'       'test/'
             5 'GNU - 2001 - Python Standard Library.pdf'       'test/'
             6 'Python Standard Library.zip'                    'test/'
             9 '(eBook) GNU - Python Standard Library 2001.pdf' 'test/'
  ok 4
  
  Note:
  
  - There are 4 files in the second similar files group.
  - The file 'Python Standard Library.zip' is still in the group.
  - But this time, because it is also considered to be similar to the .pdf
    file (since their size are now similar, 6 vs 9), a 4th file the .pdf
    is now included in the 2nd group.
  - If the size of file 'Python Standard Library.zip' is 12(KB), then the
    second similar files group will be split into two. Do you know why and
    which files each group will contain?

The File::Searcher::Similars package comes with a fully functional demo
script fileSimilars.pl. Please refer to its help file for further
explanations.

This package is highly customizable. Refer to hash variable %config and/or
the 3 arrwash_ functions for customization hints.

=cut

# }}}

# {{{ global declaration:

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(
&similarity_check_name	
);

# ============================================================== &us ===
# ............................................................. Uses ...

# -- global modules
use strict;			# !

use Carp;
use Getopt::Long;
use File::Basename;
use Text::Soundex;

# -- local modules

sub dbg_show {};

# -- global variables
use vars qw($progname $VERSION $verbose $debugging);

# ============================================================== &cs ===
# ................................................. Constant setting ...
#
$VERSION = sprintf("%d.%02d", q$Revision: 1.27 $ =~ /(\d+)\.(\d+)/);


# ============================================================== &gv ===
# .................................................. Global Varibles ...
#
use vars qw(%config @filequeue @fileInfo %sdxCnt %wrdLst);

$config{WeightSoundex} = 50;	# precentage of weight that soundex takes,
				# the rest is for file size
$config{Threshold} = 75;	# over which files are considered similar
$config{Deliminator} = "\n## =========\n";
$config{Format} = "%12d '%s' %s'%s'";

# @fileInfo: List of the following list:
my (
    $N_dName,			# dir name
    $N_fName,			# file name
    $N_fSize,			# file size
    $N_fSdxl,			# file soundex list, reference
    ) = (0..9);

my $fc_level=0;

# }}}


# Preloaded methods go here.

# ############################################################## &ss ###
# ................................................ Subroutions start ...

# =========================================================== &s-sub ===
# S -  File::Searcher::Similars->init($fc_level, \@ARGV);
# D -  initialize file comparing level and dir queue
# 
# T -  
sub init ($\@) {
    my ($mname, $_fc_level, $init_dirs) = @_;
    $fc_level = $_fc_level;	# update module variable
    #warn "] $mname, $fc_level, $init_dirs\n";

    @filequeue = @fileInfo = ();
    @filequeue = (@filequeue, map { [$_, ''] } @$init_dirs);
    process_entries();

    dbg_show(100,"\@fileInfo", @fileInfo);
    dbg_show(100,"%sdxCnt", %sdxCnt);
    dbg_show(100,"%wrdLst", %wrdLst);
}    

# =========================================================== &s-sub ===
# I -  Input: global array @filequeue
#      Input parameters: None
# 
sub process_entries {
    my($dir, $qf) = ();
    #warn "] inside process_entries...\n";

    while ($qf = shift @filequeue) {
	($dir, $_) = ($qf->[0], $qf->[1]);
	#warn "] inside process_entries loop, $dir, $_, ...\n";
        next if /^..?$/;
        my $name = "$dir/$_";
	#warn "] processing file '$name'.\n";
	if ($name eq '-/') {
	    # get info from stdin
	    process_stdin();
	}
	elsif (-d $name) {
	    # a directory, process it recursively.
	    process_dir($name);
	}
	else {
	    process_file($dir, $_);
	}
    }
}

# =========================================================== &s-sub ===
# D -  Process info given from stdin, which should of form same as
#       find -printf "%p\t%s\n"
# 
sub process_stdin {
  
  while (<>){
    croak "Wrong input format: '$_'" unless m{(.*)/(.+?)\t(\d+)$};
    my ($dn, $fn, $size) = ( $1, $2, $3 );
    my $fSdxl = [ get_soundex($fn) ]; # file soundex list
    push @fileInfo, [ $dn, $fn, $size, $fSdxl, ];

    dbg_show(100,"fileInfo",@fileInfo);
    map { $sdxCnt{$_}++ } @$fSdxl;
  }
}

# =========================================================== &s-sub ===
# D -  Process given dir recursively
# N -  BFS is more memory friendly than DFS
# 
# T -  $dir="/home/tong/tmp"
sub process_dir {
    my($dir) = @_;
    #warn "] processing dir '$dir'...\n";

    opendir(DIR,$dir) || die "File::Searcher::Similars error: Can't open $dir";
    my @filenames = readdir(DIR);
    closedir(DIR);

    # record the dirname/fname pair to queue
    @filequeue = (@filequeue, map { [$dir, $_] } @filenames);
    dbg_show(100,"filequeue", @filequeue)
}

# =========================================================== &s-sub ===
# S -  process_file($dirname, $fname), process file $fname under $dirname
# D -  Process one file and update global vars
# U -  
#
# I -  Input parameters:
#	$dirname: dir name string
#	$fname:	 file name string
# O -  Global vars get updated
#      fileInfo [ $dirname, $fname, $fsize, [ file_soundex ] ]
# T -  

sub process_file {
    my ($dn, $fn) = @_;
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,@rest) =
	stat("$dn/$fn");
    my $fSdxl = [ get_soundex($fn) ]; # file soundex list
    push @fileInfo, [ $dn, $fn, $size, $fSdxl, ];

    dbg_show(100,"fileInfo",@fileInfo);
    map { $sdxCnt{$_}++ } @$fSdxl;
}

# =========================================================== &s-sub ===
# S -  get_soundex($fname), get soundex for file $fname
# D -  Return a list of soundex of each individual word in file name
# U -  $aref = [ get_soundex($fname) ];
#
# I -  Input parameters:
#	$fname:	 file name string
# O -  sorted anonymous soundex array w/ duplications removed
# T -  @out = get_soundex 'Java_RMI - _Remote_Method_Invocation_ch03.tgz';
#      @out = get_soundex 'ASuchKindOfFile.tgz';

sub get_soundex {
    my ($fn) = @_;
    # split to individual words
    my @fn_wlist = split /[-_[:cntrl:][:blank:][:punct:][:digit:]]/i, $fn;
    # discards file extension, if any
    pop @fn_wlist if @fn_wlist >= 1;
    # if it is single word, try further decompose SuchKindOfWord
    @fn_wlist = $fn_wlist[0] =~ /[A-Z][^A-Z]*/g
	if @fn_wlist == 1 && $fn_wlist[0] =~ /^[A-Z]/;
    # wash short
    dbg_show(100,"wlist 0",@fn_wlist);
    @fn_wlist = arrwash_short(\@fn_wlist);
    dbg_show(100,"wlist 1",@fn_wlist);

    # language specific handling
    @fn_wlist = arrwash_lang(\@fn_wlist);
    dbg_show(100,"wlist 2",@fn_wlist);
    
    # change word to soundex, record soundex/word in global hash
    map {
	if (/[[:alpha:]]/) {
	    my $sdx = soundex($_);
	    $wrdLst{$sdx}{$_}++;
	    s/^.*$/$sdx/;
	    }
	} @fn_wlist;
    dbg_show(1,"wrdLst",%wrdLst);

    # wash empty/duplicates
    @fn_wlist = grep(!/^$/, @fn_wlist);
    @fn_wlist = arrwash_dup(\@fn_wlist);
    
    return sort @fn_wlist;
}

# =========================================================== &s-sub ===
# S -  arrwash_short($arr_ref), wash short from array $arr_ref
# D -  weed out empty lines and less-than-3-letter words (e.g. ch12)
# U -  @fn_wlist = arrwash_short(\@fn_wlist);
#

sub arrwash_short($) {
    my ($arr_ref) = @_;
    return @$arr_ref unless @$arr_ref >= 1;
    my @r= grep tr/a-zA-Z// >=3, @$arr_ref;
    return @r if @r;
    return @$arr_ref		# for upper ASCII
	if grep(/[\200-\377]/, @$arr_ref);
    return @r;
}

# =========================================================== &s-sub ===
# S -  arrwash_dup($arr_ref), wash duplicates from array $arr_ref
# D -  weed out duplicates
# U -  @fn_wlist = arrwash_dup(\@fn_wlist);
#

sub arrwash_dup($) {
    my ($arr_ref) = @_;
    my %saw;
    return grep !$saw{$_}++, @$arr_ref;
}

# =========================================================== &s-sub ===
# S -  arrwash_lang($arr_ref), language specific washing from array $arr_ref
# U -  @fn_wlist = arrwash_lang(\@fn_wlist);
#

sub arrwash_lang($) {
    my ($arr_ref) = @_;
    
    # split Chinese into individual chars
    my @r;
    map {
	if (/[\200-\377]{2}/) {
	    @r = (@r, /[\200-\377]{2}/g);
	}
	else {
	    @r = (@r, $_);
	}
    } @$arr_ref;
    
    return @r;
}

# =========================================================== &s-sub ===
# S -  similarity_check_name: similarity check on glabal array @fileInfo
# U -  similarity_check_name();
#
# I -  Input parameters: None
# O -  similar files printed on stdout

sub similarity_check_name {

    # get a ordered (by soundex count) file Info array
    # (Use short file names to compare to long file names)
    my @fileInfos = 
	sort { $#{$a->[$N_fSdxl]} cmp $#{$b->[$N_fSdxl]} } @fileInfo;
    dbg_show(100,"\@fileInfos", @fileInfos);

    my @saw = (0) x ($#fileInfos+1);
    foreach my $ii (0..$#fileInfos) {
	#warn "] ii=$ii\n";
	my @similar = (); 
	my $fnl;
	
	dbg_show(100,"\@fileInfos", $fileInfos[$ii]);
	push @similar, [$ii, $ii, $fileInfos[$ii]->[$N_fSize] ];
	foreach my $jj (($ii+1) ..$#fileInfos) {
	    $fnl=0;		# 0 is good enough since file at [ii] is 
				# shorter in name than  the one at [jj]
	    #warn "] jj=$jj\n";
	    # don't care about same dir files?
	    next 
		if (!$fc_level && ($fileInfos[$ii]->[$N_dName] 
		    eq $fileInfos[$jj]->[$N_dName])) ;
	    if (file_diff(\@fileInfos, $ii, $jj) >= $config{Threshold}) {
		push @similar, [$ii, $jj, $fileInfos[$jj]->[$N_fSize] ];
		$fnl= length($fileInfos[$jj]->[$N_fName]) if
		    $fnl < length($fileInfos[$jj]->[$N_fName]);
	    }
	}
	dbg_show(100,"\@similar", @similar);
	# output unvisited potential similars by each row, order by fSize 
	@similar = grep {!$saw[$_->[1]]}
	  sort { $a->[2] <=> $b->[2] } @similar;
	next unless @similar>1;
	print $config{Deliminator};
	foreach my $similar (@similar) {
	    print file_info(\@fileInfos, $similar->[1], $fnl). "\n";
	    $saw[$similar->[1]]++;
	}
    }
}

# =========================================================== &s-sub ===
sub file_info ($$$) {
    my ($fileInfos, $ndx, $fnl) = @_;
    return sprintf($config{Format}, $fileInfos->[$ndx]->[$N_fSize], 
		   $fileInfos->[$ndx]->[$N_fName],
		   ' ' x ($fnl - length($fileInfos->[$ndx]->[$N_fName])),
		   "$fileInfos->[$ndx]->[$N_dName]");
}

# =========================================================== &s-sub ===
# S -  file_diff: determind how difference two files are by name & size
# U -  file_diff($fileInfos, $ndx1, $ndx2);
#
# I -  $fileInfos:	reference to @fileInfos
#	$ndx1, $ndx2:	index to the two file in @fileInfos
# O -  100%: files are identical
#	0%: no similarity at all
sub file_diff ($$$) {
    my ($fileInfos, $ndx1, $ndx2) = @_;

    return 0 unless @{$fileInfos->[$ndx1]->[$N_fSdxl]};
    
    # find intersection in two soudex array
    my %count = ();
    foreach my $element 
	(@{$fileInfos->[$ndx1]->[$N_fSdxl]},
	 @{$fileInfos->[$ndx2]->[$N_fSdxl]}) { $count{$element}++ }
    # since there is no duplication in each of file soudex
    my $intersection = 
	grep $count{$_} > 1, keys %count;
    # return p * normal(\common soudex) + (1-p) * ( 1 - normal(\delta fSize))
    # so the bigger the return value is, the similar the two files are
    $intersection *= $config{WeightSoundex} /
	(@{$fileInfos->[$ndx1]->[$N_fSdxl]});
    dbg_show(100,"intersection", $intersection, $ndx1, $ndx2);
    my $WeightfSzie = 100 - $config{WeightSoundex};
    my $dfSize = abs($fileInfos->[$ndx1]->[$N_fSize] -
		     $fileInfos->[$ndx2]->[$N_fSize]) * $WeightfSzie / 
		($fileInfos->[$ndx1]->[$N_fSize] + 1);
    $dfSize = $dfSize > $WeightfSzie ? $WeightfSzie : $dfSize;
    my $file_diff = $intersection + ($WeightfSzie - $dfSize);
    if ($file_diff >= $config{Threshold}) {
	dbg_show(010,"file_diff",
		 @{$fileInfos->[$ndx1]},
		 @{$fileInfos->[$ndx2]},
		 $intersection, $dfSize, $file_diff
		 );
    }
    return $file_diff;
}


1;
__END__


=head1 AUTHOR

 Author:  SUN, Tong <suntong at cpan.org>
 HomeURL: http://xpt.sourceforge.net/


=head1 SEE ALSO

File::Compare(3), perl(1) and the following scripts. 

## File::Find::Duplicates - Find duplicate files

http://belfast.pm.org/Modules/Duplicates.html

my %dupes = find_duplicate_files('/basedir1', '/basedir2');

When passed a base directory (or list of such directories) it returns a hash,
keyed on filesize, of lists of the identical files of that size.

## ch::claudio::finddups - Find duplicate files in given directory

http://www.claudio.ch/Perl/finddups.html

ch::claudio::finddups is a script as well as a package. When called as script
it will search the directory and its subdirectories for files with (possibly)
identical content.

To find identical files fast this program will just remember the Digest::SHA1
hash of each file, and signal two files as equal if their hash matches. It
will output lines that can be given to a bourne shell to compare the two
files, and remove one of them if the comparison indicated that the files are
indeed identical.

Besides that it can be used as a package, and gives so access to the following
variables, routines and methods.

## dupper.pl - finds duplicate files, optionally removes them

http://sial.org/code/perl/scripts/dupper.pl.html

Script to find (and optionally remove) duplicate files in one or more
directories. Duplicates are spotted though the use of MD5 checksums.


=head1 COPYRIGHT

Copyright (c) 2001-2008 Tong SUN. All rights reserved.

=head1 TODO

=cut
