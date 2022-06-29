PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

value = $0200 ; 2 bytes
mod10 = $0202 ; 2 bytes
message = $0204 ; 6 bytes
counter = $020a

E  = %10000000
RW = %01000000
RS = %00100000

  .org $8000

reset: 
  ldx #$ff 	 ; Initialize stack at $ff
  txs

  lda #%11111111 ; Sets all pins on port B to output
  sta DDRB

  lda #%11100000 ; Set top 3 pins on port A to output
  sta DDRA

  lda #%00000001 ; Clear display
  jsr lcd_instruction
  lda #%00111000 ; Set to 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; curson on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction

  lda #0
  sta message
  ; Init value to be converted
  lda number
  sta value
  lda number + 1
  sta value + 1

divide: 
  ; Init remainder to 0
  lda #0
  sta mod10
  sta mod10 + 1
  clc

  ldx #16

divloop:
  ; Rotate quotient and remainder
  rol value
  rol value + 1
  rol mod10
  rol mod10 + 1

  ; a,y = divident - divisor
  sec
  lda mod10
  sbc #10
  tay ; save low byte in Y
  lda mod10 + 1
  sbc #0
  bcc ignore_result ; branch if dividend < divisor
  sty mod10
  sta mod10 + 1

ignore_result:
  dex
  bne divloop
  rol value ; shift in the last bit of the quotient
  rol value + 1

  lda mod10
  clc
  adc #"0"
  jsr push_char

  ; if value != 0, continute dividing
  lda value
  ora value + 1
  bne divide

  ldx #0
print:
  lda message,x
  beq loop
  jsr print_char
  inx
  jmp print  

loop:
  jmp loop

number: .word 1729

push_char:
  pha ; push new first char onto stack
  ldy #0

char_loop:
  lda message,y
  tax
  pla
  sta message,y
  iny
  txa
  pha
  bne char_loop
  
  pla
  sta message,y

  rts 

lcd_wait:
  pha		 ; Store contents in A reg into the stack
  lda #%00000000 ; Port B is input
  sta DDRB
lcd_busy:
  lda #RW
  sta PORTA
  lda #(RW | E)  ; set E bit to send instruction
  sta PORTA
  lda PORTB
  and #%10000000 
  bne lcd_busy   ; check if zero flag is high; if not, check again

  lda #RW
  sta PORTA
  lda #%11111111 ; Port B is output
  sta DDRB
  pla
  rts

lcd_instruction:
  jsr lcd_wait
  sta PORTB
  lda #0	 ; Clear RS/RW/E bits
  sta PORTA
  lda #E 	 ; Set E bit to send instruction
  sta PORTA
  lda #0	 ; Clear RS/RW/E bits
  sta PORTA
  rts

print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS        ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)  ; Set E bit to send instruction
  sta PORTA
  lda #RS        ; Clear E bits
  sta PORTA
  rts

nmi:
  rti
irq:
  rti 

  .org $fffa
  .word nmi
  .word reset
  .word irq
