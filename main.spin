CON
_clkmode = xtal1+pll16x
_xinfreq = 5_000_000

exec = 0
firstpin = 1
direction = 2
distance = 3
delay = 4

OBJ
  LCD        : "Nokia5110.spin"
  MOTOR      : "motor.spin"

VAR
  long motor_a[5], motor_b[5], motor_c[5], motor_d[5]

  long cogs[4]


PUB Main | x

  Bootup

  motor_a[direction] := 1
  motor_a[distance] := 3000
  motor_a[delay] := 40_000
  motor_a[exec] := 2         ' go


  repeat
    x := 1
    waitcnt(cnt + (clkfreq/60))


PUB Bootup
  LCD.Init
  LCD.Clear
  LCD.Goto(0, 0)

  LCD.WriteString( string("Booting Motors") )

  motor_a[exec] := 0         ' stop
  motor_a[firstpin] := 6

  motor_b[exec] := 0
  motor_b[firstpin] := 9

  motor_c[exec] := 0
  motor_c[firstpin] := 12

  motor_d[exec] := 0
  motor_d[firstpin] := 15

  ' ----------------------------


  cogs[0] := MOTOR.start(@motor_a)
  'cogs[1] = MOTOR.start(@motor_b)
  'cogs[2] = MOTOR.start(@motor_c)
  'cogs[3] = MOTOR.start(@motor_d)


