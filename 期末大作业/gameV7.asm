; =====================================================
; TEXT MODE MINI GAME (Ver.7 - 无颜色版)
; Border + Wrap + Apple + Score
; =====================================================

.MODEL SMALL
.STACK 100h

; =========================
; 数据段（唯一共享）
; =========================
.DATA

GameState   DB 0        ; 0=start 1=playing 2=exit

PlayerX     DB 40
PlayerY     DB 12
OldPlayerX  DB 40
OldPlayerY  DB 12
Direction   DB 3        ; 0=up 1=down 2=left 3=right

AppleX      DB 30
AppleY      DB 10

Score       DB 0

; ====== 蛇身数据 ======
SnakeLen    DB 1            ; 初始长度 = 1（只有头）
MaxLen      EQU 100

SnakeX      DB MaxLen DUP(?)
SnakeY      DB MaxLen DUP(?)

GrowFlag    DB 0            ; 吃到苹果的标志

; ====== 屏幕擦除用坐标 ======
EraseX  DB 0
EraseY  DB 0
NeedErase   DB 0    ; 1 = 需要擦除旧尾巴, 0 = 刚才长大了，不需要擦除

; ====== 颜色定义 ======
ColorBorder DB 1Eh    ; 黄字边框
ColorHead   DB 0Ah    ; 亮绿蛇头
ColorBody   DB 02h    ; 深绿蛇身
ColorApple  DB 0Ch    ; 红色苹果
ColorText   DB 0Fh    ; 白字文本

MoveTick    DB 0
MoveDelay   DB 20        ; 越大越慢

CharPlayer  DB '@'
CharApple   DB '*'
CharWall    DB '#'

LeftBound   DB 5
RightBound  DB 75
TopBound    DB 0
BottomBound DB 20

RandSeed    DW 4321

MsgStart DB 'TEXT GAME - PRESS ANY KEY$',13,10,'$'
MsgOver  DB 'GAME OVER - PRESS ANY KEY$',13,10,'$'
MsgScore DB 'SCORE:$'

; =========================
; 代码段
; =========================
.CODE

; =====================================================
MAIN PROC FAR
    mov ax,@DATA
    mov ds,ax

    call StartScreen
    call InitGame

MainLoop:
    call ReadKeyboard
    call UpdatePlayer
    call CheckApple
    call DrawGame
    call CheckSelfCollision
    call Delay

    cmp GameState,2
    jne MainLoop

    call GameOver
    mov ax,4C00h
    int 21h
MAIN ENDP

; =====================================================
HideCursor PROC NEAR
    mov ah,01h
    mov ch,20h        ; Start scanline > End scanline
    mov cl,00h
    int 10h
    ret
HideCursor ENDP

ShowCursor PROC NEAR
    mov ah,01h
    mov ch,06h        ; 常见文本光标
    mov cl,07h
    int 10h
    ret
ShowCursor ENDP

; =====================================================
StartScreen PROC NEAR
    call ClearScreen
    lea dx,MsgStart
    mov ah,09h
    int 21h

WaitKey:
    mov ah,01h
    int 16h
    jz WaitKey
    mov ah,00h
    int 16h
    ret
StartScreen ENDP

; =====================================================
InitGame PROC NEAR
    mov GameState,1

    mov PlayerX,40
    mov PlayerY,12
    mov Direction,3
    mov Score,0

    mov SnakeLen,1
    mov GrowFlag,0
    mov al,PlayerX
    mov SnakeX,al
    mov al,PlayerY
    mov SnakeY,al

    call SpawnApple
    call ClearScreen
    call HideCursor
    call DrawBorder
    call DrawScore
    ret
InitGame ENDP

; =====================================================
ReadKeyboard PROC NEAR
    mov ah,01h
    int 16h
    jz NoKey

    mov ah,00h
    int 16h

    cmp ah,01h
    je ExitGame

    cmp ah,48h
    je KeyUp
    cmp ah,50h
    je KeyDown
    cmp ah,4Bh
    je KeyLeft
    cmp ah,4Dh
    je KeyRight
    jmp NoKey

