;https://github.com/camsaul/nesasm/blob/master/usage.txt

	.inesprg 1   ;16KB of memory for code
	.ineschr 1   ;8KB of memory for chr file
  
	.rsset $0000  ;rs reservation starts from memory address $0000
  
player_1_up_y .rs 1
player_1_down_y .rs 1
player_2_up_y .rs 1
player_2_down_y .rs 1
player_collision_helper .rs 1
wyn_1 .rs 1
wyn_2 .rs 1
ilegoli1 .rs 1
ilegoli2 .rs 1
ball_x .rs 1
ball_y .rs 1
oldx .rs 1
oldy .rs 1
ball_look .rs 1
curr_ball_dir_x .rs 1
curr_ball_dir_y .rs 1

	.bank 0
	.org $C000 

;http://nesdev.com/6502.txt
;https://wiki.nesdev.com/w/index.php/APU
;https://wiki.nesdev.com/w/index.php/PPU_registers

RESET:
	SEI			;no interrupt requests

	LDX #$40
	STX $4017	;disable frame interrupt (write) - no random sounds while turning on
	LDX #$FF
	TXS			;reset stack
	
	INX
	STX $2000    ;reset PPU flags
	STX $2001    ;disable on-screen rendering
	STX $4010    ;disable DMC IRQs

vblank_1:       ;wait for vblank - moment of cycle, when one is allowed to draw on screen
	BIT $2002
	BPL vblank_1

clear_ram:		;reset ram memory
	LDA #$00
	STA $0000, x
	STA $0100, x
	STA $0200, x
	STA $0300, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x
	INX
	BNE clear_ram

ball_start_direction:	;at the beggining ball goes right and down
	LDA #$00
	STA curr_ball_dir_x
	LDA #$01
	STA curr_ball_dir_y
  
LoadPalette:
	LDA $2002             ;read PPU status to reset the high/low latch
	LDA #$3F
	STA $2006             ;write the high byte of $3F00 address
	LDA #$00
	STA $2006             ;write the low byte of $3F00 address
	LDX #$00              ;start out at 0

LoadBackgroundPaletteLoop:
	LDA background_palette, x		;load data from palette + the value in x
	STA $2007						;write to PPU
	INX
	CPX #$10						;Compare X to hex $10, decimal 16
	BNE LoadBackgroundPaletteLoop	;Branch to LoadBackgroundPaletteLoop if compare was Not Equal to zero
	LDX #$00

LoadSpritePaletteLoop:
	LDA sprite_palette, x	;load data from spirte palette + the value in x
	STA $2007				;write to PPU - 2007: PPU Data
	INX						;set index to next byte
	CPX #$10
	BNE LoadSpritePaletteLoop
	LDX #$00

LoadSpritesLoop:
	LDA sprites, x			;load sprites (spirtes + x)
	STA $0200, x			;store into RAM address ($0200 + x);
	INX
	CPX #$1C				;this much bytes of sprite information are used
	BNE LoadSpritesLoop
  
	LDA #%10000000	;enable NMI, sprites from Pattern Table 0
	STA $2000
  
	LDA #%00010000	;enable sprites
	STA $2001
  
	LDA $0210
	STA ball_y
  
	LDA $0211
	STA ball_look
  
	LDA $0213
	STA ball_x
  
	LDA $0200
	STA player_1_up_y
  
	LDA $0204
	STA player_1_down_y
  
	LDA $0208
	STA player_2_up_y
  
	LDA $020C
	STA player_2_down_y
  
	LDA $0215
	STA wyn_1
	
	LDA $0219
	STA wyn_2
	
	LDA #$0
	STA ilegoli1

	LDA #$0
	STA ilegoli2

;getting ready to increment
  
  	LDA wyn_2
	STA $0215
	TAX
	CLC
	ADC #$08
	INX
	STX wyn_2
	
	LDA wyn_1
	STA $0219
	TAX
	CLC
	ADC #$08
	INX
	STX wyn_1
  
Foreverloop:
	JMP Foreverloop	;infinite loop, waiting for NMI

NMI:
	LDA #$00
	STA $2003
	LDA #$02
	STA $4014
  
