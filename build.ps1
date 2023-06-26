param (
    $Registration = "CHANGE_ME",
    $Version = "CHANGE_ME",
    $Memory = 8192,
    $Cpus = 2,
    $Headless = "false",
    [ValidateSet('all', 'base')] $Target = "all",
    [switch]$Rebuild = $False
)

$envFile = ".\env"
if (Test-Path $envFile -ErrorAction SilentlyContinue) {
    . $envFile
}

if ($Rebuild) {
    Remove-Item ".\build\serverbase-$VERSION" -Force -Recurse -ErrorAction SilentlyContinue
}

if (!(Test-Path ".\build\serverbase-$VERSION" -ErrorAction SilentlyContinue)) {
    packer build -var version=$Version -var "registration_code=$Registration" -var memory=$Memory -var cpus=$Cpus -var headless=$Headless -force -timestamp-ui -on-error=ask packer-base.json

    if ($LastExitCode -ne 0 -or $Target -eq "base") {
        Write-Output "Exiting :( $LastExitCode"
        exit $LastExitCode
    }
}

if ($Target -ne 'all') {
    exit 0
}

Remove-Item ".\build\nimbusserver-$VERSION" -Force -Recurse -ErrorAction SilentlyContinue

packer build -var version=$Version -var "registration_code=$Registration" -var memory=$Memory -var cpus=$Cpus -var headless=$Headless -force -timestamp-ui -on-error=ask packer-setup.json

if ($LastExitCode -ne 0) {
    Write-Output "Exiting: $LastExitCode"
    exit $LastExitCode
}
