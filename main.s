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

.equ SYS_FORK,     0x39
.equ SYS_EXIT,     0x3c 
.equ EXIT_SUCCESS, 0x0


.section .text
  .global _start


_start:




call socket

save socketfd

call bind

call listen

call accept

save accept fd

fork

handle the request

if parent: close and go to accept

if child: close and terminate

