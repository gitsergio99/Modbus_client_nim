import modbusutil
import std/strformat
import std/strutils
import std/parseutils
import sequtils

proc cast_c(ch:uint8):char =
    return cast[char](ch)

proc cast_u16(ch:uint16|uint32):seq[char] = 
    return ch.toHex().parseHexStr().toSeq()

var
    tm_str:string
    parsed:uint8
    res:int
    bls:seq[bool] = @[true,true,true,true,false,false,false,true,true,true,true,false,true]
    chrs:seq[char] = @[]
    fn:uint8  = 33
    test_u:uint32 = 0x21212121
tm_str = "11110000"
res = parseBin(tm_str,parsed)
echo &"parsed is {cast[char](parsed)}, res is {res}"

chrs = bools_pack_to_bytes(bls)
echo &"bls is {bls}"
for x in chrs:
    echo &"res is {int(x).toBin(8)}"

echo fmt"cast is {cast[char](fn)}"
echo fmt"cast is {cast_c(fn)}"
echo fmt"cast test_u is {cast_u16(test_u)}"
