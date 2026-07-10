MODEL small
STACK 100h
DATASEG
	x dw 100
	y dw 100
	color db 3
	len dw 30
CODESEG

setDS macro
	mov ax, @data
	mov ds, ax
endm

graphicMode macro
	mov ax, 13h
	int 10h
endm

textMode macro
	mov ax, 3h
	int 10h
endm

wait4key macro
	mov ah, 00h
	int 16h
endm

quitGame macro
    mov ax, 4c00h   
    int 21h
endm

drawPixel proc
	push ax bx cx dx
	mov bh, 0h
	mov cx, [x]
	mov dx, [y]
	mov al, [color]
	mov ah, 0ch
	int 10h
	pop dx cx bx ax
ret
drawPixel endp

drawLine proc
    push cx          
    push [x]         
    mov cx, [len]    
pixelLoop:
    call drawPixel   
    inc [x]          
    loop pixelLoop   
  
    pop [x]          
    pop cx           
    ret
drawLine endp

drawSquare proc
	push cx
	push [y]
	mov cx, [len]
lineloop:
	call drawLine
	inc [y]
	loop lineloop
	
	pop [y]
	pop cx
	ret
drawSquare endp	

start:
	setDS
	graphicMode
	mov cx, 20
	call drawSquare
	wait4key
	textMode

exit:
    quitGame
	
END start