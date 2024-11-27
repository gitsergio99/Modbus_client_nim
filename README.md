# Modbus_client_nim
Modbus rtu, tcp client lib for nim programming language.
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
## mbclient.nim
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
