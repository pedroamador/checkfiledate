# Check file date

The aim of "checkfiledate" is to search for new files in a specific directory, and send an alert email under certain conditions

## Requisites

You must install a mail server (like "sendmail", "exim", "postfix"), a mail client (like "mail") and "find" plus "egrep" utilities.

## Use mode

1. Create a file called "filelist.txt" (there is a template in "filelist.txt.dist" with instructions)
2. Create a file called "maillist.txt", with one mail address per line
3. Create a crontab that execute "checkfiledate.sh"

    root@local:~# cat /etc/cron.d/checkfiledate

    # m h dom mon dow user  command
    00 00    * * *   root    /opt/checkfiledate/checkfiledate.sh > /var/log/checkfiledate.log 2>&1

4. Stay tuned to your mail inbox!

There is two posible parameters:

* mailtest => Send email to al target address in "maillist.txt"

    $ ./checkfiledate.sh mailtest

* dryrun => Do the check, but without sending any mail

    $ ./checkfiledate.sh dryrun

## Weekly test email

If you run the script in the weekday 0 (sunday), it send a "checkpoint" mail with "WEEKLY TEST EMAIL" subject
