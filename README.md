# CDT-Redteamtool - Support Wheel 

Support Wheel is a Linux userland red team tool created for CSEC-473 class.
It's main purpose is to deploy client agents into a machine, and establish persistent through 
various userland payloads in linux. 

![Support Wheel](/diagram.PNG)

## Components 

Support Wheel has three major components 
* **C2** - Command & Control server, client, and master 
  * **Server:** Handles all incoming/outgoing traffic between the client and the server 
  * **Client:** Agent deployed in victim machines, handles commands, sends back output to the server 
  * **Master:** Actual shell environment to send commands to all the clients through the server 
  
* **Deploy** - Deploys all the necessary payloads on the victim machine 

* **Payloads** - Various payloads to deploy client.py and establish persistence 
  * **backdoor users** - Multiple users with UID of 0, multiple users with low-number UIDs
  * **revman** - A service which runs reverse shell payload every 1 minute
  * **copyman** - A service which overwrites sshd_config, sudoers, pam common-auth every 5 seconds  
  * **.bashrc** - Runs reverse shell 
  * **cronjob** - Runs reverse shell 
  * **Shimmed binaries** - Hides Support Wheel related strings 
    * ps 
    * netstat 
    * iptables - Flushes iptables 

## Installation 

Linux: 

`cd /opt; git clone https://github.com/choisg/cdt-redteamtool.git`

`/opt/cdt-redteamtool/rev_setup.sh`

`<Transfer over the /tmp/cdt-redteamtool.tar to target machine>`

`scp /tmp/cdt-redteamtool.tar <user>@<ip>:/opt/`

`(target machine) tar xvf /opt/cdt-redteamtool`

`(target machine) /opt/cdt-redteamtool/deploy.sh`


## DISCLAIMER
Support Wheel is a proof of concept tool which is only created for educational purposes in classroom and competitions. This tool is not created, nor is good enough for any real world usage. I do not condone use of this tool anything other than educational purposes. 

## Credits 
Support Wheel was inspired by https://github.com/ritredteam and @micahjmartin's TrainingWheelsProtocol (https://github.com/RITRedteam/TrainingWheelsProtocol). 

Special thanks to @oneNutW0nder
