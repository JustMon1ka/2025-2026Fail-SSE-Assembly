.LC0:
        .string "%c "            ; 格式字符串：一个字符后跟一个空格，用于 printf

main:
        push    rbp              ; 建立栈帧 - 保存旧的基指针
        mov     rbp, rsp         ; rbp <- rsp，创建新的栈帧基址
        sub     rsp, 16          ; 在栈上分配 16 字节的本地变量空间

        mov     BYTE PTR [rbp-1], 97
                                ; 在 rbp-1 处存储字节 97 ('a') —— 当前要输出的字符
        mov     DWORD PTR [rbp-8], 0
                                ; 在 rbp-8 处存储 0 —— 行计数/外层循环计数 (rows)
        jmp     .L2              ; 跳转到外层循环判断入口（统一从判断处进入）

.L5:
        mov     DWORD PTR [rbp-12], 0
                                ; 在 rbp-12 处存储 0 —— 列计数/内层循环计数 (cols)
        jmp     .L3              ; 跳到内层循环的判断处

.L4:
        movsx   eax, BYTE PTR [rbp-1]
                                ; 将 rbp-1 的有符号字节符号扩展到 eax（把当前字符装到 eax）
        mov     esi, eax        ; 将字符（整型）放到 esi —— printf 的第二个参数 (RSI)
        mov     edi, OFFSET FLAT:.LC0
                                ; 将格式字符串地址放到 edi —— printf 的第一个参数 (RDI)
        mov     eax, 0
                                ; 将 eax 置 0（在 x86-64 SysV 下，调用可变参数函数前置零 EAX 以指示 SSE 参数个数）
        call    printf          ; 调用 printf("%c ", char) —— 输出一个字符并跟一个空格

        movzx   eax, BYTE PTR [rbp-1]
                                ; 无符号扩展 rbp-1 的字节到 eax（把字符值当作无符号数）
        add     eax, 1
                                ; eax = eax + 1 —— 下一个字符的 ASCII 值
        mov     BYTE PTR [rbp-1], al
                                ; 将低 8 位（al）写回 rbp-1，更新当前要输出的字符
        add     DWORD PTR [rbp-12], 1
                                ; 列计数 +1（cols++）

.L3:
        cmp     DWORD PTR [rbp-12], 12
                                ; 比较 cols 和 12
        jle     .L4             ; 如果 cols <= 12 则跳回 L4（继续输出字符）
                                ; 注意：当 cols 从 0 递增到 12 时，会执行 L4 共 13 次（0..12）

        mov     edi, 10         ; 准备调用 putchar 输出换行（10 = '\n'）
        call    putchar         ; putchar(10) —— 输出换行字符
        add     DWORD PTR [rbp-8], 1
                                ; 行计数 +1（rows++）

.L2:
        cmp     DWORD PTR [rbp-8], 1
                                ; 比较 rows 和 1
        jle     .L5             ; 如果 rows <= 1 则跳回 L5（开始下一行的内层循环）
                                ; 也就是说当 rows = 0 或 1 时都会进入内层，执行两次整行输出

        mov     eax, 0
        leave                   ; 恢复栈帧（等价于 mov rsp, rbp; pop rbp）
        ret                     ; 返回（相当于 return 0;）
