; ==========================================
; הגדרת מקטע המחסנית
; ==========================================
STACK SEGMENT STACK
    DB 100h DUP(?)
STACK ENDS

; ==========================================
; הגדרת מקטע הנתונים
; ==========================================
DATA SEGMENT
    msg1 DB 'Enter 3 characters: $'
    msg2 DB 13, 10, 'The max char is: $' ; 13,10 זה ירידת שורה
DATA ENDS

; ==========================================
; הגדרת מקטע הקוד
; ==========================================
CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK

start:
    ; --- שלב א': אתחול DS ---
    MOV AX, DATA
    MOV DS, AX

    ; --- שלב ב': הדפסת הודעת בקשה ---
    MOV AH, 09h
    MOV DX, OFFSET msg1
    INT 21h

    ; --- שלב ג': קליטת תו 1 ושמירתו ב-BL ---
    ; שירות 01h קולט תו ל-AL ומדפיס אותו
    MOV AH, 01h
    INT 21h
    MOV BL, AL          ; BL הוא ה"מקס" הזמני שלנו

    ; --- שלב ד': קליטת תו 2 והשוואה ---
    MOV AH, 01h
    INT 21h
    ; נשווה את התו החדש (AL) ל"מקס" הנוכחי (BL)
    CMP AL, BL
    ; JNBE = Jump if Not Below or Equal (קפוץ אם גדול יותר, לא חתום)
    JGE update_max1    
    JMP char3_input     ; אם לא גדול יותר, דלג ישר לקלט הבא

update_max1:
    MOV BL, AL          ; עדכן את המקס לתו החדש

char3_input:
    ; --- שלב ה': קליטת תו 3 והשוואה ---
    MOV AH, 01h
    INT 21h
    CMP AL, BL
    JNBE update_max2
    JMP print_result

update_max2:
    MOV BL, AL          ; עדכן את המקס לתו החדש

print_result:
    ; --- שלב ו': הדפסת התוצאה ---
    ; הדפסת הודעת התוצאה
    MOV AH, 09h
    MOV DX, OFFSET msg2
    INT 21h

    ; הדפסת התו המקסימלי (שנמצא ב-BL)
    ; שירות 02h מדפיס תו בודד מ-DL
    MOV AH, 02h
    MOV DL, BL          ; המקס הסופי
    INT 21h

    ; --- שלב ז': יציאה ל-DOS ---
    MOV AH, 4Ch
    MOV AL, 00h
    INT 21h

CODE ENDS
END start