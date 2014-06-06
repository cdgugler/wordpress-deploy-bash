#!/bin/bash
function print_usage() {
    echo "deploy.sh

DESCRIPTION: Deploy files and/or database for wordpress installation.
USAGE: deploy.sh <origin> <destination>
PARAMETERS:
    -a  Add new environment
    -f  Deploy files
    -d  Deploy database
    -n  Dry run
    -s  Silent
    "
}
function add_environment() {
    echo "Adding environment..."
    exit
}
function deploy_files() {
    check_dry_run ;
    echo "Deploying files from $ARG1 to $ARG2"
}
function deploy_database() {
    check_dry_run ;
    echo "Deploying database from $ARG1 to $ARG2"
}
function check_dry_run() {
    if [ "$DEPLOY_DRY_RUN" = true ] ; then
        echo "********** DRY RUN **********"
    fi
}

if [[ "$1" =~ ^((-{1,2})([Hh]$|[Hh][Ee][Ll][Pp])|)$ ]]; then
    print_usage; exit 1
else
    # Parse arguments
    while getopts ":afdns" opt; do
        case $opt in
            a)  add_environment ;;
            f)  DEPLOY_FILES=true ;;
            d)  DEPLOY_DATABASE=true ;;
            n)  DEPLOY_DRY_RUN=true ;;
            s)  DEPLOY_SILENT=true ;;
            \?) echo "Invalid option: -$OPTARG"
                exit 1 ;;
        esac
    done
    shift $(($OPTIND -1))

    # convert args to uppercase
    ARG1=${1^^}
    ARG2=${2^^}
    echo "FROM: " $ARG1
    echo "TO: " $ARG2

    if [ "$DEPLOY_FILES" = true ] ; then
        deploy_files
    fi

    if [ "$DEPLOY_DATABASE" = true ] ; then
        deploy_database
    fi
fi
