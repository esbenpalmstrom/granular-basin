#!/usr/bin/env bash

version=1.0
loopinterval=10

function show_help {
    echo "usage: ${0##*/} [OPTIONS] [COMMAND]"
    echo "Status script which traverses the subdirectories of the current "
    echo "directory for simulations."
    echo
    echo "The following COMMANDS are supported:"
    echo "   loop                continuously show status of simulations"
    echo "   render              continuously show status of simulations"
    echo
    echo "OPTIONS are one or more of the following:"
    echo "   -h, --help                show this message"
    echo "   -v, --version             show version and license information"
    echo "   -n, --interval SECONDS    sleep duration between status loops"
    echo "   --                        do not consider any following args as options"
}

function show_version {
    echo "${0##*/} version $version"
    echo "Licensed under the GNU Public License, v3+"
    echo "written by Anders Damsgaard, anders@adamsgaard.dk"
    echo "https://gitlab.com/admesg/dotfiles"
}

function die {
    printf '%s\n' "$1" >&2
    exit 1
}

while :; do
    case "$1" in
        -h|-\?|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        -n|--interval)
            loopinterval="$2"
            shift
            ;;
        --) # end all options
            shift
            break
            ;;
        -?*)
            die 'Error: Unknown option specified'
            ;;
        *)  # No more options
            break
    esac
    shift
done

for cmd in "$@"; do
    case "$cmd" in
        loop)
            julia --color=yes -e "import Granular; Granular.status(loop=true, t_int=$loopinterval)"
            exit 0
            ;;
        visualize)
            julia --color=yes -e "import Granular; Granular.status(visualize=true)"
            exit 0
            ;;
        *)
            die 'Unknown commmand specified'
            ;;
    esac
done
julia --color=yes -e "import Granular; Granular.status()"
