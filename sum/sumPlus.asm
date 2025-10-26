.MODEL SMALL
.STACK 100H
.DATA
    tmp1 DW 0
    ch0 DW 0     
    chars DW 4 DUP(0)
    msg DB 'input a number between 1-100: $'
    crlf DB 13, 10, '$'
    inputBuffer  DB 5          ; 缓冲区长度，包括最大字符数
            DB ?               ; DOS 会在这里存实际输入字符数
            DB 5 DUP (?)       ; 存储输入的字符

.CODE

MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    MOV ch0, '0'

    CALL InputData
    CALL GetSum
    CALL PrintDec

    MOV AH, 4CH
    INT 21H
MAIN ENDP

;-----------------------------
; 函数：InputData
; 作用：向用户询问输入，转为16位数值存入CX中
;-----------------------------
InputData PROC
    LEA DX, msg
    MOV AH, 09H
    INT 21H
    LEA DX, crlf
    INT 21H

    MOV AH, 0AH
    LEA DX, inputBuffer
    INT 21H

    LEA DX, crlf
    MOV AH, 09H
    INT 21H

    MOV DL, inputBuffer[1]
    MOV AX, 0
    MOV BL, 10
    MOV SI, 2
    LoopMul:
        MOV CL, inputBuffer[SI]
        SUB CX, ch0 
        MUL BL
        ADD AL, CL
        INC SI
        DEC DL
    JNZ LoopMul
    MOV CX, AX

    RET
InputData ENDP

;-----------------------------
; 函数：GetSum
; 作用：求和1-n，把结果存入tmp1
;-----------------------------
GetSum PROC
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