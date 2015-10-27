#!/usr/bin/perl

# PUS - the Project Utility Script
#
# This nifty script can handle your project test-compiling and
# submission needs so you don't have to manually type that handin
# command or 'scp' that file to the lab machine to test it.
#
# Subcommands:
# ltest <archive>     - Extracts the specified tar GZ archive to a
#                       local directory and issues the 'make' command.
#                       This test succeeds as long as the compile is
#                       successful.
#
# rtest <archive>     - Sends the archive to the configured machine and
#                       issues the 'make' command. This test succeeds as
#                       long as the compile is successful.
#
# submit <archive>    - Turns in the specified archive to handin.
#

use Term::ANSIColor;
use File::Copy;
use File::Path;

# read the configuration file
read_configuration() if (-e ".pus.conf");


# first argument is the subcommand
if ($ARGV[0] eq "ltest") {
	die "You need to specify an archive like this: pus.pl ltest proj.tgz\n" if !defined $ARGV[1];
	print colored("Let's see if this thing compiles on your machine...\n", "yellow");
	local_compile($ARGV[1]);
}
elsif ($ARGV[0] eq "rtest") {
	die "You need to specify an archive like this: pus.pl rtest proj.tgz\n" if !defined $ARGV[1];
	print colored("Running compile test remotely...\n", "yellow");
	remote_compile($ARGV[1]);
}
elsif ($ARGV[0] eq "submit") {
	die "You need to specify an archive like this: pus.pl submit proj.tgz\n" if !defined $ARGV[1];
	print colored("Submitting...\n", "yellow");
	submit($ARGV[1]);
}
else {
	die "Usage: pus.pl <localtest | labtest | submit> archive\n";
}

