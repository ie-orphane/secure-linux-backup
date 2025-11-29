#!/bin/bash

# ================================
#  Secure Backup & Restore Script
# ================================

REQUIRED_TOOLS=("rsync" "tar" "openssl")
BACKUP_FOLDER_NAME="backup"

# --------------------------------
#  Check required tools
# --------------------------------
check_tools() {
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "❌ Missing tool: $tool"
            read -p "Install $tool? (y/n): " ans
            if [[ "$ans" == "y" ]]; then
                sudo apt update
                sudo apt install -y "$tool"
            else
                echo "❌ Cannot continue without $tool"
                exit 1
            fi
        fi
    done
}

# --------------------------------
#  Choose external drive
# --------------------------------
choose_drive() {
    drives=()
    for dir in /media/"$USER"/*; do
        [ -d "$dir" ] && drives+=("$dir")
    done

    if (( ${#drives[@]} == 0 )); then
        echo "❌ No external drives found."
        exit 1
    fi

    echo "📦 Available external drives:"
    for i in "${!drives[@]}"; do
        echo "$((i+1))) ${drives[$i]}"
    done

    read -p "Choose a drive: " choice
    drive_index=$((choice-1))

    if [[ -z "${drives[$drive_index]}" ]]; then
        echo "❌ Invalid choice."
        exit 1
    fi

    echo "${drives[$drive_index]}"
}

# --------------------------------
#  Encrypt backup
# --------------------------------
encrypt_backup() {
    local input_file=$1
    local output_file=$2

    echo "🔐 Enter encryption password:"
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "$input_file" -out "$output_file"
}

# --------------------------------
#  Decrypt backup
# --------------------------------
decrypt_backup() {
    local input_file=$1
    local output_file=$2

    echo "🔐 Enter decryption password:"
    openssl enc -d -aes-256-cbc -salt -pbkdf2 -in "$input_file" -out "$output_file"
}

# --------------------------------
#  Backup
# --------------------------------
store_data() {
    drive=$(choose_drive)
    backup_path="$drive/$BACKUP_FOLDER_NAME"
    mkdir -p "$backup_path"

    echo "📁 Backing up to: $backup_path"

    items=(
        "$HOME/Documents"
        "$HOME/Pictures"
        "$HOME/Videos"
        "$HOME/Music"
        "$HOME/Desktop"
        "$HOME/Downloads"
        "$HOME/.ssh"
        "$HOME/.config"
        "$HOME/.local/share"
        "$HOME/.bashrc"
        "$HOME/.zshrc"
    )

    working_dir="/tmp/backup_temp"
    rm -rf "$working_dir"
    mkdir -p "$working_dir"

    echo "📦 Copying files..."
    for item in "${items[@]}"; do
        if [ -e "$item" ]; then
            rsync -av "$item" "$working_dir/"
        fi
    done

    # Compress
    tar czf "$working_dir/data.tar.gz" -C "$working_dir" .

    # Encrypt
    encrypt_backup "$working_dir/data.tar.gz" "$backup_path/backup.enc"

    rm -rf "$working_dir"
    echo "✅ Backup finished!"
}

# --------------------------------
#  Restore
# --------------------------------
restore_data() {
    drive=$(choose_drive)
    backup_path="$drive/$BACKUP_FOLDER_NAME/backup.enc"

    if [ ! -f "$backup_path" ]; then
        echo "❌ No encrypted backup found."
        exit 1
    fi

    temp="/tmp/restore_temp"
    rm -rf "$temp"
    mkdir -p "$temp"

    # Decrypt
    decrypt_backup "$backup_path" "$temp/data.tar.gz"

    # Extract
    tar xzf "$temp/data.tar.gz" -C "$HOME"

    rm -rf "$temp"
    echo "✅ Restore finished!"
}

# --------------------------------
#  Script menu
# --------------------------------
case "$1" in
    -s | --store)
        check_tools
        store_data
        ;;
    -r | --restore)
        check_tools
        restore_data
        ;;
    *)
        echo -e "Usage: \e[1;37m$0\e[0m [OPTION]\n\nOptions:"
        echo -e "  \e[1;32m-s\e[0;32m, \e[1;32m--store\e[0m    store your files in an encrypted backup"
        echo -e "  \e[1;33m-r\e[1;33m, \e[1;33m--restore\e[0m   restore your files from an encrypted backup"
        exit 1
        ;;
esac
