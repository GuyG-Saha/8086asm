STACK SEGMENT STACK
    DB 100h DUP(?)
STACK ENDS

DATA SEGMENT
    my_array DB 4,7,2,16,5,8,0,9
    arr_size DW 8
	msg DB 'Count of even numbers: $'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK
start:
	mov ax, DATA
	mov ds, ax
	
	mov cx, [arr_size]
	mov si, 0 ;arr index
	mov bl, 0 ;our counter
	
user_loop:
	mov dl, [my_array+si]
	test dl, 1
	jnz odd_num
	
	inc bl
	
odd_num:
	inc si
	loop user_loop
	
	mov ah, 09h
	mov dx, OFFSET msg
	int 21h
	
	mov ah, 02h
	mov dl, bl
	or dl, 30h ;convert to ASCII for printing
	
	int 21h

exit:	
	MOV AH, 4Ch
    MOV AL, 00h
    INT 21h
	
CODE ENDS
END start