; ---------- 方向控制（禁止掉头） ----------

KeyUp:
    mov al,0              ; Up
    call TrySetDirection
    jmp NoKey

KeyDown:
    mov al,1              ; Down
    call TrySetDirection
    jmp NoKey

KeyLeft:
    mov al,2              ; Left
    call TrySetDirection
    jmp NoKey

KeyRight:
    mov al,3              ; Right
    call TrySetDirection
    jmp NoKey

ExitGame:
    mov GameState,2

NoKey:
    ret
ReadKeyboard ENDP

; =====================================================
; AL = 新方向
TrySetDirection PROC NEAR
    mov bl,Direction
    add bl,al
    cmp bl,1              ; Up(0) <-> Down(1)
    je IgnoreDir
    cmp bl,5              ; Left(2) <-> Right(3)
    je IgnoreDir
    mov Direction,al
IgnoreDir:
    ret
TrySetDirection ENDP

; =====================================================
UpdatePlayer PROC NEAR
    mov al,PlayerX
    mov OldPlayerX,al
    mov al,PlayerY
    mov OldPlayerY,al

    inc MoveTick
    mov al,MoveTick
    cmp al,MoveDelay
    jl NoMove
    mov MoveTick,0

    cmp Direction,0
    je MoveUp
    cmp Direction,1
    je MoveDown
    cmp Direction,2
    je MoveLeft
    cmp Direction,3
    je MoveRight
    ret

MoveUp:
    dec PlayerY
    mov al,PlayerY
    cmp al,TopBound
    jg EndMove
    mov al,BottomBound
    dec al
    mov PlayerY,al
    jmp EndMove

MoveDown:
    inc PlayerY
    mov al,PlayerY
    cmp al,BottomBound
    jl EndMove
    mov al,TopBound
    inc al
    mov PlayerY,al
    jmp EndMove

MoveLeft:
    dec PlayerX
    mov al,PlayerX
    cmp al,LeftBound
    jg EndMove
    mov al,RightBound
    dec al
    mov PlayerX,al
    jmp EndMove

MoveRight:
    inc PlayerX
    mov al,PlayerX
    cmp al,RightBound
    jl EndMove
    mov al,LeftBound
    inc al
    mov PlayerX,al

EndMove:
    call MoveSnake
NoMove:
    ret
UpdatePlayer ENDP

; =====================================================
MoveSnake PROC NEAR
    ; --------------------------------------
    ; ① 判断是否生长 & 保存旧尾巴坐标
    ; --------------------------------------
    cmp GrowFlag, 1
    je IsGrowing

    ; --- 没吃到苹果：需要保存尾巴，准备擦除 ---
    mov NeedErase, 1        ; 标记：DrawGame 请执行擦除

    ; 获取当前尾巴的索引 (SnakeLen - 1)
    mov al, SnakeLen
    dec al
    xor ah, ah              ; 务必清空高位，防止 SI 乱码
    mov si, ax

    ; 【关键】：在移位覆盖数据前，先把旧尾巴存起来
    mov al, SnakeX[si]
    mov EraseX, al
    mov al, SnakeY[si]
    mov EraseY, al
    
    jmp StartMove

IsGrowing:
    ; --- 吃到苹果：直接增长，不要擦除 ---
    mov NeedErase, 0        ; 标记：DrawGame 不要擦除
    inc SnakeLen
    mov GrowFlag, 0         ; 重置吃苹果标志

StartMove:
    ; --------------------------------------
    ; ② 正常的蛇身移位逻辑 (不用变)
    ; --------------------------------------
    mov al,SnakeLen
    cmp al,1
    jbe SkipShift

    ; CL = SnakeLen - 1
    dec al
    xor cx,cx
    mov cl,al

ShiftLoop:
    mov si,cx
    dec si

    mov al,SnakeX[si]
    mov di,cx
    mov SnakeX[di],al

    mov al,SnakeY[si]
    mov SnakeY[di],al

    dec cl
    jnz ShiftLoop

