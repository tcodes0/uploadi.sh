#! /usr/bin/env bash
#~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
#     EDIT INFO HERE
#
#enter below: command to use for SSH, and port
#example: "ssh -p 83723"
SSH=""
#enter below: username@hostname:pathToRemoteDirectory
#example: "you@server.web-hosting.com:/home/you/work"
remote_dir=""
#enter below: local directory to upload **relative** to project directory
#example: "build"
local_dir=""
#
#~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

#- - - - - - - - - - - - - - - - - - - - - - - - -
#                 HELPER FUNCTIONS
#- - - - - - - - - - - - - - - - - - - - - - - - -
#pretty echo.
precho() {
  echo -e "\e[1m♦︎ $@\e[0m"
}

#exits with a message
bailout() {
	local message="$@"
	if [[ "$#" == "0" ]]; then
		message="error"
	fi
	echo -ne "\e[1;31m❌\040 $message\e[0m"
	if [[ ! "$-" =~ i ]]; then
		#shell is not interactive, so kill it.
		exit 1
	fi
}

parse-options() {
#input   - $@ or string containing shorts (-s), longs (--longs), and arguments
#returns - arrays with parsed data and opts set as vars
#exports a var for each option. (-s => $s, --foo => $foo, --long-opt => $long_opt)
#"-" are translated into "_"
#"--" signals the end of options
#shorts take no arguments, to give args to an option use a --long=arg

if [[ "$#" == 0 ]]; then
  return
fi

# Opts we may have inherited from a parent function also using parse-options. Unset to void collisions.
if [ "$allOptions" ]; then
  for opt in ${allOptions[@]}; do
    unset $opt
  done
fi

local argn long short noMoreOptions

#echo to split quoted args, repeat until no args left
for arg in $(echo "$@"); do
  argn=$(($argn + 1))

  # if flag set
  if [[ "$noMoreOptions" ]]; then
    #end of options seen, just push remaining args
    arguments+=($arg)
    continue
  fi

  # if end of options is seen
  if [[ "$arg" =~ ^--$ ]]; then
    # set flag to stop parsing
    noMoreOptions="true"
    continue
  fi

  # if long
  if [[ "$arg" =~ ^--[[:alnum:]] ]]; then
    #start on char 2, skip leading --
    long=${arg:2}
    # substitute any - with _
    long=${long/-/_}
    # if opt has an =, it means it has an arg
    if [[ "$arg" =~ ^--[[:alnum:]][[:alnum:]]+= ]]; then
      # split opt from arg. Ann=choco makes export ann=choco
      export ${long%=*}="${long#*=}"
      longsWithArgs+=(${long%=*})
    else
      #no arg, just push
      longs+=($long)
    fi
    continue
  fi

  # if short
  if [[ "$arg" =~ ^-[[:alnum:]] ]]; then
    local i=1 #start on 1, skip leading -
    # since shorts can be chained (-gpH), look at one char at a time
    while [ $i != ${#arg} ]; do
      short=${arg:$i:1}
      shorts+=($short)
      i=$((i + 1))
    done
    continue
  fi

  # not a long or short, push as an arg
  arguments+=($arg)
done

# give opts with no arguments value "true"
for short in ${shorts[@]}; do
  export $short="true"
done

for long in ${longs[@]}; do
  export $long="true"
done

export allOptions="$(get-shorts)$(get-longs)"
}

#part of parse-options
get-shorts() {
  if [ "$shorts" ]; then
    for short in ${shorts[@]}; do
      echo -ne "$short "
    done
  fi
}

#part of parse-options
get-longs() {
  if [ "$longs" ]; then
    for long in ${longs[@]}; do
      echo -ne "$long "
    done
  fi
  if [ "$longsWithArgs" ]; then
    for long in ${longsWithArgs[@]}; do
      echo -ne "${long}* "
    done
  fi
}

#part of parse-options
get-arguments() {
  for arg in ${arguments[@]}; do
    echo -ne "$arg "
  done
}

#- - - - - - - - - - - - - - - - - - - - - - - - -
#                      MAIN
#- - - - - - - - - - - - - - - - - - - - - - - - -

parse-options "$@"

if [ "$h" -o "$help" ]; then
  precho "upload-rsync.sh uploads a local directory to a web server.
  It appends the current directory to the destination, to make it
  easier to call it from multiple project folders.

  -h, --help      see this help
  -y, --yes       auto confirmation
  -v, --verbose   verbose rsync
                    see rsync option --verbose
  --delete        remove extraneous files on server
                    see rsync option --delete
  --dry-run       show what would be done
                    see rsync option --dry-run"
  exit
fi

# info validation
if [ ! "$SSH" -o ! "$remote_dir" -o ! "$local_dir" ]; then
  bailout "Missing either \$SSH, \$remote_dir or \$local_dir. Please edit the script."
fi

if [[ ! -d "$local_dir" ]]; then
  bailout "Looking for \"$(basename $local_dir)\" inside \"$PWD\":
  $local_dir doesn't appear to exist.
  Keep in mind the directory is relative."
fi

remote_dir=$remote_dir"/$(basename $PWD)/"
local_dir=$PWD/$local_dir/

case "true" in
  "$y" | "$yes")
    REPLY="yes"
  ;;&
  "$dry_run")
    options=$options" --dry-run"
  ;;&
  "$delete")
    options=$options" --delete"
  ;;&
  "$v" | "$verbose")
    options=$options" --verbose"
  ;;
esac

if [ "$REPLY" != "yes" ]; then
  precho "Upload to server via rsync? (y/n)
  ...defaulting to yes in 6s"
  read -t 6
  if [ "$?" != 0 ]; then
    REPLY=''
  fi
fi

if [ "$REPLY" == "y" -o "$REPLY" == "yes" -o "$REPLY" == "Y" -o "$REPLY" == "YES" -o "$REPLY" == "" ]; then
  echo -ne "\e[1;49;33m♦︎ Uploading all files with rsync...\e[0m"
  options=$options" --recursive --update --inplace --no-relative --checksum --compress"
  rsync $options -e "$SSH" $local_dir $remote_dir
  if [[ "$?" == 0 ]]; then
    echo -e "\r\e[1;49;32m✔ Done 🕰  $(date +%H:%M)                                         \e[0m"
  fi
fi
