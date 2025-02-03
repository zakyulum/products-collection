#!/bin/bash

CONFIG_FILE="data/config.json"

# Warna untuk output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
RED='\033[0;31m'
YELLOW='\033[1;33m'

# Fungsi untuk menampilkan menu
show_menu() {
    clear
    echo -e "${BLUE}=== MENU MANAJEMEN KONTEN ===${NC}"
    echo "1. Ubah Nama Halaman"
    echo "2. Tambah Produk Baru"
    echo "3. Hapus Produk"
    echo "4. Lihat Daftar Produk"
    echo "5. Update dari GitHub"
    echo "6. Push ke GitHub"
    echo "7. Keluar"
    echo -e "${BLUE}=============================${NC}"
}

# Fungsi untuk menampilkan daftar produk menggunakan Python
list_products() {
    echo -e "${BLUE}=== DAFTAR PRODUK ===${NC}"
    python -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
for product in data['products']:
    print(f\"ID: {product['id']}\nNama: {product['name']}\nLink: {product['link']}\nGambar: {product['image']}\n\")
"
    echo -e "${BLUE}====================${NC}"
    echo -n "Tekan Enter untuk kembali ke menu..."
    read
}

# Fungsi untuk mengubah nama halaman menggunakan Python
change_site_name() {
    echo -n "Masukkan nama halaman baru: "
    read new_name
    python -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
data['siteName'] = '$new_name'
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=4)
"
    echo -e "${GREEN}Nama halaman berhasil diubah menjadi: $new_name${NC}"
}

# Fungsi untuk menambah produk
add_product() {
    clear
    echo -e "${BLUE}=== TAMBAH PRODUK BARU ===${NC}"
    
    # Input ID Produk dengan validasi
    while true; do
        echo -n "ID Produk (3 digit, contoh: 001): "
        read id
        if [[ $id =~ ^[0-9]{3}$ ]]; then
            # Gunakan Python untuk cek ID
            ID_EXISTS=$(python -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
print(any(p['id'] == '$id' for p in data['products']))
")

            if [ "$ID_EXISTS" = "True" ]; then
                echo -e "${RED}ID $id sudah digunakan. Silakan gunakan ID lain.${NC}"
            else
                break
            fi
        else
            echo -e "${RED}ID harus 3 digit angka!${NC}"
        fi
    done
    
    # Input judul produk
    echo -n "Judul Produk: "
    read -e name
    
    # Input link produk
    echo -n "Link Produk Shopee: "
    read -e link
    
    # Input URL gambar (otomatis dari preview WhatsApp)
    echo -n "URL Gambar (dari preview WhatsApp): "
    read -e image

    # Konfirmasi data
    echo -e "\n${BLUE}=== KONFIRMASI DATA ===${NC}"
    echo -e "ID Produk  : ${GREEN}$id${NC}"
    echo -e "Judul      : ${GREEN}$name${NC}"
    echo -e "Link       : ${GREEN}$link${NC}"
    echo -e "URL Gambar : ${GREEN}$image${NC}"
    
    echo -n -e "\nApakah data sudah benar? (y/n): "
    read confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        # Tambah produk menggunakan Python
        python -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
data['products'].append({
    'id': '$id',
    'name': '$name',
    'image': '$image',
    'link': '$link'
})
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=4)
"
        echo -e "\n${GREEN}✓ Produk berhasil ditambahkan!${NC}"
    else
        echo -e "\n${RED}✗ Pembatalan penambahan produk${NC}"
        return 1
    fi
}

# Fungsi untuk menghapus produk menggunakan Python
remove_product() {
    echo "Produk yang tersedia:"
    python -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
for product in data['products']:
    print(f\"ID: {product['id']} - {product['name']}\")
"
    echo -n "Masukkan ID produk yang akan dihapus: "
    read id
    python -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
data['products'] = [p for p in data['products'] if p['id'] != '$id']
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=4)
"
    echo -e "${GREEN}Produk dengan ID $id berhasil dihapus${NC}"
}

# Fungsi untuk commit dan push perubahan
save_changes() {
    if ! git diff --quiet "$CONFIG_FILE"; then
        git add "$CONFIG_FILE"
        git commit -m "Update konten via menu"
        git push
        echo -e "${GREEN}Perubahan berhasil disimpan dan di-push ke GitHub${NC}"
    fi
}

# Fungsi untuk inisialisasi git jika belum ada
init_git() {
    # Cek apakah sudah ada .git
    if [ ! -d ".git" ]; then
        git init
        git add .
        git commit -m "Initial commit"
    fi
}

# Fungsi untuk update dari GitHub
update_from_github() {
    echo -e "\n${BLUE}=== UPDATE DARI GITHUB ===${NC}"
    echo -e "Menyiapkan repository..."
    
    # Tambahkan semua file yang belum di-track
    git add .
    
    # Simpan perubahan lokal jika ada
    if ! git diff --quiet --cached; then
        echo -e "${YELLOW}Ditemukan perubahan lokal yang belum disimpan${NC}"
        echo -n "Simpan perubahan lokal terlebih dahulu? (y/n): "
        read save
        if [[ $save =~ ^[Yy]$ ]]; then
            git commit -m "Update konten sebelum pull"
        else
            git stash
        fi
    fi
    
    echo -e "Mengambil perubahan terbaru..."
    if git pull origin main; then
        echo -e "${GREEN}✓ Berhasil update dari GitHub!${NC}"
    else
        echo -e "${RED}✗ Gagal update dari GitHub${NC}"
        if [[ $save != "y" ]]; then
            git stash pop
        fi
    fi
}

# Fungsi untuk push ke GitHub
push_to_github() {
    echo -e "\n${BLUE}=== PUSH KE GITHUB ===${NC}"
    
    # Tambahkan semua file
    git add .
    
    # Cek apakah ada perubahan
    if ! git diff --quiet --cached; then
        echo -e "Menyimpan perubahan..."
        git commit -m "Update konten via menu"
        
        # Set upstream jika belum ada
        if ! git remote | grep -q "^origin$"; then
            echo -n "Masukkan URL repository GitHub: "
            read repo_url
            git remote add origin "$repo_url"
        fi
        
        if git push -u origin main; then
            echo -e "${GREEN}✓ Berhasil push ke GitHub!${NC}"
            echo -e "${YELLOW}Silakan refresh browser untuk melihat perubahan${NC}"
            
            # Tunggu konfirmasi dari user
            echo -n "Tekan Enter setelah me-refresh browser..."
            read
        else
            echo -e "${RED}✗ Gagal push ke GitHub${NC}"
        fi
    else
        echo -e "${YELLOW}Tidak ada perubahan untuk disimpan${NC}"
    fi
}

# Update main loop untuk menjalankan init_git saat pertama kali
init_git

while true; do
    show_menu
    echo -n "Pilih menu (1-7): "
    read choice

    case $choice in
        1) change_site_name; save_changes ;;
        2) add_product; save_changes ;;
        3) remove_product; save_changes ;;
        4) list_products ;;
        5) update_from_github ;;
        6) push_to_github ;;
        7) echo -e "\n${GREEN}Terima kasih!${NC}"; exit 0 ;;
        *) echo -e "\n${RED}Pilihan tidak valid. Silakan coba lagi.${NC}" ;;
    esac

    if [[ $choice != "4" && $choice != "7" ]]; then
        echo -n -e "\nTekan Enter untuk kembali ke menu..."
        read
    fi
done 