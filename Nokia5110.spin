{{
Display driver for the 84x48 pixel Nokia 5110 display from Sparkfun (uses PCD8544 display driver chip)

http://www.sparkfun.com/products/10168

Copyright (C) 2011 by Jason Dorie
See end of file for terms of use

Notes:

Preset the various PIN_ constants to suit your needs.

If you're going to enable the LED pin, do so carefully, as it does not appear to
have a resistor inline - current consumption at 3.3v is probably damaging.  PWM-ing
or using a current limiting resistor is advised.

The LCD VOP (contrast) value is currently set to $20 (32) which is 1/4 the allowable range.


Sample usage:

OBJ
  LCD        : "Nokia5110.spin"

PUB Main

  LCD.Init
  LCD.Clear
  LCD.Goto(0, 0)

  LCD.WriteString( string("Hello world.") )

}}

CON
  _clkmode = xtal1+pll16x
  _xinfreq = 5_000_000

  PIN_SCE  = 0 '29   'Serial clock enable pin
  PIN_RST  = 1 '28   'Reset pin
  PIN_DC   = 2 '27   'Data / Command selection pin
  PIN_SDIN = 3 '26   'Serial Data pin
  PIN_SCLK = 4 '25   'Serial Clock pin
  PIN_LED  = 5 '24   'LED backlight enable pin

  LCD_C = 0       'Command value constant
  LCD_D = 1       'Data value constant



PUB Init

''Initialize the display driver.  Call this before anything else.

  OUTA[PIN_SDIN]~
  OUTA[PIN_SCLK]~
  
  DIRA[PIN_SCE]~~               'SCE pin = output
  DIRA[PIN_RST]~~               'RST pin = output
  DIRA[PIN_DC]~~                'D/C pin = output
  DIRA[PIN_SDIN]~~              'SDIN pin = output
  DIRA[PIN_SCLK]~~              'SCLK pin = output
  OUTA[PIN_RST]~                'RST pin = low
  OUTA[PIN_RST]~~               'RST pin = high (toggle to reset LCD device)
  OUTA[PIN_SCE]~~
  
  Write(LCD_C, $21)             'LCD Extended Commands.
  Write(LCD_C, $80 + $40)       'Set LCD Vop (Contrast)
  Write(LCD_C, $04)             'Set Temp coefficent to 0
  Write(LCD_C, $14)             'LCD bias mode 1:48
  Write(LCD_C, $0C)             'LCD in normal mode. 0x0d for inverse

  Write(LCD_C, $20)             'LCD Basic Commands, chip active, horizontal addressing
  Write(LCD_C, $0C)             'LCD Normal display mode
   
  DIRA[PIN_LED]~~               'LED pin = output
  OUTA[PIN_LED]~~                'LED pin = low



PUB Clear | i

''Clear the display

  repeat i from 0 to constant(84 * 48 / 8)
    Write(LCD_D, $00)


PUB WriteString( address )

''Write a null terminated string from the current cursor location

  repeat while( byte[address] <> 0 )
    WriteChar( byte[address] )
    address++


