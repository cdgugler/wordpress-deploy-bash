# Wordpress Deploy Bash

Just a nice bash script for syncing your wordpress development server with your production server.

## Warning

Use at your own risk! Backup and test on your setup before using in a production environment.

## Usage

Download and place the script outside of your project root dir. 
Run ./deploy.sh -a to add environments to the deploy.cfg file. Be sure to answer 'Y' to your local environment. 
You must sync from a remote environment to a local environment or vice-versa. (No remote to remote sync).

USAGE: deploy.sh <options> origin destination

DESCRIPTION: Deploy files and/or database from origin environment to destination

OPTIONS:

    -a  Add new environment         create new environment in deploy.cfg
    -f  Deploy files                push files from origin to destination
    -d  Deploy database             push db from origin to destination
    -n  Dry run                     show result of operation without executing
    -s  Silent                      don't ask for confirmation

## Status

Version 1.0.0 - Complete rewrite.
Ver 0 - Rough stuff

## Troubleshooting

### I ran this script and it corrupted my wordpress install, stole my car, and punched me in eye.

I'm sorry to hear that! You did make backups though, right? Restore your backup, call your insurance company and put some ice on that eye.

## License

[MIT license](LICENSE.md)

Check out [grunt-wordpress-deploy](https://github.com/webrain/grunt-wordpress-deploy) for a js/grunt solution (no relation with this project).
