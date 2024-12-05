# Modbus_master_nim
Modbus rtu, tcp master lib for nim programming language.
## Supported ModBus fucntions: 
<br>                                01 (0x01) Read Coils
<br>                           02 (0x02) Read Discrete Inputs
<br>                           03 (0x03) Read Holding Registers
<br>                           04 (0x04) Read Input Registers
<br>                           05 (0x05) Write Single Coil
<br>                            06 (0x06) Write Single Register
<br>                            15 (0x0F) Write Multiple Coils
<br>                            16 (0x10) Write Multiple registers
<br>                            22 (0x16) Mask Write Register
<br>                            23 (0x17) Read/Write Multiple registers
<br>
***
ModBus TCP use std\net Socket. ModBus RTU use SerialPort from serial lib or std\net Socket for RTU over TCP.
# How to use
## mbmaster.nim
Contains few compleated functions to operate with modbus protocol:
###### mb_read_rtu (dev_adr,reg_adr,quantity,fn,transport) ->> seq[char]
<br> Use to read data from Modbus RTU devices (mb fn: 1,2,3,4). Example:
<br> mb_read_rtu (1,0,7,mb_fucntion.r_coils,serial) -> Read state of coils 0-6 from device '1' over serial port.
<br> Result is sequence contain 1 char(1 byte): 7 coils state packed to 1 byte.
###### mb_write_rtu (dev_adr,fn,reg_adr,quantity,write_data,transport)->> seq[char]
<br> Use to write data to Modbus RTU devices (mb fn:5,6,15,16,22). Example:
<br> mb_write_rtu(2,mb_fucntion.w_mult_coils,0,15,@[0b1111111111111111'u16,0xFFFF,0x0000],socket) -> 
<br> Write coils 0-14 on device 2 rtu over tcp. Excessive data no matter.
<br> Result is sequence contain response of device.
###### mb_read_write_f23_rtu(dev_adr,reg_adr_r,quantity_r,reg_adr_w,quantity_w,write_data,transport) ->>seq[char]
<br> Use to read/write to Modbus RTU device mb fn 23. Example:
<br> mb_read_write_f23_rtu(1,0,3,10,5,@[uint16(10),uint16(20),uint16(30),uint16(40),uint16(50)],socket) ->
<br> Read holding registers 0-2 and write data to holding registers 10-14.
<br> Result is values of holding registers 0-2.
***
<br> Use fuctions:
<br> mb_read_write_tcp_f23
<br> mb_read_from_tcp
<br> mb_write_tcp
<br> to Modbus TCP devices.
<br> Also if need only request could use fucntions such as: mb_request_write_tcp, mb_request_read_rtu etc.
<br> Result of these fucntions is Modbus request.
# modbus utils library
<br> modbusutil.nim has lot of useful functions, such as:
######calc_CRC16(buf: openArray[char|uint8]): uint16
<br> Calculate Modbus CRC16 value which use in serial communication.
###### modbus_read_pdu , modbus_write_pdu , read_write_pdu_f23 ->> seq[char]
<br>Create Modbus PDU(Protocol data unit).
###### seq_of_chars_to_hold_regs(rgs:seq[char]):seq[int16]
<br>Transform sequence of chars(bytes) which reads from modbus device to sequence of int16
###### seq_of_chars_to_floats(rgs:seq[char],float_pattern:array[0..3,int]):seq[float]
<br>Transform sequence of chars(bytes) which reads from modbus device to sequence of floats.
<br>Diffrent devices use different formats of float(sequance of bytes in floats).
<br>By float_pattern you can set sequence of bytes of float like this:
<br>float_pattern =[0,1,2,3] or float_pattern =[2,3,0,1] or other.
###### seq_of_float_to_seq_of_chars(flts:seq[float32],float_pattern:array[0..3,int]):seq[char]
<br> Transform seq of floats to chars(bytes) to write to modbus device.
###### bytes_to_seq_of_bools(bts:seq[char],quantity:int):seq[bool]
<br> State of coils and state of discrete inputs packted to bytes by rules of modbus protocol.
<br> Proc unpack to sequence of bools.
###### bools_pack_to_bytes*(bls:seq[bool]):seq[char]
<br> Pack sequence of bools to bytes. Unuseble bits fill by zero.


