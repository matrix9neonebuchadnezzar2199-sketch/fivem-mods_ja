param([string]$Path = '.')

Get-ChildItem -Path $Path -Recurse -Include *.lua,*.md,*.html,*.css,*.js -File | ForEach-Object {
    $fp = $_.FullName
    $bytes = [System.IO.File]::ReadAllBytes($fp)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Write-Output ("BOM  " + $fp)
    } else {
        $head = ''
        for ($i = 0; $i -lt [Math]::Min(3, $bytes.Length); $i++) {
            $head += ('{0:X2} ' -f $bytes[$i])
        }
        Write-Output ("OK   " + $fp + " [" + $head.Trim() + "]")
    }
}
