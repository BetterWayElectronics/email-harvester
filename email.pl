use strict;
use warnings;
use File::Find;
use File::Basename;

# Specify the directory to search
my $directory = 'DIRECTORY';

# Regular expression pattern to match email addresses
my $email_pattern = qr/\b([a-z0-9._%+-]{2,}@[a-z.-]+\.[a-z]{2,})\b/;

# Domains to exclude
my @excluded_domains = ('microsoft.com', '2x.png', '3x.png', '4x.png', 'openssl.org', 'example.com', 'c.us', 's.whatsapp.net');

# File names and extensions to ignore
my @ignored_files = ('README', 'LICENSE', 'CHANGES');
my @ignored_extensions = ('188', 'md');

# Hash to store encountered email addresses
my %seen_emails;

# Function to process each file found
sub process_file {
    my $file = $File::Find::name;

    # Skip directories
    return if -d $file;

    # Check file name and extension
    my ($name, $path, $ext) = fileparse($file, qr/\.[^.]*/);
    return if grep { $_ eq $name } @ignored_files;
    return if grep { $_ eq $ext } @ignored_extensions;

    # Try to open the file and search for email addresses
    open(my $fh, '<:raw', $file) or do {
        warn "Unable to open file: $file - $!";
        return;
    };

    my @matches;
    while (my $line = <$fh>) {
        $line =~ s/\r\n|\r/\n/g;  # Normalize line endings
        push @matches, $1 while ($line =~ /$email_pattern/g);
    }

    if (@matches) {
        my $found = 0;
        foreach my $match (@matches) {
            # Check if the email domain is excluded
            my ($domain) = $match =~ /@(.+)$/;
            next if grep { lc($_) eq lc($domain) } @excluded_domains;
            next if $seen_emails{$match};  # Skip if email address is already seen
            $found = 1;
            $seen_emails{$match} = 1;  # Mark email address as seen
            print "File: $file\n";
            print "Emails found:\n";
            print "- $match\n";
            print "\n";
        }
    }

    close $fh;
}

# Redirect standard error (STDERR) to /dev/null
open(STDERR, '>', '/dev/null');

# Start searching from the specified directory
eval {
    find({
        wanted   => \&process_file,
        no_chdir => 1,
    }, $directory);
};

# Check for any error in the eval block
if ($@) {
    warn "Error occurred during file search: $@";
}

# Write unique emails to the 'emails.txt' file
open(my $email_file, '>', 'emails.txt') or die "Unable to open 'emails.txt' file: $!";
print $email_file join("\n", keys %seen_emails);
close $email_file;
