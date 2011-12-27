{{
motor.spin

This is the motor control program for my reprap. I really should come up with a project name for my electronics.

Step patterns
  MS1 MS2 MS3
   0   0   0    Full Step
   1   0   0    Half Step
   0   1   0    Quarter Step
   1   1   0    Eighth Step
   1   1   1    Sixteenth Step

   So, flipping them into normal bit order
   %000  0 Full
   %001  1 Half
   %010  2 Quarter
   %011  3 Eighth
   %111  7 Sixteenth

   These values are to be shifted left by 2, because the low two bits are "step" and "direction".

Output pins from shift register:
  P0 : Step
  P1 : Direction
  P2 : MS1
  P3 : MS2
  P4 : MS3

So a full step one direction is: %00011
Other direction:                 %00001

Half step one direction: %00111
Other direction          %00101

So: (Stepsize << 2) | (direction << 1) | 1

----
USAGE:
The motor module will run in a cog, and it will monitor a shared block of memory for position commands.

To tell the motor to go somewhere, give it a distance, a direction, and an inter-step delay.

The control structure will be used as so:
  execute
  firstpin
  direction
  distance
  interstep delay

So - fill out the distance, direction and delay values, and then set 'execute' to 2. When
the motor controller sees the execute value set to 2, it then reads the other values and
then sets execute to 1, meaning "moving now". When it arrives, it sets execute to 0.

Notes:
It seems to me that the best place to use microstepping is when running the motor slowly, so we
can have a smoother line. You tend to see step aliasing when using long shallow lines. This is a
case where one motor would be going very slowly. That would be a good place to use 16th stepping.
The question is - what do we use as an interstep delay? I guess I can figure out what the full
step delay would be, and then divide that delay by 16 for the 16th step, so in a given period of
time we move the same distance, but in 16 steps instead of one.

When you start the cog, make sure that the firstpin value is correct before starting it,
because this is loaded once and then cached for the duration.

Questions:
* What about curves? That will require acceleration/deceleration, and two motors will have to be in sync
* What about linear acceleration/deceleration to take into account the fact that the head cannot move instantaneously?

}}
CON
'_clkmode = xtal1+pll16x
'_xinfreq = 5_000_000

'VAR
'  long  cog

PUB start(ptr) : cog

  cog := cognew(@entry, ptr) +1

PUB stop(cog)

  if cog
    cogstop(cog~ -1 )

DAT
        ORG   0
        ' x = firstpin
        ' Px   = Input for the next pin that gets shifted in - SER, pin 14
        ' Px+1 = Shifts the register by 1                    - SRCLK, pin 11
        ' Px+2 = Sets the output pins to the register value  - RCLK, pin 12
entry
              mov             base, par
              mov             execute_addr, base
              add             base, #4
              mov             firstpin_addr, base
              add             base, #4
              mov             direction_addr, base
              add             base, #4
              mov             distance_addr, base
              add             base, #4
              mov             delay_addr, base

              rdlong          firstpin, firstpin_addr



''              rdlong          delay, delay_addr
''              mov             accum,#15                 ' set the direction register
''              shl             accum, #16
''              mov             dira, accum
''              mov             accum, firstpin
''              shl             accum, #16             ' now take the firstpin & shift into LED position
''              mov             outa, accum            ' and light up some leds
''stophere
''              waitcnt         time, idledelay
''              jmp             #stophere


              mov             accum, #%111
              shl             accum, firstpin
              mov             dira, accum                                       ' set the output mask


'              ' Make sure our output pins are working
'              mov             outa, accum
'stophere                                                ' <<<<<<<<<<<<<<<<<<<<<<<
'              waitcnt         time, idledelay           ' <<<<<<<<<<<<<<<<<<<<<<< Portable breakpoint
'              jmp             #stophere                 ' <<<<<<<<<<<<<<<<<<<<<<<


              mov             time, cnt
              add             time, idledelay
              mov             delay, idledelay
