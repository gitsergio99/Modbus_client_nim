import modbusutil
import std/strformat
import std/strutils
import sequtils
import std/random
export modbusutil
export sequtils
import std/net
import serial


#Function to create request for reading regs from modbus device. Result of function is chars sequence with crc, what can transfer to serial port.

proc mb_request_read_rtu*(dev_adr:uint8,reg_adr:uint16,quantity:uint16,fn:mb_function):seq[char] = 
    var 
        res = newSeq[char]()
    res.add(cast_c(dev_adr))
    res.add(modbus_read_pdu(fn,reg_adr,quantity))
    res.add(crc16_seq(calc_CRC16(res)))
    return res

#Function to get data from rtu modbus device. May use two type of transport hardware serial port or serial port over tcp
proc mb_read_rtu*(dev_adr:uint8,reg_adr:uint16,quantity:uint16,fn:mb_function,transport:Socket|SerialPort):seq[char] =
    var
        res:seq[char] = @[]
        request:seq[char] = @[]
        bytes_to_send:int
        bytes_to_recv:int
        tcp_p:pointer
        ret:int
        str:string
        transportS:SerialPort
        buff:string
        tmp_str:string
    request = mb_request_read_rtu(dev_adr,reg_adr,quantity,fn)
    bytes_to_send = request.len
    # send data to transport
    if (fn == mb_function.r_coils) or (fn == mb_function.r_discret_inputs):
        bytes_to_recv = 5 + bytes_cnt(quantity)
    else:
        bytes_to_recv = 5 + int(quantity)*2
    when transport is Socket:
        tcp_p = addr(request[0])
        ret = transport.send(tcp_p,bytes_to_send)
        ret = transport.recv(str,3,3000)
        #echo fmt"two first bytes is {str.toHex.parseHexStr.toSeq()}"
        if cast[uint8](str.toHex.parseHexStr.toSeq()[1]) == uint8(fn.ord) and cast[uint8](str.toHex.parseHexStr.toSeq()[0]) == dev_adr:
            ret = transport.recv(tmp_str,bytes_to_recv-3,3000)
            str=str&tmp_str
            if  crc16_seq(calc_CRC16(str[0..str.len-3].toHex.parseHexStr.toSeq())) == str.toHex.parseHexStr.toSeq()[str.len-2..str.len-1]:
                str = str[3..str.len-3]
            else:
                str = "Bad CRC" 
        else:
            #ret = transport.recv(str,3,3000)
            str = "error code is "&str[2]&" Or may be wrong address "&str[0]
    else:
        transportS = transport
        #buff = newString(bytes_to_recv)
        buff = newString(3)
        ret = transportS.write(join(request,""))
        ret = transportS.read(buff)
        if cast[uint8](buff.toHex.parseHexStr.toSeq()[1]) == uint8(fn.ord) and cast[uint8](buff.toHex.parseHexStr.toSeq()[0]) == dev_adr:
            tmp_str = buff
            buff = newString(bytes_to_recv-3)
            ret = transportS.read(buff)
            str = tmp_str&buff
            if  crc16_seq(calc_CRC16(str[0..str.len-3].toHex.parseHexStr.toSeq())) == str.toHex.parseHexStr.toSeq()[str.len-2..str.len-1]:
                str = str[3..str.len-3]
            else:
                str = "Bad CRC" 
        else:
            str = "error code is "&buff[2]&" Or may be wrong address "&buff[0]
    res.add(str.toHex.parseHexStr.toSeq())
    return res




#Function to create request for writing regs to modbus device. Result of function is chars sequence with crc, what can transfer to serial port.
#proc mb_request_write*(dev_adr:uint8,reg_adr:uint16,quantity:uint16,fn:mb_function):seq[char] = 

proc mb_request_read_tcp*(dev_adr:uint8,reg_adr:uint16,quantity:uint16,fn:mb_function):seq[char] =
    var
        res = newSeq[char]()
        session_indentifer:uint16
        protocol_inditifer:uint16 = 0 #for modbus is always 0
        num_of_bytes:uint16 = 0
        pdu = newSeq[char]()
    randomize()
    session_indentifer = uint16(rand(10..255)) #sesion inditificator in replay from device is must be same
    #echo &"Session inditificator is {session_indentifer}"
    res.add(session_indentifer.toHex().parseHexStr().toSeq())
    res.add(protocol_inditifer.toHex().parseHexStr().toSeq())
    pdu.add(modbus_read_pdu(fn,reg_adr,quantity))
    num_of_bytes = uint16(pdu.len()) + 1
    res.add(num_of_bytes.toHex().parseHexStr().toSeq())
    res.add(cast_c(dev_adr))
    res.add(pdu)
    return res

