MODEL small
STACK 100h
DATASEG
    ; משתנים זמניים עבור פרוצדורות הציור שלך
    x     dw 0
    y     dw 0
    color db 4       ; אדום
    len   dw 10      ; גודל כל ריבוע בנחש (10x10 פיקסלים)

    ; --- מערכים עבור מיקומי חלקי הנחש (עד 50 חלקים) ---
    ; נאתחל נחש באורך 4 איברים שיושבים אחד ליד השני בזיכרון
    snake_x    dw 150, 140, 130, 120, 46 dup(0)
    snake_y    dw 100, 100, 100, 100, 46 dup(0)
    snake_len  dw 4

    ; כיוון תנועה נוכחי (לפי קוד סריקה של החיצים)
    ; 4Dh מייצג חץ ימינה - הנחש יתחיל לזוז ימינה אוטומטית ברגע שהמשחק נפתח
    current_dir db 4Dh
CODESEG

; ==========================================================
; מקרואים (סינטקס סטנדרטי)
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
; הפרוצדורות המקוריות שלך (בדיוק כפי שכתבת אותן!)
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

; ==========================================================
; פרוצדורה חדשה: סריקת המערך וציור הנחש השלם
; ==========================================================
drawSnake proc
    push cx
    push si
    
    mov cx, [snake_len]   ; מספר הריבועים שצריך לצייר
    mov si, 0             ; אינדקס התחלתי במערך (0, 2, 4...)
    
draw_loop:
    push cx
    ; שליפת הקואורדינטות מהמערך והשמתן במשתנים הזמניים שאתה הגדרת
    mov ax, [snake_x + si]
    mov [x], ax
    mov ax, [snake_y + si]
    mov [y], ax
    
    call drawSquare       ; קריאה לפרוצדורה שלך שמציירת ריבוע בודד!
    
    add si, 2             ; מעבר לאיבר הבא במערך (dw = 2 בתים בזיכרון)
    pop cx
    loop draw_loop
    
    pop si
    pop cx
    ret
drawSnake endp

; ==========================================================
; נקודת הזינוק ולולאת המשחק הראשית
; ==========================================================
start:
    setDS
    graphicMode

game_loop:
    graphicMode           ; ניקוי מסך מלא (מונע מריחה של הנחש)
    
    call drawSnake        ; ציור הנחש השלם במיקומו הנוכחי

    ; לולאת השהייה מקוננת (כדי שהנחש יזחול בקצב הגיוני ב-DOSBox)
    mov cx, 6
delay_outer:
    push cx
    mov cx, 0ffffh
delay_inner:
    nop
    loop delay_inner
    pop cx
    loop delay_outer

    ; בדיקת מקלדת ללא עצירה (הנחש ממשיך לזחול גם אם לא לחצנו על כלום!)
    mov ah, 01h
    int 16h
    jnz key_pressed
    jmp update_movement   ; אם לא נלחץ מקש, המשך לזחול בכיוון הנוכחי

key_pressed:
    mov ah, 00h           ; קריאת המקש שנלחץ מחוצץ המקלדת
    int 16h
    
    cmp al, 27d           ; מקש Esc - יציאה מהמשחק
    je exit_program
    
    ; עדכון כיוון התנועה בזיכרון (רק אם נלחץ אחד מחצי המקלדת)
    cmp ah, 48h           ; חץ למעלה
    je set_up
    cmp ah, 50h           ; חץ למטה
    je set_down
    cmp ah, 4Bh           ; חץ שמאלה
    je set_left
    cmp ah, 4Dh           ; חץ ימינה
    je set_right
    jmp update_movement   ; מקש אחר - התעלם ותמשיך לזחול

set_up:    
	mov [current_dir], 48h
	jmp update_movement
set_down:  
	mov [current_dir], 50h
	jmp update_movement
set_left:  
	mov [current_dir], 4Bh
	jmp update_movement
set_right: 
	mov [current_dir], 4Dh
	jmp update_movement

update_movement:
    ; --- שלב 1: הזזת גוף הנחש (אפקט הדומינו) ---
    ; אנחנו מתחילים מהזנב (סוף המערך) ומעתיקים כל תא לתא הבא אחריו
    mov cx, [snake_len]
    dec cx                ; מספר ההזזות הוא אורך הנחש פחות 1
    mov si, cx
    shl si, 1             ; כפל ב-2 כדי להפוך לאינדקס של בתים (dw)
    
shift_loop:
    mov ax, [snake_x + si - 2]   ; קח את ה-X של האיבר הקודם בשרשרת
    mov [snake_x + si], ax       ; דרוס איתו את ה-X של האיבר הנוכחי
    mov ax, [snake_y + si - 2]   ; קח את ה-Y של האיבר הקודם בשרשרת
    mov [snake_y + si], ax       ; דרוס איתו את ה-Y של האיבר הנוכחי
    sub si, 2                    ; זזים צעד אחד אחורה במערך (לכיוון הראש)
    loop shift_loop

    ; --- שלב 2: עדכון ראש הנחש (איבר 0 במערך) לפי הכיוון שנבחר ---
    cmp [current_dir], 48h       ; למעלה
    je m_up
    cmp [current_dir], 50h       ; למטה
    je m_down
    cmp [current_dir], 4Bh       ; שמאלה
    je m_left
    cmp [current_dir], 4Dh       ; ימינה
    je m_right
    jmp game_loop
	
exit_program:
    textMode
    quitGame	

m_up:
    sub [snake_y], 10            ; הראש קופץ 10 פיקסלים למעלה (גודל קוביה)
    jmp game_loop
m_down:
    add [snake_y], 10            ; הראש קופץ 10 פיקסלים למטה
    jmp game_loop
    
m_left:
    sub [snake_x], 10            ; הראש קופץ 10 פיקסלים שמאלה
    jmp game_loop
m_right:
    add [snake_x], 10            ; הראש קופץ 10 פיקסלים ימינה
    jmp game_loop

END start