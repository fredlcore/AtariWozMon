;  The WOZ Monitor for the Apple 1
;  Written by Steve Wozniak in 1976
;  Ported to the Atari 8-Bit by Frederik Holst in 2022/23 for ABBUC Software Contest 2023
;  Thanks to dommas from steckschwein.de for dissecting and commenting the original source code, most code comments are taken from here:
;  https://www.steckschwein.de/2018/07/22/wozmon-a-memory-monitor-in-256-bytes/ 
;  which in turn took comments from this great site:
;  https://www.sbprojects.net/projects/apple1/wozmon.php
;
; Usage:
; 
; After start you can simply enter a hexadecimal address and get its value returned:
; e.g. 
; 600
; 0600: D8
;
; Several locations can be entered with a space in between:
; 600 604 60B
; 0600: D8
; 0604: 01
; 060B: A9
;
; Entering a dot followed by an address will return all memory addresses in between the last address and the address entered:
; .60F
;  05 9D 42 03
;
; A range can also be entered:
; 600.60F
; 0600: D8 A5 06 F0 01 68 A9 9B         
; 0608: 20 DD 06 A9 05 9D 42 03         
;
; Memory values can be written using a colon:
; A800:A0
; A800: 00
; Take note that the returned value is the value before writing. You can confirm the written value by reading it again:
; A800
; A800: A0
;
; Several bytes can be written by adding them with a space inbetween:
; A800:A9 03 8D 00 A9
; A800: A0
; Only the first (previous) value is returned. Confirm again by querying the range:
; A800.A807
; A800: A9 03 8D 00 A9 00 00 00
;
; Jump to a memory location and execute from there (no return):
; 179F R
; (Jumps to the DOS 2.5 run address. Convenient way to return to DOS from WozMon.)
;
; Exit WozMon and return to BASIC:
; X
; (DOS 2.5 unfortunately does a JMP instead of a JSR, so we can only return to DOS by jumping to the address stored in vector 0x000A/B):
;

                XAML = $CB              ; last "opened" location Low
                XAMH = $CC              ; last "opened" location High
                STL  = $CD              ; store address Low
                STH  = $CE              ; store address High
                L = $CF                 ; hex value parsing LSD (Least Significant Digit, low byte)
                H = $D0                 ; hex value parsing MSB (Most Significant Digit, high byte)
                YSAV = $D1              ; used to see if hex value is given
                MODE = $D4              ; $00=XAM, $74=STOR, $AE=BLOCK XAM
                OUTBUF = $D5            ; output buffer (1 byte) 
                IN = $D6                ; input buffer (until $FA)

                ICHID = $340
                ICCOM = ICHID + 2
                ICBAL = ICHID + 4
                ICBAH = ICHID + 5
                ICBLL = ICHID + 8
                ICBLH = ICHID + 9
                ICAX1 = ICHID + 10
                CIOV = $e456

;                E_DEVICE_NAME = $323

;                CMD_OPEN = $03         ; open command
                CMD_GETREC = $05
;                CMD_GETCHAR = $07      ; get character command
                CMD_PUTCHAR = $0b       ; put character command
;                OUPDATE = $0c          ; read and write mode

; This part until MESSAGE_END can be removed and is mainly added to satisfy ABBUC software competition rules.

                run start
                org $400                ; use cassette buffer to (temporarily) store title screen, doesn't matter if it's overwritten later
                pla                     ; if called from BASIC, pull parameter count from stack

start           ldy #0                  ; message text counter
nextchr         lda MESSAGE,Y           ; get character
                jsr echo                ; use CIOV routine to output
                iny                     ; next character
                cpy #MESSAGE1_END-MESSAGE; are we there yet?
                bne nextchr             ; no!
                ldy #0                  ; message text counter
nextchr2        lda MESSAGE2,Y          ; get character
                jsr echo                ; use CIOV routine to output
                iny                     ; next character
                cpy #MESSAGE_END-MESSAGE2; are we there yet?
                bne nextchr2            ; no!
                jmp main                ; and return to where we came from (DOS/BASIC) - run the actual program by jumping to address $600

MESSAGE         .byte $9b
                .sb+32 "WOZMON BY STEVE WOZNIAK 1976", $9b-32
                .sb+32 "ATARI PORT BY FREDERIK HOLST", $9b-32
                .sb+32 "FOR ASC 2023", $9b-32, $9b-32