#read data from tcp modbus device
proc mb_read_from_tcp*(dev_adr:uint8,reg_adr:uint16,quantity:uint16,fn:mb_function,soc:Socket):seq[char] =
    var
        res = newSeq[char]()
        num_of_bytes_to_recive:int
        request = newSeq[char]()
        request_pointer:pointer
        num_of_bytes_to_send:int
        str_res:string
        ret:int
        #num_bytes:int
    request = mb_request_read_tcp(dev_adr,reg_adr,quantity,fn)
    #echo &"Request is {request}"
    request_pointer = addr(request[0])
    num_of_bytes_to_send = request.len
    #calculate lenth of replay
    case fn
    of mb_function.r_mult_holding_regs:
        num_of_bytes_to_recive = request[request.len-1].int*2 + 9
    of mb_function.r_coils:
        num_of_bytes_to_recive = 9+bytes_cnt(quantity)
    of mb_function.r_discret_inputs:
        num_of_bytes_to_recive = 9+bytes_cnt(quantity)
    of mb_function.r_input_regs:
        num_of_bytes_to_recive = request[request.len-1].int*2 + 9
    else:
        num_of_bytes_to_recive = 11
    # send request to tcp and get replay
    ret = send(soc,request_pointer,num_of_bytes_to_send)
    ret = recv(soc,str_res,num_of_bytes_to_recive,timeout = 3000)
    # cut from replay data and pull to return
    res = str_res.toHex().parseHexStr().toSeq()
    #echo &"Replay is {res}"
    if res[0..3] == request[0..3]: #in repaly first fourth bytes must be same as first fourth bytes in request
        res = res[9..res.len-1]
    else:
        res = "Bad replay".toHex.parseHexStr.toSeq()
    return res

#create request to write data at modbus tcp device  
proc mb_request_write_tcp*(dev_adr:uint8,reg_adr:uint16,quantity:uint16,write_data:seq[uint16],fn:mb_function):seq[char] =
    var
        res = newSeq[char]()
        session_indentifer:uint16
        protocol_inditifer:uint16 = 0 #for modbus is always 0
        num_of_bytes:uint16 = 0
        pdu = newSeq[char]()
    randomize()
    session_indentifer = uint16(rand(10..255)) #sesion inditificator in replay from device is must be same
    #echo &"Session inditificator is {session_indentifer}"
    res.add(cast_u16(session_indentifer))
    res.add(cast_u16(protocol_inditifer))
    pdu.add(modbus_write_pdu(fn,reg_adr,quantity,write_data))
    num_of_bytes = uint16(pdu.len()) + 1
    res.add(cast_u16(num_of_bytes))
    res.add(cast_c(dev_adr))
    res.add(pdu)
    return res


#write data by tcp socket in modbus device
proc mb_write_tcp*(dev_adr:uint8,reg_adr:uint16,quantity:uint16,write_data:seq[uint16],fn:mb_function,soc:Socket):seq[char] =
    var
        res = newSeq[char]()
        num_of_bytes_to_recive:int
        request = newSeq[char]()
        request_pointer:pointer
        num_of_bytes_to_send:int
        ret:int
        str_res:string
    request = mb_request_write_tcp(dev_adr,reg_adr,quantity,write_data,fn)
    #echo &"Request is {request}"
    request_pointer = addr(request[0])
    num_of_bytes_to_send = request.len
    debug num_of_bytes_to_send
    #calculate lenth of replay
    if fn in [w_single_coil,w_mult_coils,w_single_holding_reg,w_mult_holding_regs,w_mask_regs]:
        if fn != mb_function.w_mask_regs:
            num_of_bytes_to_recive = 12
        else:
            num_of_bytes_to_recive = 14
    ret = send(soc,request_pointer,num_of_bytes_to_send)
    ret = recv(soc,str_res,num_of_bytes_to_recive,timeout = 3000)
    res = str_res.toHex().parseHexStr().toSeq()
    return res


