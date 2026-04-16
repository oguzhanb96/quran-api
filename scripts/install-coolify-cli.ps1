$ErrorActionPreference = "Stop"
$s = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/coollabsio/coolify-cli/main/scripts/install.ps1" -UseBasicParsing
$sb = [scriptblock]::Create($s)
& $sb -User