SetupController:
	LDA #$01
	STA $4016
	LDA #$00       ;preparing controlers
	STA $4016



;CONTROLER 1
ReadA:
	LDA $4016		;player 1 - A
	AND #%00000001	;only look at bit 0
	BEQ ReadADone	;branch to ReadADone if button is NOT pressed (0)	
	BNE DoA
	
DoA:

	LDA curr_ball_dir_x
	CMP #$02
	BNE pause
	JMP ReadStartDone

pause:
	LDA curr_ball_dir_x
	STA oldx
	
	LDA curr_ball_dir_y
	STA oldy

	LDA #$02
	STA curr_ball_dir_x
	
	LDA #$02
	STA curr_ball_dir_y
	
	JMP ReadStartDone
ReadADone:
  
ReadB:
	LDA $4016
	AND #%00000001
	BEQ ReadBDone
ReadBDone:

ReadSelect:
	LDA $4016
	AND #%00000001
	BEQ ReadSelectDone
ReadSelectDone:

ReadStart:
	LDA $4016
	AND #%00000001
	BEQ ReadStartDone
	BNE DoStart

DoStart:
	
	LDA curr_ball_dir_x
	CMP #$02
	BEQ no_pause
	JMP ReadStartDone

no_pause:
	
	LDA ball_look
	STA $0211
	TAX
	CLC
	ADC #$08
	LDX #$01
	STX ball_look
	
	LDA ball_look
	STA $0211
	TAX
	CLC
	ADC #$08
	LDX #$01
	STX ball_look
	
	LDA oldx
	STA curr_ball_dir_x
	
	LDA oldy
	STA curr_ball_dir_y

ReadStartDone:

ReadUp: 
	LDA $4016
	AND #%00000001
	BEQ ReadUpDone
	BNE DoUp

DoUp:					;change position on the y axis of player 1 - lower part and upper part
	LDA player_1_up_y
	STA $0200
	TAX
	CLC
	ADC #$08
	DEX
	STX player_1_up_y

	LDA player_1_down_y  
	STA $0204
	TAX
	CLC
	ADC #$08
	DEX
	STX player_1_down_y

ReadUpDone:

ReadDown:				;change position on the y axis of player 1 - lower part and upper part
	LDA $4016
	AND #%00000001
	BEQ ReadDownDone
	BNE DoDown

DoDown:
	LDA player_1_up_y
	STA $0200
	TAX	
	CLC
	ADC #$08
	INX
	STX player_1_up_y
  
	LDA player_1_down_y
	STA $0204
	TAX
	CLC
	ADC #$08
	INX
	STX player_1_down_y
 
ReadDownDone:
  
ReadLeft: 
	LDA $4016
	AND #%00000001
	BEQ ReadLeftDone  
ReadLeftDone:

ReadRight: 
	LDA $4016
	AND #%00000001
	BEQ ReadRightDone
ReadRightDone:



;CONTROLER 2
ReadA2: 
	LDA $4017
	AND #%00000001
	BEQ ReadADone2
	
ReadADone2:
  
ReadB2: 
	LDA $4017
	AND #%00000001
	BEQ ReadBDone2

ReadBDone2:

ReadSelect2: 
	LDA $4017
	AND #%00000001
	BEQ ReadSelectDone2

ReadSelectDone2:

ReadStart2: 
	LDA $4017
	AND #%00000001
	BEQ ReadStartDone2
	
ReadStartDone2:

ReadUp2: 
	LDA $4017
	AND #%00000001
	BEQ ReadUpDone2
	BNE DoUp2

DoUp2:
	LDA player_2_up_y
  
	STA $0208
	TAX
	CLC
	ADC #$08
	DEX
  
	STX player_2_up_y
  
	LDA player_2_down_y
  
	STA $020C
	TAX
	CLC
	ADC #$08
	DEX
  
	STX player_2_down_y

ReadUpDone2:

ReadDown2: 
	LDA $4017
	AND #%00000001
	BEQ ReadDownDone2
	BNE DoDown2
 
