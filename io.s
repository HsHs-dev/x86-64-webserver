.intel_syntax noprefix

.global open
.global read
.global write
.global close


.equ SYS_READ,      0x0
.equ SYS_WRITE,     0x1
.equ SYS_OPEN,      0x2
.equ SYS_CLOSE,     0x3


.equ O_RDONLY,      0x0


.section .text

/*
open a given filepath name and return an fd to it
int open(const char *pathname, int flags);
*/
open:
  mov rsi, O_RDONLY
  mov rax, SYS_OPEN
  syscall
  ret

/*
read from an file descriptor to a buffer
ssize_t read(int fd, void *buf, size_t count);
*/
# all args are provided by the caller
read:
  mov rax, SYS_READ
  syscall
  ret

/*
write from a buf to a file descriptor
ssize_t write(int fd, const void* buf, size_t count)
*/
# all args are provided by the caller
write:
  mov rax, SYS_WRITE
  syscall
  ret

/**/
close:
  mov rax, SYS_CLOSE
  syscall
  ret
