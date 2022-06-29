PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

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

  ldx #0 	 ; set index of x reg to 0
print: 		 ; index message string by byte and print
  lda message,x
  beq loop
  jsr print_char
  inx
  jmp print

loop:
  jmp loop

message: .asciiz "    Let's Go                              Mountaineers"

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

  .org $fffc
  .word reset
  .word $0000
