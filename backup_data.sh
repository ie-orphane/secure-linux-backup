#!/bin/bash

EXTERNAL_DRIVE="/media/$USER"
BACKUP_FOLDER="backup_raw"
ENCRYPTED_FILE="backup.enc"

find_drive() {
    for d in "$EXTERNAL_DRIVE"/*; do
        [ -d "$d" ] && echo "$d" && return
    done
}

backup_data() {
    drive=$(find_drive)
    [ -z "$drive" ] && echo "❌ No external drive found" && exit 1

    work="$drive/$BACKUP_FOLDER"
    rm -rf "$work"
    mkdir -p "$work"

    echo "📁 Backing up to: $work"

    normal_folders=("Documents" "Pictures" "Videos" "Music" "Desktop" "Downloads")

    for f in "${normal_folders[@]}"; do
        [ -d "$HOME/$f" ] && rsync -av --delete "$HOME/$f/" "$work/$f/"
    done

    hidden_items=(
        ".ssh"
        ".config"
        ".local/share/applications"
        ".local/share/icons"
        ".local/share/themes"
        ".bashrc"
        ".zshrc"
        ".profile"
        ".gitconfig"
        ".npmrc"
        ".cargo"
        ".vscode"
    )

    for item in "${hidden_items[@]}"; do
        [ -e "$HOME/$item" ] && rsync -av --delete "$HOME/$item/" "$work/$item/"
    done

    if [ -d "$HOME/.config/opera" ]; then
        rsync -av --delete "$HOME/.config/opera/" "$work/opera_profile/"
    fi

    echo "🔐 Encrypting backup..."

    tar -czf "$drive/backup.tar.gz" -C "$drive" "$BACKUP_FOLDER"

    openssl enc -aes-256-cbc -salt -pbkdf2 \
        -in "$drive/backup.tar.gz" \
        -out "$drive/$ENCRYPTED_FILE"

    rm "$drive/backup.tar.gz"
    rm -rf "$work"

    echo "✅ Backup encrypted and saved as: $drive/$ENCRYPTED_FILE"
}

restore_data() {
    drive=$(find_drive)
    [ -z "$drive" ] && echo "❌ No external drive found" && exit 1

    if [ ! -f "$drive/$ENCRYPTED_FILE" ]; then
        echo "❌ Encrypted backup file not found!"
        exit 1
    fi

    temp="$drive/restore_temp"
    rm -rf "$temp"
    mkdir -p "$temp"

    echo "🔓 Decrypting backup..."
    openssl enc -d -aes-256-cbc -salt -pbkdf2 \
        -in "$drive/$ENCRYPTED_FILE" \
        -out "$temp/backup.tar.gz"

    echo "📂 Extracting..."
    tar -xzf "$temp/backup.tar.gz" -C "$temp"

    raw="$temp/$BACKUP_FOLDER"

    echo "⬅ Restoring files..."

    normal_folders=("Documents" "Pictures" "Videos" "Music" "Desktop" "Downloads")
    for f in "${normal_folders[@]}"; do
        [ -d "$raw/$f" ] && rsync -av "$raw/$f/" "$HOME/$f/"
    done

    hidden_items=(
        ".ssh"
        ".config"
        ".local/share/applications"
        ".local/share/icons"
        ".local/share/themes"
        ".bashrc"
        ".zshrc"
        ".profile"
        ".gitconfig"
        ".npmrc"
        ".cargo"
        ".vscode"
    )

    for item in "${hidden_items[@]}"; do
        [ -e "$raw/$item" ] && rsync -av "$raw/$item/" "$HOME/$item/"
    done

    if [ -d "$raw/opera_profile" ]; then
        mkdir -p "$HOME/.config/opera"
        rsync -av "$raw/opera_profile/" "$HOME/.config/opera/"
    fi

    rm -rf "$temp"
    echo "✅ Restore complete!"
}


echo "==============================="
echo " Backup & Restore Utility"
echo "==============================="
echo "1) Backup (Encrypted)"
echo "2) Restore"
echo "3) Exit"
read -p "Select an option: " input

case $input in
    1) backup_data ;;
    2) restore_data ;;
    *) exit 0 ;;
esac

