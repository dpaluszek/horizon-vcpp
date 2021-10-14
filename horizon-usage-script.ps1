###Horizon Usage for VMware Cloud Provider Program
###Version 1.0 - 19July2018 - Daniel Paluszek, VMware Cloud Provider Program
###Version 2.0 - 14Oct2021 - Gabrie van Zanten, Open Line 
###Part 2 of 2 - this Powershell script will get the password secure string file, connect to the Horizon Manager and retrieve the usage stats to a file & email.
###For usage of stored credentials, the same user account that runs this script must have generated the stored encrypted password in the accompanying text file.

##ConnectHVServer variables
##Replace "C:\horizon" with the path for your environment where the password file and the output files will be stored
## No backslash at the end.
$Directory = "c:\horizon"
$timestamp = Get-Date -UFormat %Y%b%d
$file = "$Directory\horizon-usage-$timestamp.txt"

## Replace file.txt with the name of your password file
$password = get-content "$Directory\file.txt" | ConvertTo-SecureString

##Replace "DOMAIN\username" with service account name previously used in Part 1 of 2
$credentials = new-object -TypeName System.Management.Automation.PSCredential -argumentlist "CORP\horizonsvc",$password

##Replace FQDN with hostname of your Horizon Manager server.
## With some configurations I noticed, you need to connect using the hostname instead of FQDN
$hznode ="view-01a.corp.local"

## Email properties
$subject = "$hznode Horizon Report for $timestamp"
$emailbody = "Horizon Manager $hznode - Concurrent User Connection Report for $timestamp"

## Change the three variables below for your environment: smtpserver, recipient, and sender. 
$smtpserver = "mail.rainpole.com"
$recipient = "administrator@rainpole.com"
$sender = "administrator@rainpole.com"

###
### License output header:
$body =  "************************************`r`n"
$body += "**   Horizon View license usage   **`r`n"
$body += "************************************`r`n"


##Import the Horizon Module
import-module VMware.VimAutomation.HorizonView

## Don't complain about certificates
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

##Connect to the connection server
connect-hvserver -Credential $credentials -Server $hznode

## To monitor if we encounter an issue getting the information
$WasThereAnError = $false 

##variable for navigating API Extension Data
$hzservices=$Global:DefaultHVServers.ExtensionData
if( $hzservices -eq $null)
{
    $body += "There was an error retreiving connecting to the HVServer. Contact the Horizon administrator`r`n"
    $body | Out-File $file -append
    Send-MailMessage -from $sender -Attachments $file -Body $emailbody -SmtpServer $smtpserver -Subject $subject -To $recipient
    
    ## Stop the script
    break
}

##variable for storing connection server health metrics (contains data we're after)
$hzhealth=$hzservices.UsageStatistics.UsageStatistics_GetLicensingCounters()
## If the nummber of totalconcurrentconnections is 
if( $hzhealth.HighestUsage.TotalConcurrentConnections -lt 2 )
{
    $body += "Unlikely value retreived!!!`r`n UsageStatistics.UsageStatistics_GetLicensingCounters() is smaller than 2 `r`n Double check the results `r`n License count will NOT be reset!! `r`n Contact the Horizon administrator `r`n"
    $WasThereAnError = $true
}

## Creating the output file
$body += "Needed voor licensing count:`r`n HighestUsage.TotalConcurrentConnections = $($hzhealth.HighestUsage.TotalConcurrentConnections)`n"
$body += "`r`n`r`n`r`n`r`n`r`n`r`n"
$body += "************************************`r`n"
$body += "**            Debug info          **`r`n"
$body += "************************************`r`n"
$body += "Highest usage `r`n"
$body += $($hzhealth.HighestUsage | Out-String)
$body += "`r`n Current usage `r"
$body += $($hzhealth.CurrentUsage | Out-String)
$body += "`r`n"

if( !$WasThereAnError)
{
    ##Reset Highest Usage Count
    $hzservices.UsageStatistics.UsageStatistics_ResetHighestUsageCount()
    $body += "`r`n`r`n  License counter has been reset, according to plan.`r`n"
}else{
    $body += "`r`n`r`n  There was no license counter reset. Contact the Horizon administrator`r`n"
}

## Write the output to file
$body | Out-File $file -append 

## Disconnect the Horizon View server
Disconnect-HVServer -Server * -Confirm:$false

## Send the email
Send-MailMessage -from $sender -Attachments $file -Body $emailbody -SmtpServer $smtpserver -Subject $subject -To $recipient