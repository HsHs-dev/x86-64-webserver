.intel_syntax noprefix

.extern open
.extern read
.extern write
.extern close

.section .data
  res_msg:
    # TODO: not sure about memory alignment
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

.equ BUF_SIZE, 0x100

.section .text

req_handler:

  /* parse the request */

  # load the first 4 bytes (either "GET " or "POST")
  mov eax, [rdi]

  cmp eax, GET_VAL
  je get
  cmp eax, POST_VAL
  je post
  jmp unkown_method



  get:
    # mark beginning and ending of the filepath
    add rdi, GET_FILENAME_OFFSET
    # determine the end of the file path (by the first whitespace)
    # and put '\0' to mark the end of it
    mov rsi, rdi
    loop:
    mov al, [rsi]
    cmp al, SPACE
    je done
    inc rsi
    jmp loop
    done:
    mov byte ptr [rsi], 0x0

    call open

    # save the opened fd
    push rax

    # read the contents of the requested file
    sub rsp, BUF_SIZE
    mov rdi, rax
    mov rsi, rsp
    mov rdx, BUF_SIZE
    call read

    # restore the opened fd
    pop rdi

    # save the number of read bytes
    push rax

    # close the requested file 
    call close

    call write_res_msg

    # write the contents
    mov rdi, rbx
    mov rsi, rsp
    pop rdx # number of read bytes
    call write

    # restore the buffer
    add rsp, BUF_SIZE

    ret


  post:
    # TODO



  write_res_msg:
    # write the response message to the acceptfd
    mov rdi, r12
    mov rsi, res_msg
    mov rdx, RES_MSG_SIZE
    call write
    ret

ret
