[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- MODULARISASI: Load modules ---
. "$PSScriptRoot\modules\UIStyles.ps1"
. "$PSScriptRoot\modules\ApiService.ps1"
. "$PSScriptRoot\modules\FileHandler.ps1"

function Start-GeminiChat {
    # --- 1. KONFIGURASI API & MODEL ---
    $envPath = Join-Path $PSScriptRoot ".env"
    if (Test-Path $envPath) {
        $apiKey = (Get-Content $envPath -Raw).Trim()
    }

    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Host "[!] ERROR: API Key kosong atau file .env tidak ditemukan!" -ForegroundColor Red
        return
    }
    
    $modelName = "gemini-2.5-flash-lite" 
    $url = "https://generativelanguage.googleapis.com/v1beta/models/$($modelName):generateContent?key=$apiKey"
    [System.Net.ServicePointManager]::Expect100Continue = $false
    
    # --- 2. KONFIGURASI LOGGING ---
    $logFolder = Join-Path $PSScriptRoot "gemini-cli-chat-history"
    if (-not (Test-Path $logFolder)) { New-Item -ItemType Directory -Path $logFolder }
    $script:logFile = Join-Path $logFolder "ChatHistory_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    
    # --- 3. STATE AWAL ---
    $script:chatHistory = @()
    $script:promptVars = @{} # Hashtable untuk menyimpan {{1}}, {{2}}, dst.
    $isBrief = $false
    $lastResponse = ""
    
    # Tampilkan UI Awal
    Show-Header -isBrief $isBrief -msgCount 0 -currentLog $script:logFile

    # Inisialisasi file log baru
    if (-not (Test-Path $script:logFile)) { 
        $header = "# Sesi Chat Gemini - $(Get-Date -Format 'dd MMMM yyyy HH:mm')`r`n`r`n"
        [System.IO.File]::WriteAllText($script:logFile, $header, [System.Text.Encoding]::UTF8)
    }
    
    # --- 4. MAIN INTERACTIVE LOOP ---
    while ($true) {
        Write-Host "`n[$(Get-Date -Format 'HH:mm')] " -NoNewline -ForegroundColor DarkGray
        Write-Host "> " -NoNewline -ForegroundColor Cyan
        $userInput = (Read-Host).Trim()
        
        if ([string]::IsNullOrWhiteSpace($userInput)) { continue }

        # --- VALIDASI INPUT ---
        if (-not $userInput.StartsWith("/") -and $userInput.Length -lt 8) {
            Write-Host "[!] Input terlalu pendek (min 8 karakter)." -ForegroundColor DarkGray
            continue
        }
        
        $commandProcessed = $false
        
        # --- LOGIC PERINTAH KHUSUS ---
        if ($userInput -eq "/exit") { 
            Write-Host "Cleaning up empty logs..." -ForegroundColor DarkGray
            Remove-EmptyLogs -logFolder $logFolder -currentLog $script:logFile
            Write-Host "Goodbye!" -ForegroundColor Magenta
            break 
        }
        
        if ($userInput -eq "/help") {
            Write-Host "`n[ DAFTAR PERINTAH ]" -ForegroundColor Cyan
            Write-Host " /explorer    : Buka folder history di File Explorer" -ForegroundColor Gray
            Write-Host " /load [idx]  : Load history file sebagai konteks chat" -ForegroundColor Gray
            Write-Host " /logs [idx]  : Lihat daftar/preview history" -ForegroundColor Gray
            Write-Host " /del [idx]   : Hapus file history" -ForegroundColor Gray
            Write-Host " /ren [idx]   : Rename file history" -ForegroundColor Gray
            Write-Host " /brief       : Toggle mode jawaban singkat (1 paragraf)" -ForegroundColor Gray
            Write-Host " /clear       : Bersihkan layar (tetap ingat percakapan)" -ForegroundColor Gray
            Write-Host " /clear-chat  : Reset total konteks chat (lupa ingatan)" -ForegroundColor Gray
            Write-Host " /clean-logs  : Hapus paksa file log kosong (< 50 bytes)" -ForegroundColor Gray
            Write-Host " /copy        : Menyalin respons terakhir ke clipboard" -ForegroundColor Gray
            Write-Host " /paste [n]   : Simpan clipboard ke variabel {{n}} atau langsung kirim" -ForegroundColor Gray
            Write-Host " /vars        : Tampilkan daftar variabel {{n}} yang tersimpan" -ForegroundColor Gray
            Write-Host " /code [idx]  : Membuka file log di VS Code" -ForegroundColor Gray
            
            Write-Host "`n[ TIPS PROMPT ENGINEERING ]" -ForegroundColor Yellow
            Write-Host " Gunakan {{1}}, {{2}}, dst. di dalam prompt untuk memanggil teks" -ForegroundColor Gray
            Write-Host " yang sudah di-paste sebelumnya." -ForegroundColor Gray
            
            $commandProcessed = $true; continue
        }
        
        # --- LOGIC PASTE KE VARIABLE (/paste [idx]) ---
        if ($userInput -match "^/paste(\s+(\d+))?$") {
            $idx = $Matches[2]
            $cbText = Get-Clipboard -Raw
            
            if ([string]::IsNullOrWhiteSpace($cbText)) {
                Write-Host "[!] Clipboard kosong." -ForegroundColor Yellow
                continue
            }

            if ($null -eq $idx) {
                # Jika cuma /paste tanpa angka, jalankan seperti biasa (langsung kirim)
                $userInput = $cbText.Trim()
                Write-Host "[Mendeteksi $($userInput.Length) karakter dari clipboard]" -ForegroundColor DarkGray
                $commandProcessed = $false
            } else {
                # Jika /paste 1, simpan ke variabel {{1}}
                $script:promptVars[$idx] = $cbText.Trim()
                Write-Host "[√] Berhasil disimpan ke {{ $idx }} ($($cbText.Length) karakter)" -ForegroundColor Green
                $commandProcessed = $true
                continue
            }
        }

        if ($userInput -eq "/vars") {
            Write-Host "`n--- Daftar Variabel Prompt ---" -ForegroundColor Cyan
            foreach ($key in $script:promptVars.Keys) {
                $preview = $script:promptVars[$key].SubString(0, [Math]::Min(50, $script:promptVars[$key].Length))
                Write-Host "{{$key}} : $preview..." -ForegroundColor Gray
            }
            $commandProcessed = $true
            continue
        }

        if ($userInput -eq "/clear") { 
            Show-Header -isBrief $isBrief -msgCount ($script:chatHistory.Count / 2) -currentLog $script:logFile
            $commandProcessed = $true; continue 
        }

        if ($userInput -eq "/clear-chat") { 
            $script:chatHistory = @()
            Show-Header -isBrief $isBrief -msgCount 0 -currentLog $script:logFile
            Write-Host "--- Riwayat Chat Dibersihkan ---" -ForegroundColor Yellow
            $commandProcessed = $true; continue 
        }

        if ($userInput -eq "/clean-logs") {
            Remove-EmptyLogs -logFolder $logFolder -currentLog $script:logFile
            $commandProcessed = $true; continue
        }

        if ($userInput -eq "/copy") {
            if ($lastResponse) { $lastResponse | Set-Clipboard; Write-Host "Copied to clipboard!" -ForegroundColor Green }
            else { Write-Host "Nothing to copy." -ForegroundColor Yellow }
            $commandProcessed = $true; continue
        }
        
        if ($userInput -eq "/explorer") {
            Start-Process explorer.exe $logFolder
            $commandProcessed = $true; continue
        }
        
        if ($userInput -eq "/brief") { 
            $isBrief = -not $isBrief
            Show-Header -isBrief $isBrief -msgCount ($script:chatHistory.Count / 2) -currentLog $script:logFile
            $commandProcessed = $true; continue 
        }

        # --- LOGIC LOAD / LOGS / DEL / REN / CODE ---
        if ($userInput -match "^/(load|logs|del|ren|code)(\s+(\d+))?$") {
            $cmd = $Matches[1]
            $targetIndex = $Matches[3]
            $files = Get-HistoryFiles -logFolder $logFolder
            
            if ($null -eq $targetIndex -or $targetIndex -eq "") {
                Write-Host "`n--- Daftar History ($($files.Count) file) ---" -ForegroundColor Cyan
                for ($i=0; $i -lt $files.Count; $i++) { Write-Host "[$i] $($files[$i].Name)" -ForegroundColor Yellow }
                $targetIndex = Read-Host "`nPilih nomor"
            }

            if ($targetIndex -match "^\d+$" -and [int]$targetIndex -lt $files.Count) {
                $targetFile = $files[[int]$targetIndex]
                
                if ($cmd -eq "load") {
                    $script:logFile = $targetFile.FullName
                    $script:chatHistory = Parse-MarkdownContext -filePath $script:logFile
                    Write-Host "Berhasil! Konteks dimuat dari $($targetFile.Name)." -ForegroundColor Green
                }
                elseif ($cmd -eq "logs") {
                    Write-Host "`nPREVIEW: $($targetFile.Name)" -BackgroundColor DarkGray
                    Write-Markdown -entireText (Get-Content $targetFile.FullName -Raw)
                } 
                elseif ($cmd -eq "code") { & code $targetFile.FullName }
                elseif ($cmd -eq "del") { Remove-Item $targetFile.FullName; Write-Host "Dihapus." -ForegroundColor Red }
                elseif ($cmd -eq "ren") {
                    $newName = Read-Host "Nama baru (tanpa .md)"
                    if ($newName) { Rename-Item $targetFile.FullName -NewName "$newName.md"; Write-Host "Renamed." -ForegroundColor Green }
                }
            }
            $commandProcessed = $true; continue
        }

        # --- VALIDASI COMMAND TIDAK DIKENAL ---
        if ($userInput.StartsWith("/") -and -not $commandProcessed) {
            Write-Host "[!] Error: Command '$userInput' tidak ditemukan. Gunakan /help." -ForegroundColor Red
            continue
        }

        # --- 5. REQUEST KE API (FIXED LOGIC) ---
        $finalPrompt = if ($isBrief) { "Answer briefly in 1 paragraph: $userInput" } else { $userInput }

        foreach ($key in $script:promptVars.Keys) {
            $placeholder = "{{" + $key + "}}"
            if ($finalPrompt.Contains($placeholder)) {
                $finalPrompt = $finalPrompt.Replace($placeholder, $script:promptVars[$key])
            }
        }

        $maxTokens = if ($isBrief) { 200 } else { 2048 }
        $script:chatHistory += @{ role = "user"; parts = @(@{ text = $finalPrompt }) }
        
        Write-Host "Gemini thinking..." -ForegroundColor DarkGray

        try {
            $response = Invoke-GeminiRequest -url $url -chatHistory $script:chatHistory -maxTokens $maxTokens
            
            if ($response.candidates) {
                $aiResponse = $response.candidates[0].content.parts[0].text
                $lastResponse = $aiResponse
                
                Write-Host "`n--- Gemini ---" -ForegroundColor Green
                Write-Markdown -entireText $aiResponse
                
                # 3. Masukkan ke history menggunakan $finalPrompt
                $script:chatHistory += @{ role = "user"; parts = @(@{ text = $finalPrompt }) }

                # Log to file
                $logEntry = "## [TIME] $(Get-Date -Format 'HH:mm:ss')`n- **Anda:** $userInput`n- **Gemini:**`n$aiResponse`n---`n"
                [System.IO.File]::AppendAllText($script:logFile, $logEntry, [System.Text.Encoding]::UTF8)
            }
        } catch {
            Write-Host "`n[!] Error: $($_.Exception.Message)" -ForegroundColor Red
            if ($script:chatHistory.Count -gt 0) { $script:chatHistory = $script:chatHistory[0..($script:chatHistory.Count - 2)] }
        }
    }
}
Start-GeminiChat