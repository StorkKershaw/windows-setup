if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host 'Please run this script as an Administrator.'
    return
}

if ($null -eq $(Get-Command -Name winget.exe -ErrorAction SilentlyContinue)) {
    Write-Host 'Please install winget.exe before running this script.'
    return
}

function Format-Selection {
    param (
        [Parameter(Mandatory = $true)]
        [int]
        $Index,
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $Options
    )

    $Lines = [System.Collections.Generic.List[string]]::new()
    $CursorLine = 0

    for ($OptionIndex = 0; $OptionIndex -lt $Options.Count; $OptionIndex++) {
        $Option = $Options[$OptionIndex]

        if ($Option.ContainsKey('Group')) {
            if ($OptionIndex -eq $Index) {
                $CursorLine = $Lines.Count
            }
            $Lines.Add('- {0}' -f $Option.Group)
        }

        if ($OptionIndex -eq $Index) {
            $CursorLine = $Lines.Count
        }

        $Cursor = if ($OptionIndex -eq $Index) { '>' } else { ' ' }
        $Checkbox = if ($Option.Checked) { '[x]' } else { '[ ]' }
        $Line = '{0} {1} {2}' -f $Cursor, $Checkbox, $Option.Label

        if ($Option.ContainsKey('Description')) {
            $Line += ' - ' + $Option.Description
        }

        $Lines.Add($Line)
    }

    return [PSCustomObject]@{
        Lines      = $Lines
        CursorLine = $CursorLine
    }
}


function Out-Viewport {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $Lines,
        [Parameter(Mandatory = $true)]
        [int]
        $CursorLine,
        [Parameter(Mandatory = $false)]
        [string]
        $Footer
    )

    $ViewportHeight = [Math]::Max([Console]::WindowHeight - 5, 1)
    $ScrollOffset = if ($CursorLine -ge $ViewportHeight) { $CursorLine - $ViewportHeight + 1 } else { 0 }
    $End = [Math]::Min($ScrollOffset + $ViewportHeight, $Lines.Count)

    $Builder = [System.Text.StringBuilder]::new()

    for ($Index = $ScrollOffset; $Index -lt $End; $Index++) {
        $Builder.AppendLine($Lines[$Index]) | Out-Null
    }

    if ($End -lt $Lines.Count) {
        $Builder.AppendLine(' ↓ more...') | Out-Null
    }

    if ($Footer) {
        $Builder.AppendLine('') | Out-Null
        $Builder.AppendLine($Footer) | Out-Null
    }

    Write-Host $Builder.ToString()
}

