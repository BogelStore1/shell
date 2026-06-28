#!/usr/bin/env bash

set -e

REPO="https://github.com/BogelStore1/shell.git"
INSTALL_DIR="/opt/bogelshell-protect"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "==============================================="
echo "        BogelShell Protect Installer"
echo "==============================================="
echo -e "${NC}"

# Root check
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Installer dijalankan tanpa root.${NC}"
    if [ ! -w "/usr/local/bin" ]; then
        echo -e "${RED}Silakan jalankan menggunakan sudo atau root.${NC}"
        exit 1
    fi
fi

# Dependency check
for cmd in git bash base64 gzip rev awk sed grep; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${RED}Dependency tidak ditemukan: $cmd${NC}"
        exit 1
    fi
done

echo -e "${BLUE}Downloading project...${NC}"

rm -rf "$INSTALL_DIR"

git clone "$REPO" "$INSTALL_DIR"

chmod +x "$INSTALL_DIR/main.sh"

cat >/usr/local/bin/bogelshell <<EOF
#!/usr/bin/env bash
exec $INSTALL_DIR/main.sh "\$@"
EOF

chmod +x /usr/local/bin/bogelshell

echo
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN} Install berhasil${NC}"
echo -e "${GREEN}=========================================${NC}"
echo
echo "Jalankan dengan:"
echo
echo "    bogelshell"
echo
