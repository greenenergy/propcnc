{{
First motor: P6, P7, P8

P6: Data pin
P7: Shift pin
P8: Output pin
}}

CON
_clkmode = xtal1+pll16x
_xinfreq = 5_000_000


PUB Main | x
  dira := $FFFFFFFF
  outa := %11 << 29
  repeat
    x := 0

{{
 Output bitmask:
 0: step
 1: direction
 2: ms1
 3: ms2
 4: ms3

So, to step once (full) clockwise, output 1, then output 0

To step once (full) counterclockwise, output 2, then 0

Since we're using a shift register, we build up the output mask from high to low

So, to output a 5 bit 1, the sequence is %10, %10, %10, %10, %11, %100
To putput a 5 bit 2, the sequence is     %10, %10, %10, %11, %10, %100


}}

  repeat 1000
    motor(1, 0)
    waitcnt(20_000+cnt)
    motor(0, 0)
    waitcnt(20_000+cnt)


PUB motor(val, pin) | accum
  val ><= 5  ' We want the low 5 bits, reversed
  repeat 5
    accum := val & 1
    outa := (accum) << pin
    outa := (%10) << pin
    val >>= 1


