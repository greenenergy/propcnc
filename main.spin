CON
_clkmode = xtal1+pll16x
_xinfreq = 5_000_000

OBJ
  LCD        : "Nokia5110.spin"
  MOTOR      : "motor.spin"

VAR
  long
PUB Main
  Bootup()

PUB Bootup
  LCD.Init
  LCD.Clear
  LCD.Goto(10, 10)

  LCD.WriteString( string("Booting Motors") )


