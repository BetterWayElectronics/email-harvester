use strict;
use warnings;
use File::Find;

# Specify the directory to search
my $directory = 'C:\Users';

# Regular expression pattern to match email addresses
my $email_pattern = qr/\b([a-z0-9._%+-]{2,}@[a-z.-]+\.[a-z]{2,})\b/;

# Domains to exclude
my @excluded_domains = ('microsoft.com', '2x.png', '3x.png', '4x.png', 'openssl.org', 'example.com', 'c.us');

# Hash to store encountered email addresses
my %seen_emails;

# Function to process each file found
sub process_file {
    my $file = $File::Find::name;

    # Skip directories
    return if -d $file;

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
			

        }
        print "\n" if $found;

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

# Execute the program
process_file($directory);
