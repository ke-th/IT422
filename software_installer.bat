@echo off

set "firefox_installer=C:\Downloads\firefox_installer.exe"
set "quicktime_installer=C:\Downloads\quicktime_installer.exe"
set "vlc_installer=C:\Downloads\vlc_installer.exe"
set "adobe_installer=C:\Downloads\adobe_installer.exe"
set "itunes_installer=C:\Downloads\itunes_installer.exe"
set "chrome_installer=C:\Downloads\chrome_installer.exe"

echo Installing Firefox...
start "" /wait "%firefox_installer%" /passive

echo Installing QuickTime...
start "" /wait "%quicktime_installer%" /passive

echo Installing VLC...
start "" /wait "%vlc_installer%" /passive

echo Installing Adobe Reader...
start "" /wait "%adobe_installer%" /passive

echo Installing iTunes...
start "" /wait "%itunes_installer%" /passive

echo Installing Chrome...
start "" /wait "%chrome_installer%" /passive

echo All installations complete.