#create request to read/write data at modbus tcp device f23  
proc mb_request_read_write_tcp_f23*(dev_adr:uint8,reg_adr_r:uint16,quantity_r:uint16,reg_adr_w:uint16,quantity_w:uint16,write_data:seq[uint16]):seq[char] =
    var
        res = newSeq[char]()
        session_indentifer:uint16
        protocol_inditifer:uint16 = 0 #for modbus is always 0
        num_of_bytes:uint16 = 0
        pdu = newSeq[char]()
    randomize()
    session_indentifer = uint16(rand(10..255)) #sesion inditificator in replay from device is must be same
    #echo &"Session inditificator is {session_indentifer}"
    res.add(cast_u16(session_indentifer))
    res.add(cast_u16(protocol_inditifer))
    pdu.add(read_write_pdu_f23(reg_adr_r,quantity_r,reg_adr_w,quantity_w,write_data))
    num_of_bytes = uint16(pdu.len()) + 1
    res.add(cast_u16(num_of_bytes))
    res.add(cast_c(dev_adr))
    res.add(pdu)
    return res



    #read/write data by tcp socket function 23
proc mb_read_write_tcp_f23*(dev_adr:uint8,reg_adr_r:uint16,quantity_r:uint16,reg_adr_w:uint16,quantity_w:uint16,write_data:seq[uint16],soc:Socket):seq[char] =
    var
        res = newSeq[char]()
        num_of_bytes_to_recive:int
        request = newSeq[char]()
        request_pointer:pointer
        num_of_bytes_to_send:int
        ret:int
        str_res:string
    request = mb_request_read_write_tcp_f23(dev_adr,reg_adr_r,quantity_r,reg_adr_w,quantity_w,write_data)
    #echo &"Request is {request}"
    request_pointer = addr(request[0])
    num_of_bytes_to_send = request.len
    #debug num_of_bytes_to_send
    num_of_bytes_to_recive = request[16].int + 9
    #debug num_of_bytes_to_recive
    ret = send(soc,request_pointer,num_of_bytes_to_send)
    ret = recv(soc,str_res,num_of_bytes_to_recive,timeout = 3000)
    res = str_res.toHex().parseHexStr().toSeq()
    return res

#create request modbus fuction 23 rtu
proc mb_request_read_write_f23_rtu*(dev_adr:uint8,reg_adr_r:uint16,quantity_r:uint16,reg_adr_w:uint16,quantity_w:uint16,write_data:seq[uint16]):seq[char] =
    var
        res = newSeq[char]()
        crc = newSeq[char]()
    
    res.add(cast_c(dev_adr))
    res.add(read_write_pdu_f23(reg_adr_r,quantity_r,reg_adr_w,quantity_w,write_data))
    crc.add(calc_CRC16(res).toHex.parseHexStr.toSeq())
    res.add(crc[1])
    res.add(crc[0])
    return res

#get data from rtu device fuction 23
proc mb_read_write_f23_rtu*(dev_adr:uint8,reg_adr_r:uint16,quantity_r:uint16,reg_adr_w:uint16,quantity_w:uint16,write_data:seq[uint16],transport:Socket|SerialPort):seq[char] =
    var
        res = newSeq[char]()
        request = newSeq[char]()
        bytes_to_send:int
        bytes_to_recv:int
        tcp_p:pointer
        ret:int
        str:string
        buff:string
        tmp_str:string

    request = mb_request_read_write_f23_rtu(dev_adr,reg_adr_r,quantity_r,reg_adr_w,quantity_w,write_data)
    tcp_p = addr(request[0])
    bytes_to_send = request.len
    bytes_to_recv = 5 + int(quantity_r)*2
    when transport is Socket:
        ret = transport.send(tcp_p,bytes_to_send)
        ret = transport.recv(str,3)
        if cast[uint8](str.toHex.parseHexStr.toSeq()[1]) == uint8(23) and cast[uint8](str.toHex.parseHexStr.toSeq()[0]) == dev_adr:
            ret = transport.recv(tmp_str,bytes_to_recv-3,3000)
            str =str&tmp_str
            #
            if  crc16_seq(calc_CRC16(str[0..str.len-3].toHex.parseHexStr.toSeq())) == str.toHex.parseHexStr.toSeq()[str.len-2..str.len-1]:
                str = str[3..str.len-3]
            else:
                str = "Bad CRC"
        else:
            str = "error code is "&str[2]&" .Or may be wrong address "&str[0]  
    else:
        buff = newString(3)
        ret = transport.write(join(request,""))
        ret = transport.read(buff)
        if cast[uint8](buff.toHex.parseHexStr.toSeq()[1]) == uint8(23) and cast[uint8](buff.toHex.parseHexStr.toSeq()[0]) == dev_adr:
            tmp_str = buff
            buff = newString(bytes_to_recv-3)
            ret = transport.read(buff)
            tmp_str = tmp_str&buff
            if  crc16_seq(calc_CRC16(tmp_str[0..tmp_str.len-3].toHex.parseHexStr.toSeq())) == tmp_str.toHex.parseHexStr.toSeq()[tmp_str.len-2..tmp_str.len-1]:
                str = buff[0..buff.len-3]
            else:
                str = "Bad CRC"
        else:
            str = "error code is "&buff[2]&" .Or may be wrong address "&buff[0]
    res.add(str.toHex.parseHexStr.toSeq())
    return res
    
