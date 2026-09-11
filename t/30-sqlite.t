#!/usr/bin/perl -w

use strict;
use Test::More;

use DBI;
use ExtUtils::testlib;
use File::Temp qw(tempfile);

my ($db_fh, $db_file) = tempfile(SUFFIX => '.db');
close $db_fh or die "Can't close $db_file: $!";

my $status = system(
	$^X,
	'-Mblib',
	'bin/sizeme_store.pl',
	'--db', $db_file,
	't/20-smt-basic.smt',
);

is($status, 0, 'sizeme_store creates a SQLite report');

SKIP: {
	skip 'sizeme_store did not create the SQLite report', 2 if $status;

	my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", '', '', {
		RaiseError => 1,
		PrintError => 0,
	});

	my ($table_count) = $dbh->selectrow_array(
		q{SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = 'node'}
	);
	is($table_count, 1, 'SQLite report contains the node table');

	my ($node_count) = $dbh->selectrow_array('SELECT COUNT(*) FROM node');
	cmp_ok($node_count, '>', 0, 'SQLite report contains nodes');

	$dbh->disconnect;
}

done_testing;
