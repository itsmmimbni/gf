function Get-HistoryFiles {
    param($logFolder)
    return Get-ChildItem $logFolder -Filter *.md | Sort-Object LastWriteTime -Descending
}

function Parse-MarkdownContext {
    param($filePath)
    $content = Get-Content $filePath -Raw
    $history = @()
    $sections = [regex]::Split($content, "(?m)^- \*\*(Anda|Gemini):\*\*")
    for ($i = 1; $i -lt $sections.Count; $i += 2) {
        $role = if ($sections[$i] -eq "Anda") { "user" } else { "model" }
        $text = $sections[$i+1].Split("---")[0].Trim()
        $history += @{ role = $role; parts = @(@{ text = $text }) }
    }
    return $history
}

function Remove-EmptyLogs {
    param($logFolder, $currentLog)
    Get-ChildItem $logFolder -Filter *.md | Where-Object { $_.Length -lt 50 -and $_.FullName -ne $currentLog } | Remove-Item
}