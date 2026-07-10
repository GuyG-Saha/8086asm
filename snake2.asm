MODEL small
STACK 100h
DATASEG
    ; משתנים זמניים עבור פרוצדורות הציור שלך
    x     dw 0
    y     dw 0
    color db 4       ; אדום
    len   dw 10      ; גודל כל ריבוע בנחש ובכל תפוח (10x10 פיקסלים)

    ; --- מערכים עבור מיקומי חלקי הנחש (עד 100 חלקים) ---
    snake_x    dw 150, 140, 130, 120, 96 dup(0)
    snake_y    dw 100, 100, 100, 100, 96 dup(0)
    snake_len  dw 4

    ; --- [תוספת] מיקום התפוח הירוק ---
    apple_x    dw 200     ; מיקום התחלתי קבוע לבדיקה
    apple_y    dw 150
    apple_color db 3       ; ירוק

    ; כיוון תנועה נוכחי (לפי קוד סריקה של החיצים)
    current_dir db 4Dh    ; 4Dh = ימינה
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
; פרוצדורה: סריקת המערך וציור הנחש השלם
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
; [תוספת] פרוצדורה: ציור התפוח הירוק
; ==========================================================
drawApple proc
    push ax bx cx dx
    ; שימוש במשתנים הזמניים כדי לא להרוס את הנתונים
    mov ax, [apple_x]
    mov [x], ax
    mov ax, [apple_y]
    mov [y], ax
    mov al, [apple_color]
    mov [color], al
    
    call drawSquare       ; קריאה לפרוצדורה שלך שמציירת ריבוע בודד!
    
    ; שחזור הצבע האדום עבור הנחש
    mov al, 4d
    mov [color], al
    pop dx cx bx ax
    ret
drawApple endp

; ==========================================================
; נקודת הזינוק ולולאת המשחק הראשית
; ==========================================================
start:
    setDS
    graphicMode

game_loop:
    graphicMode           ; ניקוי מסך מלא (מונע מריחה)
    
    call drawSnake        ; ציור הנחש השלם
    call drawApple        ; [תוספת] ציור התפוח הירוק

    ; לולאת השהייה מקוננת (כדי שהנחש יזחול בקצב הגיוני ב-DOSBox)
    mov cx, 5             ; [תוספת] שינוי קל לזירוז הנחש
delay_outer:
    push cx
    mov cx, 0ffffh
delay_inner:
    nop
    loop delay_inner
    pop cx
    loop delay_outer

    ; בדיקת מקלדת ללא עצירה
    mov ah, 01h
    int 16h
    jnz key_pressed
    jmp continue_game     ; אם לא נלחץ מקש, המשך לזחול

key_pressed:
    mov ah, 00h           ; קריאת המקש
    int 16h
    
    cmp al, 27d           ; האם המקש הוא Esc?
    jne not_esc           ; [תיקון] אם הוא לא Esc -> דלג קדימה והמשך לבדוק את החיצים!
    jmp exit_program      ; אם הוא כן Esc -> סגור את המשחק

not_esc:
    ; עדכון כיוון התנועה (רק אם נלחץ אחד מחצי המקלדת)
    cmp ah, 48h           ; חץ למעלה
    je set_up
    cmp ah, 50h           ; חץ למטה
    je set_down
    cmp ah, 4Bh           ; חץ שמאלה
    je set_left
    cmp ah, 4Dh           ; חץ ימינה
    je set_right
    jmp continue_game     ; מקש אחר - התעלם

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

continue_game:
    ; --- [תוספת] בדיקת אכילת תפוח ---
    ; האם הראש של הנחש (snake_x, snake_y) הגיע לתפוח?
    mov ax, [snake_x]
    cmp ax, [apple_x]
    jnz update_movement   ; לא אותו X, המשך תנועה רגילה
    
    mov ax, [snake_y]
    cmp ax, [apple_y]
    jnz update_movement   ; לא אותו Y, המשך תנועה רגילה
    
    ; בום! אכלנו תפוח!
    inc [snake_len]       ; 1. הגדלת אורך הנחש
    
    ; 2. שיגור מחדש של התפוח למקום אחר
    ; (לצורך הפשטות, כרגע נשתגר למקום קבוע אחר. נלמד מספרים אקראיים בהמשך).
    add [apple_x], 40
    add [apple_y], 30
    
    ; מניעת יציאה מגבולות המסך (בדיקה גסה)
    cmp [apple_x], 300
    jl apple_y_check
    mov [apple_x], 10d
apple_y_check:
    cmp [apple_y], 180
    jl update_movement
    mov [apple_y], 10d

update_movement:
    ; --- שלב 1: הזזת גוף הנחש (אפקט הדומינו) ---
    mov cx, [snake_len]
    dec cx                
    mov si, cx
    shl si, 1             


    
shift_loop:
    mov ax, [snake_x + si - 2]   
    mov [snake_x + si], ax       
    mov ax, [snake_y + si - 2]   
    mov [snake_y + si], ax       
    sub si, 2                    
    loop shift_loop

    ; --- שלב 2: עדכון ראש הנחש לפי הכיוון ---
    cmp [current_dir], 48h       ; למעלה
    je m_up
    cmp [current_dir], 50h       ; למטה
    je m_down
    cmp [current_dir], 4Bh       ; שמאלה
    je m_left
    cmp [current_dir], 4Dh       ; ימינה
    je m_right
    jmp game_loop


m_up:      
	sub [snake_y], 10
	jmp game_loop
m_down:    
	add [snake_y], 10
	jmp game_loop
m_left:    
	sub [snake_x], 10
	jmp game_loop
m_right:   
	add [snake_x], 10
	jmp game_loop


exit_program:
    textMode
    quitGame


END start