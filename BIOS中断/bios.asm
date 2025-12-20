.MODEL SMALL
.STACK 100H

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

MainLoop:
    ;-----------------------------------
    ; 检查 Shift 状态
    ;-----------------------------------
    MOV AH, 02H
    INT 16H

    TEST AL, 00000011B     ; bit0=右Shift, bit1=左Shift
    JNZ ExitProgram

    ;-----------------------------------
    ; 检查是否有按键（不阻塞）
    ;-----------------------------------
    MOV AH, 01H
    INT 16H
    JZ MainLoop            ; 没键就继续轮询

    ;-----------------------------------
    ; 有键，读取并显示
    ;-----------------------------------
    MOV AH, 00H
    INT 16H

    MOV AH, 0EH
    MOV BH, 00H
    MOV BL, 07H
    INT 10H

    JMP MainLoop

ExitProgram:
    ;-----------------------------------
    ; 使用 BIOS 方式“结束”
    ;-----------------------------------
    INT 19H                ; 重启到 BIOS/DOS

MAIN ENDP
END MAIN
