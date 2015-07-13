%define SECTORS 16                          ; keep it under 18
%define IMAGE_SIZE ((SECTORS + 1) * 512)    ; SECTORS + 1 (~= 18) * 512 bytes
%define STACK_SIZE 256                      ; 4096 bytes in paragraphs

bits 16                                     ; 16 bit mode
;org 0x7C00                                 ; BIOS boot sector entry point

start:
    cli ; disable interrupts

    ;
    ; Notes:
    ;  1 paragraph  = 16 bytes
    ; 32 paragraphs = 512 bytes
    ;
    ; Skip past our SECTORS
    ; Skip past our reserved video memory buffer (for double buffering)
    ; Skip past allocated STACK_SIZE
    ;
    mov ax, (((SECTORS + 1) * 32) + 4000 + STACK_SIZE)
    mov ss, ax
    mov sp, STACK_SIZE * 16 ; 4096 in bytes

    sti ; enable interrupts

    mov ax, 07C0h           ; point all segments to _start
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; dl contains the drive number

    mov ax, 0               ; reset disk function
    int 13h                 ; call BIOS interrupt
    jc disk_reset_error

    ; FIXME: if SECTORS + 1 > 18 (~= max sectors per track)
    ; then we should try to do _multiple_ reads
    ;
    ; Notes:
    ;
    ; 1 sector          = 512 bytes
    ; 1 cylinder/track  = 18 sectors
    ; 1 side            = 80 cylinders/tracks
    ; 1 disk (1'44 MB)  = 2 sides
    ;
    ; 2 * 80 * 18 * 512 = 1474560 bytes = 1440 kilo bytes = 1.4 mega bytes
    ;
    ; We start _reading_ at SECTOR 2 because SECTOR 1 is where our stage 1
    ; _bootloader_ (this piece of code up until the dw 0xAA55 marker, if you
    ; take the time and scroll down below) is *loaded* automatically by BIOS
    ; and therefore there is no need to read it again ...

    push es             ; save es

    mov ax, 07E0h       ; destination location (address of _start)
    mov es, ax          ; destination location
    mov bx, 0           ; index 0

    mov ah, 2           ; read sectors function
    mov al, SECTORS     ; number of sectors
    mov ch, 0           ; cylinder number
    mov dh, 0           ; head number
    mov cl, 2           ; starting sector number
    int 13h             ; call BIOS interrupt

    jc disk_read_error

    pop es              ; restore es

    mov si, boot_msg    ; boot message
    call _puts          ; print

    jmp 07E0h:0000h     ; jump to _start (a.k.a stage 2)

disk_reset_error:
    mov si, disk_reset_error_msg
    jmp fatal

disk_read_error:
    mov si, disk_read_error_msg

fatal:
    call _puts  ; print message in [DS:SI]

    mov ax, 0   ; wait for a keypress
    int 16h

    mov ax, 0   ; reboot
    int 19h

; ===========================================
; PROTOTYPE : void _puts(char *s)
; INPUT     : offset/pointer to string in SI
; RETURN    : n/a
; ===========================================
_puts:
    lodsb       ; move byte [DS:SI] into AL

    cmp al, 0   ; 0 == end of string ?
    je .end

    mov ah, 0Eh ; display character function
    int 10h     ; call BIOS interrupt

    jmp _puts   ; next character

.end:
    ret

disk_reset_error_msg: db 'Could not reset disk', 0
disk_read_error_msg: db 'Could not read disk', 0
boot_msg: db 'Booting Floppy Bird ... ', 0

times 510 - ($ - $$) db 0   ; pad to 510 bytes
dw 0xAA55                   ; pad 2 more bytes = 512 bytes = THE BOOT SECTOR

; entry point
_start:
    call main               ; call main
    jmp $                   ; loop forever

pointA:  db 128,  85,  0
pointB:  db 195, 200, 40
pointC:  db  60, 200, 40
cos:     dd 0.984807753
cos_sqr: dd 0.969846310
sin:     dd 0.173648178
sin_sqr: dd 0.030153689

%define BLACK    0x0
%define BLUE     0x1
%define GREEN    0x2
%define CYAN     0x3
%define RED      0x4
%define MAGENTA  0x5
%define BROWN    0x6
%define LGREY    0x7
%define DGREY    0x8
%define LBLUE    0x9
%define LGREEN   0xA
%define LCYAN    0xB
%define LRED     0xC
%define LMAGENTA 0xD
%define YELLOW   0xE
%define WHITE    0xF

main:
    ;mov ax, 0x3     ; 80x25 @ 16 color mode
    ;int 10h         ; call BIOS interrupt

    ;mov si, msg
    ;call puts

    call set_vga_mode ; 320x200 @ 256 color mode
.loop:
    ;=====================
    ; drawing a pixel
    ;push 30         ; x
    ;push 30         ; y
    ;push WHITE      ; color

    ;call put_pixel
    push pointA
    push pointB
    push pointC
    call draw_triangle

    call vsync
    call flpscr

    jmp .loop

    ret

set_txt_mode:
    pusha

    mov ax, 0x3     ; 80x25 @ 16 color mode
    int 10h         ; call BIOS interrupt

    popa
    ret

puts:
    pusha

.loop:
    lodsb       ; move byte [DS:SI] into AL

    cmp al, 0   ; 0 == end of string ?
    je .end

    mov ah, 0Eh ; display character function
    int 10h     ; call BIOS interrupt

    jmp .loop   ; next character

.end:
    popa
    ret

%define VIDMEW 320        ; video memory width
%define VIDMEH 200        ; video memory height
%define VIDMES 64000      ; video memory size
%define VIDMEM IMAGE_SIZE ; back buffer video memory
%define VIDMED 0xA000     ; system video memory

; ==========================================
; PROTOTYPE : void set_vga_mode(void)
; INPUT     : n/a
; RETURN    : n/a
; ==========================================
set_vga_mode:
    pusha

    mov ax, 0x13    ; 320x200 @ 256 color mode
    int 10h         ; call BIOS interrupt

    popa
    ret

; ==========================================
; PROTOTYPE : void vsync(void)
; INPUT     : n/a
; RETURN    : n/a
; ==========================================
vsync:
    pusha
    mov dx, 0x3DA   ; port 0x3DA

.l1:
    in al, dx       ; port
    test al, 8      ; test bit 4
    jnz .l1         ; retrace in progress?

.l2:
    in al, dx       ; port
    test al, 8      ; test bit 4
    jz .l2          ; new retrace?

    popa
    ret

; ==========================================
; PROTOTYPE : void flpscr(void)
; INPUT     : n/a
; RETURN    : n/a
; ==========================================
flpscr:
    push ds
    push cx

    mov cx, VIDMED
    mov es, cx
    xor di, di

    mov cx, VIDMEM
    mov ds, cx
    xor si, si

    mov cx, VIDMES / 4 ; 64000 / 4

    rep movsd  ; copy 4 bytes from [DS:SI] into [ES:DI]

    pop cx
    pop ds
    ret

; ==========================================
; PROTOTYPE : void put_pixel(short x, short y
;                            unsigned char color)
; INPUT     : n/a
; RETURN    : n/a
; ==========================================
put_pixel:
    push bp
    mov bp, sp          ; top of the stack

    pusha

    mov ax, VIDMEM      ; pointer to screen buffer
    mov es, ax          ;

    mov ax, [bp+6]      ; y
    mov bx, [bp+8]      ; x
    mov cx, 320         ; screen width
    mul cx              ; multiply ax by 320 (cx)
    add ax, bx          ; and add x
    mov di, ax          ; load Destination Index register with ax value (the coords to put the pixel)
    mov dl, byte [bp+4] ; color
    mov [es:di], dl

    popa
    pop bp
    ret 6              ; 3 params * 2 bytes

; draw_triangle: draw a 3d looking pyramid
; inputs:
;   ax,bx,cx - 3 locations of 3 points to draw
; return: none
draw_triangle:
    pusha

    ; Draw A-B
    ;lw  $a0,0($s0)
    ;lw  $a1,4($s0)
    ;lw  $a2,12($s0)
    ;lw  $a3,16($s0)
    ;jal DrawLine
    mov ax, [bp+6]
    push ax
    mov ax, [bp+4]
    push ax
    push WHITE
    call put_pixel

    ; Draw A-C
    ;lw  $a0,0($s0)
    ;lw  $a1,4($s0)
    ;lw  $a2,24($s0)
    ;lw  $a3,28($s0)
    ;jal DrawLine

    ; Draw A-D
    ;lw  $a0,0($s0)
    ;lw  $a1,4($s0)
    ;lw  $a2,36($s0)
    ;lw  $a3,40($s0)
    ;jal DrawLine

    ; Draw B-C
    ;lw  $a0,12($s0)
    ;lw  $a1,16($s0)
    ;lw  $a2,24($s0)
    ;lw  $a3,28($s0)
    ;jal DrawLine

    ; Draw B-D
    ;lw  $a0,12($s0)
    ;lw  $a1,16($s0)
    ;lw  $a2,36($s0)
    ;lw  $a3,40($s0)
    ;jal DrawLine

    ; Draw C-D
    ;lw  $a0,24($s0)
    ;lw  $a1,28($s0)
    ;lw  $a2,36($s0)
    ;lw  $a3,40($s0)
    ;jal DrawLine

    popa
    ret 6
