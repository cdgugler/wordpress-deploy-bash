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
    echo -n "Enter the name of the new environment: "
    read env_name
    declare -A ${env_name}
    echo "declare -A ${env_name}"
    echo -n "Enter user name: "
    read env_user_name
    echo "env_user_name is ${env_user_name}"
    # eval to force bash to evaluate the assignment and not try to execute it
    echo ${env_name}[user_name]=${env_user_name}
    eval ${env_name}[user_name]=${env_user_name}
    echo "Adding environment $env_name"
    # eval again to evaluate command substitution
    # escape first $ to prevent parameter expansion to echo
    eval echo \${$env_name[@]}
    # echo "User name is: ${${env_name}[user_name]}"
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
