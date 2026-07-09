$config = @"
# GitHub (mzk-C4)
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    AddKeysToAgent yes
"@
Set-Content -Path "$env:USERPROFILE\.ssh\config" -Value $config -Force
Write-Host "✅ SSH config 已更新" -ForegroundColor Green
Get-Content "$env:USERPROFILE\.ssh\config"