function Format-Command {
    param (
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $Options
    )

    foreach ($Option in $Options) {
        if ($Option.Checked) {
            $Builder = [System.Text.StringBuilder]::new()

            $Builder.Append('winget.exe install --disable-interactivity --accept-package-agreements --accept-source-agreements') | Out-Null
            $Builder.AppendFormat(' --source winget --id {0} --exact', $Option.PackageId) | Out-Null

            if ($Option.ContainsKey('InstallOption')) {
                $Builder.AppendFormat(" --override `"{0}`"", $Option.InstallOption) | Out-Null
            }

            $Command = $Builder.ToString()
            Write-Output $Command
        }
    }
}

$Options = @(
    @{
        Group     = 'Terminal & Shell';
        Checked   = $false;
        Label     = 'Windows Terminal';
        PackageId = 'Microsoft.WindowsTerminal';
    }
    @{
        Checked   = $false;
        Label     = 'PowerShell v7';
        PackageId = 'Microsoft.PowerShell';
    }
    @{
        Checked     = $false;
        Label       = 'Oh My Posh';
        Description = 'PowerShell のプロンプトをカスタマイズできます。';
        PackageId   = 'JanDeDobbeleer.OhMyPosh';
    }
    @{
        Group     = 'Editors';
        Checked   = $false;
        Label     = 'Cursor';
        PackageId = 'Anysphere.Cursor';
    }
    @{
        Checked   = $false;
        Label     = 'Visual Studio Code';
        PackageId = 'Microsoft.VisualStudioCode';
    }
    @{
        Checked   = $false;
        Label     = 'Nano';
        PackageId = 'GNU.Nano';
    }
    @{
        Group     = 'Containers';
        Checked   = $false;
        Label     = 'Docker Desktop';
        PackageId = 'Docker.DockerDesktop';
    }
    @{
        Group     = 'Git & Git Utilities';
        Checked   = $false;
        Label     = 'Git';
        PackageId = 'Git.Git';
    }
    @{
        Checked   = $false;
        Label     = 'Git LFS';
        PackageId = 'GitHub.GitLFS';
    }
    @{
        Checked     = $false;
        Label       = 'Lefthook';
        Description = 'Git フックを YAML ファイルから定義できます。';
        PackageId   = 'evilmartians.lefthook';
    }
    @{
        Group         = 'C++ & .NET';
        Checked       = $false;
        Label         = 'Build Tools for Visual Studio 2022';
        Description   = 'Microsoft C++ Compiler を含むツールチェーン。インストールに時間がかかります。';
        PackageId     = 'Microsoft.VisualStudio.2022.BuildTools';
        InstallOption = '--quiet --wait --norestart --nocache --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended';
    }
    @{
        Checked   = $false;
        Label     = 'Microsoft .Net SDK 8.0';
        PackageId = 'Microsoft.DotNet.SDK.8';
    }
    @{
        Group     = 'Python';
        Checked   = $false;
        Label     = 'uv';
        PackageId = 'astral-sh.uv';
    }
    @{
        Checked   = $false;
        Label     = 'Ruff';
        PackageId = 'astral-sh.ruff';
    }
    @{
        Group     = 'Node.js';
        Checked   = $false;
        Label     = 'Volta';
        PackageId = 'Volta.Volta';
    }
    @{
        Group     = 'Utilities';
        Checked   = $false;
        Label     = 'AWS CLI';
        PackageId = 'Amazon.AWSCLI';
    }
    @{
        Checked     = $false;
        Label       = 'Task';
        Description = 'Makefile のように複数コマンドからなるタスクを定義し、コマンドラインから実行できます。';
        PackageId   = 'Task.Task';
    }
    @{
        Checked   = $false;
        Label     = 'Slack';
        PackageId = 'SlackTechnologies.Slack';
    }
    @{
        Checked   = $false;
        Label     = 'Notion';
        PackageId = 'Notion.Notion';
    }
    @{
        Checked     = $false;
        Label       = 'Google Drive for Desktop';
        Description = 'Google ドライブにエクスプローラーからアクセスできるようになります。';
        PackageId   = 'Google.GoogleDrive';
    }
    @{
        Checked     = $false;
        Label       = 'WinAuth';
        Description = '二要素認証のトークンを Windows PC から管理できるようになります。';
        PackageId   = 'WinAuth.WinAuth';
    }
    @{
        Checked     = $false;
        Label       = 'ScreenToGif';
        Description = '画面を GIF アニメーションとして録画できます。';
        PackageId   = 'NickeManarin.ScreenToGif';
    }
    @{
        Checked     = $false;
        Label       = 'DB Browser for SQLite';
        Description = 'SQLite データベースのスキーマやレコードを GUI から確認できます。';
        PackageId   = 'DBBrowserForSQLite.DBBrowserForSQLite';
    }
)

$Index = 0

do {
    $Formatted = Format-Selection `
        -Index $Index `
        -Options $Options

    Out-Viewport `
        -Lines $Formatted.Lines `
        -CursorLine $Formatted.CursorLine `
        -Footer '↑↓ : 移動 / Space : 切替 / Enter : インストール / Esc : 終了'

    $Key = [Console]::ReadKey($true)

    switch ($Key.Key) {
        'UpArrow' {
            if ($Index -gt 0) {
                $Index--
            }
        }
        'DownArrow' {
            if ($Index -lt $Options.Count - 1) {
                $Index++
            }
        }
        'Spacebar' {
            $Options[$Index].Checked = -not $Options[$Index].Checked
        }
        'Escape' {
            return
        }
    }
} while ($Key.Key -ne 'Enter')

Format-Command -Options $Options | ForEach-Object {
    Write-Host $_
    Invoke-Expression $_
}
