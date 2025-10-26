.MODEL SMALL
.STACK 100H
.DATA
    tmp1 DW 0
    ch0 DW 0     
    chars DW 4 DUP(0)
    test_msg DB 'test$'

.CODE

MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    MOV ch0, '0'

    CALL GetSum
    ; LEA DX, test_msg
    ; MOV AH, 09H
    ; INT 21H
    
    CALL PrintDec

    MOV AH, 4CH
    INT 21H
MAIN ENDP

;-----------------------------
; 函数：GetSum
; 作用：求和1-100，把结果存入tmp1
;-----------------------------
GetSum PROC
    MOV CX, 100
    MOV AX, 1      ; ax作为加数
    MOV BX, 0      ; bx作为累加结果
    LoopSum:
        ADD BX, AX
        INC AX
    LOOP LoopSum
    MOV tmp1, BX
    RET
GetSum ENDP

;-----------------------------
; 函数：PrintDec
; 作用：打印tmp1的十进制形式
;-----------------------------
PrintDec PROC
    MOV AX, tmp1        ; 除法运算后商会写入AX
    MOV BX, 10
    MOV CX, 0

    LoopDiv:
        XOR DX, DX      ; 清空DX，除法运算的余数写入DX
        DIV BX
        ADD DX, ch0
        MOV SI, CX
        MOV chars[SI], DX
        INC CX
        CMP AX, 0
    JNZ LoopDiv

    MOV AH, 02H
    LoopPrint:
        MOV SI, CX
        DEC SI            ; 设置偏移量为cx-1
        MOV DX, chars[SI]
        INT 21H
    LOOP LoopPrint

    RET
PrintDec ENDP

END MAIN