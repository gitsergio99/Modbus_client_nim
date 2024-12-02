import std/strformat
import std/strutils
import modbusutil
import mbmaster
import std/net
import serial
var
    replay:seq[char] = @[]
    int_res:seq[int16] = @[]
    float_res:seq[float] = @[]
    replay_coils:seq[char] = @[]
    bools_rep:seq[bool] = @[]
    write_res:seq[char] = @[]
    p_c:pointer
    ret:int
    recv_str:string
let socket = newSocket()
socket.connect("192.168.127.254",Port(4001))
let srport = newSerialPort("COM8")
srport.open(9600, Parity.None, 8, StopBits.One)
#replay = mb_request_read_rtu(1,0,10,mb_function.r_mult_holding_regs)
#debugEcho replay
#p_c = addr(replay[0])
#ret = socket.send(p_c,replay.len)
#for i in 1..20:
#    ret = socket.recv(recv_str,1,3000)
#    echo recv_str.toHex()
#replay = mb_read_rtu(1,0,3,mb_function.r_mult_holding_regs,srport)
#replay = mb_read_write_f23_rtu(1,0,3,10,5,@[uint16(10),uint16(20),uint16(30),uint16(40),uint16(50)],socket)
replay = mb_write_rtu(1,mb_function.w_mask_regs,0,3,@[uint16(10),uint16(20),uint16(30)],socket)
echo replay
srport.close()
socket.close()
#replay = mb_read_rtu(1,0,10,mb_function.r_coils,socket)


#holding regs
#replay = mb_read_from_tcp(1,0,4,mb_function.r_input_regs,socket)
#int_res = seq_of_chars_to_hold_regs(replay)
#float_res = seq_of_chars_to_floats(replay,[2,3,0,1])
#echo &"replay is {replay}"
#echo &"int holding regs is {int_res}"
#echo &"in float is {float_res}"

#coils regs
#replay_coils = mb_read_from_tcp(1,0,23,mb_function.r_discret_inputs,socket)
#bools_rep = bytes_to_seq_of_bools(replay_coils,23)
#echo &"bools is {bools_rep}"
#write_res = mb_write_from_tcp(1,2,9,@[uint16(0xFFFF),uint16(0xFFFF)],mb_function.w_mask_regs,socket)
#echo &"return of writing is {write_res}"
#replay = mb_read_write_from_tcp_f23(1,0,5,10,5,@[uint16(0xffff),uint16(0xffff),uint16(0xffff),uint16(0xffff),uint16(0xffff)],socket)
#echo replay

