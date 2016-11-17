#!/usr/bin/perl
use strict;
use warnings;
use File::Copy;
use Data::Dumper;

#contributed by mad_ady

#configuration
my $mediaboot = '/media/boot';
my $bootini   = 'boot.ini';
my $config    = 'boot.ini.default';

logger( "info", "Applying user preferences for boot.ini" );

#read the config file with the user's settings and apply them one by one

my %ini;
if ( -f "$mediaboot/$config" ) {
    open CONFIG, "$mediaboot/$config" or die "Unable to read $mediaboot/$config. $!";
    while (<CONFIG>) {
        my $line = $_;
        if ( $line =~ /^\s*([^=]+)=(.*)/ ) {
            my $setting = $1;
            my $value   = $2;

            #ignore commented out settings
            next if ( $setting =~ /#/ );

            #trim whitespaces from settings and value
            $setting =~ s/^\s+|\s+$//g;
            $value =~ s/^\s+|\s+$//g;

            #save the config
            $ini{$setting} = $value;
        }
    }
}
else {
    logger( "error", "Missing persistent configuration file - $mediaboot/$config. Will not touch $bootini" );
    exit;
}
print Dumper( \%ini );

#load boot.ini into an array and perform changes on it in memory
my @boot;
my @newboot;
my $changed = 0;
open BOOT, "$mediaboot/$bootini" or die $!;
@boot = <BOOT>;
close BOOT;
logger( "debug", "$bootini has " . ( scalar @boot ) . " lines" );

#do a preliminary lookup inside boot.ini to find which variables we need to set, but are commented out
my %current;
foreach my $line (@boot) {
    foreach my $section ( sort keys %ini ) {
        if ( $line =~ /^\s*setenv\s*$section\s*\"([^\"]+)\".*/ ) {

            #this setting is set, we can edit this line
            $current{$section}{'isSet'} = 1;
        }
        if ( $line =~ /^\s*\#\s*setenv\s*$section\s*\"([^\"]+)\".*/ ) {

            #this setting is not set
            $current{$section}{'isNotSet'} = 1;
        }
    }
}

#iterate through all the lines in boot.ini and see if the current line matches
#save all changes to a new array, because we append lines

for ( my $i = 0 ; $i < scalar(@boot) ; $i++ ) {
    my $found = 0;

    #look for any of the settings left to set
    foreach my $section ( sort keys %ini ) {

        #try to match the setting as if it was set
        if ( defined $current{$section}{'isSet'} ) {
            if ( $boot[$i] =~ /^\s*setenv\s*$section\s*\"([^\"]+)\".*/ ) {
                my $old   = $1;
                my $extra = $2;

                #check if the value is the same as the default
                if ( $ini{$section} eq $old ) {
                    logger( "info", "$section is already set to $old. No change necessary" );

                    #forget about this setting
                    delete( $ini{$section} );
                    $found = 1;
                    push @newboot, $boot[$i];
                }
                else {
                    logger( "info", "Setting $section from $old to $ini{$section}" );
                    $found = 1;

                    #setting a variable means:
                    #1. comment out the current line
                    push @newboot, "#" . $boot[$i];

                    #2. insert a new line with the new value
                    push @newboot, "setenv $section \"$ini{$section}\"";

                    #forget about this setting
                    delete( $ini{$section} );
                }
            }
        }
        else {
            #it's not set by default

            if ( $boot[$i] =~ /^\s*\#+\s*setenv\s*$section\s*\"([^\"]+)\".*/ ) {
                my $old   = $1;
                my $extra = $2;

                #since it was commented out, we will output an uncommented line. No need to check the old value
                logger( "info", "$section enabled and set to $ini{$section}" );
                $found = 1;

                #1. push the current line (commented already)
                push @newboot, $boot[$i];

                #2. push the new config option
                push @newboot, "setenv $section \"$ini{$section}\"";

                #forget about this setting
                delete( $ini{$section} );
            }
        }
    }
    if ( !$found ) {

        #the line doesn't match any config option. Let it through
        push @newboot, $boot[$i];
    }
}

#sanity check
if ( scalar(@newboot) > 5 ) {

    #write the new boot.ini back to disk
    open BOOT, ">$mediaboot/$bootini" or die $!;
    foreach my $line (@newboot) {
        $line =~ s/\r|\n//g;    #trim newlines
        print BOOT "$line\n";
    }
    close BOOT;
    logger( "info", "Writing $bootini finished. Written " . ( scalar(@newboot) ) . " lines" );
}
else {
    logger( "fatal", "$bootini is incomplete. Not writing to disk" );
}

sub logger {
    my $severity = shift;
    my $message  = shift;

    print `logger -s -t $0 -p "$severity" '$message'`;
}

