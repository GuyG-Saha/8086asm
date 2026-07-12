STACK SEGMENT STACK
    DB 100h DUP(?)
STACK ENDS

DATA SEGMENT
    my_array DB 24,7,3,10,11,19,0,1
    arr_size DW 8
	msg_even DB 13, 10, 'EVEN$'
	msg_odd DB 13, 10, 'ODD$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK
start:
	mov ax, DATA
	mov ds, ax
	
	mov cx, [arr_size]
	mov si, 0 ;arr index
	
user_loop:
	mov dl, [my_array+si]
	test dl, 1
	jnz odd_num
even_num:
    mov ah, 09h
	mov dx, OFFSET msg_even
	int 21h
	inc si
	loop user_loop
	
odd_num:
	mov ah, 09h
	mov dx, OFFSET msg_odd
	int 21h
	inc si
	loop user_loop
	
exit:	
	MOV AH, 4Ch
    MOV AL, 00h
    INT 21h
	
CODE ENDS
END start