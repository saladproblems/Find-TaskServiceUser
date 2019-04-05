﻿
#Get files.
$files  = @( Get-ChildItem -Path $PSScriptRoot\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach($import in @($files))
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import file $($import.fullname): $_"
    }
}

#check update
New-Variable -Name ModuleVersion -Value "1.5.0" #v1.3.0 only for tests

$url = "https://api.github.com/repos/voytas75/Find-TaskServiceUser/releases/latest"
$oldProtocol = [Net.ServicePointManager]::SecurityProtocol
# We switch to using TLS 1.2 because GitHub closes the connection if it uses 1.0 or 1.1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try
{
    $response = Invoke-WebRequest -URI $url | ConvertFrom-Json
    if ([System.Version]$response.name -ge [System.Version]$ModuleVersion)
    {
       Write-Output "There is a newer version available. Run 'Update-Module -Name Find-TaskServiceUser' to update to the latest version." -ForegroundColor Red
       Write-Output "Alternatively, you can download it manually from https://github.com/voytas75/Find-TaskServiceUser/releases/latest" -ForegroundColor RED
    }
    else
    {
        Write-Output "You have the latest version installed!" -ForegroundColor Green
    }
}
catch
{
    # Github limits the number of unauthenticated API requests. To avoid this throwing an error we supress it here.
    Write-Output "Importing Find-TaskServiceUser version $ModuleVersion" -ForegroundColor Red
    Write-Output "Unable to reach GitHub, please manually verify that you have the latest version by going to https://github.com/voytas75/Find-TaskServiceUser/releases/latest" -ForegroundColor Red
}
[Net.ServicePointManager]::SecurityProtocol = $oldProtocol
