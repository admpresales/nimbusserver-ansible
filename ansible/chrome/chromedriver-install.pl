#!/usr/bin/env perl

use v5.30;
use LWP::Simple;
use JSON;
use Data::Dumper;

# Figure out the currently installed version of Chrome and attempt to install a
# compatible version of the ChromeDriver

my @chrome_info = qx(apt-cache show google-chrome-stable);
my $chrome_version;

for (@chrome_info) {
    if (/^Version: ([^-]+)/) {
        $chrome_version = $1;
        last;
    }
}

die "Could not detect chrome version.\n" unless $chrome_version;
print "Chrome Version: $chrome_version\n";

my $data = get('https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json');
my $json = decode_json($data);

my ($version_info)  = grep { $chrome_version eq $_->{version} } $json->{versions}->@*;
my ($download_info) = grep { $_->{platform}  eq 'linux64'     } $version_info->{downloads}->{chromedriver}->@*;
my $download_url = $download_info->{url};

die "Could not find download URL.\n" unless $download_url;
print "Downloading $download_url\n";

chdir '/tmp';

my $filename = 'chromedriver-linux64.zip';
my $dest_dir = '/opt/chromedriver';

my $zip = get($download_url);

open my $fh, '> :raw :bytes', $filename;
print $fh $zip;
close $fh;

die "Unknown download error.\n" unless -s $filename;

system("mkdir -p $dest_dir") == 0 or die "ERROR: Could not create '$dest_dir': $?\n";
system("unzip -o $filename") == 0 or die "ERROR: Could not extract '$filename': $?\n";
system("mv -vf chromedriver-linux64/chromedriver $dest_dir/chromedriver") == 0 or die "ERROR: Could not install binary: $?\n";
