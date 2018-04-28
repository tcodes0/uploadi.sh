# Uploadi.sh

Simple script that uploads a project to a remote location, using rsync and SSH. The project name is assumed to be the current directory, so you can reuse for all your projects going to the same remote.

## Example

- Suppose your project is directory `ecom` to be uploaded to `/home/you/work/ecom` in your webhost.
- You use a build tool and the it puts the files in directory `build` inside `~/webdev/ecom`
- Assume SSH login port number 83723 (for example's sake)
- The edited script would look like:
```bash
SSH="ssh -p 83723"
remote_dir="you@hosting.web-whatever.com:/home/you/work"
local_dir="build"
```
- Note it says **/home/you/work**, not /home/you/work/ecom. Omit the project directory, it will be created for you.
- cd to project directory: `cd ~/webdev/ecom` and call `uploadi.sh`

### Reuse for several projects

Because the local project directory name (`ecom`) is not hardcoded, but appended to the remote (`/home/you/work`) automatically, you can reuse the same settings for all projects to be uploaded to `/home/you/work.`

## Installation

- Download or clone this repo, the file needed is `uploadi.sh.`
- Edit `uploadi.sh` and enter your info for SHH and destination to be used, near the top:
```bash
#~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
#     EDIT INFO HERE
#
#enter below: command to use for SSH, and port number
#example: "ssh -p 83723"
SSH=""
#enter below: username@hostname:(path to directory that contains your projects)
#example: "you@hosting.web-whatever.com:/home/you/work"
remote_dir=""
#enter below: local directory to upload *relative* to project directory
#example: "build"
local_dir=""
#
#~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
```
- Call `uploadi.sh` from project directory

## See also

`uploadi.sh -h` for supported options

#### _Make the shell work for you!_
