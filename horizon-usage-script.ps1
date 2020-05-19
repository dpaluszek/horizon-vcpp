###Horizon Usage for VMware Cloud Provider Program
###Version 1.0 - 19July2018 - Daniel Paluszek, VMware Cloud Provider Program
###Part 2 of 2 - this Powershell script will get the password secure string file, connect to the Horizon Manager and retrieve the usage stats to a file & email.
###For usage of stored credentials, the same user account that runs this script must have generated the stored encrypted password in the accompanying text file.

##ConnectHVServer variables
##Replace "C:\DIRECTORY\file.txt" with the path to your encrypted service account password
$password = get-content C:\horizon\file.txt | ConvertTo-SecureString

##Replace "DOMAIN\username" with service account name previously used in Part 1 of 2
$credentials = new-object -TypeName System.Management.Automation.PSCredential -argumentlist "CORP\horizonsvc",$password

##Replace FQDN with hostname of your Horizon Manager server.
$hznode ="view-01a.corp.local"

##Import the Horizon Module
import-module VMware.VimAutomation.HorizonView

##Connect to the connection server
connect-hvserver -Credential $credentials -Server $hznode

##variable for navigating API Extension Data
$hzservices=$Global:DefaultHVServers.ExtensionData

##variable for storing connection server health metrics (contains data we're after)
$hzhealth=$hzservices.UsageStatistics.UsageStatistics_GetLicensingCounters()

##Replace "$file" line with the target location for your attachment (i.e. C:\directory\file) - leave the $timestamp variable.
$timestamp = Get-Date -UFormat %Y%b%d
$file = "c:\horizon\horizon-usage-$timestamp.txt"

$hzhealth.HighestUsage | Out-File $file

##Reset Highest Usage Count
$hzservices.UsageStatistics.UsageStatistics_ResetHighestUsageCount()

##Last step - output to file and email usage report. 
$date = Get-Date -UFormat %c
$subject = "$hznode Horizon Report for $date"
$body = "Horizon Manager $hznode - Concurrent User Connection Report for $date - please now reset the highest users count by logging into https://$hznode/admin/#/license and clicking Reset Highest Count button"

##Change the three variables below for your environment: smtpserver, recipient, and sender. 
$smtpserver = "mail.rainpole.com"
$recipient = "administrator@rainpole.com"
$sender = "administrator@rainpole.com"

Send-MailMessage -from $sender -Attachments $file -Body $body -SmtpServer $smtpserver -Subject $subject -To $recipient