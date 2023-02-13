.model small, pascal, os_dos

.Stack
.CODE
start: 
; before we run a program, we have to resize our own memory
; so that the system have enough memory to run the other program
; we have to fit it to what we only need for our program and release
; the other (memory) to the system. We can compute the size in paragraph
; by using the SS, SP and the PSP. It must be in paragraph (16 bytes) 
; and the formula woud be (SS - PSP) + (SP >> 4) + 1.

push cs
pop ds
push es
mov ax, sp
mov bx, es
mov cl, 4
shr ax, cl
inc ax              ; add 1 just to make sure it's enough since other 
                    ; data may have been pushed to the stack
mov cx, ss
add ax, cx
sub ax, bx

mov es, bx          ; now resize it.
mov bx, ax
mov ah, 4Ah
int 21h

mov ax, 4b00h       ; and execute the program
mov dx, Offset filename_vntd
push ds
pop es
mov bx, Offset param_block
int 21h

mov ax, 4b00h
mov dx, Offset filename_solvbe
mov bx, Offset param_block
int 21h

mov ax, 4b00h
mov dx, Offset filename_as
mov bx, Offset param_block
pop cx
mov word ptr[param_block+2], cx
mov word ptr[param_block+4], 80h
int 21h

mov ah, 4ch
int 21h

filename_vntd   DB 'VNTD.COM', 0
filename_solvbe DB 'SOLVBE.EXE', 0
filename_as     DB 'AS1.EXE',0
param_empty     DB 01h, 0dh
param_block DW 0
            DD param_empty
            DD 0
            DD 0

end start