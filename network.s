# contains wrappers for network functions
.intel_syntax noprefix

.global socket
.global bind
.global listen
.global accept

# network functions syscalls RAX value
.equ SYS_SOCKET,    0x29
.equ SYS_BIND,      0x31
.equ SYS_LISTEN,    0x32
.equ SYS_ACCEPT,    0x2b

# some functions parameters values
.equ AF_INET,       0x2     # IPv4 address family
.equ SOCK_STREAM,   0x1     # Connection-based (TCP)
.equ ANY,    0x0     # Bind to 0.0.0.0
.equ PORT_80,       0x5000  # Port 80 in Big Endian (0x0050 swapped)
.equ SOCKADDR_IN_SIZE, 0x10  # 16 bytes


.section .text

/*
create a network socket
int socket(int domain, int type, int protocol)
domain = AF_INET = 2
type = SOCK_STREAM = 1
protocol = default = 0
*/
socket:
  mov rdi, AF_INET
  mov rsi, SOCK_STREAM
  mov rdx, ANY
  mov rax, SYS_SOCKET
  syscall
  ret

/*
assigns the address specified by addr to 
the socket referred to by the file descriptor sockfd.
int bind(int sockfd, const struct sockaddr *addr,
         socklen_t addrlen);
sockfd = socket function return value
struct sockaddr_in {
  uint16_t  sin_family;
  uint16_t  sin_port;
  uint32_t  sin_addr;
  uint8_t   __pad[8];
}
addr = {AF_INET = 2, 80 (in big endian), ANY, 0}
*/
bind:

  # create the socket address struct (16 bytes) on the stack
  # specifically a struct sockaddr_in
  push rbp
  mov rbp, rsp
  sub rsp, SOCKADDR_IN_SIZE

  # uint16_t sin_family
  mov word ptr [rsp], AF_INET
  # uint16_t sin_port big endian
  mov word ptr [rsp + 2], PORT_80
  # uint32_t sin_addr
  mov dword ptr [rsp + 4], ANY
  # uint8_t __pad[8]
  mov qword ptr[rsp + 8], ANY

  # call bind with args
  # rdi contains the socketfd from the caller
  mov rsi, rsp
  mov rdx, SOCKADDR_IN_SIZE
  mov rax, SYS_BIND
  syscall

  mov rsp, rbp
  pop rbp
  ret

/*
marks the socket referred to by sockfd as a passive socket,
that is, as a socket that will be used to accept in coming connection requests 
int listen(int sockfd, int backlog)
*/
listen:
  # rdi contains the socketfd from the caller
  mov rsi, ANY
  mov rax, SYS_LISTEN
  syscall
  ret

/*
extracts the first connection request on the queue of pending connections for the 
listening socket, sockfd, 
creates a new connected socket, and returns a new file descriptor referring to that socket.
int accept(int sockfd, struct sockaddr addr, socklen_t addrlen);
*/
accept:
  # rdi contains the socketfd from the caller
  mov rsi, ANY
  mov rdx, ANY
  mov rax, SYS_ACCEPT
  syscall
  ret

