#!/bin/bash

# prints colored text
print_style () {

    if [ "$2" == "info" ] ; then
        COLOR="96m"
    elif [ "$2" == "success" ] ; then
        COLOR="92m"
    elif [ "$2" == "warning" ] ; then
        COLOR="93m"
    elif [ "$2" == "danger" ] ; then
        COLOR="91m"
    else #default color
        COLOR="0m"
    fi

    STARTCOLOR="\e[$COLOR"
    ENDCOLOR="\e[0m"

    printf "$STARTCOLOR%b$ENDCOLOR" "$1"
}

display_options () {
    printf "Available options:\n";
    print_style "   firstup [services]" "success"; printf "\t Starts docker compose sets permissions and composer install.\n"
    print_style "   up [services]" "success"; printf "\t Starts docker compose.\n"
    print_style "   down" "success"; printf "\t\t\t Stops and remove containers.\n"
    print_style "   stop" "success"; printf "\t\t\t Stops containers.\n"
    print_style "   bash" "success"; printf "\t\t\t Opens bash on the cron container user www-data.\n"
    print_style "   backup" "success"; printf "\t\t\t Backups mysql data.\n"
}

if [[ $# -eq 0 ]] ; then
    print_style "Missing arguments.\n" "danger"
    display_options
    exit 1
fi

if [ "$1" == "firstup" ] ; then
    print_style "Initializing Docker Compose\n" "info"
    shift # removing first argument
    docker-compose up -d ${@}
    print_style "Composer install\n" "info"
    docker-compose exec --user www-data apache composer install
    docker-compose exec --user www-data apache /fix_permissions.sh
    print_style "Set production\n" "info"
    docker-compose exec --user www-data apache php bin/magento deploy:mode:set production
elif [ "$1" == "install" ]; then
    print_style "Initializing Docker Compose\n" "info"
    shift # removing first argument
    docker-compose up -d ${@}
    docker-compose exec --user www-data apache mv fb_host_probe.txt /tmp/fb_host_probe.txt
    docker-compose exec --user www-data apache composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition .
    docker-compose exec --user www-data apache mv /tmp/fb_host_probe.txt fb_host_probe.txt
    docker-compose exec --user www-data apache /fix-permissions.sh
elif [ "$1" == "up" ]; then
    print_style "Initializing Docker Compose\n" "info"
    shift # removing first argument
    docker-compose up -d ${@}
elif [ "$1" == "down" ]; then
    print_style "Stopping  Docker Compose and removing containers\n" "info"
    docker-compose down
elif [ "$1" == "stop" ]; then
    print_style "Stopping Docker Compose\n" "info"
    docker-compose stop
elif [ "$1" == "bash" ]; then
    docker-compose exec --user www-data cron bash
elif [ "$1" == "backup" ]; then
    docker-compose exec backup_db_magento2 /script.sh
else
    print_style "Invalid arguments.\n" "danger"
    display_options
    exit 1
fi
