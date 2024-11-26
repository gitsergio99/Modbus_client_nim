import std/net
import serial
import modbusutil

#proc test(sport:SerialPort|)


var
    lst_chars:seq[char] = @['\x00','\xFF','\x01','\x10','j','n']
    s:string


let socket = newSocket()
let srport = newSerialPort("COM21")

s = seq_to_str(lst_chars)
echo socket is SerialPort
echo srport is SerialPort
echo s
echo s.len
echo bytes_cnt(uint16(2))
echo mb_function.r_w_mult_holding_regs.ord