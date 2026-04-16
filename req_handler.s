.intel_syntax noprefix

.extern open
.extern read
.extern write
.extern close

.section .data
  res_msg:
    .ascii "HTTP/1.0 200 OK\r\n\r\n"

.global req_handler

.equ RES_MSG_SIZE, 0x13
                 # "GET " = 0x47455420 flipped
.equ GET_VAL,      0x20544547
                 # "POST" = 0x504f5354 flipped
.equ POST_VAL,     0x54534f50
                 # "\r\n\r\n" = 0x0d0a0d0a flipped
.equ HEADERS_END,  0x0a0d0a0d

.equ SPACE, 0x20

.equ GET_FILENAME_OFFSET,  0x4
.equ POST_FILENAME_OFFSET, 0x5

.equ BUF_SIZE, 0x2000 

.equ O_RDONLY,      0x0
.equ O_WRONLY,      0x1
.equ O_CREAT,       0x40

.section .text

req_handler:

  push r14
  push r15

  /* parse the request */

  # load the first 4 bytes (either "GET " or "POST")
  mov eax, [rdi]

  cmp eax, GET_VAL
  je get
  cmp eax, POST_VAL
  je post
  ret

  get:
    # mark beginning and ending of the filepath
    add rdi, GET_FILENAME_OFFSET
    # determine the end of the file path (by the first whitespace)
    # and put '\0' to mark the end of it
    mov rsi, rdi
    get_loop:
    mov al, [rsi]
    cmp al, SPACE
    je get_done
    inc rsi
    jmp get_loop
    get_done:
    mov byte ptr [rsi], 0x0

    mov rsi, O_RDONLY
    call open

    # save the opened fd
    mov r14, rax

    # read the contents of the requested file
    sub rsp, BUF_SIZE
    mov rdi, rax
    mov rsi, rsp
    mov rdx, BUF_SIZE
    call read

    # save the number of read bytes
    mov r15, rax

    # close the requested file
    mov rdi, r14
    call close

    call write_res_msg

    # write the contents
    mov rdi, r12
    mov rsi, rsp
    mov rdx, r15 # number of read bytes
    call write

    # restore the buffer
    add rsp, BUF_SIZE

    jmp end


  post:
    mov r14, rdi # save the buf*
    mov r15, rsi # save the number of read bytes

    # mark beginning and ending of the filepath
    add rdi, POST_FILENAME_OFFSET
    # determine the end of the file path (by the first whitespace)
    # and put '\0' to mark the end of it
    mov rsi, rdi
    post_loop:
      mov al, [rsi]
      cmp al, SPACE
      je post_done
      inc rsi
      jmp post_loop
      post_done:
      mov byte ptr [rsi], 0x0

    # find the content length by subtracting the request length
    # from the total length of the headers
    mov rdx, r14
    mov rax, 0x0 # counter
    length_loop:
      #0x0a0d0a0d
      cmp byte ptr [rdx], 0x0d
      jne next
      cmp byte ptr [rdx + 1], 0x0a
      jne next
      cmp byte ptr [rdx + 2], 0x0d
      jne next
      cmp byte ptr [rdx + 3], 0x0a
      je length_done
    next:
      inc rdx
      inc rax
      jmp length_loop
    length_done:
    add rdx, 0x4 # skip the \r\n\r\n
    add rax, 0x4
    mov r14, rdx
    sub r15, rax

    mov rsi, O_WRONLY | O_CREAT
    mov rdx, 0777
    call open

    push rax

    mov rdi, rax
    mov rsi, r14
    mov rdx, r15
    call write

    pop rdi
    call close

    call write_res_msg

    jmp end


  write_res_msg:
    # write the response message to the acceptfd
    mov rdi, r12
    lea rsi, [rip + res_msg]
    mov rdx, RES_MSG_SIZE
    call write
    ret

  end:
    pop r15
    pop r14
    ret
