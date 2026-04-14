# 🚀 gf (Gemini Fast) - CLI Interactive Chat

**gf** adalah *tool* berbasis PowerShell yang dirancang untuk berinteraksi dengan Google Gemini API secara cepat, ringan, dan terorganisir langsung dari terminal. Proyek ini dibangun dengan arsitektur modular untuk memisahkan logika antarmuka, layanan API, dan pengelolaan file.

---

## 📂 Struktur Proyek

Proyek ini menerapkan prinsip *Separation of Concerns* agar kode mudah dipelihara:

```text
gf/
├── .env                # Berisi API Key (Hidden)
├── GeminiChat.ps1      # Entry point / Main Program
├── modules/
│   ├── ApiService.ps1  # Logika komunikasi ke Google API
│   ├── FileHandler.ps1 # Pengelolaan log dan parsing history
│   └── UIStyles.ps1    # Fungsi tampilan, warna, dan ASCII Art
└── gemini-cli-chat-history/  # Folder penyimpanan log percakapan (.md)
```

---

## ✨ Fitur Utama

- **Modular Architecture**: Menggunakan *Dot Sourcing* untuk memuat modul eksternal.
- **Context Awareness**: Mendukung pemuatan riwayat chat lama sebagai konteks percakapan baru.
- **Rich UI**: Tampilan Markdown yang berwarna di terminal dan Header informasi real-time.
- **Log Management**: Otomatis menyimpan percakapan dalam format Markdown dan fitur pembersihan log kosong.
- **Brief Mode**: Mode jawaban singkat (1 paragraf) untuk efisiensi token.

---

## 🛠️ Cara Instalasi

1. **Persiapan API Key**:
    Dapatkan API Key dari [Google AI Studio](https://aistudio.google.com/).
2. **Konfigurasi Environment**:
    Buat file `.env` di folder root proyek dan masukkan API Key Anda:

    ```text
    YOUR_GEMINI_API_KEY_DISINI
    ```

3. **Jalankan Program**:
    Buka PowerShell di direktori proyek, lalu jalankan:

    ```powershell
    .\GeminiChat.ps1
    ```

---

## ⌨️ Daftar Perintah (Commands)

| Perintah      | Deskripsi                                                  |
| :------------ | :--------------------------------------------------------- |
| `/help`       | Menampilkan daftar perintah yang tersedia.                 |
| `/brief`      | Aktifkan/Nonaktifkan mode jawaban singkat.                 |
| `/load [idx]` | Memuat file history tertentu ke dalam konteks chat aktif.  |
| `/logs [idx]` | Melihat daftar file history atau isi file secara spesifik. |
| `/clear`      | Membersihkan layar terminal (konteks tetap diingat).       |
| `/clear-chat` | Reset total riwayat chat saat ini.                         |
| `/copy`       | Menyalin respons terakhir Gemini ke clipboard.             |
| `/code`       | Membuka file log aktif di VS Code.                         |
| `/clean-logs` | Menghapus file log yang kosong atau hanya berisi header.   |
| `/exit`       | Keluar dari program dengan pembersihan log otomatis.       |

---

## ⚙️ Detail Teknis

### Modularisasi

Program ini membagi tanggung jawab ke dalam tiga modul utama:

1. **UIStyles**: Mengatur fungsi `Write-Markdown` untuk rendering teks dan `Show-Header` untuk estetika terminal.
2. **ApiService**: Menangani `Invoke-RestMethod` ke endpoint Gemini 1.5 Flash.
3. **FileHandler**: Mengurus manipulasi file sistem menggunakan regex untuk mem-parsing riwayat chat dari file Markdown.

### Persyaratan Sistem

- PowerShell 5.1 atau PowerShell Core 7+.
- Koneksi Internet.
- VS Code (opsional, untuk perintah `/code`).

---

**Dibuat dengan ❤️ untuk produktivitas developer.**

### Cara Menyimpannya

1. Buka teks editor Anda.
2. Simpan dengan nama `README.md` di folder `C:\Users\70556\Scripts\gf\`.

Dengan adanya README ini, proyek Anda sekarang terlihat seperti proyek open-source profesional yang siap di-*upload* ke GitHub atau digunakan oleh rekan kerja! Apakah ada bagian lain yang ingin Anda tambahkan atau sesuaikan?
