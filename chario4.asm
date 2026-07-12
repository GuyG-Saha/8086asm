STACK SEGMENT STACK
    DB 100h DUP(?)
STACK ENDS

DATA SEGMENT
    msg1 DB 'Enter a digit (1-9): $'
    msg2 DB 13, 10, 'Foobar$'

DATA ENDS


CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK
	
start:
	mov ax, DATA
	mov ds, ax
	
get_user_input:	
	mov ah, 09h
	mov dx, OFFSET msg1
	int 21h

	mov ah, 01h
	int 21h
	
	sub al, 30h
	cmp al, 0
	je get_user_input
	
	mov ch, 00h
	mov cl, al
	
out_loop:
	mov ah, 09h
	mov dx, OFFSET msg2
	int 21h
	loop out_loop

	MOV AH, 4Ch
    MOV AL, 00h
    INT 21h
	
CODE ENDS
END start	