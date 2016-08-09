# Check file date

The aim of "checkfiledate" is to search for new files in a specific directory, and send an alert email under certain conditions

## Requisites

You must install a mail server (like "sendmail", "exim", "postfix"), a mail client (like "mail") and "find" plus "egrep" utilities.

## Mode of use

1. Create a file called "filelist.txt" (there is a template in "filelist.txt.dist" with instructions)
2. Create a file called "maillist.txt", with one mail address per line
3. Create a crontab that execute "checkfiledate.sh"

    root@local:~# cat /etc/cron.d/checkfiledate

    # m h dom mon dow user  command
    00 00    * * *   root    /opt/checkfiledate/checkfiledate.sh > /var/log/checkfiledate.log 2>&1

4. Stay tuned to your mail inbox!

You can test the email functionality by executing "./checkfiledate.sh mailtest"
