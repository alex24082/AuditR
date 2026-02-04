#!/bin/bash
# AuditR - Tool CLI pentru audit de securitate pe Linux
# Autor: Mizea Vlad Alexandru (SC 31)

VERSION="1.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

OUTPUT_FORMAT="html"
OUTPUT_FILE=""
REZULTATE=""

banner() {
    echo -e "${BLUE}"
    if [ -f "$SCRIPT_DIR/asciiart" ]; then
        cat "$SCRIPT_DIR/asciiart"
        echo "                               v$VERSION"
    else
        echo "    AuditR v$VERSION"
    fi
    echo -e "${NC}"
}

ajutor() {
    banner
    echo "Utilizare: ./auditr.sh [optiuni]"
    echo ""
    echo "Optiuni:"
    echo "  -p    Verifica procese suspecte"
    echo "  -P    Verifica porturi deschise"  
    echo "  -m    Verifica permisiuni fisiere"
    echo "  -M    Verifica fisiere modificate recent"
    echo "  -a    Ruleaza toate verificarile"
    echo "  -f    Format output: html, json (implicit: html)"
    echo "  -o    Fisier output"
    echo "  -h    Afiseaza acest ajutor"
    echo ""
    echo "Exemple:"
    echo "  ./auditr.sh -a -f html -o raport.html"
    echo "  ./auditr.sh -p -P"
}

verifica_procese() {
    echo -e "${BLUE}[*] Verificare procese...${NC}"
    local output="=== PROCESE SUSPECTE ===\n"
    output+="Data: $(date)\n\n"
    
    output+="-- Procese cu CPU > 50% --\n"
    local high_cpu=$(ps aux --sort=-%cpu | awk 'NR>1 && $3>50 {print $0}')
    if [ -n "$high_cpu" ]; then
        output+="$high_cpu\n"
    else
        output+="[OK] Niciun proces cu CPU ridicat\n"
    fi
    
    output+="\n-- Procese cu nume suspecte --\n"
    local suspect=$(ps aux | grep -iE "nc|netcat|cryptominer|xmrig" | grep -v grep)
    if [ -n "$suspect" ]; then
        output+="[ATENTIE] Procese suspecte detectate:\n$suspect\n"
    else
        output+="[OK] Niciun proces suspect\n"
    fi
    
    output+="\n-- Top 5 procese dupa CPU --\n"
    output+="$(ps aux --sort=-%cpu | head -6)\n"
    
    REZULTATE+="$output\n"
    echo -e "${GREEN}[OK] Verificare procese completa${NC}"
}

get_ports_snapshot() {
    if command -v ss &> /dev/null; then
        ss -tuln 2>/dev/null
        return
    fi
    netstat -tuln 2>/dev/null
}

verifica_porturi() {
    echo -e "${BLUE}[*] Verificare porturi...${NC}"
    local output="=== PORTURI DESCHISE ===\n"
    output+="Data: $(date)\n\n"
    
    output+="-- Porturi TCP/UDP --\n"
    if command -v ss &> /dev/null; then
        output+="$(ss -tulnp 2>/dev/null | head -20)\n"
    else
        output+="$(netstat -tulnp 2>/dev/null | head -20)\n"
    fi
    
    output+="\n-- Verificare porturi suspecte --\n"
    local suspect_ports="23 21 4444 1337 31337"
    local ports_snapshot
    ports_snapshot="$(get_ports_snapshot)"
    local found=0
    for port in $suspect_ports; do
        if echo "$ports_snapshot" | grep -qE "[:.]$port\\b"; then
            output+="[ATENTIE] Port suspect deschis: $port\n"
            found=1
        fi
    done
    [ $found -eq 0 ] && output+="[OK] Niciun port suspect\n"
    
    REZULTATE+="$output\n"
    echo -e "${GREEN}[OK] Verificare porturi completa${NC}"
}

verifica_permisiuni() {
    echo -e "${BLUE}[*] Verificare permisiuni...${NC}"
    local output="=== PERMISIUNI FISIERE ===\n"
    output+="Data: $(date)\n\n"
    
    local fisiere="/etc/passwd /etc/shadow /etc/sudoers"
    
    output+="-- Fisiere critice --\n"
    for f in $fisiere; do
        if [ -f "$f" ]; then
            local perm=$(stat -c "%a" "$f" 2>/dev/null)
            local owner=$(stat -c "%U:%G" "$f" 2>/dev/null)
            output+="$f - permisiuni: $perm, proprietar: $owner\n"
        fi
    done
    
    output+="\n-- Fisiere world-writable in /etc --\n"
    local ww=$(find /etc -type f -perm -002 2>/dev/null | head -10)
    if [ -n "$ww" ]; then
        output+="[ATENTIE]\n$ww\n"
    else
        output+="[OK] Niciun fisier world-writable\n"
    fi
    
    REZULTATE+="$output\n"
    echo -e "${GREEN}[OK] Verificare permisiuni completa${NC}"
}