SkipShift:
    ; ③ 写入新头 (不用变)
    mov al,PlayerX
    mov SnakeX,al
    mov al,PlayerY
    mov SnakeY,al

    ret
MoveSnake ENDP

; =====================================================
CheckApple PROC NEAR
    mov al,PlayerX
    cmp al,AppleX
    jne NoHit
    mov al,PlayerY
    cmp al,AppleY
    jne NoHit

    ; ===== 吃到苹果 =====
    inc Score
    mov GrowFlag,1

    ; ===== 根据分数调整速度 =====
    mov al,Score

    cmp al,3
    jb  SpeedLv1       ; 0-2

    cmp al,6
    jb  SpeedLv2       ; 3-5

    cmp al,9
    jb  SpeedLv3       ; 6-8

    cmp al,12
    jb  SpeedLv4       ; 9-11

    cmp al,15
    jb  SpeedLv5       ; 12-14

    ; >= 15
    mov MoveDelay,10
    jmp SpeedDone

SpeedLv1:
    mov MoveDelay,20
    jmp SpeedDone

SpeedLv2:
    mov MoveDelay,18
    jmp SpeedDone

SpeedLv3:
    mov MoveDelay,16
    jmp SpeedDone

SpeedLv4:
    mov MoveDelay,14
    jmp SpeedDone

SpeedLv5:
    mov MoveDelay,12
    jmp SpeedDone

SpeedDone:
    call SpawnApple

NoHit:
    ret
CheckApple ENDP

; =====================================================
SpawnApple PROC NEAR
    call Rand
    mov al,dl
    and al,00111111b
    add al,LeftBound
    inc al
    cmp al,RightBound
    jl Xok
    mov al,RightBound
    dec al
Xok:
    mov AppleX,al

    call Rand
    mov al,dl
    and al,00001111b
    add al,TopBound
    inc al
    cmp al,BottomBound
    jl Yok
    mov al,BottomBound
    dec al
Yok:
    mov AppleY,al
    ret
SpawnApple ENDP

; =====================================================
Rand PROC NEAR
    mov ax,RandSeed
    mov bx,25173
    mul bx
    add ax,13849
    mov RandSeed,ax
    mov dx,ax
    ret
Rand ENDP

; =====================================================
DrawGame PROC NEAR
    
    ; 1. 擦除旧尾巴
    ; 直接检查 MoveSnake 设置好的标志位
    cmp NeedErase, 1
    jne SkipEraseStep       ; 如果是 0 (刚长大)，跳过擦除

    call EraseCell          ; 擦除 EraseX, EraseY 指定的位置

SkipEraseStep:
    
    ; 2. 绘制苹果 (保持原样)
    mov ah,02h
    mov bh,0
    mov dh,AppleY
    mov dl,AppleX
    int 10h

    mov ah,0Ah
    mov al,CharApple
    mov cx,1
    int 10h

    ; 3. 绘制整条蛇 (保持你修改后的 Push/Pop 版本)
    mov cl,SnakeLen
    mov si,0

DrawSnakeLoop:
    mov dh,SnakeY[si]
    mov dl,SnakeX[si]
    mov ah,02h
    mov bh,0
    int 10h

    push cx                 ; 保护 CX
    mov ah,0Ah
    mov al,CharPlayer
    mov cx,1
    int 10h
    pop cx                  ; 恢复 CX

    inc si
    dec cl
    jnz DrawSnakeLoop

    ; 4. 更新分数 (保持原样)
    call DrawScore

    ret
DrawGame ENDP

; =====================================================
DrawScore PROC NEAR
    ; 光标定位
    mov ah,02h
    mov bh,0
    mov dh,BottomBound
    inc dh
    mov dl,LeftBound
    int 10h

    ; 打印 "SCORE:"
    lea dx,MsgScore
    mov ah,09h
    int 21h

    ; ===== 拆分两位数 =====
    mov al,Score
    xor ah,ah
    mov bl,10
    div bl              ; AL=十位, AH=个位

    mov bh,ah           ; ★ 保存个位到 BH

    ; 打印十位
    add al,'0'
    mov ah,0Eh
    int 10h

    ; 打印个位
    mov al,bh
    add al,'0'
    mov ah,0Eh
    int 10h

    mov ax, 0
    mov bx, 0

    ret