MESSAGE1_END
                org $4b0
MESSAGE2
                .sb+32 "COMMANDS:", $9b-32
                .sb+32+128 "A.B"
                .sb+32 " DUMP FROM A TO B", $9b-32
                .sb+32+128 "A:B", $9b-32
                .sb+32 " WRITE B TO ADDRESS A", $9b-32
                .sb+32+128 "A R"
                .sb+32 " RUN FROM ADDRESS A", $9b-32
                .sb+32+128 "X"
                .sb+32 " EXIT", $9b-32, $9b-32
                .sb+32 "TO RUN WOZMON AGAIN LATER,", $9b-32
                .sb+32 "JUMP TO 1536/$601:", $9b-32
                .sb+32 "BASIC: X=USR(1536)", $9b-32
                .sb+32 "DOS: M 601", $9b-32, $9b-32
MESSAGE_END

                org $600        ; store in page 6

;                jsr get_ch
;                cpx #$80
;                beq exit
;                jsr open_ch

                pla
main            cld                     ; clear decimal arithmetic mode
                lda #'\'
                jsr echo
getline         lda #$9b                ; output ATASCII newline
                jsr echo

; get line from keyboard
                lda #CMD_GETREC         ; 'get record' command
                sta ICCOM,X
                lda #<IN                ; input buffer IN (low)
                sta ICBAL,X     
                lda #>IN                ; input buffer IN (high)
                sta ICBAH,X     
                lda #36                 ; max. 36 characters in "safe" BASIC zero page
                sta ICBLL,X     
; ICBLH is still zero from echo subroutine
;                lda #0
;                sta ICBLH,X
                jsr CIOV                ; execute

                ldy #$ff                ; reset text index
                lda #0                  ; for XAM mode
                tax                     ; 0 -> X
setstor         asl                     ; converts $BA (colon, i.e. STOR mode) to $74 if setting STOR mode, so bit 7 is clear and can be differentiated from $AE (dot, i.e. BLOCK XAM mode) in the later BIT test
setmode         sta MODE                ; $00=XAM (examine single memory location, i.e. no other command was entered) $74=STOR (store value in memory, i.e. colon was entered) $AE=BLOK XAM (examine block of memory, i.e. dot was entered)
blkskip         iny                     ; advance text index
nextitem        lda IN,Y                ; get character
                ora #$80                ; add bit 7 which is always set on Apple 1 characters, necessary to perform BIT test later on
                cmp #$9b                ; ATASCII CR?
                beq getline             ; yes, line done
                cmp #'.'+$80            ; dot?
                bcc blkskip             ; less than "."? Must be space, so skip this delimiter (actually, all characters less than "." count as a delimiter)
                beq setmode             ; it's a dot, so set STOR mode
                cmp #':'+$80            ; colon?
                beq setstor             ; yes, set STOR mode
                cmp #'R'+$80            ; R?
                beq run                 ; run user program
                cmp #'X'+$80            ; X?
                bne cont                ; no, then continue
                rts                     ; exit WozMon
cont            stx L                   ; 0 -> L
                stx H                   ; and H
                sty YSAV                ; save Y for later comparison
nexthex         lda IN,Y                ; get character for hex test
                eor #'0'                ; map digits to $00-$09
                cmp #10                 ; less than 10? 
                bcc dig                 ; then it's a digit
                adc #$88                ; map letters "A"-"F" to $FA-$FF
                cmp #$fa                ; less than $FA (0x0A)?
                bcc nothex              ; then it's not a hex digit
dig             asl                     ; hex digit to high nibble of accumulator
                asl
                asl
                asl
                ldx #4                  ; shift count
hexshift        asl                     ; shift hex digit to the left, highest bit (7) to carry
                rol L                   ; rotate that carry bit into bit 0 of L (low byte)
                rol H                   ; if previous ROL results in a carry bit, then rotate that into bit 0 of H (high byte)
                dex                     ; done four shifts?
                bne hexshift            ; no, then loop
                iny                     ; advance text index
                bne nexthex             ; always taken, check next character for hex value
nothex          cpy YSAV                ; check if L, H empty (no hex digits)
                beq getline             ; if yes, then break and read next line
                bit MODE                ; test MODE byte (bit 6 of MODE into oVerflow flag, bit 7 into Negative flag)
                bvc notstor             ; V flag clear (i.e. bit 6 was clear)? Then it's a XAM & BLOCK XAM operation. Otherwise (bit 6 is set) it's a STOR operation. 
                lda L                   ; least significant digit of hex data
                sta (STL,X)             ; store at current 'store index'
                inc STL                 ; increment store index
                bne nextitem            ; get next item (if no carry)
                inc STH                 ; otherwise add carry to 'store index' high order
