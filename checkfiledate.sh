#!/bin/bash

echo "Checkfiledate (c) Pedro Amador 2016"
echo

# Check Local Environment

# Variables Definition
COMMAND_LIST="mail find egrep"
EXIT_CODE=0

# Check required commands
for COMMAND in $COMMAND_LIST
do
   command -v $COMMAND >/dev/null || EXIT_CODE=1
done
if [[ $EXIT_CODE -eq 1 ]]
then
   echo -e "\ncheckfiledate requires '${COMMAND}' command but is not installed"
   echo -e "\nExecution aborted\n"
   exit 1
fi

#
# Function for print the script execution mode
#
print_exec_mode ()
{
   echo -e "\n\tEXECUTION MODE =>\t$0 [mailtest|dryrun]\n"
}

# Check for optional "mailtest" parameter
if [ $# -ne 0 ]
then
    if [ $# -ne 1 ]
    then
        print_exec_mode
        exit 1
    else
        if [ "$1" != "mailtest" ] && [ $1 != "dryrun" ]
        then
            print_exec_mode
            exit 1
        else
            echo "$1 mode"
        fi
    fi
fi

cd $(dirname $0)

# Get config
echo "Reading config..."
maillist=""
if [ ! -f maillist.txt ]
then
    echo "ERROR: There is not maillist.txt"
    exit 1
else
    while IFS='' read -r mailline || [[ -n "$mailline" ]]; do
        if [ "${mailline:0:1}" != "#" ] && [ "${mailline}" != "" ]
        then
            maillist="${maillist} ${mailline}"
            echo "- Adding mail: ${mailline}"
        fi
    done < maillist.txt
fi
items=0
if [ ! -f filelist.txt ]
then
    echo "ERROR: There is not filelist.txt"
    exit 1
else
    while IFS='' read -r fileline || [[ -n "$fileline" ]]; do
        if [ "${fileline:0:1}" != "#" ] && [ "${fileline}" != "" ]
        then
            ((items += 1))
            echo "- Adding config #${items}:"
            itemcheck[$items]=${fileline}
            itemdirectory[$items]=$(echo ${fileline} | awk '{print $1}')
            itemtime[$items]=$(echo ${fileline} | awk '{print $2}')
            itempresence[$items]=$(echo ${fileline} | awk '{print $3}')
            itemrecursive[$items]=$(echo ${fileline} | awk '{print $4}')
            echo -e "\tDirectory......: ${itemdirectory[$items]}"
            echo -e "\tTime...........: ${itemtime[$items]}"
            echo -e "\tPresence flag..: ${itempresence[$items]}"
            echo -e "\tRecursive flag.: ${itemrecursive[$items]}"
        fi
    done < filelist.txt
fi
echo -e  "Config reading done... do the checks\n"

# Mailtest option
if [ "$1" == "mailtest" ]
then
    for targetmail in ${maillist}
    do
        echo -e -n "Sending mail to ${targetmail}..."
        echo -e "Hostname: $(hostname -f)\nDate: $(date)\nCheck #0: test\n" | mail -s "[$(hostname)] CHECKFILEDATE TEST" ${targetmail}
        echo -e " [ok]"
    done
    exit 0
fi

# Do the checks
returnvalue=0
for item in $(seq 1 $items)
do
    sendemail=0
    if [ ${itemrecursive[$item]} -eq 0 ]
    then
        checktype="NON RECURSIVE"
        maxdepth="-maxdepth 1"
    else
        checktype="RECURSIVE"
        maxdepth=""
    fi
    find_command="find ${itemdirectory[$item]} ${maxdepth} -mtime ${itemtime[$item]} | egrep '.*'"
    echo "- Check config $item:"
    echo -e -n "\tCheck type..: "
    if [ ${itempresence[$item]} -eq 0 ]
    then
        checktype="${checktype} / ABSENCE OF FILES"
    else
        checktype="${checktype} / PRESENCE OF FILES"
    fi
    checktype="${checktype} / TIME ${itemtime[$item]}" 
    echo ${checktype}
    echo -e "\tCommand.....: ${find_command}"
    echo -e -n "\tResult......: "
    # In this find: 0 means there is files, 1 means there is no files
    result_console=$(eval "$find_command")
    result=$?
    if [ $result -eq 0 ]
    then
        if [ ${itempresence[$item]} -ne 0 ]
        then
            echo "[OK]"
        else
            echo "[ERROR]"
            sendemail=1
        fi
    else
        if [ ${itempresence[$item]} -eq 0 ]
        then
            echo "[OK]"
        else
            echo "[ERROR]"
            sendemail=1
        fi
    fi

    if [ $sendemail -eq 1 ]
    then
        returnvalue=1
        for targetmail in ${maillist}
        do
            if [ "$1" == "dryrun" ]
            then
                echo -e "\t\tdryrun mode, don't send email to ${targetmail}"
            else
                echo -e -n "\t\tSending mail to ${targetmail}..."
                echo -e "Hostname: $(hostname -f)\nDate: $(date)\nCheck #${item}\n- Config line: ${itemcheck[$item]}\n- Check type: ${checktype}\nCommand: ${find_command}\nResult:\n================ CUT HERE ================\n${result_console}\n================ CUT HERE ================" | mail -s "[$(hostname)] CHECKFILEDATE ERROR" ${targetmail}
                echo -e " [ok]"
            fi
        done
    fi
done

# Send weekly test mail (only if not dryrun)
if [ ${returnvalue} -eq 0 ]
then
    if [ $(date +%u) -eq 0 ]
    then
        echo -e "\nWEEKLY MAIL TEST"
        for targetmail in ${maillist}
        do
            if [ "$1" == "dryrun" ]
            then
                echo -e "\tdryrun mode, don't send weekly eemail test to ${targetmail}"
            else
                echo -e -n "\tSending weekly mail test to ${targetmail}..."
                echo -e "Hostname: $(hostname -f)\nDate: $(date)\nWeekly mail test" | mail -s "[$(hostname)] CHECKFILEDATE WEEKLY MAIL TEST" ${targetmail}
                echo -e " [ok]"
            fi
        done
    fi
fi
exit ${returnvalue}