#create modbus rtu write request
proc mb_request_write_rtu*(dev_adr:uint8,fn:mb_function,reg_adr:uint16,quantity:uint16,write_data:seq[uint16]):seq[char] = 
    var
       req:seq[char] = @[]
    req.add(cast_c(dev_adr))
    req.add(modbus_write_pdu(fn,reg_adr,quantity,write_data))
    req.add(crc16_seq(calc_CRC16(req)))
    return req

#write data to modbus rtu device
proc mb_write_rtu*(dev_adr:uint8,fn:mb_function,reg_adr:uint16,quantity:uint16,write_data:seq[uint16],transport:Socket|SerialPort):seq[char] =
    var
        req:seq[char] = @[]
        str:string
        tmp_str:string
        bytes_to_send:int
        bytes_to_recv:int
        point_c: pointer
        ret:int

    req = mb_request_write_rtu(dev_adr,fn,reg_adr,quantity,write_data)
    point_c = addr(req[0])
    bytes_to_send = req.len
    if fn == mb_function.w_mask_regs:
        bytes_to_recv = 10
    else:
        bytes_to_recv = 8 #common response from rtu device, when write data have 6 bytes lenth + 2 bytes crc16
    when transport is Socket:
        #if transport rtu over tcp
        ret = transport.send(point_c,bytes_to_send)
        ret = transport.recv(tmp_str,3,3000)
        if cast[uint8](tmp_str.toHex.parseHexStr.toSeq()[1]) == uint8(fn.ord) and cast[uint8](tmp_str.toHex.parseHexStr.toSeq()[0]) == dev_adr:
            str = tmp_str
            ret = transport.recv(tmp_str,bytes_to_recv - 3)
            str = str&tmp_str
            #echo str.toHex.parseHexStr.toSeq()
            #echo crc16_seq(calc_CRC16(str[0..str.len-3].toHex.parseHexStr.toSeq()))
            #echo str.toHex.parseHexStr.toSeq()[str.len-2..str.len-1]
            if  crc16_seq(calc_CRC16(str[0..str.len-3].toHex.parseHexStr.toSeq())) == str.toHex.parseHexStr.toSeq()[str.len-2..str.len-1]:
                str = str[2..str.len - 2]
            else:
                str = "Bad CRC"
        else:
            str = "error code is "&tmp_str[2]&" .Or may be wrong address "&tmp_str[0]
    else:
        #if transport Serial port
        ret = transport.write(join(req,""))
        tmp_str = newString(3)
        ret = transport.read(tmp_str)
        if cast[uint8](tmp_str.toHex.parseHexStr.toSeq()[1]) == uint8(fn.ord) and cast[uint8](tmp_str.toHex.parseHexStr.toSeq()[0]) == dev_adr:
            str = tmp_str
            tmp_str = newString(bytes_to_recv - 3)
            ret =transport.read(tmp_str)
            str = str&tmp_str
            #echo str.toHex.parseHexStr.toSeq()
            #echo crc16_seq(calc_CRC16(str[0..str.len-3].toHex.parseHexStr.toSeq()))
            #echo str.toHex.parseHexStr.toSeq()[str.len-2..str.len-1]
            if  crc16_seq(calc_CRC16(str[0..str.len-3].toHex.parseHexStr.toSeq())) == str.toHex.parseHexStr.toSeq()[str.len-2..str.len-1]:
                str = str[2..str.len - 2]
            else:
                str = "Bad CRC"
        else:
            str = "error code is "&tmp_str[2]&" .Or may be wrong address "&tmp_str[0]
    return str.toHex.parseHexStr.toSeq()