DrawScore ENDP

; =====================================================
DrawBorder PROC NEAR
    mov bh,0
    mov dh,TopBound
TopLine:
    mov dl,LeftBound
TopLoop:
    mov ah,02h
    int 10h
    mov ah,0Ah
    mov al,CharWall
    mov cx,1
    int 10h
    inc dl
    cmp dl,RightBound
    jle TopLoop

    mov dh,BottomBound
    mov dl,LeftBound
BottomLoop:
    mov ah,02h
    int 10h
    mov ah,0Ah
    mov al,CharWall
    mov cx,1
    int 10h
    inc dl
    cmp dl,RightBound
    jle BottomLoop

    mov dh,TopBound
SideLoop:
    mov ah,02h
    mov dl,LeftBound
    int 10h
    mov ah,0Ah
    mov al,CharWall
    mov cx,1
    int 10h

    mov ah,02h
    mov dl,RightBound
    int 10h
    mov ah,0Ah
    mov al,CharWall
    mov cx,1
    int 10h

    inc dh
    cmp dh,BottomBound
    jle SideLoop
    ret
DrawBorder ENDP

; =====================================================
ClearScreen PROC NEAR
    mov ax,0600h
    mov bh,07h
    mov cx,0000h
    mov dx,184Fh
    int 10h
    ret
ClearScreen ENDP

; =====================================================
ClearPlayField PROC NEAR
    mov bh,0

    mov dh,TopBound
    inc dh                  ; 从边框内第一行开始

RowLoop:
    mov dl,LeftBound
    inc dl                  ; 从边框内第一列开始

ColLoop:
    mov ah,02h
    int 10h

    mov ah,0Ah
    mov al,' '
    mov cx,1
    int 10h

    inc dl
    cmp dl,RightBound
    jl ColLoop

    inc dh
    cmp dh,BottomBound
    jl RowLoop

    ret
ClearPlayField ENDP

; =====================================================
EraseCell PROC NEAR
    mov ah,02h
    mov bh,0
    mov dh,EraseY
    mov dl,EraseX
    int 10h

    mov ah,0Ah
    mov al,' '
    mov cx,1
    int 10h
    ret
EraseCell ENDP

; =====================================================
Delay PROC NEAR
    mov cx,4000
DelayLoop:
    dec cx
    jnz DelayLoop
    ret
Delay ENDP

CheckSelfCollision PROC
    ; 如果长度 < 2，不可能撞自己
    mov al, SnakeLen
    cmp al, 2
    jb  NoCollision

    ; BX = i = 1（从第1节身体开始）
    mov bl, 1

    ; AL = SnakeX[0]
    mov al, SnakeX
    ; AH = SnakeY[0]
    mov ah, SnakeY

CheckLoop:
    cmp bl, SnakeLen
    jae NoCollision

    ; 比较 X
    cmp al, SnakeX[bx]
    jne NextSeg

    ; 比较 Y
    cmp ah, SnakeY[bx]
    jne NextSeg

    ; 撞到自己 → Game Over
    mov GameState, 2
    ret

NextSeg:
    inc bl
    jmp CheckLoop

NoCollision:
    ret
CheckSelfCollision ENDP

; =====================================================
GameOver PROC NEAR
    call ClearScreen
    call ShowCursor
    ; ===== 显示 SCORE: =====
    call DrawScore

    ; ===== 换行 =====
    mov ah,02h
    mov dl,13          ; CR
    int 21h
    mov dl,10          ; LF
    int 21h

    ; ===== 显示 GAME OVER =====
    lea dx,MsgOver
    mov ah,09h
    int 21h
WaitEnd:
    mov ah,01h
    int 16h
    jz WaitEnd
    mov ah,00h
    int 16h
    ret
GameOver ENDP

END MAIN
