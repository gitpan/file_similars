#! /usr/bin/env perl
# -*- perl -*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 4, todo => [1] }

# load your module...
use File::Searcher::Similars;

print "# Testing File::Searcher::Similars version $File::Searcher::Similars::VERSION\n";

# Test code

sub dotest{
    my ($fsize) = @_;

    open(FH, ">test/Python Standard Library.zip");
    print FH 'a' x $fsize;
    close(FH);

    open(TESTOUT, 'LANG=C perl "-Iblib/lib" "-Iblib/arch" fileSimilars.pl --level=1 test |');
    my @strs = <TESTOUT>;
    my $strs = join("",@strs);
    #print "\n Returns:\n$strs";

    return $strs;
}

my ($result0, $result1);

# ======================================================= &test_case ===

$result0="";
$result1=dotest(2);

$result0="  9 test/(eBook) GNU - Python Standard Library 2001.pdf
  3 test/CardLayoutTest.java
  5 test/GNU - 2001 - Python Standard Library.pdf
  4 test/GNU - Python Standard Library (2001).rar
  9 test/LayoutTest.java
  3 test/PopupTest.java
  2 test/Python Standard Library.zip
  5 test/TestLayout.java
";
print "\n== Testing 1, files under test/ subdir:\n\n$result0";
open(TESTOUT, 'find test -printf "%3s %p\n" | tail -n +2 | LANG=C sort -k 2 |');
my @strs = <TESTOUT>;
my $strs = join("",@strs);
ok($strs,$result0) || print $strs;

print "
Note:

- The fileSimilars.pl script will pick out similar files from them in next test.
- Let's assume that the number represent the file size in KB.
";

# ======================================================= &test_case ===

$result0="
## =========
           3 'CardLayoutTest.java' 'test/'
           5 'TestLayout.java' 'test/'

## =========
           4 'GNU - Python Standard Library (2001).rar' 'test/'
           5 'GNU - 2001 - Python Standard Library.pdf' 'test/'
";
print "\n== Testing 2 result should be:\n$result0";
ok($result1,$result0) || print $result1;

print "
Note:

- There are 2 groups of similar files picked out by the script.
  The second group makes more sense.
- The similar files are picked because their file names look similar.
- However, the file size plays an important role as well.
- There are 2 files in the second similar files group.
- The file 'Python Standard Library.zip' is not considered to be similar to
  the group because its size is not similar to the group.
";

# ======================================================= &test_case ===

$result0="
## =========
           3 'CardLayoutTest.java' 'test/'
           5 'TestLayout.java' 'test/'

## =========
           4 'Python Standard Library.zip' 'test/'
           4 'GNU - Python Standard Library (2001).rar' 'test/'
           5 'GNU - 2001 - Python Standard Library.pdf' 'test/'
";
print "\n== Testing 3, if Python.zip is bigger, result should be:\n$result0";
$result1=dotest(4);
ok($result1,$result0) || print $result1;

print "
Note:

- There are 3 files in the second similar files group.
- The file 'Python Standard Library.zip' is now in the 2nd similar files
  group because its size is now similar to the group.
";

# ======================================================= &test_case ===

$result0="
## =========
           3 'CardLayoutTest.java' 'test/'
           5 'TestLayout.java' 'test/'

## =========
           4 'GNU - Python Standard Library (2001).rar'       'test/'
           5 'GNU - 2001 - Python Standard Library.pdf'       'test/'
           6 'Python Standard Library.zip'                    'test/'
           9 '(eBook) GNU - Python Standard Library 2001.pdf' 'test/'
";
print "\n== Testing 4, if Python.zip is even bigger, result should be:\n$result0";
$result1=dotest(6);
ok($result1,$result0) || print $result1;

print "
Note:

- There are 4 files in the second similar files group.
- The file 'Python Standard Library.zip' is still in the group.
- But this time, because it is also considered to be similar to the .pdf
  file (since their size are now similar, 6 vs 9), a 4th file the .pdf
  is now included in the 2nd group.
- If the size of file 'Python Standard Library.zip' is 12(KB), then the
  second similar files group will be split into two. Do you know why and
  which files each group will contain?
";

1;

# Test End
