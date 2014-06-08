#!/bin/bash
function print_usage() {
    echo "deploy.sh

USAGE: deploy.sh <origin> <destination>
DESCRIPTION: Deploy files and/or database for wordpress installation.
PARAMETERS:
    -a  Add new environment
    -f  Deploy files
    -d  Deploy database
    -n  Dry run
    -s  Silent
    "
}

# Add new environment to config file
function add_environment() {
    echo -n "Enter the name of the new environment: "
    read env_name
    env_name=${env_name^^}

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

    echo -n "Development server? [Y/n] "
    read env_dev
    env_dev=${env_dev^^}
    eval ${env_name}[development]=${env_dev}

    echo -n "Exclude files: "
    read env_exclude
    eval ${env_name}[exclude]=${env_exclude}

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
    echo -n "Development Environment? "
    eval echo \${$env_name[development]}
    echo -n "Exclude files: "
    eval echo \${$env_name[exclude]}
    
    read -p "Write to deploy.cfg? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        echo "########## $env_name ##########" >> deploy.cfg
        echo declare -A ${env_name} >> deploy.cfg
        echo ${env_name}[user_name]=${env_user_name} >> deploy.cfg
        echo ${env_name}[server_name]=${env_server_name} >> deploy.cfg
        echo ${env_name}[db_name]=${env_db_name} >> deploy.cfg
        echo ${env_name}[db_user]=${env_db_user} >> deploy.cfg
        echo ${env_name}[db_password]=${env_db_password} >> deploy.cfg
        echo ${env_name}[directory]="${env_directory}" >> deploy.cfg
        echo ${env_name}[sql_host]=${env_sql} >> deploy.cfg
        echo ${env_name}[development]=${env_dev} >> deploy.cfg
        echo ${env_name}[exclude]=${env_exclude} >> deploy.cfg
        echo "$env_name added."
        exit
    fi
    echo "Cancelled."

    exit
}

# Move files from one environment to another with rsync
function deploy_files() {
    check_dry_run ;
    # echo "Deploying files from $ARG1 to $ARG2"
    eval echo Deploying files from \${$ARG1[server_name]} to \${$ARG2[server_name]}
    deploy_silent ;
    # eval echo "dev is \${$ARG1[development]}"
    eval temp=\${$ARG1[development]}
    eval temp2=\${$ARG2[development]}

    if [ $temp == "Y" ] ; then
        if [ "$DEPLOY_DRY_RUN" = true ] ; then
            eval rsync --dry-run -arvus --progress \${$ARG1[directory]} \${$ARG2[user_name]}@\${$ARG2[server_name]}:\${$ARG2[directory]}
        else
            eval rsync -arvus --progress \${$ARG1[directory]} \${$ARG2[user_name]}@\${$ARG2[server_name]}:\${$ARG2[directory]}
        fi
    elif [ $temp2 == "Y" ] ; then
        if [ "$DEPLOY_DRY_RUN" = true ] ; then
            eval rsync --dry-run -arvus --progress \${$ARG1[user_name]}@\${$ARG1[server_name]}:\${$ARG1[directory]} \${$ARG2[directory]}
        else
            eval rsync -arvus --progress \${$ARG1[user_name]}@\${$ARG1[server_name]}:\${$ARG1[directory]} \${$ARG2[directory]}
        fi
    else
        echo "Error. No local server."
        exit 1
    fi
}

# Move database between environments
function deploy_database() {
    check_dry_run ;
    echo "Deploying database from $ARG1 to $ARG2"
}

# Display dry run message if applicable
function check_dry_run() {
    if [ "$DEPLOY_DRY_RUN" = true ] ; then
        echo "********** DRY RUN **********"
    fi
}


# Ask for confirmation if not deploying silently
function deploy_silent() {
    if [ "$DEPLOY_SILENT" != true ] ; then
        read -p "Continue? " -n 1 -r
        echo
        # matches if not Y/y
        if [[ $REPLY =~ ^[Yy]$ ]] ; then
            echo "Alright, let's do it!"
        else
            exit
        fi
    fi
}

# Verify servers passed in as args and exist in config file
function check_for_servers() {
    if [ "$ARG1" = "" ] || [ "$ARG2" = "" ] ; then
        print_usage ; exit 1
    fi
    eval local server1=\${$ARG1[server_name]}
    eval local server2=\${$ARG2[server_name]}

    if [ "$server1" = "" ] || [ "$server2" = "" ] ; then
        echo "Server not found, check deploy.cfg or add environment"
        exit
    fi
}

# Start script
if [[ "$1" =~ ^((-{1,2})([Hh]$|[Hh][Ee][Ll][Pp])|)$ ]]; then
    print_usage ; exit 1
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

    source ./deploy.cfg
    # echo "FROM: " $ARG1
    # echo "TO: " $ARG2

    check_for_servers

    if [ "$DEPLOY_FILES" = true ] ; then
        deploy_files
    fi

    if [ "$DEPLOY_DATABASE" = true ] ; then
        deploy_database
    fi
fi
