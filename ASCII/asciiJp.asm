.MODEL SMALL
.STACK 100H
.DATA
.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    MOV DL, 'a'
    MOV BX, 2            ; 行循环数
    MOV CX, 13

    LoopRow:
        PUSH CX          ; 将列循环数暂存在栈内
        LoopCol:
            MOV AH, 02H  ; 输出当前字母
            INT 21H
            INC DX

            PUSH DX      ; 把DX中的内容（输出当前字母）暂存到栈内
            MOV DL, ' '
            MOV AH, 02H  
            INT 21H
            POP DX       ; 复原dx

            DEC CX
        JNZ LoopCol    ; 当zf != 0 时跳转,如果cx被减到0，zf就会变成0

        PUSH DX
        MOV DL, 0DH    ; 回车 CR
        MOV AH, 02H
        INT 21H
        MOV DL, 0AH    ; 换行 LF
        MOV AH, 02H
        INT 21H 
        POP DX

        POP CX         ; 复原列循环数
        DEC BX
    JNZ LoopRow

    MOV AH, 4CH
    INT 21H

MAIN ENDP
END MAIN