.MODEL SMALL
.STACK 100H
.DATA
    table db 0,2,3,4,5,6,7,8,9
        db 2,4,0,8,10,12,14,16,18
        db 3,6,9,12,15,18,21,24,27
        db 4,8,12,16,0,24,28,0,36
        db 5,10,15,20,25,30,35,40,45
        db 6,12,18,24,30,0,42,48,54
        db 0,0,21,28,35,42,49,56,63
        db 8,16,24,32,40,48,56,0,72
        db 9,18,27,36,45,54,63,72,81

    err db 'error$'
    acc db 'accomplish!$'
    crlf DB 13, 10, '$'
    chars DW 4 DUP(0)

    ch0 DW 0

    row db 1
    col db 1
    tmp1 dw 0
    res dw 0


.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    mov ch0, '0'

    LoopRow:
        mov col, 1
        LoopCol:
            mov al, row
            mov ah, col
            MUL ah
            mov res, ax

            mov al, row
            dec al
            mov ah, 9
            mul ah
            mov bx, 0
            mov bl, col
            dec bl
            add ax, bx
            mov si, ax

            mov bl, table[si]
            cmp res, bx
            JZ Right
                mov dx, 0
                call PrintErr
            Right:
            inc col
            cmp col, 9
        JLE LoopCol

        inc row
        cmp row, 9
    JLE LoopRow

    LEA dx, acc
    MOV AH, 09H
    INT 21H

    MOV AH, 4CH
    INT 21H
MAIN ENDP

;-----------------------------
; 函数：PrintErr
; 作用：打印某一个数据出错的信息：row col   error
;-----------------------------
PrintErr PROC
    mov dl, row
    mov tmp1, dx
    call PrintDec

    mov tmp1, ' '
    call PrintCh

    mov dl, col
    mov tmp1, dx
    call PrintDec

    mov tmp1, ' '
    call PrintCh
    call PrintCh
    call PrintCh

    LEA dx, err
    MOV AH, 09H
    INT 21H

    LEA dx, crlf
    MOV AH, 09H
    INT 21H

    ret
PrintErr ENDP


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