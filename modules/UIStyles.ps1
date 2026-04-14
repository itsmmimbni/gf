 # --- 4. HELPER: FORMATTER WARNA MARKDOWN ---
    function Write-Markdown {
        param([string]$entireText)
        
        $lines = $entireText -split "`n"
        $inCodeBlock = $false

        foreach ($line in $lines) {
            # 1. Tampilan Code Block (Batas ```)
            if ($line -match '```') {
                $inCodeBlock = -not $inCodeBlock
                # Gunakan Green agar terlihat seperti terminal hacker
                Write-Host $line -ForegroundColor Green 
                continue
            }

            # 2. Isi di dalam Code Block
            if ($inCodeBlock) {
                # Gunakan Gray (bukan DarkGray) agar lebih terang
                Write-Host $line -ForegroundColor Gray 
                continue
            }

            # 3. Deteksi Header ( # Judul )
            if ($line -match '^#+\s+(.*)') {
                Write-Host $line -ForegroundColor Cyan -Bold # Header jadi Biru Muda Terang
                continue
            }

            # 4. Deteksi Bullet Point
            $currentLine = $line
            if ($line -match '^\s*\*\s+(.*)') {
                # Menggunakan tanda '>' yang lebih aman untuk semua jenis terminal
                Write-Host " > " -ForegroundColor Yellow -NoNewline
                $currentLine = $Matches[1]
            }

            # 5. Regex: Bold (**), Italic (*), Inline Code (`)
            $pattern = '(\*\*.*?\*\*|\*.*?\*|`.*?`)'
            $parts = [regex]::Split($currentLine, $pattern)
            
            foreach ($part in $parts) {
                if ($part -match '^\*\*(.*?)\*\*$') {
                    # BOLD -> Kuning Terang
                    Write-Host $Matches[1] -ForegroundColor Yellow -NoNewline
                } elseif ($part -match '^\*(.*?)\*$') {
                    # ITALIC -> Hijau Terang (Ganti dari Ungu)
                    Write-Host $part.Replace("*","") -ForegroundColor Green -NoNewline
                } elseif ($part -match '^`(.*?)`$') {
                    # INLINE CODE -> Putih dengan Background Biru (sangat kontras)
                    Write-Host " $($Matches[1]) " -ForegroundColor White -BackgroundColor Blue -NoNewline
                } else {
                    # TEKS NORMAL -> Putih Terang
                    Write-Host $part -ForegroundColor White -NoNewline
                }
            }
            Write-Host "" 
        }
    }

# --- 5. HELPER: TAMPILAN HEADER ---
    function Show-Header {
        Clear-Host
        $msgCount = $script:chatHistory.Count
        $statusBrief = if ($isBrief) { "AKTIF (1 Paragraf)" } else { "NON-AKTIF" }
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host "          _____                    _____          " -ForegroundColor Green
        Write-Host "         /\    \                  /\    \         " -ForegroundColor Green
        Write-Host "        /::\    \                /::\    \        " -ForegroundColor Green
        Write-Host "       /::::\    \              /::::\    \       " -ForegroundColor Green
        Write-Host "      /::::::\    \            /::::::\    \      " -ForegroundColor Green
        Write-Host "     /:::/\:::\    \          /:::/\:::\    \     " -ForegroundColor Green
        Write-Host "    /:::/  \:::\    \        /:::/__\:::\    \    " -ForegroundColor Green
        Write-Host "   /:::/    \:::\    \      /::::\   \:::\    \   " -ForegroundColor Green
        Write-Host "  /:::/    / \:::\    \    /::::::\   \:::\    \  " -ForegroundColor Green
        Write-Host " /:::/    /   \:::\ ___\  /:::/\:::\   \:::\    \ " -ForegroundColor Green
        Write-Host "/:::/____/  ___\:::|    |/:::/  \:::\   \:::\____\" -ForegroundColor Green
        Write-Host "\:::\    \ /\  /:::|____|\::/    \:::\   \::/    /" -ForegroundColor Green
        Write-Host " \:::\    /::\ \::/    /  \/____/ \:::\   \/____/ " -ForegroundColor Green
        Write-Host "  \:::\   \:::\ \/____/            \:::\    \     " -ForegroundColor Green
        Write-Host "   \:::\   \:::\____\               \:::\____\    " -ForegroundColor Green
        Write-Host "    \:::\  /:::/    /                \::/    /    " -ForegroundColor Green
        Write-Host "     \:::\/:::/    /                  \/____/     " -ForegroundColor Green
        Write-Host "      \::::::/    /                               " -ForegroundColor Green
        Write-Host "       \::::/    /                                " -ForegroundColor Green
        Write-Host "        \::/____/                                 " -ForegroundColor Green
        Write-Host "                                                  " -ForegroundColor Green
        Write-Host "                                                  " -ForegroundColor Green
        Write-Host "GEMINI AI INTERACTIVE CLI - v4.8 FAST" -ForegroundColor White -BackgroundColor Blue
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host " [BRIEF: $statusBrief] | [MEMORI: $msgCount Pesan] | [LOG: $(Split-Path $script:logFile -Leaf)]" -ForegroundColor Yellow
        Write-Host " help: /help | exit: /exit | clear screen: /clear" -ForegroundColor DarkGray
        Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    }
