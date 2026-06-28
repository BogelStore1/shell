# BogelShell Protect

Professional Bash Script Encrypt & Decrypt Utility.

> Catatan penting: tool ini adalah **obfuscator/protector**, bukan enkripsi kriptografi yang benar-benar aman. Script Bash yang bisa dijalankan tetap dapat dianalisis oleh orang yang sangat paham shell. Gunakan untuk melindungi distribusi script milik sendiri dari pembacaan kasual, bukan untuk menyimpan password atau rahasia penting.

## Features

- Encrypt / Obfuscate Bash Script
- Decrypt file hasil BogelShell Protect
- Multi Layer Encode: gzip + base64 + rev + eval loader
- Random Variable
- Random Function
- Random Loader
- Payload Split
- 500+ dummy variable acak
- Cross Platform: Linux, Ubuntu, Debian, CentOS, AlmaLinux, Rocky Linux, OpenWRT, Termux
- Bash only, tanpa Python

## Requirement

- Bash 4+
- gzip
- base64
- rev
- grep
- sed
- awk
- chmod

## Install

```bash
git clone <repo-anda> bogelshell-protect
cd bogelshell-protect
chmod +x main.sh
./main.sh
```

Atau jika file dikirim manual:

```bash
cd bogelshell-protect
chmod +x main.sh
./main.sh
```

## Cara Penggunaan

Jalankan:

```bash
./main.sh
```

Tampilan awal:

```text
=========================================================
                BOGELSHELL PROTECT
        Bash Script Encrypt & Decrypt Utility
=========================================================

Version : 2.0
Author  : Bogel Project
```

Menu CLI:

```text
┌──────────────────────────────────────────────┐
│              MAIN MENU                       │
├──────────────────────────────────────────────┤
│ 1. Encrypt Bash Script                       │
│ 2. Decrypt Bash Script                       │
│ 3. About                                     │
│ 4. Exit                                      │
└──────────────────────────────────────────────┘
```

## Contoh Encrypt

```text
Pilih menu [1-4]: 1
Input Script : install.sh
Nama output  : install-encrypt.sh
```

Output:

```text
Reading Script... Done
Encoding Base64... Done
Randomizing Variable... Done
Building Loader... Done
Writing Output... Done
[SUCCESS] Done: install-encrypt.sh
```

Jalankan hasil protect:

```bash
./install-encrypt.sh
```

## Contoh Decrypt

```text
Pilih menu [1-4]: 2
Input encrypted file : install-encrypt.sh
Output file          : install-original.sh
```

Output:

```text
Reading Encrypted File... Done
Reversing Payload... Done
Writing Output... Done
[SUCCESS] Done: install-original.sh
```

## Screenshot CLI

```text
┌──────────────────────────────────────────────┐
│              MAIN MENU                       │
├──────────────────────────────────────────────┤
│ 1. Encrypt Bash Script                       │
│ 2. Decrypt Bash Script                       │
│ 3. About                                     │
│ 4. Exit                                      │
└──────────────────────────────────────────────┘
```

## Struktur Folder

```text
bogelshell-protect/
├── main.sh
├── modules/
│   ├── encrypt.sh
│   ├── decrypt.sh
│   └── about.sh
├── lib/
│   ├── color.sh
│   ├── progress.sh
│   ├── random.sh
│   ├── validate.sh
│   ├── builder.sh
│   └── loader.sh
├── assets/
│   └── logo.txt
└── README.md
```

## Cara Update

1. Backup folder lama.
2. Replace file `main.sh`, `modules/`, `lib/`, dan `assets/` dari versi terbaru.
3. Jalankan ulang permission:

```bash
chmod +x main.sh
```

4. Test encrypt dan decrypt dengan script kecil sebelum dipakai produksi.

## Troubleshooting

### ERROR: File tidak ditemukan
Pastikan nama file benar dan berada di folder yang sama, atau gunakan path lengkap.

```bash
/home/user/install.sh
```

### ERROR: File kosong
File input tidak memiliki isi. Isi script terlebih dahulu.

### ERROR: Permission ditolak
Berikan izin baca/tulis/jalankan:

```bash
chmod +r input.sh
chmod +w .
chmod +x main.sh
```

### Invalid encrypted file
File bukan hasil BogelShell Protect v2, metadata rusak, atau payload sudah berubah.

### base64 decode gagal di OpenWRT/Termux
Pastikan paket coreutils/base64 tersedia. Di Termux:

```bash
pkg install coreutils gzip
```

Di OpenWRT:

```bash
opkg update
opkg install bash coreutils-base64 gzip
```

## Keamanan

BogelShell Protect memakai obfuscation berlapis:

1. gzip
2. base64
3. rev
4. payload split
5. randomized variable/function
6. dummy code
7. eval loader

Ini membantu menyulitkan pembacaan langsung, tetapi bukan pengganti enkripsi kuat. Jangan menaruh API key, password VPS, token bot, atau data sensitif langsung di script.

## Author

Bogel Project
