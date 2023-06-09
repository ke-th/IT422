


####Working one 
$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument 'Get-Eventlog -LogName Security -After ((Get-Date).Date.AddDays(-30)) | Export-Csv "c:\Users\sarah\OneDrive\Desktop\30dayssecurity.csv"'
$Trigger = New-ScheduledTaskTrigger -Once -At 8:50pm
$Settings = New-ScheduledTaskSettingsSet
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $principal
Register-ScheduledTask -TaskName '2My PowerShell Security Event Script' -InputObject $Task
