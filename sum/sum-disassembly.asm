.LC0:
        .string "%d\n"           ; 定义格式化字符串，用于 printf 打印整数并换行
main:
        push    rbp              ; 保存调用者的栈基址
        mov     rbp, rsp         ; 建立当前函数的栈帧
        sub     rsp, 16          ; 给局部变量分配 16 字节空间

        mov     DWORD PTR [rbp-4], 0   ; sum = 0，存放累加结果
        mov     DWORD PTR [rbp-8], 1   ; i = 1，循环计数器
        jmp     .L2                     ; 跳转到循环条件判断

.L3:                                   ; 循环体入口
        mov     eax, DWORD PTR [rbp-8] ; eax = i
        add     DWORD PTR [rbp-4], eax ; sum += i
        add     DWORD PTR [rbp-8], 1   ; i++

.L2:                                   ; 循环条件判断
        cmp     DWORD PTR [rbp-8], 100 ; 比较 i 和 100
        jle     .L3                     ; 如果 i <= 100，则继续循环

        mov     eax, DWORD PTR [rbp-4] ; eax = sum
        mov     esi, eax               ; printf 第一个参数（整数）放到 esi
        mov     edi, OFFSET FLAT:.LC0 ; printf 格式字符串地址放到 edi
        mov     eax, 0                 ; printf 调用约定要求置 0（浮点寄存器数量）
        call    printf                 ; 调用 printf 打印 sum

        mov     eax, 0                 ; 函数返回值 0
        leave                          ; 恢复栈帧（mov rsp, rbp + pop rbp）
        ret                            ; 返回调用者