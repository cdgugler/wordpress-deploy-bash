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

    echo -n "Enter user name: "
    read env_user_name
    # eval to force bash to evaluate the assignment and not try to execute it
    eval ${env_name}[user_name]=${env_user_name}

    echo -n "Enter server address[server.com]: "
    read env_server_name
    eval ${env_name}[server_name]=${env_server_name}

    echo -n "Enter DB name: "
    read env_db_name
    eval ${env_name}[db_name]=${env_db_name}

    echo -n "Enter DB user name: "
    read env_db_user
    eval ${env_name}[db_user]=${env_db_user}

    echo -n "Enter DB password: "
    read env_db_password
    eval ${env_name}[db_password]=${env_db_password}

    echo -n "Enter directory: "
    read env_directory
    eval ${env_name}[db_directory]="${env_directory}"

    echo -n "Enter sql host[localhost]: "
    read env_sql
    eval ${env_name}[sql_host]=${env_sql}

    echo "**********************************"
    echo "Confirm new environment: $env_name"
    # eval again to evaluate command substitution
    # escape first $ to prevent parameter expansion to echo
    # eval echo \${$env_name[@]}
    
    echo -n "User name: "
    eval echo \${$env_name[user_name]}
    echo -n "Server name: "
    eval echo \${$env_name[server_name]}
    echo -n "Database name: "
    eval echo \${$env_name[db_name]}
    echo -n "Database user name: "
    eval echo \${$env_name[db_user]}
    echo -n "Database password: "
    eval echo \${$env_name[db_password]}
    echo -n "Database directory: "
    eval echo \${$env_name[db_directory]}
    echo -n "Database sql host: "
    eval echo \${$env_name[sql_host]}


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
