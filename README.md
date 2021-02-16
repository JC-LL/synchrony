# Synchrony

_**warning** : work in progress / experimental_

## A simple HDL
Synchrony is a tiny Hardware description DSL.

```
require "ha"                           # build your own libraries (here : reuse half adder!)

circuit Example
  input a,b,c,d                        # by default type is 'bit'
  output o1,o2

  sig s1,s2                            # intermediate signals

  o1=s1 and c and !d                   # simple expressions
  s1,s2=ha(a,b)                        # use library elements, positional mapping
  o2=(a and b) or (c and d) or reg(s2) # DFF named 'reg'  
end
```

Once compiled, this circuit 'Example' will be available for reuse. It is stored in a 'example.lib' file (that is simply a serialized version of Example).

<img src="./doc/example.png" width="80%">.


## Other grammar elements
Synchrony grammar is not fully stabilized yet. Here is an overview of the grammar planed so far :

```
circuit rca{N,M}       # integer parameterized circuit
  input a,b : uint{N}  # parameterized type
  input d   : uint{M}  # parameterized type
  output s  : uint{?}  # please infer
end


circuit test_1
  input  a,e   : bit
  input  b     : uint8
  output c     : int3[4]
  output d     : int23

  sig s1,s2,s3 : bit
  sig s4       : byte  # equiv uint8
  sig s5       : sbyte # -128 to 127, equiv int8
  sig s6,s7    : bit

  s1       = a and reg(e)        # reg syntax (async init with reg(e,0))
  s2       = s1 or e$(0)         # alternative reg syntax, with e init at 0
  s3       = !b[0] xor s2$$$(0)  # alternative not, bit access, 3 pipes using $
  d[21..0] = resize(0x7,15) _ b  # resizing followed by concatenation
  d[22]    = and3(s1,s2,s3)      # positional arguments call
  s6,s7    = ha(a,e)             # positional circuit returns
  s4       = b*2                 # hummm result will be on size(b)+1
                                 # +,-,*,/,rem,mod
end
```
## Install

```
gem install synchrony
```
Note that synchrony depends on rtl_circuit Ruby gem.