# Read the configuration file.
sub read_configuration {
	open(CONFIG, ".pus.conf") || die "Failed to open configuration file.\n";

	while(<CONFIG>) {
		chomp;
		next if /^(#|$)/; # comment or empty line

		my ($opt, $setting) = $_ =~ /([A-Za-z0-9_.]+)\s*=\s*(\S+)/;
		$config{$opt} = $setting unless (!defined $setting);
	}

	# set the archive if it has been specified in configuration
	# but don't ignore the user's command
	if(!defined $ARGV[1] && defined $config{"default_archive"}) {
		$ARGV[1] = $config{"default_archive"};
	}

	close(CONFIG);
	return;
}

# Compile the specified archive on the local machine.
sub local_compile {
	my ($archive_file) = @_;

	# make sure this thing exists
	die colored("I don't see any $archive_file around here...\n", "red") if ! -f $archive_file;

	# get things into place
	mkdir "pus_test";
	copy $archive_file, "pus_test/";
	chdir "pus_test";

	my $output = `tar -zxf $archive_file 2>&1`;
	if($? != 0) { # clean up even if you fail; not nice to leave things around
		print colored("Extraction failed. Here is what tar said:\n", "red");
		print $output;
		chdir "..";
		rmtree "pus_test";
		die colored("Failed. Do not submit this... whatever it is...\nIs this even a gzipped tar?\n", "red");
	}

	# the simple make; what pretty much any instructor or TA will do
	$output = `make 2>&1`;
	if($? != 0) { # compilation failed and we still have to clean up
		print colored("Make failed. Here is what it said:\n", "red");
		print $output;
		chdir "..";
		rmtree "pus_test";
		die colored("Failed. Do not submit this archive.\n", "red");
	}

	# congrats; getting here means success
	print colored("Congratulations! Compile test met with success!\n", "green");
	
	chdir "..";
	rmtree "pus_test";

	return;
}

# Compile the specified archive on the configured remote
# machine. The configuration file must be in place with
# the right options in order for this to work.
sub remote_compile {
	die "You need to specify a remote machine in your configuration to do this.\n" if !defined $config{"remote_machine"};
	die "You need to specify a user name in your configuration to do this.\n" if !defined $config{"user_name"};
	die "You need to specify a directory in your configuration to do this.\n" if !defined $config{"remote_directory"};
	my ($archive_file) = @_;

	die colored("I don't see any $archive_file around here...\n", "red") if ! -f $archive_file;

	$remote_machine = $config{"remote_machine"};
	print colored("Let's see if this thing compiles on $remote_machine...\n", "yellow");
	my $addr = $config{"user_name"} . "\@" . $config{"remote_machine"};
	my $directory = $config{"remote_directory"};
		
	# make the directory
	print " - creating $directory...\n";
	my $output = `ssh $addr "mkdir $directory" 2>&1`;
	die(colored("Directory creation failed. Here is what ssh said:\n", "red"), $output) if $? != 0;

	# send over the archive
	print " - transferring archive...\n";
	$output = `scp $archive_file $addr:$directory 2>&1`;
	if ($? != 0) { # clean up
		print colored("Send failed. Here is what scp said:\n", "red");
		print $output;
		`ssh $addr "rm -rf $directory"`;
		exit 1;
	}

	# extract it
	print " - unarchiving files...\n";
	$output = `ssh $addr "tar -zx -C $directory -f $directory/$archive_file" 2>&1`;
	if ($? != 0) { # clean up
		print colored("Extraction failed. Here is what tar said:\n", "red");
		print $output;
		`ssh $addr "rm -rf $directory"`;
		exit 1;
	}

	# run the only command that should have to be run
	print " - issuing the command (hold your breath)!...\n";
	$output = `ssh $addr "cd $directory && make" 2>&1`;
	if ($? != 0) { # clean up
		print colored("Failed. Do not submit this archive. Check this:\n", "red");
		print $output;
		`ssh $addr "rm -rf $directory"`;
		exit 1;
	}

	print colored("Congratulations: the remote machine compiled successfully!\n", "green");
	
	`ssh $addr "rm -rf $directory"`;
	if ($? != 0) {
		print colored("Hmm... I couldn't clean up after myself... this is embarrassing...\n", "yellow");
		print colored("The directory is still on the remote computer. I couldn't be rid of it.\n", "yellow");
	}

	return;
}

sub submit {
	die "You need to specify a remote machine in your configuration to do this.\n" if !defined $config{"remote_machine"};
	die "You need to specify a user name in your configuration to do this.\n" if !defined $config{"user_name"};
	die "You need to specify a directory in your configuration to do this.\n" if !defined $config{"remote_directory"};
	die "You need to specify a handin repository in your configuration to do this.\n" if !defined $config{"handin_repo"};
	my ($archive_file) = @_;

	die colored("I don't see any $archive_file around here...\n", "red") if ! -f $archive_file;

	my $remote_machine = $config{"remote_machine"};

	# ensure that it compiles first
	print "Running a compilation test on $remote_machine... ";
	my $output = `$0 rtest $archive_file`;
	die colored("ERROR\nCompile test failed. Refusing to submit because of this:\n", "red"), $output if $? != 0;
	print colored("OK!\n", "green");

	my $addr = $config{"user_name"} . "\@" . $remote_machine;
	my $repo_url = $config{"handin_repo"};

	# create the repo and copy the archive over
	print " - creating temporary repository...\n";
	my $remote_dir = ".pus_submit_" . time; # reduce chance of file conflicts
	$output = `ssh $addr "hg clone $repo_url $remote_dir" 2>&1`;
	if ($? != 0) {
		die colored("Repository creation failed. Here is what ssh said:\n", "red"), $output;
	}

	print " - transferring archive...\n";
	$output = `scp $archive_file $addr:$remote_dir/`;
	if ($? != 0) {
		print colored("Send failed. Here is what scp said:\n", "red");
		print $output;
		`ssh $addr "rm -rf $remote_dir"`;
		exit 1;
	}

	# these Mercurial commands will be issued in order
	my @hg_commands = ( "ssh $addr \"hg add --cwd $remote_dir $archive_file\" 2>&1",
	"ssh $addr \"hg --cwd $remote_dir commit -m \'New submission.\' 2>&1\"",
	"ssh $addr \"hg --cwd $remote_dir push 2>&1\"");

	# submit!
	print " - issuing Hg commands...\n";
	foreach $cmd (@hg_commands) {
		$output = `$cmd`;
		if ($? != 0) {
			print " - removing remote directory... ";
			`ssh $addr "rm -rf $remote_dir"`;
			print " ok...\n" if ($? == 0);
			print " couldn't even do that...\n" if ($? != 0);
			die colored("Submission failed. Here's what Hg said:\n", "red"), $output;
		}
	}

	print colored("Congratulations: the submission made it to handin!\n", "green");

	# clean up
	`ssh $addr "rm -rf $remote_dir"`;
	die colored("I couldn't clean up after myself. You'll have to manually remove $remote_dir.\n", "yellow") if $? != 0;

	return;
}

exit;
