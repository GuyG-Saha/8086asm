MODEL small
STACK 100h
DATASEG
    ; משתנים זמניים עבור פרוצדורות הציור
    x     dw 0
    y     dw 0
    color db 4       ; אדום (לנחש)
    len   dw 10      ; גודל כל ריבוע (10x10 פיקסלים)

    ; --- מערכים עבור מיקומי חלקי הנחש (עד 100 חלקים) ---
    snake_x    dw 150, 140, 130, 120, 96 dup(0)
    snake_y    dw 100, 100, 100, 100, 96 dup(0)
    snake_len  dw 4

    ; --- מיקום התפוח הירוק ---
    apple_x    dw 200     
    apple_y    dw 150
    apple_color db 2       ; ירוק (צבע 2 ב-Mode 13h הוא ירוק עז יותר)

    ; כיוון תנועה נוכחי
    current_dir db 4Dh    ; 4Dh = ימינה

CODESEG

; ==========================================================
; מקרואים
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
; פרוצדורות ציור בסיסיות
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
; פרוצדורה: ציור הנחש השלם
; ==========================================================
drawSnake proc
    push cx si ax
    
    mov cx, [snake_len]   
    mov si, 0             
    mov al, 4             ; צבע אדום לנחש
    mov [color], al
    
draw_loop:
    push cx
    mov ax, [snake_x + si]
    mov [x], ax
    mov ax, [snake_y + si]
    mov [y], ax
    
    call drawSquare       
    
    add si, 2             
    pop cx
    loop draw_loop
    
    pop ax si cx
    ret
drawSnake endp

; ==========================================================
; פרוצדורה: ציור התפוח
; ==========================================================
drawApple proc
    push ax bx cx dx
    mov ax, [apple_x]
    mov [x], ax
    mov ax, [apple_y]
    mov [y], ax
    mov al, [apple_color]
    mov [color], al
    
    call drawSquare       
    pop dx cx bx ax
    ret
drawApple endp

; ==========================================================
; פרוצדורה: ייצור מיקום אקראי לתפוח (מבוסס שעון מערכת)
; ==========================================================
random_apple proc
    push ax bx cx dx
    
    ; --- 1. אקראיות עבור ציר X ---
    mov ah, 00h
    int 1Ah              ; קריאת שעון המערכת -> ערך אקראי זורם לתוך DX
    mov ax, dx
    xor dx, dx           ; איפוס החצי העליון לקראת חילוק
    mov cx, 31           ; נחלק ב-31 לקבלת שארית בין 0 ל-30 (רשת ה-X)
    div cx               
    
    ; הכפלה ב-10 לקבלת פיקסלים (0, 10, 20... עד 300)
    mov ax, dx
    mov cx, 10
    mul cx               
    mov [apple_x], ax    ; שמירת ה-X האקראי החדש!

    ; --- 2. אקראיות עבור ציר Y ---
    mov ah, 00h
    int 1Ah              ; קריאה נוספת לשעון לקבלת זרע חדש
    mov ax, dx
    xor dx, dx
    mov cx, 18           ; נחלק ב-18 לקבלת שארית בין 0 ל-17
    div cx               
    
    ; הכפלה ב-10 והוספת 10 (טווח 10 עד 180 פיקסלים ב-Y)
    mov ax, dx
    mov cx, 10
    mul cx               
    add ax, 10           
    mov [apple_y], ax    ; שמירת ה-Y האקראי החדש!
    
    pop dx cx bx ax
    ret
random_apple endp

; ==========================================================
; נקודת הזינוק הראשית
; ==========================================================
start:
    setDS
    graphicMode
    
    ; הגרלת מיקום התפוח הראשון על ההתחלה
    call random_apple

game_loop:
    graphicMode           ; ניקוי מסך מלא
    
    call drawSnake        
    call drawApple        

; === השהייה מבוססת תקתוקי שעון (BIOS Ticks) ===
    mov ah, 00h
    int 1Ah              ; קריאת השעון -> מספר התקתוקים הנוכחי נכנס ל-DX
    mov bx, dx           ; שמירת הזמן הנוכחי ב-BX
    add bx, 3            ; כמה תקתוקים לחכות?
	
delay_loop:
    mov ah, 00h
    int 1Ah              ; קריאה חוזרת של השעון
    cmp dx, bx           ; האם הגענו לזמן היעד שקבענו ב-BX?
    jb delay_loop        ; אם DX עדיין קטן מ-BX, המשך להמתין בלולאה

    ; בדיקת מקלדת ללא עצירה
    mov ah, 01h
    int 16h
    jnz key_pressed
    jmp continue_game     

key_pressed:
    mov ah, 00h           
    int 16h
    
    cmp al, 27d           ; Esc?
    jne not_esc           ; [תיקון מקלדת] אם לא Esc - דלג לבדיקת חיצים
    jmp exit_program      ; אם כן Esc - צא מהמשחק
    
not_esc:
    cmp ah, 48h           ; חץ למעלה
    je set_up
    cmp ah, 50h           ; חץ למטה
    je set_down
    cmp ah, 4Bh           ; חץ שמאלה
    je set_left
    cmp ah, 4Dh           ; חץ ימינה
    je set_right
	cmp al, 'w'
	je set_up
	cmp al, 's'
	je set_down
	cmp al, 'a'
	je set_left
	cmp al, 'd'
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
    ; --- בדיקת אכילת תפוח ---
    mov ax, [snake_x]
    cmp ax, [apple_x]
    jnz update_movement   
    
    mov ax, [snake_y]
    cmp ax, [apple_y]
    jnz update_movement   
    
    ; אכלנו! נגדיל את הנחש ונייצר תפוח חדש במקום אקראי
    inc [snake_len]       
    call random_apple     ; [קריאה לפונקציה האקראית החדשה]

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
    cmp [current_dir], 48h       
    je m_up
    cmp [current_dir], 50h       
    je m_down
    cmp [current_dir], 4Bh       
    je m_left
    cmp [current_dir], 4Dh       
    je m_right
    jmp game_loop

m_up:      
    sub [snake_y], 10 
    jmp check_game_over
m_down:    
    add [snake_y], 10 
    jmp check_game_over
m_left:    
    sub [snake_x], 10 
    jmp check_game_over
m_right:   
    add [snake_x], 10 
    jmp check_game_over

; --- [מנגנון פסילה עצמית] ---
check_game_over:
	cmp [snake_x], 0
    jl exit_program          ; left border crossed
    cmp [snake_x], 320
    jge exit_program         ; right border crossed

    cmp [snake_y], 0
    jl exit_program         
    cmp [snake_y], 200
    jge exit_program  
	
    mov cx, [snake_len]   
    dec cx                
    jz back_to_loop
    
    mov si, 2             ; התחלה מהאיבר השני בגוף

self_collision_loop:
    mov ax, [snake_x]     
    cmp ax, [snake_x + si]
    jnz next_part         
    
    mov ax, [snake_y]     
    cmp ax, [snake_y + si]
    je exit_program       ; התנגשות! הראש נגע בגוף -> סגור משחק

next_part:
    add si, 2             
    loop self_collision_loop

back_to_loop:
    jmp game_loop         ; המשך כרגיל

exit_program:
    textMode
    quitGame

END start