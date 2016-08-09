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
   echo -e "\n\tEXECUTION MODE =>\t$0 [mailtest]\n"
}

# Check for optional "mailtest" parameter

if [ $# -ne 0 ]
then
    if [ $# -ne 1 ]
    then
        print_exec_mode
        exit 1
    else
        if [ "$1" != "mailtest" ]
        then
            print_exec_mode
            exit 1
        fi
    fi
fi

cd $(dirname $0)

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
        checktype="RECURSIVE"
        maxdepth="-maxdepth 1"
    else
        checktype="NON RECURSIVE"
        maxdepth=""
    fi
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
            echo -n "[ERROR]"
            sendemail=1
        fi
    else
        if [ ${itempresence[$item]} -eq 0 ]
        then
            echo "[OK]"
        else
            echo -n "[ERROR]"
            sendemail=1
        fi
    fi

    if [ $sendemail -eq 1 ]
    then
        returnvalue=1
        for targetmail in ${maillist}
        do
            echo -e -n "\t\tSending mail to ${targetmail}..."
            echo -e "Hostname: $(hostname -f)\nDate: $(date)\nCheck #${item}\n- Config line: ${itemcheck[$item]}\n- Check type: ${checktype}\nCommand: ${find_command}\nResult:\n================ CUT HERE ================\n${result_console}\n================ CUT HERE ================" | mail ${targetmail} -s "[$(hostname)] CHECKFILEDATE ERROR"
            echo -e " [ok]"
        done
    fi
done
exit ${returnvalue}
