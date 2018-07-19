###Horizon Usage for VMware Cloud Provider Program
###Version 1.0 - 19July2018 - Daniel Paluszek / Winston Blake
###This part will prompt for the service account credentials and store them in a secure string text file. 

$filename=read-host -Prompt "What should the name of the file be? (will be a .txt file)"

#Replace "C:\directory\" with the target directory for your secure string text file.
read-host -AsSecureString -prompt "Please enter the password" | ConvertFrom-SecureString | Out-File C:\horizon\$filename.txt