# Project Utility Script

![PUS](https://github.com/mdclyburn/pus/raw/master/images/rtest.png "Running pus.pl rtest")

## What is it?

The Project Utility Script, or PUS, is a tool that can be used
to quickly test your projects both locally and remotely, so you
can be sure that your code compiles on school computers.

## Prerequisites

In order to use PUS, you'll need only a Makefile (likely with
some sort of rule to create a gzipped tarball). PUS does not
make the archive for you.

## Subcommands

Here are the supported subcommands:

| Subcommand | Function |
| :--------: | :------- |
| ltest      | performs a compilation test on your machine |
| rtest      | performs a compilation test on a specified remote machine |
| submit     | uses handin to turn in the archive |

All subcommands must be given the archive to submit on the
command line like so:
`pus.pl rtest http_server.tgz`

If an error occurs during the process at any time, PUS will relay
the relevant output to the terminal so you can correct it.

### ltest

`pus.pl ltest <archive>`

Creates a test directory (called 'pus_test') and copies the provided
archive into it. The `make` command is then issued. PUS then reports
the results back.

### rtest

`pus.pl rtest <archive>`

Creates a test directory on the configured remote machine called and
copies the provided archive over to it. The `make` command is then
issued. PUS then reports the results back.

Both the machine and directory to use is specified in the `.pus.conf` file.

### submit

`pus.pl submit <archive>`

Runs a remote compilation test on the specified archive and, if successful,
submits it to handin using the configuration specified in `.pus.conf`.

## Configuration

There are a few extra pieces of information that PUS needs before it can
begin working magic for you. This includes: a remote machine address, a
valid user name for that remote machine, the handin repository URL, and
a remote directory to do work in (so that PUS doesn't accidentally erase
your stuff!).

See the provided example configuration for brief information.

* `handin_repo` is the full path to the handin repository used in the `submit` subcommand.

* `remote_directory` is the directory that PUS will create and work in when testing your archive.
PUS will refuse to work in the directory if it alread exists.
This is simply because PUS removes the entire directory tree after it finishes.
When the `submit` subcommand is used, a timestamp is appended to this name to minimize the likelihood of collisions during this more sensitive operation.

* `remote_machine` is the address of the machine that the `rtest` subcommand will use.
PUS accesses this machine via SSH.
Currently, there is no way to specify a different port; however, this is an easy modification to the script.

* `user_name` is the user name to be used when logging into the remote machine.

### License

This project, in its entirety, is licensed under the MIT license. See the
included LICENSE file in the top level of the repository for more information.