DoDown2:
	LDA player_2_up_y
  
	STA $0208
	TAX
	CLC
	ADC #$08
	INX
  
	STX player_2_up_y
  
	LDA player_2_down_y
  
	STA $020C
	TAX
	CLC
	ADC #$08
	INX
  
	STX player_2_down_y

ReadDownDone2:
  
ReadLeft2: 
	LDA $4017
	AND #%00000001
	BEQ ReadLeftDone2

ReadLeftDone2:

ReadRight2: 
	LDA $4017
	AND #%00000001
	BEQ ReadRightDone2
  
ReadRightDone2:



;BALL MOVEMENT
check_dir_x:
	LDA curr_ball_dir_x
	CMP #$0
	BEQ ball_goes_right ;x=0 -> ball goes right, x=1 -> down, else do nothing
	CMP #$1
	BEQ ball_goes_left
	JMP no_collision
  
ball_goes_right:		;movement of the ball
	LDA ball_x
	STA $0213
	TAX
	CLC
	ADC #$08
	INX
	STX ball_x
    
	JMP check_dir_y
  
ball_goes_left:			;movement of the ball
	
	LDA curr_ball_dir_x
	CMP #$1
	BEQ dalej
	JMP no_collision
dalej:	
	LDA ball_x
	STA $0213
	TAX
	CLC
	ADC #$08
	DEX
	STX ball_x


check_dir_y:
	LDA curr_ball_dir_y
	CMP #$0
	BEQ ball_goes_up ;y=0 -> ball goes up, y=1 -> down, else nothing
	CMP #$1
	BEQ ball_goes_down
	JMP no_collision

ball_goes_down:  
	LDA ball_y
	STA $0210
	TAX
	CLC
	ADC #$08
	INX
	STX ball_y   
	
	JMP dir_y_check_end

ball_goes_up:  
	LDA ball_y
  
	STA $0210
	TAX
	CLC
	ADC #$08
	DEX
  
	STX ball_y

dir_y_check_end:		;check if y direction shall be changed (if hit bottom/top walls)
	LDA ball_y
  
	CMP #$E0
	BEQ change_dir_y_to_up
  
	CMP #$04
	BEQ change_dir_y_to_down
  
	JMP collision_x

change_dir_y_to_up:
	LDX curr_ball_dir_y
	DEX
	STX curr_ball_dir_y
	JMP collision_x
  
change_dir_y_to_down:
	LDX curr_ball_dir_y
	INX
	STX curr_ball_dir_y
	JMP collision_x
	
collision_x:		;collision - currently WIP - it works, but it will work better hopefully
					;if ball in position of possible collision (so x coordinate of left or right player)
					;check if y cooridnate in range of player - if yes: change x direction of the ball.
	LDA ball_x
  
	CMP #$08
	BEQ possible_collision_p1 
	CMP #$F2
	BEQ possible_collision_p2
	JMP no_collision
  
possible_collision_p1:

upper1:
	LDA player_1_up_y
	STA player_collision_helper
	LDA player_collision_helper
	
	CLC
	ADC #$0A

	STA player_collision_helper
	
	LDA ball_y
	CMP player_collision_helper
	BCC lower1
	BEQ lower1
  
	JMP goal_for_p2

lower1:
	LDA player_1_down_y
	STA player_collision_helper
	LDA player_collision_helper
	
	CLC
	SBC #$0A
	
	STA player_collision_helper
	
	LDA ball_y
	CMP player_collision_helper
	BCS change_dir_x_to_right

	JMP goal_for_p2
    
possible_collision_p2:
	LDA ball_y
  
upper2:
	LDA player_2_up_y
	STA player_collision_helper
	LDA player_collision_helper

	CLC
	ADC #$0A

	STA player_collision_helper
	
	LDA ball_y
	CMP player_collision_helper
	BCC lower2
	BEQ lower2
	
	JMP goal_for_p1

lower2:
	LDA player_2_down_y
	STA player_collision_helper
	LDA player_collision_helper
	
	CLC
	SBC #$0A
	
	STA player_collision_helper
	
	LDA ball_y
	CMP player_collision_helper
	BCS change_dir_x_to_left

	JMP goal_for_p1

