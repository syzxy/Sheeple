#!/usr/bin/perl
#===============================================================================
#
#         FILE: sheeple.pl
#
#        USAGE: ./sheeple.pl  
#
#  DESCRIPTION: a shell to perl compiler which reads shell from command line args
#               or STDIN and prints perl to STDOUT
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Sam (z5244619) 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/08/20 21:51:58
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

my @shell = ();
my @perl = ();
my @cases = ();
my %first_case = ();
my %subrutines = ();# a list of subrutine names defined in the shell
my $sub_open = 0;   # 1 if the definition line of a subrutine is read
                    # 0 if the closing } is read

#=========================#
#      reading input      #
#=========================#
while (<>) {
    chomp;
    s/\s+$//;                     # delet trailing spaces
    s{
        (?<!\\)\$                 # negative lookbehind that matches non excaped '$'
        (10|[1-9])                # 1-10, $0 contains the filename in both shell and perl
    }
    {'$ARGV['.($1 - 1).']'}gex;   # convert to $ARGV[0-9], /e enables expression evaluation
    s/(?<!\\)\$[@|\*|#]/\@ARGV/g; # $@, $# -> @ARGV
    if ( /(?<!\\);;/ ) {
        push @shell, $_;
    } elsif ( /((?<!\\);)/ ) {         # negative lookbehind that matches non-escaping semicolons;
        push @shell, split /$1\s*/;
    } else {
        push @shell, $_;
    }
}

#DEBUG(__LINE__);

#=========================#
#         helpers         #
#=========================#
sub DEBUG {
    my ($line_num) = @_;
    print "================\n";
    print "DEBUG AT LINE", $line_num, "\n\@shell array is now:\n";
    print "----------------\n";
    print join("\n", @shell),"\n";
    print "================\n";
}

my %operator = (
    '&'  => 'and',
    '|'  => 'or',
    '-a' => 'and',
    '-o' => 'or',
#str sh ---> pl
    '>'  => 'gt',
    '<'  => 'lt',
    '='  => 'eq',
    '>=' => 'ge',
    '<=' => 'le',
    '!=' => 'nq',
#int sh ---> pl
    '-gt' => '>',
    '-lt' => '<',
    '-eq' => '==',
    '-ge' => '>=',
    '-le' => '<=',
    '-nq' => '!='
);

sub is_arg {
    my ($line) = @_;
    return (! is_local_arg($line) and ($line =~ /^\$ARGV\[\d\]$/ or $line eq '@ARGV'));
}

sub is_arithmetic {
    return ( $_[0] =~ /^\$\(\(/ );
}

sub is_cmd_substitution { # `...` and $()
    return ( $_[0] =~ /^(?:`|\$\()/ );
}

sub is_file_operator {
    return ( $_[0] =~ /^-[erwdxzsfhL]$/ );
}

sub is_local_arg {
    return ( $sub_open and $_[0] =~ /^[\$|@]ARGV/ )
}

sub is_number {
    my ($line) = @_;
    return ($line =~ /^\d+\.?\d*$/);
}

sub is_operator {
    return (defined $operator{$_[0]} or $_[0] =~ m/^[-\+\/%]$|^\*{1,2}$/);
}

sub is_string {
    my ($line) = @_;
    return (! is_number($line)
            and ! is_operator($line)
            and ! is_cmd_substitution($line)
            and $line=~ /^[^\$].*$/);
}

sub is_sub_call {
    return (defined $subrutines{$_[0]});
}

sub is_var { # $n
    my ($line) = @_;
    return (! is_arg($line) and ! is_local_arg($line) and $line =~ /^\$\w+$/);
}

sub need_translation {
    return ($_[0] =~ /^(?:read|cd|test|expr|echo)$/);
}

sub parse_arithmetic {
    my ($expr) = @_;
    $expr =~ s/^\$\(\(\s*(.*)\s*\)\)/$1/;
    $expr =~ s/'|"|\\//g;
    my @expr = split /\s+/, $expr;
    foreach (@expr) {
        $_ = "\$$_" if is_string($_);
        $_ = $operator{$_} if defined $operator{$_};
    }
    return join(" ", @expr);
}

sub parse_cmd_substitution {
    my ($expr) = @_;
    $expr =~ s/^(?:\$\()|`|'|"|\\|\)$//g;
    $expr =~ s/^expr\s+(.*)/$1;/;
    return $expr;
}

sub parse_expression {
    my ($expr) = @_;
    $expr =~ s/^\s+|\s+$//;
    #$expr =~ s/\\//g;   # \>, \< --> >
    my @expr = split /\s+/, $expr;
    #print __LINE__, ": expression: @expr\n";
    foreach ( @expr ) {
        next if (is_arg($_)
                or is_local_arg($_)
                or is_var($_)
                or is_file_operator($_) && $_ !~ /^-[hL]$/ );
        if ( is_string($_) ) {
            $_ = "'$_'";
        } elsif ( $operator{$_} ) {
            $_ = $operator{$_};
        } elsif ( /^-[hL]$/ ) {
            $_ = '-l';
        }
    }
    return '(' . join(' ', @expr) . ')';
}

#=========================#
#       main parser       #
#=========================#
#foreach ( @shell ) {
#while ($_ =  shift @shell ) {
sub compile {
    ($_) = @_;
    my $perl_code;

    #=========================#
    #     inline comments     #
    #=========================#
    my $comment = '';
    if ( /(?<!\\)#(?!!)/ ) {
        ($_, $comment) = split(/(?<!\\)#(?!!)/, $_[0], 3);
        s/(\s*)$//;
        $comment = ($1 ? "$1#" : '#') . $comment;
    }
    #print "$_:$comment\n";
    
    #=========================#
    #     &&, || oneliner     #
    #=========================#
    if ( /(\s*)(.*)\s+(&&|\|\|)\s+(.*)/ )
    {
        my $indent = $1;
        my $lh = $2;
        my $operator = $3;
        my $rh = $4;
#        print "\$2: $2, \$3: $3, \$4: $4\n";
        (my $left = compile($lh)) =~ s/;$//;
#        print "left: $left\n";
        (my $right = compile($rh)) =~ s/;$//;
#        print "right: $right\n";

        if ( $lh =~ /^(?:test|\[)\s+/ ) {
            $operator = ( $operator eq '&&' ) ? 'and' : 'or';
        } else {
            $operator = ( $operator eq '&&' ) ? 'or' : 'and';
        }
        return "$indent$left $operator $right;";
#        $perl_code = "$indent$left $operator $right;";
#        print "perl_code: $perl_code\n";
    }

    #=========================#
    #       subset 0&3        #
    #=========================#
    if ( /^\s*#!/ )
    {
        # shbang
        $perl_code = '#!/usr/bin/perl -w';
        #push @perl, '#!/usr/bin/perl -w';
    }
    elsif ( /^(\s*)\b(\S+)=(.*)/ )
    {
        # variable assignment or arithmetic operation $(())
        my $assignment = "$1\$$2 = ";
#        if ( is_var($3) or is_arg($3) ) {
        if ( is_string($3) ) {
            $assignment .= "'$3';";
        } elsif ( is_arithmetic($3) ) {
            $assignment .= (parse_arithmetic($3) . ';');
        } elsif ( is_cmd_substitution($3)) {
            $assignment .= parse_cmd_substitution($3);
        } elsif ( is_local_arg($3) ) {
            (my $arg = $3) =~ s/ARGV/_/;
            $assignment .= "$arg;";
        } else {
            $assignment .= "$3;";
        }
        $perl_code = $assignment;
#        push @perl, $assignment;
    }
    elsif ( /^(\s*)\becho\s+(.*)/ )
    {
        my $indent = $1;
        my $content = $2;
        my $no_new_line = $content =~ /^-n/;
        $content =~ s/^(?:-n)?\s+//;
        if ( $content =~ /^'.*'$/ ) {
            $content =~ s/"/\\"/g;
            $content =~ s/^'|'$/"/g;
#        }
#        elsif ( is_cmd_substitution($content) ) {
#            $content = parse_cmd_substitution($content);
        } elsif ( $content !~ /^".*"$/ ) {
            $content = '"' . $content . '"';
        }
        $content =~ s/"$/\\n"/ unless $no_new_line;
#            push @perl, "${indent}print $content;";
#        } else {
#            # `echo $a $b` -> `print "$a $b\n";`
#            if ( $content =~ /^'.*'$/ ) {
#                $content =~ s/"/\\"/g;
#                $content =~ s/^'|'$/"/;
#                $content =~ s/'$/\\n"/;
#            } elsif ( $content =~ /^".*"$/ ) {
#                $content =~ s/"$/\\n"/;
#            } else {
#                $content = '"' . $content . '\\n"';
#            }
#            push @perl, "${indent}print $content;";
#        }
        $perl_code = "${indent}print $content;";
    }
    elsif ( /^(\s*\b(?:ls|pwd|id|date|rm|mv|chmod)\s+[^;]*)/ )
    {
        (my $line = $1) =~ s/"//g;
        $perl_code = "system \"$1\";";
#        push @perl, "system \"$1\";";
    }

    #=========================#
    #        subset 1         #
    #=========================#
    elsif ( /^(\s*)\bcd\s+([^;]*)/ )
    {
        # `cd /tem` -> `chdir '/tmp/';`
        $perl_code = "$1chdir '$2';";
#        push @perl, "$1chdir '$2';";
    }
    elsif ( /^(\s*)\b((?:exit|return)\s+[^;]*)/ )
    {
        $perl_code = "$1$2;";
#        push @perl, "$1$2;";
    }
    elsif ( /^(\s*)\bread\s+([^;]*)/ )
    {
        $perl_code = "$1\$$2 = <STDIN>;\n$1chomp \$$2;";
#        push @perl, "$1\$line = <STDIN>;\n$1chomp \$$2;";
#        push @perl, "$1chomp \$$2;";
    }
    elsif ( /^(\s*)\bfor\s+(.*?)\s+in\s+([^;]*)/ )
    {
        # `for w in a 1 b` -> `foreach $w ('a', 1, 'b') {`
        #DEBUG(__LINE__);
        my @list = split /\s+/, $3;
        foreach (@list) {
            $_ = "'$_'" if ( /\w/ );
        }
        my $list = join ", ", @list;
        $perl_code = "$1foreach \$$2 ($list) {";
#        push @perl, "$1foreach \$$2 ($list) {";
    }
    elsif ( /^(\s*)\b(?:do|then|{)\s+([^;]*)/ && $2 )
    {
        unshift @shell, "$1\t$2";
    }
    elsif ( /^(\s*)\b(?:done|fi)$/ )
    {
        $perl_code = "$1}";
#        push @perl, '}';
    }

    #=========================#
    #       subset 2&3        #
    #=========================#
#    elsif ( /^(\s*)(if|elif|while)\s+(test|\[)\s+(.*)/ )
    elsif ( /^(\s*)(if|elif|while)\s+(\S+)\s+(.*)/ )
    {
        my $indent = $1;
        my $keyword = ($2 eq 'elif')? '} elsif' : $2;
        (my $expression = $4) =~ s/\s+$//;
        my $perl_exp = '';
        if ($3 eq 'test' or $3 eq '[') {
            $expression =~ s/\]$// if ($3 eq '[');
            if (is_arithmetic($expression)) {
                $perl_exp = '(' . parse_arithmetic($expression) . ')';
            } else {
                $perl_exp = parse_expression($expression);
            }
        } elsif (is_sub_call($3)) {
            $perl_exp = "($3 $expression)";
        } else {
            $perl_exp = "(! system \"$3 $expression\")";
        }
        $perl_code = "$indent$keyword $perl_exp {";
    }
    elsif ( /^(\s*)\bwhile\s+(?:true|:)/ )
    {
        $perl_code = "$1while (1) {";
    }
    elsif ( /^(\s*)(\[|test)\s+(.*)/ )
    {
        my $indent = $1;
        my $perl_exp = '';
        (my $expression = $3) =~ s/\s+$//;
        $expression =~ s/\]$// if ($2 eq '[');
        if (is_arithmetic($expression)) {
            $perl_exp = parse_arithmetic($expression);
        } else {
            $perl_exp = parse_expression($expression);
        }
        $perl_code = "$indent$perl_exp";
    }
    elsif ( /^(\s*)\belse\b/ )
    {
        $perl_code = "$1} else {";
#        push @perl, "$1} else {";
    }

    #=========================#
    #       subset 3&4        #
    #=========================#
    elsif ( /(\s*)(\w+)\(\)\s*{?/ )
    {
        $sub_open = 1;
        my $indent = $1;
        my $sub_name = $2;
        $subrutines{$sub_name} = 1;
        $perl_code = "sub $sub_name {";
    }
    elsif ( /^(\s*){\s*([^;]*)/ )
    {
        unshift @shell, "$1\t$2" if $2;
    }
    elsif ( /^(\s*)local\s+(.*)$/ )
    {
        my @local_vars = split /\s+/, $2;
        $_ = "\$$_" foreach (@local_vars);
        $perl_code = "$1my (" . join(', ', @local_vars) . ');';
    }
    elsif ( /^\s*}$/ )
    {
        $sub_open = 0;
        $perl_code = $_;
    }
    elsif ( /^\s*\bcase\s+(.*)\s+in/ )
    {
        push @cases, $1;
        $first_case{$1} = 1;
    }
    elsif ( /^(\s*)([^\)]*)\)/ and @cases )
    {
        my $var = $cases[$#cases];
        if ($first_case{$var}) {
            $perl_code = "$1if ($var =~ /^$2\$/) {";
            $first_case{$var} = 0;
        } elsif ($2 eq '*') {
            $perl_code = "$1} else {";
        } else {
            $perl_code = "$1} elsif ($var =~ /^$2\$/) {";
        }
    }
    elsif ( /^(\s*);;\s*/ )
    {
        ;
    }
    elsif ( /^(\s*)\besac\b/ )
    {
        my $var = pop @cases;
        $first_case{$var} = 0;
        $perl_code = "$1}";
    }
    elsif ( /^(\s*)(\w+)\s+(.*)/ )
    {
        if (is_sub_call($2)) {
            $perl_code = "$_;";
        } elsif (! need_translation($2)) {
            $perl_code = "$1system \"$2 $3\";";
        }
    }
    
    #=========================#
    # comments & blank lines  #
    #=========================#
    #elsif ( /^\s*#(?!!)/ || /^\s*$/ )
    elsif ( /^\s*$/ )
    {
        $perl_code = $_;
#        push @perl, $_;
    }

    if ( $comment ) {
        $perl_code .= $comment;
    }
    return $perl_code;
#    push @perl, $perl_code if defined $perl_code;
}

while (defined( my $line = shift @shell) ) { # defined won't fail blank lies, 0, false...
    my $perl_code = compile($line);
    push @perl, $perl_code if defined $perl_code;
}
print($_, "\n") foreach ( @perl );
