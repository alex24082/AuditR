# AuditR

Tool CLI pentru audit de securitate pe Linux.

Proiect pentru cursul de Sisteme de Operare.

Autor: **Mizea Vlad Alexandru**, grupa **SC 31**

---

## Ce face?

AuditR este un script Bash care verifica rapid cateva aspecte de securitate pe un sistem Linux:

- **Procese suspecte** - procese cu CPU ridicat sau nume suspecte
- **Porturi deschise** - listare porturi in ascultare + porturi suspecte
- **Permisiuni fisiere** - verificare fisiere critice din `/etc`
- **Fisiere modificate** - fisiere modificate in ultimele 24h (in `/etc`)

Poate genera rapoarte in format **HTML** sau **JSON**.

---

## Documentatie

- `DOCUMENTATIE.md` (documentatie extinsa)
- `DOCUMENTATIE_Mizea_Vlad_Alexandru_SC31.docx` (format Word)

---

## Instalare

```bash
git clone <repo>
cd AuditR
chmod +x auditr.sh
```

---

## Utilizare

```bash
# Ajutor
./auditr.sh -h

# Ruleaza toate verificarile
./auditr.sh -a

# Procese + porturi
./auditr.sh -p -P

# Raport HTML
./auditr.sh -a -f html -o raport.html

# Raport JSON
./auditr.sh -a -f json -o raport.json
```

### Optiuni

| Optiune | Descriere |
|---------|-----------|
| `-p` | Verifica procese suspecte |
| `-P` | Verifica porturi deschise |
| `-m` | Verifica permisiuni fisiere |
| `-M` | Verifica fisiere modificate |
| `-a` | Toate verificarile |
| `-f` | Format: `html` sau `json` |
| `-o` | Fisier output |
| `-h` | Ajutor |

---

## Docker

```bash
docker build -t auditr .
docker run --rm auditr -a
docker run --rm -v $(pwd)/output:/app/output auditr -a -f html -o /app/output/raport.html
docker-compose up
```

---

## Structura proiect

```
AuditR/
├── auditr.sh           # Script principal
├── asciiart            # Banner ASCII
├── Dockerfile          # Container Docker
├── docker-compose.yml  # Orchestrare Docker
├── output/             # Rapoarte generate
├── README.md           # Documentatie scurta
└── LICENSE             # Licenta
```

---

## Dependente

- `bash`
- `ps` (procps)
- `ss` sau `netstat` (iproute2/net-tools)
- `find` (findutils)
- `stat` (coreutils)

---

## Licenta

MIT License - vezi fisierul `LICENSE`.
