@echo off

:: Remove Scheduled Tasks
schtasks /delete /tn * /f

:: Delete Known Malicious Folders
cd C:\Windows\System32
rmdir /s /q "Exploits"
rmdir /s /q "Cortana"
cd C:\Users\Administrator\Downloads
rmdir /s /q "nssm-2.24"
del /F "payload.exe"
del /F "x86.bat"
del /F "nssm-2.24.zip"

:: Disable Malicious Services
sc delete "Cortana"
sc delete "svchostz"
sc delete "WINUpdate"
sc delete "WindowsDefender"

:: Install Python, move NewClient.py file and run Heartbeat Python Script
msiexec /i python-2.7.msi /passive
copy NewClient.py C:\Python27
cd C:\Python27
python.exe NewClient.py

:: Disable NIC
:: devcon.exe disable *PCI\VEN_1022

:: Enable Firewall and Reset Rules
netsh firewall set opmode ENABLE
netsh firewall reset

:: Add Local Admin
net user /Add LAXP Sodapopcan3! 
net localgroup administrators LAXP /Add  
net user LAXP /Active:yes

:: Disable Malicious User Accounts
net user ellenripley Sodapopcan3! 
net localgroup administrators ellenripley /delete  
net user ellenripley /Active:no

net user vader Sodapopcan3! 
net localgroup administrators vader /delete  
net user vader /Active:no

net user Me Sodapopcan3! 
net localgroup administrators Me /delete  
net user Me /Active:no

:: Disable SMBv1
powershell.exe "Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol"

:: Uninstall TightVNC
wmic product where name="TightVNC" call uninstall

:: Download Programs
:: vlc-3.0.18-win32.exe /S /L=1033

:: Install Printer
copy /r Printing_Admin_Scripts C:\Windows\System32\Printing_Admin_Scripts
cscript prnport.vbs -a -r IP_192.168.1.5 -h 192.168.1.5 -o raw

