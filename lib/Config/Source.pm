package Config::Source;

use 5.008008;
use strict 'vars';
use warnings;
use constant { DEBUG => 0 };

require Exporter;
if (DEBUG) { use Data::Dumper }

our @ISA = qw(Exporter);

our @EXPORT = qw(source);

our $VERSION = '0.02';

my $cmd;

my $cmdtmpl = <<'_EOF_'
@@MAGICVAR@@=$(set | perl -e '@l = <>; for (@l) { chomp; s/^(\w+)=.*$/$1/ and push @a, $_ }; print "@@MAGICVAR@@ @a"'); . "@@BASHCONFIG@@"; set | perl -e '@a = qw/'"$@@MAGICVAR@@"'/; @l = <>; for (@a) { $h{$_}++ } for (@l) { chomp; if (m/^(\w+)=(.*)$/) { print "$1=$2\n" unless $h{$1} or $1 eq "PIPESTATUS" } }'
_EOF_
;
my $shell = 'sh';
my $magicvar = "_MAGICLAMP";

sub _cmdsetup {
	my $script = shift;
	$cmd = $cmdtmpl;
	$cmd =~ s/\@\@BASHCONFIG\@\@/$script/g;
	$cmd =~ s/\@\@MAGICVAR\@\@/$magicvar/g;
}

sub source {
	my (@arr);
	my (%h);
	my ($arr, $elem, $i, $j);

	my $script = shift;
	DEBUG and print <<_EOF_
\$script='$script'
_EOF_
;
	_cmdsetup($script);
	open(P, "-|", $shell, "-c", $cmd);
	while (<P>) {
		chomp;
		if (m/^([^=]+)=\((.*?)\)$/) {
			# Array
			@arr = ();
			$arr = $2;
			$i = 0;
			while ($i = index($arr, '"', $i) and $i != -1) {
				$j = $i;
				do {
					$j = index($arr, '"', $j + 1);
				} while substr($arr, $j - 1, 1) eq '\\';
				$elem = substr($arr, $i + 1, $j - $i - 1);
				push @arr, $elem;
				$i = $j + 1;
			}
			$h{$1} = [ @arr ];
		}
		elsif (m/^([^=]+)='?(.*?)'?$/) {
			# String
			$h{$1} = $2;
		}
	}
	close P;

	DEBUG and print Dumper \%h;
	return \%h;
}


1;
__END__

=head1 NAME

Config::Source - Perl extension for sourcing shell scripts

=head1 SYNOPSIS

  use Config::Source;
  
  $hashref = source("/path/to/file.sh");

=head1 DESCRIPTION

  Config::Source exports a function source(), which on invocation
  with a path to a shell file as parameter will return a hash ref
  with all the variables that shell file set, as if it was sourced
  by a shell. It works on nested source files and can deal with
  all shell syntax and commands, since it actually invokes /bin/sh
  to do the work. So be careful, the source file will be actually
  executed, and is able to do harm if malicious. The same thing
  goes for shell scripts that make use of the source (".") command.

=head2 EXPORT

sub source()

=head1 SEE ALSO

  Your shell's manual, look for the description of the source
  builtin, also written as "."

=head1 AUTHOR

M. L. de Boer, E<lt>locsmif@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

  Config::Source is a Perl module that can source shell scripts.
  It actually invokes /bin/sh, so it can handle anything the shell
  otherwise would have, including nested sourcing, arrays, and 
  shell instructions. It returns the variables set by the sourced
  script, so that your Perl script can use the same configuration
  files as your shell scripts.
  Copyright (C) 2007  M. L. de Boer a.k.a. Locsmif

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
