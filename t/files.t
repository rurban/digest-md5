print "1..5\n";

use strict;
use Digest::MD5 qw(md5 md5_hex md5_base64);

#
# This is the output of: 'md5sum Changes README MD5.pm MD5.xs rfc1321.txt'
#
my $EXPECT = <<EOT;
964f5d355d5bf60d2cf4736eebbb0ba6  Changes
7d7b8d686e102992616e2d53273d58ba  README
265667801b773e16cfdc33154fa4934f  MD5.pm
3e50650b49a9854543e79877f16209fe  MD5.xs
754b9db19f79dbc4992f7166eb0f37ce  rfc1321.txt
EOT

if (!(-f "README") && -f "../README") {
   chdir("..") or die "Can't chdir: $!";
}

my $testno = 0;

my $B64 = 1;
eval { require MIME::Base64; };
if ($@) {
    print $@;
    print "Will not test base64 methods\n";
    $B64 = 0;
}

for (split /^/, $EXPECT) {
     my($md5hex, $file) = split ' ';
     my $md5bin = pack("H*", $md5hex);
     my $md5b64;
     if ($B64) {
	 $md5b64 = MIME::Base64::encode($md5bin, "");
	 chop($md5b64); chop($md5b64);   # remove padding
     }
     my $failed;

     if (digest_file($file, 'digest') ne $md5bin) {
	 print "$file: Bad digest\n";
	 $failed++;
     }

     if (digest_file($file, 'hexdigest') ne $md5hex) {
	 print "$file: Bad hexdigest\n";
	 $failed++;
     }

     if ($B64 && digest_file($file, 'b64digest') ne $md5b64) {
	 print "$file: Bad b64digest\n";
	 $failed++;
     }

     my $data = cat_file($file);
     if (md5($data) ne $md5bin) {
	 print "$file: md5() failed\n";
	 $failed++;
     }
     if (md5_hex($data) ne $md5hex) {
	 print "$file: md5_hex() failed\n";
	 $failed++;
     }
     if ($B64 && md5_base64($data) ne $md5b64) {
	 print "$file: md5_base64() failed\n";
	 $failed++;
     }

     if (Digest::MD5->new->add($data)->digest ne $md5bin) {
	 print "$file: MD5->new->add(...)->digest failed\n";
	 $failed++;
     }
     if (Digest::MD5->new->add($data)->hexdigest ne $md5hex) {
	 print "$file: MD5->new->add(...)->hexdigest failed\n";
	 $failed++;
     }
     if ($B64 && Digest::MD5->new->add($data)->b64digest ne $md5b64) {
	 print "$file: MD5->new->add(...)->b64digest failed\n";
	 $failed++;
     }

     my @data = split //, $data;
     if (md5(@data) ne $md5bin) {
	 print "$file: md5(\@data) failed\n";
	 $failed++;
     }
     if (Digest::MD5->new->add(@data)->digest ne $md5bin) {
	 print "$file: MD5->new->add(\@data)->digest failed\n";
	 $failed++;
     }
     my $md5 = Digest::MD5->new;
     for (@data) {
	 $md5->add($_);
     }
     if ($md5->digest ne $md5bin) {
	 print "$file: $md5->add()-loop failed\n";
	 $failed++;
     }

     print "not " if $failed;
     print "ok ", ++$testno, "\n";
}


sub digest_file
{
    my($file, $method) = @_;
    $method ||= "digest";
    #print "$file $method\n";

    open(FILE, $file) or die "Can't open $file: $!";
    binmode(FILE);
    my $digest = Digest::MD5->new->addfile(*FILE)->$method();
    close(FILE);

    $digest;
}

sub cat_file
{
    my($file) = @_;
    local $/;  # slurp
    open(FILE, $file) or die "Can't open $file: $!";
    binmode(FILE);
    my $tmp = <FILE>;
    close(FILE);
    $tmp;
}

