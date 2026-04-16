.intel_syntax noprefix

# network functions
.extern socket
.extern bind
.extern listen
.extern accept

# IO functions
.extern open
.extern read
.extern write
.extern close

# parser
.extern req_handler

.equ SYS_FORK,     0x39
.equ SYS_EXIT,     0x3c 
.equ EXIT_SUCCESS, 0x0 
.equ BUF_SIZE,     0x100 

.section .text
  .global _start

_start:

# prolouge
push rbp
mov rbp, rsp

call socket

# save the created socketfd
# rbx is a callee saved register
mov rbx, rax

mov rdi, rbx
call bind

mov rdi, rbx
call listen

mov rdi, rbx
call accept

# requests accepting block
accept:

  # save the acceptfd
  mov r12, rax

  # fork to serve requests concurrently
  mov rax, SYS_FORK
  syscall

  # save the process id
  mov r13, rax

  # childID = 0, pid != 0
  cmp rax, 0x0
  jnz parent

  /*
  we are in child process
  */

  /*
  close the socketfd because we won't be accepting
  new requests in the child
  */
  mov rdi, rbx
  call close

  # allocate a buffer to read the request into
  sub rsp, BUF_SIZE
  mov rdi, r12
  mov rsi, rsp
  mov rdx, BUF_SIZE
  call read

  # parse and fullfil the request
  mov rdi, rsp
  call req_handler

  # restore the buffer
  add rsp, BUF_SIZE

  parent:
    # close acceptfd
    mov rdi, r12
    call close

    # if parent, accept a new request
    # if child terminate the program
    mov rax, r13
    cmp rax, 0x0
    jnz accept


# epilouge
mov rsp, rbp
pop rbp
mov rdi, EXIT_SUCCESS
mov rax, SYS_EXIT
syscall

