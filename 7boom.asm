STACK SEGMENT STACK
    DB 100h DUP(?)
STACK ENDS

DATA SEGMENT
    msg1 DB 'Enter a digit (1-9): $'
    msgBoom DB 'BOOM! $'

DATA ENDS


CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK
	

exitToDOS macro
    mov ah, 4Ch
    mov al, 00h
    int 21h
endm

newLineOutput macro
	; הדפסת ירידת שורה אסתטית (CRLF) כדי שהרצף יתחיל בשורה חדשה
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    mov ah, 02h
    int 21h
endm

	
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
	
	mov bl, al
	mov bh, 1
	
	newLineOutput
	
cnt_loop:
	cmp bh, bl
	ja end_game
	
	cmp bh, 7
	je print_boom
	
	mov dl, bh
	add dl, 30h
	mov ah, 02h
	int 21h
	jmp print_space
	
print_boom:
	mov ah, 09h
	mov dx, OFFSET msgBoom
	int 21h
	inc bh
	jmp cnt_loop
	
	
print_space:
    mov dl, ' '
    mov ah, 02h
    int 21h
    inc bh               ; קידום הרץ למספר הבא
    jmp cnt_loop         ; חזרה לראש הלולאה
	
end_game:
    exitToDOS
	
	
CODE ENDS
END start	