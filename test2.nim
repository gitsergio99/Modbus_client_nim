import strformat
import std/strutils
import sequtils
var
    quantity:uint16 = 24
    num_bytes:uint16 = 0
    num_words:uint16 = 0
    data_words:seq[uint16] = @[0b1111111111111111'u16,56,23]
    res:seq[char]
    chars:char = '\b'
    char_seq:seq[char] = @['\x00','\x01','\x00','\x02','\x00','\x03']


if (quantity mod 8) > 0:
    num_bytes = (quantity div 8) + 1
else:
    num_bytes = quantity div 8

if (num_bytes mod 2) > 0:
    num_words = (num_bytes div 2) + 1
else:
    num_words = (num_bytes div 2)

echo fmt"number of bytes is {num_bytes}, number of words is {num_words}"
echo fmt"len of res[seq] is {res.len}"
for i in data_words:
    if uint16(res.len) <= num_bytes-1:
        res.add(i.toHex.parseHexStr().toSeq()[0])
    else:
        break
    if uint16(res.len) <= num_bytes-1:
        res.add(i.toHex.parseHexStr().toSeq()[1])
    else:
        break
echo res
echo &"char into int is {chars.int}"

var
    i:int = 0
    temp_str:string
    res_s:seq[int16]    
    float_char:seq[char] = @['\x00','\x00','\x41','\x28']
    temp_float:float
    str_32:string
    flt_32:float32 = 10.5
while i < char_seq.len:
    temp_str = (char_seq[i]&char_seq[i+1]).toHex()
    echo &"temp str is {temp_str}"
    res_s.add(temp_str.fromHex[:int16])
    i = i + 2
echo &"result is {res_s}"

str_32 = (float_char[2]&float_char[3]&float_char[0]&float_char[1]).toHex()

temp_float = cast[float32](str_32.fromHex[:uint32])
echo &"float is {temp_float}"
echo &"10.5 in hex is {cast[uint32](flt_32).toHex().parseHexStr().toSeq()}"