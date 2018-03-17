;spaceship.asm - Example ROM for the NES (Nintendo Entertainment System) showing how to control an object on the screen. Written in 6502 Assembly.
;by Mark Bouwman 
;Follow me on github: https://github.com/MarkBouwman
;Follow me on twitter https://twitter.com/bouwmanmark
  
  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring

; Hardware constants CPU
ControllerPort1       = $4016
PPU_CTRL_REG1         = $2000
PPU_CTRL_REG2         = $2001
PPU_STATUS            = $2002
PPU_SPR_ADDR          = $2003
PPU_SPR_DATA          = $2004
PPU_SCROLL_REG        = $2005
PPU_ADDRESS           = $2006
PPU_DATA              = $2007

; Hardware constants PPU
PPU_Attribute_0_Hi    = $23                   ; This is the PPU address of attribute table 0
PPU_Attribute_0_Lo    = $C0

; Sprite constants
sprite_RAM            = $0200                 ; starting point of the sprite data
sprite_YPOS           = $0200                 ; sprite Y position
sprite_Tile           = $0201                 ; sprite tile number
sprite_Attr           = $0202                 ; sprite attribute byte
sprite_XPOS           = $0203                 ; sprite X position

; Controller constants
Up_Button             = %00001000
Down_Button           = %00000100
Left_Button           = %00000010
Right_Button          = %00000001

; Game constants
SHIP_SPEED      = $02

; Variables
  .rsset $0000                          ; start variables at ram location 0
buttons                 .rs 1           ; variable to store controller state
ship_x                  .rs 1           ; The X position of the spaceship
ship_y                  .rs 1           ; The Y position of the ship

  .bank 0
  .org $C000 
RESET:                                  ; This is the reset interupt
  SEI                                   ; disable IRQs
  CLD                                   ; disable decimal mode
  LDX #$40
  STX $4017                             ; disable APU frame IRQ
  LDX #$FF
  TXS                                   ; Set up stack
  INX                                   ; now X = 0
  STX PPU_CTRL_REG1                     ; disable NMI
  STX PPU_CTRL_REG2                     ; disable rendering
  STX $4010                             ; disable DMC channel IRQs

  JSR VBlankWait                        ; First wait for vblank to make sure PPU is ready

clrmem:                                 ; Simple loop to clear all the memory
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x                          ;move all sprites off screen
  INX
  BNE clrmem
   
  JSR VBlankWait                        ; Second wait for vblank, PPU is ready after this

; init PPU
  LDA #%10010000                        ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA PPU_CTRL_REG1
  LDA #%00011110                        ; enable sprites, enable background, no clipping on left side
  STA PPU_CTRL_REG2

  LDA #$80                              ; set the initial position of the space ship
  STA ship_x
  STA ship_y

  JSR LoadPalette                       ; Load the color palette
  JSR SetShipTileConfig                 ; Load the ship sprites
; start game loop
GameLoop:
  JMP GameLoop                          ;jump back to GameLoop, infinite loop

; NMI
NMI:
  JSR SpriteDMA                         ; load in the sprites for the spaceship 

  LDA #%10010000                        ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA PPU_CTRL_REG1
  LDA #%00011110                        ; enable sprites, enable background, no clipping on left side
  STA PPU_CTRL_REG2
  LDA #$00                              ;tell the ppu there is no background scrolling
  STA PPU_SCROLL_REG

  JSR SaveControllerState               ; save the state of the controller 

; Move right
  LDA buttons                           ; load the button state
  AND #Right_Button                     ; check if right is pressed
  BEQ MoveRightDone                     ; branch is button is not pressed
MoveRight:
  LDA ship_x
  CLC
  ADC #SHIP_SPEED
  STA ship_x
MoveRightDone:

; Move left
  LDA buttons                           ; load the button state
  AND #Left_Button                      ; check if right is pressed
  BEQ MoveLeftDone                      ; branch is button is not pressed
MoveLeft:
  LDA ship_x
  SEC
  SBC #SHIP_SPEED
  STA ship_x
MoveLeftDone:

; Move up
  LDA buttons                           ; load the button state
  AND #Up_Button                        ; check if right is pressed
  BEQ MoveUpDone                        ; branch is button is not pressed
MoveUp:
  LDA ship_y
  SEC
  SBC #SHIP_SPEED
  STA ship_y
MoveUpDone:

; Move down
  LDA buttons                           ; load the button state
  AND #Down_Button                      ; check if right is pressed
  BEQ MoveDownDone                      ; branch is button is not pressed
MoveDown:
  LDA ship_y
  CLC
  ADC #SHIP_SPEED
  STA ship_y
MoveDownDone:


