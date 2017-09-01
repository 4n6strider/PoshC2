# Written by @benpturner and @davehardy20
Param($installpath)

# To install or upgrade PoshC2 run the following command in PowerShell
# 
# powershell -exec bypass -c "iex (new-object system.net.webclient).downloadstring('https://raw.githubusercontent.com/nettitude/PoshC2/master/C2-Installer.ps1')"

function Download-File 
{
    Param
    (
        [string]
        $From,
        [string]
        $To
    )
    (new-object system.net.webclient).DownloadFile($From,$To)
}

function Unzip-File
{
    Param
    (
        [string]
        $file,
        [string]
        $destination
    )
	$shell = new-object -com shell.application
	$zip = $shell.NameSpace($file)
	foreach($item in $zip.items())
	{
		$shell.Namespace($destination).copyhere($item)
	}
}

if (!$installpath) {
    $currentdirectory = Get-Location
    $prompt = Read-Host -Prompt "`n[+] Please specify the install directory [$($currentdirectory)]" 
    $installpath = ($currentdirectory,$prompt)[[bool]$prompt]
} 

$slash = $installpath -match '.+[^\\]\\$'
if (!$slash) {
    $installpath = "$($installpath)\"
}
$poshpath = $installpath+"PowershellC2\"
$downloadpath = "https://github.com/nettitude/PoshC2/archive/master.zip"
    
$pathexists = Test-Path $installpath

if (!$pathexists) {
    New-Item $installpath -Type Directory 
}

Write-Host "[+] Downloading PoshC2 to $installpath"
Download-File -From $downloadpath -To "$($installpath)PoshC2-master.zip"
$downloaded = Test-Path "$($installpath)PoshC2-master.zip"

if ($downloaded) {

    Unzip-File "$($installpath)PoshC2-master.zip" $installpath
    Remove-Item "$($installpath)PoshC2-master.zip" -Force -Recurse
    $pathexists = Test-Path "$($installpath)PowershellC2"

    if (!$pathexists) {
        Move-Item "$($installpath)PoshC2-master" "$($installpath)PowershellC2" 
    } else {
        Copy-Item -Path "$($installpath)\PoshC2-master\*" -Destination "$($installpath)PowershellC2" -Recurse -Force
        Remove-Item "$($installpath)PoshC2-master" -Force -Recurse
    }

    $SourceExe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $ArgumentsToSourceExe = "-exec bypass -c import-module ${poshpath}C2-Server.ps1; C2-Server -PoshPath $poshpath"
    $DestinationPath = "$($installpath)PowershellC2\Start-C2-Server.lnk"
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($DestinationPath)
    $Shortcut.TargetPath = $SourceExe
    $Shortcut.Arguments = $ArgumentsToSourceExe
    $Shortcut.Save()

    # add run as administrator 
    $bytes = [System.IO.File]::ReadAllBytes("$($installpath)PowershellC2\Start-C2-Server.lnk")
    $bytes[0x15] = $bytes[0x15] -bor 0x20
    [System.IO.File]::WriteAllBytes("$($installpath)PowershellC2\Start-C2-Server.lnk", $bytes)

    $SourceExe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $ArgumentsToSourceExe = "-exec bypass -c ${poshpath}C2-Installer.ps1 $installpath"
    $DestinationPath = "$($installpath)PowershellC2\Update-PoshC2.lnk"
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($DestinationPath)
    $Shortcut.TargetPath = $SourceExe
    $Shortcut.Arguments = $ArgumentsToSourceExe
    $Shortcut.Save()

    # add run as administrator 
    $bytes = [System.IO.File]::ReadAllBytes("$($installpath)PowershellC2\Start-C2-Server.lnk")
    $bytes[0x15] = $bytes[0x15] -bor 0x20
    [System.IO.File]::WriteAllBytes("$($installpath)PowershellC2\Start-C2-Server.lnk", $bytes)

    Write-Host "[+] Sucessfully installed PoshC2"
    
} else {
    Write-Host "Could not download file"
    Start-Sleep 3
}
