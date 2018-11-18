#!/bin/bash

#-------------------------------------------------------------------------------
# SCRIPT.........: deploy.sh
# ACTION.........: deploy.sh is a bash script, which can be used to automate package installtion
# COPYRIGHT......: Dynacommerce
# AUTHOR.........: Anirvan Ray (anirvanr@gmail.com)
# LICENSE........: MIT (see https://opensource.org/licenses/MIT)
# VERSION........: 0.3
# UPDATE.........: 19/11/2018
# DOCUMENTATION..: See README for instructions (TODO)
#-------------------------------------------------------------------------------
# DO NOT EDIT THIS SCRIPT unless you know what you're doing

red="\033[1;31m"
green="\033[1;32m"
blue="\033[1;34m"
nc="\033[0m"
date_now=$(date +"%d-%m-%Y-%H:%M:%S")
date=$(date +"%d-%m-%Y")
package_dir="/var/tmp/dump/$date"
log_file="$package_dir/output.log"

function full_backup ()
{
    backup_directories="/opt/AAA /opt/BBB /opt/CCC"
    backup_path="/dump/backup"
    archive_file="package-$date_now.tgz"
    dialog --title "PACKAGE Deployment" --infobox "Backup Started. Please wait...." 5 50
    if ls $backup_path/package-*.tgz >/dev/null 2>&1
    then
    # delete all backups except last one
      find $backup_path/package-*.tgz -type f -printf '%T@\t%p\n' | sort -t $'\t' -g | head -n -1 | cut -d $'\t' -f 2- | xargs rm
    tar czf "$backup_path"/"$archive_file" --absolute-names $backup_directories
    else
    tar czf "$backup_path"/"$archive_file" --absolute-names $backup_directories
    fi
    dialog --title "PACKAGE Deployment" --infobox "Backup finished. $backup_path/$archive_file" 5 50
    echo -e "${green}`date`${nc}\n${blue}----------------------------${nc}\nBackup finished.: `du -sh $backup_path/$archive_file`" >> "$log_file"
}

function pre_install ()
{
    dialog --title "PACKAGE Deployment" --msgbox "    Please make sure you have enough free disk space.
    Please make sure that /var/tmp/dump/"$date" exists before proceeding.
    Copy all of the package files to /var/tmp/dump/"$date" and press <Enter> to start or <Esc> to cancel." 10 100
    if [ "$?" != "0" ]
    then
    dialog --title "PACKAGE Deployment" --msgbox "Deployment was canceled at your request." 5 50
    else
      if [ -d "$package_dir" ]; then
        full_backup
        main_menu
      else
        dialog --title "PACKAGE Deployment" --msgbox "FATAL ERROR: Source directory not found" 5 50
        echo -e "${green}`date`${nc}\n${blue}----------------------------${nc}\n${red}FATAL ERROR${nc} ---> /var/tmp/dump/$date not found" >> "$log_file"
        exit 1
    fi
    fi
}

function package_backup_dir ()
{
destination="$backup_path/$date_now/$package_name"
if [ ! -d "$destination" ]; then
    if [[ $(mkdir -p "$destination") -ne 0 ]]; then
        echo -e "${green}`date`${nc}\n${blue}----------------------------${nc}\n${red}FATAL ERROR${nc} ---> Unable to create directory $destination" >> "$log_file"
    fi
fi
}

function package_backup_file ()
{
    for files in $package_backup_files ; do
    cp "$files" "$destination"/$(basename "$files")
    echo -e "${green}`date`${nc}\n${blue}----------------------------${nc}\n$package_backup_files copied successfully" >> "$log_file"
    done
    sleep 2
}

function package_restore_file ()
{
    for files in $package_backup_files ; do
    cat "$destination"/$(basename "$files") > $files
    echo -e "${green}`date`${nc}\n${blue}----------------------------${nc}\n$package_backup_files restore completed successfully" >> "$log_file"
    done
    sleep 2
}

function package_service_status ()
{
    if  ! ( systemctl -q is-active "$package_service_name" )
    then
    echo -e "${green}`date`${nc}\n${blue}----------------------------${nc}\n${red}FATAL ERROR${nc} ---> $package_service_name service is not running" >> "$log_file"
    fi
}

function package_service_restart ()
{
    systemctl daemon-reload
    systemctl restart "$package_service_name"
    systemctl is-active --quiet "$package_service_name" && \
    echo -e "${green}`date`${nc}\n${blue}----------------------------${nc}\n$package_service_name service restarted sucessfully" >> "$log_file" || \
    echo -e "${green}`date`${nc}\n${blue}----------------------------${nc}\n${red}FATAL ERROR${nc} ---> $package_service_name restart failed" >> "$log_file"
    sleep 2
}

function package_install ()
{
  if [ -n "$(find "$package_dir" -name "$package_name-*" 2>/dev/null)" ]
  then
  count=$(find "$package_dir" -name "$package_name-*" | wc -l)
      if [ "$count" -gt 1 ] ; then
        echo -e "${green}`date`${nc}\n${blue}----------------------------${nc}\n${red}FATAL ERROR${nc} ---> $package_name multiple files found" >> "$log_file"
      else
          rpm -e --nodeps $package_name-* >> "$log_file" 2>&1
          rpm -ivh --nodeps $package_dir/$package_name-* >> "$log_file" 2>&1
        sleep 2
      echo -e "${green}`date`${nc}\n${blue}----------------------------${nc}\n$package_name installed" >> "$log_file"
      fi
  else
    sleep 2
  echo -e "${green}`date`${nc}\n${blue}----------------------------${nc}\n${red}FATAL ERROR${nc} ---> $package_name file not found" >> "$log_file"
  fi
}

function package_java_install () {
  package_service_status
  package_backup_dir
  package_backup_file
  package_install
  package_restore_file
  package_service_restart
}

function package-AAA ()
{
  package_name=package-AAA
  package_service_name=AAA
  package_backup_files="/opt/AAA.conf"
  package_java_install
}

function package-BBB ()
{
  package_name=package-BBB
  package_service_name=BBB
  package_backup_files="/opt/BBB.conf"
  package_java_install
}

function package-CCC ()
{
  package_name=package-CCC
  package_service_name=CCC
  package_backup_files="/opt/CCC.conf"
  package_java_install
}


function post_install ()
{
  dialog --title "PACKAGE Deployment" --msgbox "Installtion completed...Please review the log file $log_file for more information" 7 50
}

function main_menu ()
{
  options=(1 "package-AAA" on
   2 "package-BBB" off
   3 "package-CCC" off)

  funcheck=(dialog --separate-output --title "PACKAGE Deployment" --checklist "Choose the TASK:" 0 0 0)

  selections=$("${funcheck[@]}" "${options[@]}" 2>&1 >/dev/tty)

  clear

  for package in $selections
  do
   case $package in
   1)
   package-AAA
   ;;
   2)
   package-BBB
   ;;
   3)
   package-CCC
   ;;
   esac
  done
}

pre_install
post_install
