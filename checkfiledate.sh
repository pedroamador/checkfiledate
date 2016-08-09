#!/bin/bash

# Check Local Environment

# Commands Definition
ECHO="echo -e"

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
   $ECHO "\ncheckfiledate requires '${COMMAND}' command but is not installed"
   $ECHO "\nExecution aborted\n"
   exit 1
fi

cd $(dirname $0)

echo "Reading config..."
maillist=""
if [ ! -f maillist.txt ]
then
    echo "ERROR: There is not maillist.txt"
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

if [ "$1" == "mailtest" ]
then
    for targetmail in ${maillist}
    do
        echo -e -n "Sending mail to ${targetmail}..."
        echo -e "Hostname: $(hostname -f)\nDate: $(date)\nCheck #0: test\n" | mail ${targetmail} -s "[$(hostname)] CHECKFILEDATE TEST"
        echo -e " [ok]"
    done
    exit 0
fi

returnvalue=0
for item in $(seq 1 $items)
do
    sendemail=0
    find_command="find ${itemdirectory[$item]} ${maxdepth} -mtime ${itemtime[$item]} | egrep '.*'"
    echo "- Check config $item:"
    echo -e -n "\tCheck type..: "
    if [ ${itemrecursive[$item]} -eq 0 ]
    then
        echo -n "RECURSIVE / "
        maxdepth="-maxdepth 1"
    else
        echo -n "NON RECURSIVE / "
        maxdepth=""
    fi
    if [ ${itempresence[$item]} -eq 0 ]
    then
        echo -n "ABSENCE OF FILES / "
    else
        echo -n "PRESENCE OF FILES / "
    fi
    echo "TIME ${itemtime[$item]}" 
    echo -e "\tCommand.....: ${find_command}"
    echo -e -n "\tResult......: "
    # In this find: 0 means there is files, 1 means there is no files
    result_console=$(eval "$find_command")
    result=$?
    if [ $result -eq 0 ]
    then
        if [ ${itempresence[$item]} -ne 0 ]
        then
            echo -n "OK!"
        else
            echo -n "error!"
            sendemail=1
        fi
    else
        if [ ${itempresence[$item]} -eq 0 ]
        then
            echo -n "OK!"
        else
            echo -n " error!"
            sendemail=1
        fi
    fi

    if [ $sendemail -eq 1 ]
    then
        returnvalue=1
        echo -n "...Sending email..."
        for targetmail in ${maillist}
        do
            echo -e -n "Sending mail to ${targetmail}..."
            echo -e "Hostname: $(hostname -f)\nDate: $(date)\nCheck #${item}: ${itemcheck[$item]}\nCommand: ${find_command}\nResult:\n================ CUT HERE ================\n${result_console}\n================ CUT HERE ================" | mail ${targetmail} -s "[$(hostname)] CHECKFILEDATE ERROR"
            echo -e " [ok]"
        done

    fi
    echo " (exit code ${result}) "
done
exit ${returnvalue}
