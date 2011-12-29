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
  FORMAT     : "Format.spin"

VAR
  long motor_a[5], motor_b[5], motor_c[5], motor_d[5]
  long cogs[4]
  byte charstr[64]


PUB Main | x
  dira[20]~~

  motor_a[direction] := 1
  motor_a[distance] := 3000
  motor_a[delay] := 20_000

  motor_b[direction] := 0
  motor_b[distance] := 3000
  motor_b[delay] := 20_000

  Bootup


  motor_a[exec] := 2         ' go
  motor_b[exec] := 2         ' go


  LCD.Goto(0, 1)
  LCD.WriteString( string("Looping") )

  x := 1
  repeat
    LCD.Goto(0,2)
    FORMAT.itoa(x, @charstr)
    LCD.WriteString( @charstr )

    ' Now write out the execute flag
    LCD.Goto(0,3)
    FORMAT.itoa(motor_a[exec], @charstr)
    LCD.WriteString( @charstr )

    x += 1

    ' Every 10 steps, trigger the motor again. With the current parameters,
    ' it takes about 2-3 seconds for the motor to finish and set exec to 0.
    if (x//5) == 0
      motor_a[direction] ^= 1
      motor_a[exec] := 2

      motor_b[direction] ^= 1
      motor_b[exec] := 2

    outa[20] ^= 1
    waitcnt(cnt + (clkfreq/2))


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


  'cogs[0] := MOTOR.start(@motor_a)
  MOTOR.start(@motor_a)
  MOTOR.start(@motor_b)

  LCD.Goto(0, 0)
  LCD.WriteString( string("Motor Started ") )

  'cogs[1] = MOTOR.start(@motor_b)
  'cogs[2] = MOTOR.start(@motor_c)
  'cogs[3] = MOTOR.start(@motor_d)


