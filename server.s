.intel_syntax noprefix
.global _start
_start:


# call socket
###################################################
# create socket
# socket(AF_INET, SOCK_STREAM, 0)
# AF_INET = 2
# SOCK_STREAM = 1
mov rdi, 2
mov rsi, 1
mov rdx, 0
mov rax, 0x29
syscall
###################################################


# call bind
################################################### call bind
# int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);

# put the struct (16 bytes) on the stack
push rbp
mov rbp, rsp
sub rsp, 0x10

# uint16_t sin_family
mov word ptr [rsp], 0x2

# uint16_t sin_port big endian
mov byte ptr [rsp + 2], 0x00
mov byte ptr [rsp + 3], 0x50

# uint32_t sin_addr
mov dword ptr [rsp + 4], 0x0

# uint8_t __pad[8]
mov qword ptr[rsp + 8], 0x0

# save socket fd before calling bind
mov rbx, rax

# call bind with args
mov rdi, rax
mov rsi, rsp
mov rdx, 0x10
mov rax, 0x31
syscall

# inc stack
add rsp, 0x10
###################################################

# save the socket fd on the stack
sub rsp, 0x8
mov [rsp], rbx

# call listen
###################################################
mov rdi, rbx
mov rsi, 0x0
mov rax, 0x32
syscall
###################################################


accept:

# rbx has the socket fd
mov rbx, [rsp]

# call accept
###################################################
mov rdi, rbx
mov rsi, 0x0
mov rdx, 0x0
mov rax, 0x2B
syscall
###################################################

# save accept fd
mov rbx, rax

# fork process
mov rax, 0x39
syscall

# determine flow depends on either child or parent process
sub rsp, 0x8
mov [rsp], rax # save the returned value
cmp rax, 0x0
jnz parent

# close the socket file descriptor in the child's process
mov rdi, [rsp + 0x8]
mov rax, 0x3
syscall

# call read
sub rsp, 0x100
mov rdi, rbx
mov rsi, rsp
mov rdx, 0x100
mov rax, 0x0
syscall

# rdi has the start of the file path: "GET /flag HTTP/1.0\r\n\r\n"
mov rdi, rsp
add rdi, 0x4

# determine the end of the file path (by the first whitespace) and put '\0' to mark the end
mov rsi, rdi
loop:
  mov al, [rsi]
  cmp al, ' '
  je done
  inc rsi
  jmp loop
done:
mov byte ptr [rsi], 0x0

# call open on the file path
# int open(const char *pathname, int flags, mode_t mode);
# filepath name already in rdi
mov rsi, 0x0 # O_RDONLY
mov rax, 0x2
syscall

# save the flag file fd
mov r12, rax

# inc stack
add rsp, 0x100

# read the contents of the flag file

sub rsp, 0x100 # allocate a buffer to read to on the stack
mov rdi, rax # fd returned by open
mov rsi, rsp # buf
mov rdx, 0x100
mov rax, 0x0
syscall

# save the number of read bytes
mov r13, rax

# close the opened flag file
mov rdi, r12
mov rax, 0x3
syscall


# write the response message: HTTP/1.0 200 OK\r\n\r\n
sub rsp, 0x18 # allocate 19 bytes on the stack (24 to be alligned)
# push raw bytes 485454502f312e30 20323030204f4b0d 0a0d0a0000000000
mov rax, 0x302e312f50545448
mov qword ptr [rsp], rax
mov rax, 0x0d4b4f2030303220
mov qword ptr [rsp + 8], rax
mov rax, 0x00000000000a0d0a
mov qword ptr [rsp + 16], rax

# call write
# ssize_t write(size_t count;
#                    int fd, const void buf[count], size_t count);
mov rdi, rbx # file descriptor
mov rsi, rsp
mov rdx, 0x13
mov rax, 0x1
syscall

# inc stack
add rsp, 0x18

# write the flag
mov rdi, rbx
mov rsi, rsp
mov rdx, r13
mov rax, 0x1
syscall

# restore the flag file buffer
add rsp, 0x100

parent:

# close file
mov rdi, rbx
mov rax, 0x3
syscall

# if parent, go to accept, if child, close the file and terminate
mov rax, [rsp]
add rsp, 0x8
cmp rax, 0x0
jnz accept

# exit
add rsp, 0x8
mov rsp, rbp
pop rbp
mov rdi, 0x0
mov rax, 0x3C
syscall
