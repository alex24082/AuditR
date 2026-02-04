# AuditR — Documentatie proiect

Student: **Mizea Vlad Alexandru**  
Grupa: **SC 31**  
Curs: Sisteme de Operare  
Data: 2026-02-05

## Rezumat

AuditR este un utilitar tip **CLI** (Command Line Interface) scris in **Bash**, care realizeaza un audit rapid de securitate pentru un sistem Linux. Scopul proiectului este sa ofere o imagine de ansamblu asupra unor indicatori uzuali: procese cu utilizare ridicata a CPU, procese cu nume suspecte, porturi deschise, permisiuni pentru fisiere critice si modificari recente in directoare sensibile (ex. `/etc`). Rezultatele pot fi afisate in terminal sau exportate in rapoarte **HTML** / **JSON**.

Proiectul este gandit ca un instrument educational: demonstreaza utilizarea comenzilor standard (`ps`, `ss`/`netstat`, `find`, `stat`) si prelucrarea output-ului lor in Bash, impreuna cu generarea de fisiere de raport.

## Descriere

AuditR este un script Bash care ruleaza un set de verificari de baza pentru securitatea unui sistem Linux si poate exporta rezultatele in format **HTML** sau **JSON**.

## Functionalitati

- **Procese suspecte**
  - listare procese cu CPU > 50%;
  - cautare procese cu nume asociate unor unelte frecvent folosite in atacuri (ex. `nc`, `netcat`, `xmrig`).
- **Porturi deschise**
  - listare socket-uri in ascultare (TCP/UDP) cu `ss` sau `netstat`;
  - cautare intr-o lista scurta de porturi considerate „suspecte” (ex. 21, 23, 4444, 1337, 31337).
- **Permisiuni fisiere**
  - afisare permisiuni si proprietar pentru fisiere critice (`/etc/passwd`, `/etc/shadow`, `/etc/sudoers`);
  - detectie fisiere world-writable in `/etc` (permisiuni `o+w`).
- **Fisiere modificate recent**
  - listare fisiere din `/etc` modificate in ultimele 24h.

## Obiective si motivatie

In practica, un audit complet de securitate necesita instrumente specializate (ex. Lynis, OpenSCAP), politici de hardening si corelarea logurilor. Totusi, intr-un context educational, este util un script care:

- ruleaza rapid si fara instalari complexe;
- foloseste un set mic de comenzi „standard” (preinstalate);
- produce output usor de interpretat;
- poate fi rulat local sau in container, pentru a demonstra izolarea mediului.

AuditR nu inlocuieste un audit profesionist, dar poate fi folosit ca checklist minimal si ca punct de plecare pentru extinderi.

## Dependente

Necesita utilitare standard prezente pe majoritatea distributiilor:
- `bash`
- `ps` (procps)
- `ss` (iproute2) sau `netstat` (net-tools)
- `find` (findutils)
- `stat` (coreutils)

## Structura proiectului

```
AuditR/
├── auditr.sh           # Scriptul principal
├── asciiart            # Banner ASCII (folosit la pornire)
├── Dockerfile          # Build container
├── docker-compose.yml  # Orchestrare simpla
├── output/             # Director pentru rapoarte (optional)
├── README.md           # Documentatie scurta
├── DOCUMENTATIE.md     # Documentatie extinsa (acest fisier)
└── LICENSE             # Licenta proiectului
```

## Instalare

```bash
git clone <repo>
cd AuditR
chmod +x auditr.sh
```

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

## Descriere functionala (cum lucreaza scriptul)

### 1) Prelucrarea argumentelor

Scriptul foloseste `getopts` pentru a seta ce verificari sunt rulate. Optiunea `-a` activeaza toate verificarile. Daca utilizatorul nu selecteaza nicio verificare, scriptul afiseaza eroare si iese cu cod diferit de 0.

Avantaje:
- implementare standard in Bash;
- usor de extins cu noi optiuni;
- compatibilitate ridicata.

### 2) Colectarea informatiilor

AuditR colecteaza date folosind comenzi standard:

- `ps aux --sort=-%cpu` pentru procesele cu consum ridicat de CPU;
- `ps aux | grep -iE ...` pentru procese cu nume suspecte;
- `ss -tulnp` (sau `netstat -tulnp`) pentru porturi deschise;
- `stat -c "%a"`, `stat -c "%U:%G"` pentru permisiuni/proprietar;
- `find /etc ...` pentru fisiere world-writable si fisiere modificate recent.

Rezultatele sunt agregate intr-o variabila globala si apoi afisate sau exportate.

### 3) Detectie procese suspecte

Verificarea de procese include doua idei simple:

