# .\provision.ps1 -bootstrapVersion 2019.01.08 -saltVersion 2019.2.0
Param(
    [Parameter( Mandatory = $true)]
    $bootstrapVersion,
    [Parameter( Mandatory = $true)]
    $saltVersion
)
$source = "C:\temp"

if ((test-path "$source") -eq $false) {
    New-Item -Path $source -ItemType Directory
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12
$wc = New-Object System.Net.WebClient
if ((test-path "$source\salt-bootstrap-$bootstrapVersion.zip") -eq $False) {
    Write-Verbose -Verbose "Downloading salt-bootstrap required"
    $wc.downloadfile("https://github.com/saltstack/salt-bootstrap/archive/v$bootstrapVersion.zip", "$source\salt-bootstrap-$bootstrapVersion.zip")
    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipFile]::ExtractToDirectory("$source\salt-bootstrap-$bootstrapVersion.zip", $source)
}

Invoke-Expression "C:\temp\salt-bootstrap-$bootstrapVersion\bootstrap-salt.ps1 -version $saltVersion -pythonVersion 3"

# Permanetly add salt directory to PATH
[Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";C:\salt",
    [EnvironmentVariableTarget]::Machine)

Write-Verbose -Verbose "Calling salt highstate"
Invoke-Expression "C:\salt\salt-call.bat state.highstate"
