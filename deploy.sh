#!/bin/bash

# Print usage instructions
function print_usage() {
    cat <<- EOF
		USAGE: deploy.sh <options> origin destination
		DESCRIPTION: Deploy files and/or database from origin environment to destination
		OPTIONS:
		    -a  Add new environment         create new environment in deploy.cfg
		    -f  Deploy files                push files from origin to destination
		    -d  Deploy database             push db from origin to destination
		    -n  Dry run                     show result of operation without executing
		    -s  Silent                      don't ask for confirmation
	EOF
}

# Add new environment to config file
function add_environment() {
    echo -n "Enter the name of the new environment: "
    read env_name
    env_name=${env_name^^}

    read -p "Enter user name: " env_user_name
    read -p "Enter server address[server.com]: " env_server_name
    read -p "Enter DB name: " env_db_name
    read -p "Enter DB user name: " env_db_user
    read -p "Enter DB password: " env_db_password
    read -p "Enter directory: " env_directory
    read -p "Enter sql host[localhost]: " env_sql
    read -p "Development server? [Y/n] " env_dev
    # uppercase convert
    env_dev=${env_dev^^}
    read -p "Exclude files(surround with single quotes): " env_exclude

    echo "**********************************"
    echo "Confirm new environment: $env_name"
    
    echo "User name: $env_user_name"
    echo "Server name: $env_server_name"
    echo "Database name: $env_db_name"
    echo "Database user name: $env_db_user"
    echo "Database password: $env_db_password"
    echo "Database directory: $env_directory"
    echo "Database sql host: $env_sql"
    echo "Development Environment? $env_dev"
    echo "Exclude files: $env_exclude"
    
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
            eval rsync --dry-run -arvus --progress \${$ARG1[directory]} \${$ARG2[user_name]}@\${$ARG2[server_name]}:\${$ARG2[directory]} \${$ARG1[exclude]}
        else
            eval rsync -arvus --progress \${$ARG1[directory]} \${$ARG2[user_name]}@\${$ARG2[server_name]}:\${$ARG2[directory]} \${$ARG1[exclude]}
        fi
    elif [ $temp2 == "Y" ] ; then
        if [ "$DEPLOY_DRY_RUN" = true ] ; then
            eval rsync --dry-run -arvus --progress \${$ARG1[user_name]}@\${$ARG1[server_name]}:\${$ARG1[directory]} \${$ARG2[directory]} \${$ARG1[exclude]}
        else
            eval rsync -arvus --progress \${$ARG1[user_name]}@\${$ARG1[server_name]}:\${$ARG1[directory]} \${$ARG2[directory]} \${$ARG1[exclude]}
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
    deploy_silent ;
    eval temp=\${$ARG1[development]}
    eval temp2=\${$ARG2[development]}
    
    if [ $temp == "Y" ] ; then
        # first arg is the local environment
        if [ "$DEPLOY_DRY_RUN" = true ] ; then
            ### back up remote db
            # create sql dir if not exist
            mkdir -p ./sql
            eval local backup_file_name=./sql/\${$ARG2[server_name]}-$(date +%Y%m%d_%H%M).sql
            eval ssh \${$ARG2[user_name]}@\${$ARG2[server_name]} \"mysqldump -u \${$ARG2[db_user]} -p\${$ARG2[db_password]} -h \${$ARG2[sql_host]} \${$ARG2[db_name]}\" > $backup_file_name
        else
            echo "Not dry run."
        fi
    elif [ $temp2 == "Y" ] ; then
        # second arg is the local environment
        if [ "$DEPLOY_DRY_RUN" = true ] ; then
            # back up local db
            # create sql dir if not exist
            mkdir -p ./sql
            eval local backup_file_name=./sql/\${$ARG2[server_name]}-$(date +%Y%m%d_%H%M).sql
            eval mysqldump -u \${$ARG2[db_user]} -p\${$ARG2[db_password]} -h \${$ARG2[sql_host]} \${$ARG2[db_name]} > $backup_file_name
        else
            echo "Not dry run."
        fi
    else
        echo "Error. No local server."
        exit 1
    fi
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