1. Procese cu CPU > 50% pot indica incarcari neobisnuite (de exemplu, minerit, bucle infinite, servicii compromise).
2. Procesele cu nume asociate unor utilitare (ex. `nc`, `netcat`) pot semnala activitati de tip remote shell/transfer neautorizat.

Limitare: „nume suspect” nu inseamna automat comportament rau intentionat; rezultatul trebuie interpretat in context (ex. in laboratoare, `nc` poate fi folosit legitim).

### 4) Porturi deschise si porturi suspecte

Porturile in ascultare sunt listate cu `ss` (preferat) sau `netstat`. Apoi scriptul cauta o lista de porturi adesea asociate cu servicii nesigure sau cu backdoor-uri demo.

Observatie: lista de porturi este intentionat scurta (pentru simplitate). Intr-un audit real, se face corelare cu serviciile asteptate (ex. 22/SSH) si cu firewall-ul.

### 5) Permisiuni si fisiere critice

Se verifica trei fisiere considerate sensibile:

- `/etc/passwd` (conturi utilizatori)
- `/etc/shadow` (hash-uri parole)
- `/etc/sudoers` (drepturi sudo)

Scriptul afiseaza permisiunile si proprietarul, apoi cauta fisiere world-writable in `/etc`. Un fisier world-writable in `/etc` este, in general, un red flag.

### 6) Modificari recente in `/etc`

Modificarile recente in `/etc` pot indica schimbari de configuratie, instalari, update-uri sau compromiteri. Scriptul afiseaza pana la un numar limitat de rezultate pentru a mentine raportul compact.

## Formate de raport

### Raport in terminal

Cand nu este specificat `-o`, scriptul afiseaza rezultatul in terminal, grupat pe sectiuni.

### Raport HTML

Raportul HTML este util pentru:
- partajare (trimis ca fisier);
- arhivare;
- lizibilitate (culori pentru `[OK]` si `[ATENTIE]`).

Nota: in HTML, marcajele `[OK]` si `[ATENTIE]` sunt evidentiata cu stiluri CSS simple.

### Raport JSON

Formatul JSON este potrivit pentru:
- integrare in pipeline-uri;
- procesare ulterioara (ex. cu `jq`);
- import intr-un sistem de raportare.

Scriptul face o escapare de baza pentru caracterele `\` si `"` si transforma newline-urile in `\\n`.

## Docker

```bash
docker build -t auditr .
docker run --rm auditr -a
docker run --rm -v $(pwd)/output:/app/output auditr -a -f html -o /app/output/raport.html
docker-compose up
```

## Exemple de rulare si interpretare

### Scenariul 1: sistem curat (asteptat)

- Procese CPU > 50%: nimic (status `[OK]`)
- Porturi suspecte: nimic (status `[OK]`)
- Permisiuni: proprietar root si permisiuni restrictive pentru `/etc/shadow`
- Fisiere modificate recent: cateva fisiere (daca au existat update-uri), de verificat manual

### Scenariul 2: port suspect

Daca este gasit un port suspect, raportul va contine:

```
[ATENTIE] Port suspect deschis: 4444
```

Interpretare: portul in sine nu confirma compromiterea, dar trebuie verificat procesul asociat (ex. prin `ss -tulnp | grep 4444`) si configuratia firewall-ului.

## Limitari

- Detectia este euristica; poate produce false positive/false negative.
- Verificarea fisierelor modificate este limitata la `/etc` si la ultimile 24h.
- Scriptul nu coreleaza cu loguri (ex. `/var/log/auth.log`) si nu verifica configuratii de hardening.
- HTML-ul este minimal; nu include grafice sau agregari.

## Posibile imbunatatiri

- Extinderea listei de verificari (ex. utilizatori cu UID 0, servicii enabled, reguli firewall).
- Export JSON structurat pe sectiuni (nu doar un string mare).
- Praguri configurabile (CPU, lista porturi).
- Optiune pentru a salva automat in `output/` cu timestamp.
- Integrare cu `systemd` (service/timer pentru rulare periodica).

## Consideratii etice si de securitate

AuditR colecteaza informatii locale; nu scaneaza reteaua si nu transmite date. Totusi:

- rularea trebuie facuta doar pe sisteme unde utilizatorul are drept de audit;
- output-ul poate contine informatii sensibile (ex. porturi deschise, configuratii), deci raportul trebuie protejat.

## Concluzie

AuditR ofera o baza simpla pentru un audit local de securitate, usor de inteles si de extins. Proiectul demonstreaza folosirea utilitarelor standard Linux impreuna cu procesarea output-ului lor in Bash, plus generarea de rapoarte in formate utile (HTML/JSON).

## Bibliografie (resurse)

- `man bash`, `man getopts`
- `man ps`, `man ss`, `man netstat`
- `man find`, `man stat`
