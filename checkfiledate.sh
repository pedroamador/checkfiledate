#!/bin/bash
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

for item in $(seq 1 $items)
do
    find_command="find ${itemdirectory[$item]} ${maxdepth} -mtime ${itemtime[$item]} | egrep '.*' &> /dev/null"
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
    eval "$find_command"
    result=$?
    if [ $result -eq 0 ]
    then
        if [ ${itempresence[$item]} -ne 0 ]
        then
            echo -n "OK!"
        else
            echo -n "error! Send mail"
        fi
    else
        if [ ${itempresence[$item]} -eq 0 ]
        then
            echo -n "OK!"
        else
            echo -n " error! Send mail"
        fi
    fi
    echo " (exit code ${result}) "
done