tonextitem      jmp nextitem            ; get next command item
run             jmp (XAML)              ; run at current XAML index
notstor         bmi xamnext             ; bit 7 = 0 for XAM, bit 7 = 1 for BLOCK XAM
                ldx #2                  ; byte count
setadr          lda L-1,X               ; copy hex data
                sta STL-1,X             ; to 'store index'
                sta XAML-1,X            ; and to 'XAM index'
                dex                     ; next of two bytes
                bne setadr              ; loop unless X = 0
nxtprnt         bne prdata              ; 'not equal', i.e. greater 0, means no address to print
                lda #$9b                ; ATASCII CR
                jsr echo                ; output it
                lda XAMH                ; 'examine index' high byte
                jsr prbyte              ; output it in hex format
                lda XAML                ; 'examine index' low byte
                jsr prbyte              ; output it in hex format
                lda #':'                ; output colon
                jsr echo
prdata          lda #' '                ; output space
                jsr echo        
                lda (XAML,x)            ; get data byte at 'examine index'
                jsr prbyte              ; output it in hex format
xamnext         stx MODE                ; 0 -> MODE (XAM mode)
                lda XAML                ; compare 'examine index'
                cmp L                   ; to hex data (low byte)
                lda XAMH        
                sbc H   
                bcs tonextitem          ; not less, so no more data to output
                inc XAML                ; increment 'examine index' low byte
                bne mod8chk             ; test for new line after reaching a modulo 8 byte number
                inc XAMH                ; increment 'examine index' low byte
mod8chk         lda XAML                ; check 'examine index' low byte
                and #7                  ; for MOD 8 = 0
                bpl nxtprnt             ; always taken
prbyte          pha                     ; save accumulator for least significant digit
                lsr     
                lsr     
                lsr     
                lsr                     ; most significant digit to least significant digit position
                jsr prhex               ; output as hex digit
                pla                     ; restore accumulator
prhex           and #$0f                ; mask least significant digit for hex print
                ora #$30                ; add "0"
                cmp #$3a                ; is it stil a digit?
                bcc echo                ; yes, output it
                adc #6                  ; otherwise add offset for letter to generate ATASCII letters A-F

echo            sta OUTBUF              ; store accumulator to output buffer byte
                lda #>OUTBUF            ; High byte of output buffer is zero because of zero page location
                tax                     ; therefore reuse it to set X to zero, then also
                sta ICBAH,X             ; store it into ICBAH
                sta ICBLH,X             ; high byte length of message
                lda #<OUTBUF            ; low byte of message
                sta ICBAL,X             ; into ICBAL
                lda #1                  ; tell CIO to only store only 1 character when reading 
                sta ICBLL,X             ; low byte length of message

                lda #CMD_PUTCHAR        ; put character command
                sta ICCOM,X             ; into ICCOM
                tya                     ; we need to preserve Y before enterin CIOV
                pha                     ; push to accumulator
                jsr CIOV                ; call CIOV
                pla                     ; restore Y from stack
                tay                     ; and transfer to Y register
exit            rts                     ; return

;                beq jsrciov
; Count the number of characters actually entered
/*
get_buflen
                 ldy #0
next_ch          lda BUFFER,Y
                 iny
                 cmp #$9b
                 bne next_ch
*/
; Open E: device
/*
open_ch          lda #CMD_OPEN       ; Open E:
                 sta ICCOM,X
                 lda #<E_DEVICE_NAME
                 sta ICBAL,X
                 lda #>E_DEVICE_NAME
                 sta ICBAH,X
                 lda #OUPDATE
                 sta ICAX1,X
jsrciov          tya
                 pha
                 jsr CIOV
                 pla
                 tay
exit             rts
*/
/*
; find out which IOCB channel is free to use
get_ch	        ldy #$00
chk_ch          tya
                clc
                rol
                rol
                rol
                rol
                tax
                lda ICHID,X
                cmp #$ff
                beq avail
                iny
                cpy #$08
                bne chk_ch
                ldx #$80
avail           stx E_CHANNEL
                rts

E_CHANNEL       .byte $ff
*/