verifica_modificate() {
    echo -e "${BLUE}[*] Verificare fisiere modificate...${NC}"
    local output="=== FISIERE MODIFICATE (ultimele 24h) ===\n"
    output+="Data: $(date)\n\n"
    
    output+="-- Fisiere modificate in /etc --\n"
    local modified=$(find /etc -type f -mtime -1 2>/dev/null | head -15)
    if [ -n "$modified" ]; then
        output+="$modified\n"
    else
        output+="[OK] Niciun fisier modificat recent\n"
    fi
    
    REZULTATE+="$output\n"
    echo -e "${GREEN}[OK] Verificare fisiere modificate completa${NC}"
}

genereaza_html() {
    local file="$1"
    cat > "$file" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Raport AuditR</title>
    <style>
        body { font-family: Arial; background: #1a1a2e; color: #eee; padding: 20px; }
        .container { max-width: 900px; margin: auto; }
        h1 { color: #667eea; }
        pre { background: #0f0f23; padding: 15px; border-radius: 5px; overflow-x: auto; }
        .ok { color: #27ae60; }
        .atentie { color: #f39c12; }
    </style>
</head>
<body>
<div class="container">
    <h1>🛡️ Raport Audit Securitate</h1>
    <p><strong>Generat:</strong> $(date)</p>
    <p><strong>Hostname:</strong> $(hostname)</p>
    <hr>
    <pre>$(echo -e "$REZULTATE" | sed 's/\[OK\]/<span class="ok">[OK]<\/span>/g' | sed 's/\[ATENTIE\]/<span class="atentie">[ATENTIE]<\/span>/g')</pre>
    <hr>
    <p><em>Generat de AuditR v$VERSION</em></p>
</div>
</body>
</html>
EOF
    echo -e "${GREEN}[OK] Raport HTML salvat: $file${NC}"
}

genereaza_json() {
    local file="$1"
    local escaped=$(echo -e "$REZULTATE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    
    cat > "$file" << EOF
{
    "titlu": "Raport Audit AuditR",
    "versiune": "$VERSION",
    "data": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "rezultate": "$escaped"
}
EOF
    echo -e "${GREEN}[OK] Raport JSON salvat: $file${NC}"
}

main() {
    local do_procese=0
    local do_porturi=0
    local do_permisiuni=0
    local do_modificate=0
    
    while getopts "pPmMaf:o:h" opt; do
        case $opt in
            p) do_procese=1 ;;
            P) do_porturi=1 ;;
            m) do_permisiuni=1 ;;
            M) do_modificate=1 ;;
            a) do_procese=1; do_porturi=1; do_permisiuni=1; do_modificate=1 ;;
            f) OUTPUT_FORMAT="$OPTARG" ;;
            o) OUTPUT_FILE="$OPTARG" ;;
            h) ajutor; exit 0 ;;
            *) ajutor; exit 1 ;;
        esac
    done
    
    banner
    
    if [ $do_procese -eq 0 ] && [ $do_porturi -eq 0 ] && [ $do_permisiuni -eq 0 ] && [ $do_modificate -eq 0 ]; then
        echo -e "${RED}[!] Eroare: Nu ai selectat nicio verificare!${NC}"
        echo "Foloseste -h pentru ajutor"
        exit 1
    fi
    
    echo -e "\n${BLUE}=== Incep auditul ===${NC}\n"
    
    [ $do_procese -eq 1 ] && verifica_procese
    [ $do_porturi -eq 1 ] && verifica_porturi
    [ $do_permisiuni -eq 1 ] && verifica_permisiuni
    [ $do_modificate -eq 1 ] && verifica_modificate
    
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "\n${BLUE}[*] Generare raport...${NC}"
        case $OUTPUT_FORMAT in
            html) genereaza_html "$OUTPUT_FILE" ;;
            json) genereaza_json "$OUTPUT_FILE" ;;
            *) echo -e "${RED}Format necunoscut: $OUTPUT_FORMAT${NC}"; exit 1 ;;
        esac
    else
        echo -e "\n${BLUE}=== REZULTATE ===${NC}\n"
        echo -e "$REZULTATE"
    fi
    
    echo -e "\n${GREEN}[OK] Audit complet!${NC}"
}

main "$@"
