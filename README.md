# PayloadCrafter 🛠️  
**Red Team Payload Generator Script – by EveRoy**

PayloadCrafter is an interactive Bash-based tool designed to simplify the generation of Metasploit payloads. It guides the user through payload selection, formatting options, advanced configurations, and even allows injection into existing EXE files. The script automatically saves the payload, uploads it to an Apache web server, and generates a Metasploit `listener.rc` file for easy use.

---

## ✨ Features

- Interactive payload selection (Windows, Linux, Python, etc.)
- Supports multiple output formats: `exe`, `dll`, `raw`, `asp`, `php`, `elf`, `macho`
- Option to inject the payload into an existing EXE using `-x -k`
- Advanced options support: `PrependMigrate`, `EXITFUNC`, `HttpUserAgent`
- Automatically uploads the payload to Apache (`/var/www/html/`)
- Creates a ready-to-use Metasploit `listener.rc` file
- Option to immediately launch the listener using `msfconsole`

---

## ⚙️ Requirements

The script will install the following tools if not already installed:

- `msfvenom` (part of the Metasploit Framework)
- `figlet`, `toilet` – for banner styling
- `ruby` and `lolcat` – for colorful output
- `apache2` – to serve the payload over HTTP
- Tested on Debian/Ubuntu-based systems

---

## 🚀 Usage

1. Make the script executable:
   ```bash
   chmod +x PayloadCrafter.sh
