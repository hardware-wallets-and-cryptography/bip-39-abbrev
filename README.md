# BIP-39 abbreviations generator

This script takes the English [BIP-39 wordlist](https://github.com/bitcoin/bips/blob/master/bip-0039/english.txt) (a local copy is in [english.txt](./english.txt)) and generates a short abbreviation for each word.

The generated list contains an uppercase abbreviation for each word of the original BIP-39 wordlist. Each abbreviation is the shortest prefix that still uniquely identifies its word within the list. If a word is itself a prefix of another word (for example, "act" and "actor"), no shorter prefix can identify it, so the full word is kept (`ACT` and `ACTO`).

To run the script, you need [Perl](https://www.perl.org/) installed.

To generate the abbreviated wordlist, run:

`perl generate.pl`

The script reads `english.txt` and creates `english_abbreviated.txt` in the script's directory (an existing file is overwritten). The new file has one abbreviation per line, in the same order as the original wordlist.

To use a different wordlist as input, pass its path as an argument:

`perl generate.pl path/to/wordlist.txt`
