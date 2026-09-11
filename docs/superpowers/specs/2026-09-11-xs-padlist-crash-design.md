# Prevent XS CV Padlist Crash

## Problem

Devel::SizeMe calls `CvPADLIST()` for every `SVt_PVCV`. On Perl 5.30, an XS
subroutine uses the same union member for an XS handshake-context pointer, so
interpreting it as a padlist causes a segmentation fault. This breaks sizing an
XS subroutine directly and whole-interpreter profiling through `perl_size()` or
`heap_size()`.

## Design

Check `CvISXSUB()` before accessing CV fields whose meaning differs for XS and
pure-Perl subroutines. XS CVs will continue to traverse `cv_const_sv`. Pure-Perl
CVs will continue to traverse `CvPADLIST()` and `CvROOT()`.

The change will remain in the existing `SVt_PVCV` branch and will not add Perl
version checks. The CV representation, rather than the Perl version, determines
which fields are valid.

## Verification

Use the existing `t/basic.t` assertion that sizes the XS implementation of
`Devel::SizeMe::total_size` as the focused regression test. Then run
`t/10-sizeme.t`, the full test suite, and a whole-script `perl -d:SizeMe` smoke
test that verifies a nonempty profile is produced without a crash.

No public API or output format changes are expected.
