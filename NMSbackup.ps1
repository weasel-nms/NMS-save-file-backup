$docs = (get-itemproperty -path "hkcu:Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -name Personal).personal
$destination = "$docs\My Games\No Man's Sky backups"
$source = $null
$checkdestination = test-path $destination
if ($checkdestination -eq $false) {
    New-Item -ItemType Directory $destination
}

# Test possible game save locations
## preference is given to steam, then xbox game pass, then gog -
## if you have NMS installed from more than one of them, it will only back up the first one
$checksteam = test-path -Path "~\AppData\Roaming\HelloGames\NMS\st_*"
if ($checksteam -eq $true) {
    $source = (get-childitem "~\AppData\Roaming\HelloGames\NMS" | where {$_.name -like "st_*"}).fullname + "\*.hg"
}

$checkxbgp = test-path -Path "~\AppData\Local\Packages\HelloGames.NoMansSky*"
if ($checkxbgp -eq $true -and $source -eq $null) {
    $source = (get-childitem "~\AppData\Local\Packages\HelloGames.NoMansSky*").fullname + "\SystemAppData\wgs\*"
}

if ($source -eq $null) {
    write-host "Error locating No Man's Sky saved files!" -ForegroundColor Red
    write-host
    write-host "press any key..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    exit
}

$checkgog = test-path -Path "~\AppData\Roaming\HelloGames\NMS\defaultuser\*.hg"
if ($checkgog -eq $true -and $source -eq $null) {
    $source = (get-childitem "~\AppData\Roaming\HelloGames\NMS\defaultuser").fullname + "\*.hg"
}

# back up files
$date = get-date -Format "yyyy-MM-dd--HH-mm-ss"
try {
    Compress-Archive -Path $source -DestinationPath $destination\$date.zip
    if ($? -eq $true) {
        write-host 
        write-host "No Man's Sky save files backup created for $date" -ForegroundColor Green
    }
}
catch {
    write-host "Error backing up No Man's Sky save files!" -ForegroundColor Red -BackgroundColor Black
}

# back up settings files if using steam 
try {
    if ($source -like "*.hg" ) {
        $existinghkcrtest = test-path -path hkcr:
        if ($existinghkcrtest -eq $false) {
            New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR >$null
        }
        $settingslocation = ((Get-ItemProperty HKCR:nms\shell\open\command -Name `(default`)).'(default)').TrimStart("`"").TrimEnd("NMS.exe`" `"%1")
        Compress-Archive -Path $settingslocation\SETTINGS\*.mxml -update -DestinationPath $destination\$date.zip
        if ($? -eq $true) {
            write-host 
            write-host "No Man's Sky settings files added to backup" -ForegroundColor Green
        }
    }
}
catch {
    write-host "Error adding No Man's Sky settings files to backup!" -ForegroundColor Red -BackgroundColor Black
}

write-host
write-host "press any key..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

