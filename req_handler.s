.intel_syntax noprefix

.extern open
.extern read
.extern write
.extern close

.section .rodata
hello_msg:
    .ascii "HTTP/1.1 200 OK\r\n"
    .ascii "Content-Type: text/html; charset=utf-8\r\n"
    .ascii "Connection: close\r\n\r\n"
    .ascii "<!DOCTYPE html>\n"
    .ascii "<html>\n"
    .ascii "<head>\n"
    .ascii "<style>\n"
    .ascii "  body { background-color: #0f172a; color: #f8fafc; font-family: system-ui, sans-serif; "
    .ascii "         display: flex; flex-direction: column; justify-content: center; align-items: center; "
    .ascii "         height: 100vh; margin: 0; }\n"
    .ascii "  .card { background: #1e293b; padding: 2.5rem; border-radius: 12px; "
    .ascii "          box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.5); border: 1px solid #334155; "
    .ascii "          text-align: center; max-width: 400px; margin-bottom: 2rem; }\n"
    .ascii "  h1 { color: #38bdf8; margin-top: 10px; }\n"
    .ascii "  p { color: #94a3b8; line-height: 1.6; }\n"
    .ascii "  .tag { background: #0ea5e9; color: white; padding: 0.25rem 0.75rem; "
    .ascii "         border-radius: 9999px; font-size: 0.8rem; font-weight: bold; }\n"
    .ascii "  footer { color: #64748b; font-size: 0.9rem; font-weight: 500; }\n"
    .ascii "</style>\n"
    .ascii "</head>\n"
    .ascii "<body>\n"
    .ascii "  <div class='card'>\n"
    .ascii "    <span class='tag'>x86_64 Assembly</span>\n"
    .ascii "    <h1>Server Online</h1>\n"
    .ascii "    <p>This page was served directly from an assembly-based web server using Linux system calls.</p>\n"
    .ascii "  </div>\n"
    .ascii "  <footer>Made with ❤️ by Hassan Siddig</footer>\n"
    .ascii "</body>\n"
    .ascii "</html>\n"
hello_msg_end:

.global req_handler

.equ HELLO_MSG_SIZE, hello_msg_end - hello_msg
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
    lea rsi, [rip + hello_msg]
    mov rdx, HELLO_MSG_SIZE
    call write
    ret

  end:
    pop r15
    pop r14
    ret