DrawShip:
  LDA ship_y
  STA sprite_YPOS
  STA sprite_YPOS+4
  STA sprite_YPOS+8
  STA sprite_YPOS+12
  CLC
  ADC #$08                              ; Add 8 to move to the next row
  STA sprite_YPOS+16
  STA sprite_YPOS+20
  STA sprite_YPOS+24
  STA sprite_YPOS+28
  CLC
  ADC #$08                              ; Add 8 to move to the next row
  STA sprite_YPOS+32
  STA sprite_YPOS+36
  STA sprite_YPOS+40
  STA sprite_YPOS+44
  CLC
  ADC #$08                              ; Add 8 to move to the next row
  STA sprite_YPOS+48
  STA sprite_YPOS+52
  STA sprite_YPOS+56
  STA sprite_YPOS+60

  LDA ship_y
  STA sprite_YPOS+64
  STA sprite_YPOS+68
  STA sprite_YPOS+72
  STA sprite_YPOS+76
  CLC
  ADC #$08                              ; Add 8 to move to the next row
  STA sprite_YPOS+80
  STA sprite_YPOS+84
  STA sprite_YPOS+88
  STA sprite_YPOS+92
  CLC
  ADC #$08                              ; Add 8 to move to the next row
  STA sprite_YPOS+96
  STA sprite_YPOS+100
  STA sprite_YPOS+104
  STA sprite_YPOS+108
  CLC
  ADC #$08                              ; Add 8 to move to the next row
  STA sprite_YPOS+112
  STA sprite_YPOS+116
  STA sprite_YPOS+120
  STA sprite_YPOS+124

  LDA ship_x
  STA sprite_XPOS
  STA sprite_XPOS+16
  STA sprite_XPOS+32
  STA sprite_XPOS+48  
  CLC
  ADC #$08                              ; Add 8 to move to the next column
  STA sprite_XPOS+4
  STA sprite_XPOS+20
  STA sprite_XPOS+36
  STA sprite_XPOS+52  
  CLC
  ADC #$08                              ; Add 8 to move to the next column
  STA sprite_XPOS+8
  STA sprite_XPOS+24
  STA sprite_XPOS+40
  STA sprite_XPOS+56
  CLC
  ADC #$08                              ; Add 8 to move to the next column
  STA sprite_XPOS+12
  STA sprite_XPOS+28
  STA sprite_XPOS+44
  STA sprite_XPOS+60

  LDA ship_x
  STA sprite_XPOS+64
  STA sprite_XPOS+80
  STA sprite_XPOS+96
  STA sprite_XPOS+112  
  CLC
  ADC #$08                              ; Add 8 to move to the next column
  STA sprite_XPOS+68
  STA sprite_XPOS+84
  STA sprite_XPOS+100
  STA sprite_XPOS+116  
  CLC
  ADC #$08                              ; Add 8 to move to the next column
  STA sprite_XPOS+72
  STA sprite_XPOS+88
  STA sprite_XPOS+104
  STA sprite_XPOS+120
  CLC
  ADC #$08                              ; Add 8 to move to the next column
  STA sprite_XPOS+76
  STA sprite_XPOS+92
  STA sprite_XPOS+108
  STA sprite_XPOS+124
  RTI                                   ; return from interrupt

; Sub routines
SpriteDMA:                              ; Sprite DMA subroutine                     
  LDA #$00
  STA PPU_SPR_ADDR
  LDA #$02                                                        
  STA $4014
  RTS
VBlankWait:
  BIT $2002
  BPL VBlankWait
  RTS  
LoadPalette:
  LDA PPU_STATUS                        ; read PPU status to reset the high/low latch
  LDA #$3F
  STA PPU_ADDRESS                       ; write the high byte of $3F00 address
  LDA #$10
  STA PPU_ADDRESS                       ; write the low byte of $3F00 address
  LDX #$00                              ; start out at 0
LoadPaletteLoop:
  LDA palette, x                        ; load data from address (palette + the value in x)
  STA PPU_DATA                          ; write to PPU
  INX                                   ; X = X + 1
  CPX #$10                              ; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
  BNE LoadPaletteLoop                   ; Branch to LoadPalettesLoop if compare was Not Equal to zero
  RTS                                   ; if compare was equal to 32, keep going down 
SetShipTileConfig:
  LDX #$00
  LDY #$00
SetShipTileConfigLoop:                  ; Loop through the sprite setup / config and write it to the sprite addresses
  LDA ShipMainSpriteSetup, y
  STA sprite_Tile,x
  LDA ShipSpriteConfig, y
  STA sprite_Attr,x
  INX
  INX
  INX
  INX                                   ; Increment X four times to get to the next sprite
  INY
  CPY #$10
  BNE SetShipTileConfigLoop
  LDY #$00
SetShipPileTileConfigLoop:              ; Loop through the sprite setup / config and write it to the sprite addresses
  LDA ShipPileSpriteSetup, y
  STA sprite_Tile,x
  LDA ShipPileSpriteConfig, y
  STA sprite_Attr,x
  INX
  INX
  INX
  INX                                   ; Increment X four times to get to the next sprite
  INY
  CPY #$10
  BNE SetShipPileTileConfigLoop  
  RTS  
SaveControllerState:
  LDA #$00
  STA ControllerPort1
  LDA #$01
  STA ControllerPort1
  LDX #$08
SaveControllerStateLoop:
  LDA ControllerPort1
  LSR A
  ROL buttons
  DEX
  BNE SaveControllerStateLoop
  RTS

  .bank 1
  .org $E000

palette:
  .db $0F,$00,$10,$20, $0F,$01,$11,$26, $0F,$00,$10,$20, $0F,$01,$11,$26

ShipMainSpriteSetup:
  .db $00,$01,$02,$03, $10,$11,$12,$13, $20,$21,$22,$23, $30,$31,$32,$33

ShipPileSpriteSetup:
  .db $04,$05,$06,$07, $14,$15,$16,$17, $24,$25,$26,$27, $34,$35,$36,$37

ShipSpriteConfig:
  .db $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00

ShipPileSpriteConfig:
  .db $01,$01,$01,$01, $01,$01,$01,$01, $01,$01,$01,$01, $01,$01,$01,$01

  .org $FFFA     
  .dw NMI                                         ; NMI interupt, jump to NMI label
  .dw RESET                                       ; Reset interupt, jump to RESET label
  .dw 0                                           ; external interrupt IRQ is not used

  .bank 2
  .org $0000
  .incbin "spaceship.chr"