checkit
              waitcnt         time, delay
              rdlong          execute, execute_addr
              cmp             execute, #2       wz                              ' Wait for main prog to signal us
   if_nz      jmp             #checkit


''stophere                                                ' <<<<<<<<<<<<<<<<<<<<<<<
''              waitcnt         time, idledelay           ' <<<<<<<<<<<<<<<<<<<<<<< Portable breakpoint
''              jmp             #stophere                 ' <<<<<<<<<<<<<<<<<<<<<<<

              wrlong          changing, execute_addr                                  ' Tell main prog we're on it

''stophere                                                ' <<<<<<<<<<<<<<<<<<<<<<<
''              waitcnt         time, idledelay           ' <<<<<<<<<<<<<<<<<<<<<<< Portable breakpoint
''              jmp             #stophere                 ' <<<<<<<<<<<<<<<<<<<<<<<


              rdlong          direction, direction_addr
              rdlong          distance, distance_addr
              rdlong          delay, delay_addr

              ' Ok, we have the data. Time for the output.

              ' First, build up the output value
              ' Then, output them one at a time to the shift register
              ' Then, trigger the shift register to output them all

              mov             stepsize, #%001           ' Force a step size of 1/2 steps
              mov             outercount, distance

loopstart
              mov             outaccum, stepsize        ' Get the step size
              shl             outaccum, #2              ' Shift it into position
              mov             accum, direction          ' Get the direction (0 = clockwise, 1 = counterclockwise)
              shl             accum, #1                 ' shift into position
              or              outaccum, accum           ' merge with outaccum
              or              outaccum, #1              ' set the 'step' bit in outaccum

              rev             outaccum, #5   ' Flip the low 5 bits so we can dump to shift register

              mov             loopcnt, #5
:shiftloop
              mov             accum, #0
              shr             outaccum, #1  wc
              rcl             accum, #1                 ' Set the low bit (the data bit) for the shift reg

              shl             accum, firstpin
              mov             outa, accum

              mov              accum, #%10               ' Set the shift-clock bit
              'or              accum, #%10               ' Set the shift-clock bit
              shl             accum, firstpin           ' Shift the composite into position
              mov             outa, accum               ' and output

              djnz            loopcnt, #:shiftloop

dump
              mov             accum, #%100              ' Now clock the accumulated register to its output pins
              shl             accum, firstpin
              mov             outa, accum

              waitcnt         time, delay               ' Wait a reasonable time
clear
              ' Now we need to set the step flag to 0 for the motor, so we will then be able to trigger it again.
              ' Question: I am turning on the step for a certain amount of time (20_000 cycles say). Do I need to turn
              ' it off for an equivalent time, or can I do it for a much shorter time? This could lead to much
              ' smoother and faster motor use.

              ' So now we just force out 5 0 characters and then wait
              mov             loopcnt, #5
:sloop
              mov             accum, #%10               ' clock out a full 5 zeros
              shl             accum, firstpin
              mov             outa, accum
              djnz            loopcnt, #:sloop

              mov             accum, #%100              ' Now clock the accumulated register to its output pins
              shl             accum, firstpin
              mov             outa, accum

              waitcnt         time, delay               ' Wait a reasonable time

              djnz            outercount, #loopstart

              wrlong          finished, execute_addr          ' Tell the master control that we're done
              jmp             #checkit

idledelay     long      20_000

changing      long      1                       ' Signal master controller we're under way
finished      long      0                       ' Signal master controller we're done

stepsize      res 1
delay         res 1
execute       res 1
distance      res 1
firstpin      res 1
direction     res 1
time          res 1

execute_addr   res 1
firstpin_addr  res 1
direction_addr res 1
distance_addr  res 1
delay_addr     res 1
loopcnt        res 1
outercount     res 1

outaccum   res   1
accum      res   1
base       res   1