change_dir_x_to_right:
	LDX curr_ball_dir_x
	DEX
	STX curr_ball_dir_x
  
	JMP no_collision
  
change_dir_x_to_left:
	LDX curr_ball_dir_x
	INX
	STX curr_ball_dir_x
	
	JMP no_collision

goal_for_p1:
	
	LDA wyn_1
	STA $0219
	TAX
	CLC
	ADC #$08
	INX
	STX wyn_1
	
	LDA #$08
	STA ball_x
	
	LDX ilegoli1
	INX
	STX ilegoli1
	
	LDA ilegoli1
	CMP #$0A
	BEQ restart
	
	JMP aftergoal
	
goal_for_p2:
	
	LDA wyn_2
	STA $0215
	TAX
	CLC
	ADC #$08
	INX
	STX wyn_2
	
	LDA #$F2
	STA ball_x
	
	LDX ilegoli2
	INX
	STX ilegoli2
	
	LDA ilegoli2
	CMP #$0A
	BEQ restart
	
	JMP aftergoal

restart:
	LDX #$0
	STX ilegoli1
	
	LDX #$0
	STX ilegoli2
	
	LDA wyn_1
	STA $0219
	TAX
	CLC
	ADC #$08
	LDX #$05
	STX wyn_1
	
	LDA wyn_2
	STA $0215
	TAX
	CLC
	ADC #$08
	LDX #$05
	STX wyn_2
	
	LDA wyn_2
	STA $0215
	TAX
	CLC
	ADC #$08
	INX
	STX wyn_2
	
	LDA wyn_1
	STA $0219
	TAX
	CLC
	ADC #$08
	INX
	STX wyn_1

aftergoal:

	LDA #$74
	STA ball_y
	
  	LDA ball_look
	STA $0211
	TAX
	CLC
	ADC #$08
	DEX
	STX ball_look
	
	LDA ball_look
	STA $0211
	TAX
	CLC
	ADC #$08
	DEX
	STX ball_look
	
	LDA #$78
	STA player_1_down_y
	
	LDA #$70
	STA player_1_up_y
	
	LDA #$78
	STA player_2_down_y
	
	LDA #$70
	STA player_2_up_y
	
	LDA curr_ball_dir_x
	STA oldx
	
	LDA curr_ball_dir_y
	STA oldy
	
	LDA #$02
	STA curr_ball_dir_x
	
	LDA #$02
	STA curr_ball_dir_y
	
	LDA player_2_up_y
  
	STA $0208
	TAX
	CLC
	ADC #$08
	INX
  
	STX player_2_up_y
  
	LDA player_2_down_y
  
	STA $020C
	TAX
	CLC
	ADC #$08
	INX
  
	STX player_2_down_y
	
	LDA player_1_up_y
	STA $0200
	TAX	
	CLC
	ADC #$08
	INX
	STX player_1_up_y
  
	LDA player_1_down_y
	STA $0204
	TAX
	CLC
	ADC #$08
	INX
	STX player_1_down_y
	
no_collision:

	RTI

	.bank 1
	.org $E000
background_palette:
	.db $22,$29,$1A,$0F
	.db $22,$36,$17,$0F
	.db $22,$30,$21,$0F
	.db $22,$27,$17,$0F
  
sprite_palette:

	.db $22,$1A,$30,$27
	.db $22,$16,$30,$27
	.db $22,$0F,$36,$17
  
sprites:
	;y - index - attr - x
	.byte $78, $04, $00, $08 ;player 1
	.byte $70, $04, $00, $08 
  
	.byte $78, $04, $00, $F2 ;player 2
	.byte $70, $04, $00, $F2

	.byte $74, $01, $00, $08 ;ball
	
	
	.byte $10, $05, $00, $CC ;results 2
	.byte $10, $05, $00, $33 ;results 1


;;;;;;;;;;;;;;  

	.org $FFFA     
	.dw NMI		;when NMI appears (once in cycle) - proceed to it

	.dw RESET	;when first turn on - go to reset
	.dw 0
  
;;;;;;;;;;;;;;  

	.bank 2
	.org $0000
	.incbin "pong.chr"