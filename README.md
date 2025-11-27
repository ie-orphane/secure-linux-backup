# Secure Linux Backup

**Secure Linux Backup** is a simple, beginner-friendly Bash script to backup and restore your important data on Ubuntu/Linux systems.  
It supports **full user folder backups**, **hidden configuration files**, **browser profiles**, and **encryption** for security.

---

## Features

- Backup main user folders:
  - `Documents`, `Pictures`, `Videos`, `Music`, `Desktop`, `Downloads`
- Backup important hidden files and folders:
  - `.ssh`, `.config`, `.bashrc`, `.zshrc`, `.local/share/applications`, `.fonts`, and more
- Backup Opera browser profile
- Fully encrypted backups using OpenSSL AES-256-CBC + PBKDF2
- Easy restore to recover your data after reinstalling Linux
- Detects external drives automatically
- Beginner-friendly and easy to modify

---

## Getting Started

### 1. Clone the repo
```bash
git clone https://github.com/abd3l3li/secure-linux-backup.git
cd secure-linux-backup
chmod +x backup_data.sh
