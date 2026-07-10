MODEL small
STACK 100h
DATASEG
    ; --- מיקום התחלתי של הריבוע (הפינה השמאלית-עליונה) ---
    x     dw 150
    y     dw 90
    color db 4       ; אדום
    len   dw 20      ; גודל הריבוע (20x20 פיקסלים)
CODESEG

; ==========================================================
; הגדרות המקרואים (בסינטקס סטנדרטי)
; ==========================================================
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

quitGame macro
    mov ax, 4c00h   
    int 21h
endm

; ==========================================================
; הפרוצדורות שאתה בנית (חסינות מפני הריסת אוגרים ומשתנים)
; ==========================================================
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
    push [x]         ; שומר על ה-X המקורי בתחילת השורה
    
    mov cx, [len]    
pixelLoop:
    call drawPixel   
    inc [x]          
    loop pixelLoop   
    
    pop [x]          ; מחזיר את ה-X שמאלה בסיום השורה
    pop cx           
    ret
drawLine endp

drawSquare proc
    push cx
    push [y]         ; שומר על ה-Y המקורי בראש הריבוע
    
    mov cx, [len]
lineloop:
    call drawLine
    inc [y]          ; יורד שורה אחת למטה
    loop lineloop
    
    pop [y]          ; מחזיר את ה-Y למעלה בסיום הריבוע
    pop cx
    ret
drawSquare endp

; ==========================================================
; נקודת הזינוק ולולאת המשחק הראשית (Game Loop)
; ==========================================================
start:
    setDS
    graphicMode      ; כניסה ראשונית למצב גרפי

game_loop:
    ; --- שלב 1: מחיקת המסך ---
    ; הפעלה מחדש של מצב 13h מנקה את הריבוע הקודם ומונעת "זנב" של מריחה
    graphicMode      

    ; --- שלב 2: ציור הריבוע במיקום הנוכחי שלו ---
    call drawSquare  

    ; --- שלב 3: לולאת השהייה (Delay) ---
    ; מונע מהריבוע לטוס מהר מדי בגלל המעבדים המודרניים
    mov cx, 0ffffh
delay_loop:
    nop
    loop delay_loop

    ; --- שלב 4: בדיקת מקלדת (האם נלחץ מקש?) ---
    mov ah, 01h
    int 16h
    
    ; טריק ה"קפיצה ההפוכה" שלמדנו כדי למנוע שגיאות מרחק (Out of range)
    jnz key_was_pressed  ; אם נלחץ מקש -> קפוץ קדימה לקרוא אותו
    jmp game_loop        ; אם לא נלחץ מקש -> קפוץ חזרה למחיקה וציור מחדש

key_was_pressed:
    ; קריאת המקש האמיתי מחוצץ המקלדת
    mov ah, 00h
    int 16h

    ; --- שלב 5: ניתוח המקש ועדכון המיקום בזיכרון ---
    cmp al, 'a'
    je move_left
    cmp al, 'd'
    je move_right
    cmp al, 'w'
    je move_up
    cmp al, 's'
    je move_down
	cmp ah, 48h
	je move_up
	cmp ah, 50h
	je move_down
	cmp ah, 4Bh
	je move_left
	cmp ah, 4Dh
	je move_right
    cmp al, 27d         ; מקש Esc (קוד אסקי 27) לסיום המשחק
    je exit_program
    jmp game_loop       ; אם נלחץ מקש לא קשור, פשוט חזור ללולאה

; --- בלוקים של תזוזה (זזים 5 פיקסלים בכל לחיצה) ---
move_left:
    sub [x], 5
    jmp game_loop

move_right:
    add [x], 5
    jmp game_loop

move_up:
    sub [y], 5
    jmp game_loop

move_down:
    add [y], 5
    jmp game_loop

; --- יציאה מסודרת מהתוכנית ---
exit_program:
    textMode         ; חזרה למצב טקסט רגיל של דוס
    quitGame         ; יציאה למערכת ההפעלה

END start