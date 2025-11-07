.MODEL SMALL
.STACK 100H
.DATA
    msg DB 'The 9mul9 table:$'
    crlf DB 13, 10, '$'

    chars DW 4 DUP(0)

    ch0 DW 0

    num1 DW 0
    num2 DW 0
    num3 DW 0
    tmp1 DW 0

    row DW 9
    col DW 0
.CODE

MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    MOV ch0, '0'

    LEA DX, msg
    MOV AH, 09H
    INT 21H
    LEA DX, crlf
    MOV AH, 09H
    INT 21H

    LoopRow:
        MOV DX, row
        MOV col, 1
        MOV num1, DX

        LoopCol:
            MOV DX, col
            MOV num2, DX
            
            CALL PrintMul

            INC col
            MOV AX, col
            CMP AX, row
        JLE LoopCol

        LEA DX, crlf
        MOV AH, 09H
        INT 21H

        DEC row
    JNZ LoopRow
    

    MOV AH, 4CH
    INT 21H
MAIN ENDP


;-----------------------------
; 函数：PrintMul
; 作用：读取num1和num2，打印出算式num1*num2=num3
;-----------------------------
PrintMul PROC
    MOV AX, num1
    MOV BX, num2
    MUL BL
    MOV num3, AX

    MOV DX, num1
    MOV tmp1, DX
    CALL PrintDec
    MOV tmp1, '*'
    CALL PrintCh
    MOV DX, num2
    MOV tmp1, DX
    CALL PrintDec
    MOV tmp1, '='
    CALL PrintCh
    MOV DX, num3
    MOV tmp1, DX
    CALL PrintDec

    MOV tmp1, ' '
    CALL PrintCh
    CALL PrintCh
    
    RET
PrintMul ENDP

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

;-----------------------------
; 函数：PrintCh
; 作用：打印tmp1对应的ASCII字符
;-----------------------------
PrintCh PROC
    MOV DX, tmp1
    INT 21H
    RET
PrintCh ENDP

END MAIN