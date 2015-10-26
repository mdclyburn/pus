# Project Utility Script

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

## Configuration

There are a few extra pieces of information that PUS needs before it can
begin working magic for you. This includes: a remote machine address, a
valid user name for that remote machine, the handin repository URL, and
a remote directory to do work in (so that PUS doesn't accidentally erase
your stuff!).

See the provided example configuration for information.

### ltest

### rtest

### submit

### License

This project, in its entirety, is licensed under the MIT license. See the
included LICENSE file in the top level of the repository for more information.
