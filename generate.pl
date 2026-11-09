#!/usr/bin/env perl
#
# Generates the shortest unique uppercase abbreviation (prefix)
# for each word of the BIP-39 English wordlist.
#
# Usage: perl generate.pl [wordlist-file]
#   Input:  the wordlist file given as the argument; by default, english.txt
#           located next to this script.
#   Output: english_abbreviated.txt, created next to this script
#           (an existing file is overwritten), with one abbreviation
#           per line in the original wordlist order.
#
# If a word is itself a prefix of another word, no proper prefix can identify
# it uniquely, so the full word is used as its abbreviation.

use strict;
use warnings;
use FindBin qw($RealBin);
use File::Spec;

# Reads and validates the wordlist: one lowercase a-z word per line,
# no duplicates. Returns the words in file order.
sub read_words {
    my ($path) = @_;

    open my $fh, '<', $path or die "Cannot open '$path': $!\n";

    my ( @words, %seen );
    while ( my $line = <$fh> ) {
        $line =~ s/\s+\z//;    # strips line ending (LF or CRLF) and trailing spaces
        $line =~ s/\A\xEF\xBB\xBF// if $. == 1;    # strips a UTF-8 BOM, if any
        next if $line eq '';

        die "Invalid word '$line' at $path line $.: expected a-z letters only\n"
          unless $line =~ /\A[a-z]+\z/;
        die "Duplicate word '$line' at $path line $.\n" if $seen{$line}++;

        push @words, $line;
    }
    close $fh or die "Cannot close '$path': $!\n";

    die "No words found in '$path'\n" unless @words;
    return @words;
}

# Returns the number of leading characters that two strings have in common.
sub common_prefix_length {
    my ( $x, $y ) = @_;
    my $max = length($x) < length($y) ? length($x) : length($y);
    my $n   = 0;
    $n++ while $n < $max && substr( $x, $n, 1 ) eq substr( $y, $n, 1 );
    return $n;
}

# Returns a hash reference mapping each word to its uppercase abbreviation:
# the shortest prefix that is not shared with any other word, i.e. one letter
# longer than the longest prefix shared with another word. A word that is
# itself a prefix of another word keeps its full spelling.
sub abbreviate {
    my @words = @_;

    # In sorted order, the word sharing the longest prefix with a given word
    # is always one of its two immediate neighbours, so only those are compared.
    my @sorted = sort @words;
    my %abbr;

    for my $i ( 0 .. $#sorted ) {
        my $word    = $sorted[$i];
        my $longest = 0;

        for my $j ( $i - 1, $i + 1 ) {
            next if $j < 0 || $j > $#sorted;
            my $len = common_prefix_length( $word, $sorted[$j] );
            $longest = $len if $len > $longest;
        }

        my $len = $longest + 1;
        $len = length $word if $len > length $word;    # word is a prefix of another
        $abbr{$word} = uc substr( $word, 0, $len );
    }

    return \%abbr;
}

my $path = @ARGV ? shift @ARGV : File::Spec->catfile( $RealBin, 'english.txt' );
die "Usage: perl generate.pl [wordlist-file]\n" if @ARGV;

my @words = read_words($path);
my $abbr  = abbreviate(@words);

# Sanity check: no two words may end up with the same abbreviation.
my %used;
for my $word (@words) {
    my $short = $abbr->{$word};
    die "Abbreviation '$short' is not unique ('$word' and '$used{$short}')\n"
      if exists $used{$short};
    $used{$short} = $word;
}

# Write to a temporary file first, then rename it, so a failure never leaves
# a partial output file behind.
my $out_path = File::Spec->catfile( $RealBin, 'english_abbreviated.txt' );
my $tmp_path = "$out_path.tmp";

open my $out, '>', $tmp_path or die "Cannot write '$tmp_path': $!\n";
print {$out} "$abbr->{$_}\n" for @words;
close $out or die "Cannot close '$tmp_path': $!\n";

rename $tmp_path, $out_path
  or die "Cannot rename '$tmp_path' to '$out_path': $!\n";

print "Wrote " . scalar(@words) . " abbreviations to $out_path\n";