{
'Use the Propeller ROM font instead of the 5x8 pixel font supplied
'It doesn't look very good (it's sub-sampled), but it works, and means
'you can delete the WhiteChar routine and the character table at the end,
'which saves 480 bytes

PUB WritePropChar( Ch ) | address, i, j, by, OddEven
  address := $8010 + ((Ch >> 1) << 7)
  OddEven := Ch & 1
  repeat i from 0 to 14 step 2
    by := 0
    repeat j from 7 to 0
      by <<= 1
      by |= (long[address][j*2] >> (i * 2 + OddEven)) & 1
    Write( LCD_D, by )
}


PUB WriteChar( Ch ) | address, i

''Write a single character to the display.  Valid chars from $20 to $7f.
''Characters are stored as 5x8 bits.  Each 5x8 is followed by a blank vertical
''row, allowing for 14 characters wide, 6 rows high.  Note that characters do
''not need to start on a 6-pixel multiple.

  address := @CH_20 + ((Ch - $20) * 5)
  repeat i from 0 to 4
    Write( LCD_D, byte[address][i] )
  Write( LCD_D, 0 ) 'blank pixel between chars



PUB Goto(x, y)

''Move the internal cursor to x,y - valid values from (0,0) to (83,5)

  Write( LCD_C, $40 + y )
  Write( LCD_C, $80 + x )


PUB Write( DC , Data ) | i

''Write a single command or data byte to the device.  DC = LCD_C for a command, LCD_D for display data

  OUTA[PIN_DC] := DC
  OUTA[PIN_SCE]~                'Set SCE low

  repeat i from 7 to 0
    OUTA[PIN_SDIN] := (Data >> i) & 1
    OUTA[PIN_SCLK]~~
    OUTA[PIN_SCLK]~         'SDIN sample is taken here

  OUTA[PIN_SCE]~~               'Set SCE high


DAT
        'Bit definitions for the font table. Each character is stored as 5 bytes,
        'where each byte represents one vertical row of 8 pixels
        
        CH_20           byte    $00, $00, $00, $00, $00 ' 20 (space)  
        CH_21           byte    $00, $00, $5f, $00, $00 ' 21 !
        CH_22           byte    $00, $07, $00, $07, $00 ' 22 "
        CH_23           byte    $14, $7f, $14, $7f, $14 ' 23 #
        CH_24           byte    $24, $2a, $7f, $2a, $12 ' 24 $
        CH_25           byte    $23, $13, $08, $64, $62 ' 25 %
        CH_26           byte    $36, $49, $55, $22, $50 ' 26 &
        CH_27           byte    $00, $05, $03, $00, $00 ' 27 '
        CH_28           byte    $00, $1c, $22, $41, $00 ' 28 (
        CH_29           byte    $00, $41, $22, $1c, $00 ' 29 )
        CH_2a           byte    $14, $08, $3e, $08, $14 ' 2a *
        CH_2b           byte    $08, $08, $3e, $08, $08 ' 2b +
        CH_2c           byte    $00, $50, $30, $00, $00 ' 2c ,
        CH_2d           byte    $08, $08, $08, $08, $08 ' 2d -
        CH_2e           byte    $00, $60, $60, $00, $00 ' 2e .
        CH_2f           byte    $20, $10, $08, $04, $02 ' 2f /
        CH_30           byte    $3e, $51, $49, $45, $3e ' 30 0
        CH_31           byte    $00, $42, $7f, $40, $00 ' 31 1
        CH_32           byte    $42, $61, $51, $49, $46 ' 32 2
        CH_33           byte    $21, $41, $45, $4b, $31 ' 33 3
        CH_34           byte    $18, $14, $12, $7f, $10 ' 34 4
        CH_35           byte    $27, $45, $45, $45, $39 ' 35 5
        CH_36           byte    $3c, $4a, $49, $49, $30 ' 36 6
        CH_37           byte    $01, $71, $09, $05, $03 ' 37 7
        CH_38           byte    $36, $49, $49, $49, $36 ' 38 8
        CH_39           byte    $06, $49, $49, $29, $1e ' 39 9
        CH_3a           byte    $00, $36, $36, $00, $00 ' 3a :
        CH_3b           byte    $00, $56, $36, $00, $00 ' 3b ;
        CH_3c           byte    $08, $14, $22, $41, $00 ' 3c <
        CH_3d           byte    $14, $14, $14, $14, $14 ' 3d =
        CH_3e           byte    $00, $41, $22, $14, $08 ' 3e >
        CH_3f           byte    $02, $01, $51, $09, $06 ' 3f ?
        CH_40           byte    $32, $49, $79, $41, $3e ' 40 @
        CH_41           byte    $7e, $11, $11, $11, $7e ' 41 A
        CH_42           byte    $7f, $49, $49, $49, $36 ' 42 B
        CH_43           byte    $3e, $41, $41, $41, $22 ' 43 C
        CH_44           byte    $7f, $41, $41, $22, $1c ' 44 D
        CH_45           byte    $7f, $49, $49, $49, $41 ' 45 E
        CH_46           byte    $7f, $09, $09, $09, $01 ' 46 F
        CH_47           byte    $3e, $41, $49, $49, $7a ' 47 G
        CH_48           byte    $7f, $08, $08, $08, $7f ' 48 H
        CH_49           byte    $00, $41, $7f, $41, $00 ' 49 I
        CH_4a           byte    $20, $40, $41, $3f, $01 ' 4a J
        CH_4b           byte    $7f, $08, $14, $22, $41 ' 4b K
        CH_4c           byte    $7f, $40, $40, $40, $40 ' 4c L
        CH_4d           byte    $7f, $02, $0c, $02, $7f ' 4d M
        CH_4e           byte    $7f, $04, $08, $10, $7f ' 4e N
        CH_4f           byte    $3e, $41, $41, $41, $3e ' 4f O
        CH_50           byte    $7f, $09, $09, $09, $06 ' 50 P
        CH_51           byte    $3e, $41, $51, $21, $5e ' 51 Q
        CH_52           byte    $7f, $09, $19, $29, $46 ' 52 R
        CH_53           byte    $46, $49, $49, $49, $31 ' 53 S
        CH_54           byte    $01, $01, $7f, $01, $01 ' 54 T
        CH_55           byte    $3f, $40, $40, $40, $3f ' 55 U
        CH_56           byte    $1f, $20, $40, $20, $1f ' 56 V
        CH_57           byte    $3f, $40, $38, $40, $3f ' 57 W
        CH_58           byte    $63, $14, $08, $14, $63 ' 58 X
        CH_59           byte    $07, $08, $70, $08, $07 ' 59 Y
        CH_5a           byte    $61, $51, $49, $45, $43 ' 5a Z
        CH_5b           byte    $00, $7f, $41, $41, $00 ' 5b [
        CH_5c           byte    $02, $04, $08, $10, $20 ' 5c ¥
        CH_5d           byte    $00, $41, $41, $7f, $00 ' 5d ]
        CH_5e           byte    $04, $02, $01, $02, $04 ' 5e ^
        CH_5f           byte    $40, $40, $40, $40, $40 ' 5f _
        CH_60           byte    $00, $01, $02, $04, $00 ' 60 `
        CH_61           byte    $20, $54, $54, $54, $78 ' 61 a
        CH_62           byte    $7f, $48, $44, $44, $38 ' 62 b
        CH_63           byte    $38, $44, $44, $44, $20 ' 63 c
        CH_64           byte    $38, $44, $44, $48, $7f ' 64 d
        CH_65           byte    $38, $54, $54, $54, $18 ' 65 e
        CH_66           byte    $08, $7e, $09, $01, $02 ' 66 f
        CH_67           byte    $0c, $52, $52, $52, $3e ' 67 g
        CH_68           byte    $7f, $08, $04, $04, $78 ' 68 h
        CH_69           byte    $00, $44, $7d, $40, $00 ' 69 i
        CH_6a           byte    $20, $40, $44, $3d, $00 ' 6a j 
        CH_6b           byte    $7f, $10, $28, $44, $00 ' 6b k
        CH_6c           byte    $00, $41, $7f, $40, $00 ' 6c l
        CH_6d           byte    $7c, $04, $18, $04, $78 ' 6d m
        CH_6e           byte    $7c, $08, $04, $04, $78 ' 6e n
        CH_6f           byte    $38, $44, $44, $44, $38 ' 6f o
        CH_70           byte    $7c, $14, $14, $14, $08 ' 70 p
        CH_71           byte    $08, $14, $14, $18, $7c ' 71 q
        CH_72           byte    $7c, $08, $04, $04, $08 ' 72 r
        CH_73           byte    $48, $54, $54, $54, $20 ' 73 s
        CH_74           byte    $04, $3f, $44, $40, $20 ' 74 t
        CH_75           byte    $3c, $40, $40, $20, $7c ' 75 u
        CH_76           byte    $1c, $20, $40, $20, $1c ' 76 v
        CH_77           byte    $3c, $40, $30, $40, $3c ' 77 w
        CH_78           byte    $44, $28, $10, $28, $44 ' 78 x
        CH_79           byte    $0c, $50, $50, $50, $3c ' 79 y
        CH_7a           byte    $44, $64, $54, $4c, $44 ' 7a z
        CH_7b           byte    $00, $08, $36, $41, $00 ' 7b {
        CH_7c           byte    $00, $00, $7f, $00, $00 ' 7c |
        CH_7d           byte    $00, $41, $36, $08, $00 ' 7d }
        CH_7e           byte    $10, $08, $08, $10, $08 ' 7e (arrow left)
        CH_7f           byte    $78, $46, $41, $46, $78 ' 7f (arrow right)

{{

+------------------------------------------------------------------------------------------------------------------------------+
|                                                   TERMS OF USE: MIT License                                                  |
+------------------------------------------------------------------------------------------------------------------------------+
|Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    |
|files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    |
|modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software|
|is furnished to do so, subject to the following conditions:                                                                   |
|                                                                                                                              |
|The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.|
|                                                                                                                              |
|THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          |
|WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         |
|COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   |
|ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         |
+------------------------------------------------------------------------------------------------------------------------------+


}}
