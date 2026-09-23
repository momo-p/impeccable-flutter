#!/usr/bin/env perl
# Extracts the upstream rule catalog from pbakaus/impeccable's Rust source
# (crates/foundation/src/registry.rs) into JSON, so the Dart port carries the
# same ids, categories, severities, and copy instead of a hand-retyped list.
#
#   extract_registry.pl <path-to-impeccable-checkout> > upstream_registry.json
use strict;
use warnings;

my $repo = shift or die "usage: $0 <impeccable-checkout>\n";
my $path = "$repo/crates/foundation/src/registry.rs";
open my $fh, '<', $path or die "$path: $!\n";
my $src = do { local $/; <$fh> };
close $fh;

# Only the built-in list; the rows after it belong to rule-pack tests.
$src =~ /pub static ANTIPATTERNS: &\[Antipattern\] = &\[(.*?)\n\];/s
  or die "ANTIPATTERNS block not found\n";
my $block = $1;

sub unquote {
    my ($s) = @_;
    return undef unless defined $s;
    $s =~ s/^\s*Some\((.*)\)\s*$/$1/s;
    return undef if $s =~ /^\s*None\s*$/;
    if ($s =~ /^\s*&\[(.*)\]\s*$/s) {           # scopes: &["type"]
        my $inner = $1;
        return [ $inner =~ /"((?:[^"\\]|\\.)*)"/g ];
    }
    $s =~ /"((?:[^"\\]|\\.)*)"/s or return undef;
    my $v = $1;
    $v =~ s/\\"/"/g;
    $v =~ s/\\\\/\\/g;
    return $v;
}

sub field {
    my ($body, $key) = @_;
    # Field values end at a comma that is followed by a newline + next key or close.
    $body =~ /^\s*\Q$key\E:\s*(.*?),\s*$/ms or return undef;
    return unquote($1);
}

sub json_str {
    my ($s) = @_;
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/\t/\\t/g;
    # Upstream copy carries typographic dashes and quotes; keep them as UTF-8.
    return "\"$s\"";
}

my @rows;
while ($block =~ /Antipattern \{(.*?)\n    \},/gs) {
    my $body = $1;
    my $id = field($body, 'id') or next;
    push @rows, {
        id          => $id,
        category    => field($body, 'category'),
        scopes      => field($body, 'scopes'),
        severity    => field($body, 'severity') // 'warning',
        name        => field($body, 'name'),
        description => field($body, 'description'),
        section     => field($body, 'skill_section'),
        guideline   => field($body, 'skill_guideline'),
    };
}

die "no rows parsed\n" unless @rows;

print "{\n";
print "  \"source\": \"pbakaus/impeccable crates/foundation/src/registry.rs\",\n";
print "  \"count\": ", scalar(@rows), ",\n";
print "  \"rules\": [\n";
for my $i (0 .. $#rows) {
    my $r = $rows[$i];
    my @kv;
    push @kv, "      \"id\": " . json_str($r->{id});
    push @kv, "      \"category\": " . json_str($r->{category});
    push @kv, "      \"severity\": " . json_str($r->{severity});
    push @kv, "      \"name\": " . json_str($r->{name});
    push @kv, "      \"description\": " . json_str($r->{description});
    if (ref $r->{scopes} eq 'ARRAY') {
        push @kv, "      \"scopes\": [" . join(', ', map { json_str($_) } @{$r->{scopes}}) . "]";
    }
    push @kv, "      \"section\": " . json_str($r->{section}) if defined $r->{section};
    push @kv, "      \"guideline\": " . json_str($r->{guideline}) if defined $r->{guideline};
    print "    {\n", join(",\n", @kv), "\n    }", ($i == $#rows ? "\n" : ",\n");
}
print "  ]\n}\n";
