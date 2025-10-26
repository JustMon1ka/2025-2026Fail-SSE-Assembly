.MODEL SMALL
.STACK 100H
.DATA
.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    MOV DL, 'a'   ; 从a开始打印
    MOV BH, 2     ; 把BX的高八位作为行循环数，低八位作为cx原数据暂存
    MOV CX, 13    ; CX是循环标志位
    MOV BL, CL

    LoopRow:      ; 行循环
        MOV CL, BL

        LoopCol:  ; 列循环
            MOV AH, 02H  ; 输出当前字母
            INT 21H

            MOV DH, DL   ; DX高八位暂存当前输出到的字母
            MOV DL, ' '
            INT 21H

            MOV DL, DH   ; 恢复DL
            INC DL

        LOOP LoopCol

        MOV DH, DL

        MOV DL, 0DH    ; 回车 CR
        MOV AH, 02H
        INT 21H

        MOV DL, 0AH    ; 换行 LF
        MOV AH, 02H
        INT 21H 

        MOV DL, DH

        MOV CL, BH
        DEC BH
    
    LOOP LoopRow

    MOV AH, 4CH
    INT 21H

MAIN ENDP
END MAIN