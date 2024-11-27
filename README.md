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
Contains few compleated functions to operate with modbus protocol.
### mb_read_rtu (dev_adr:uint8,reg_adr:uint16,quantity:uint16,fn:mb_function,transport:Socket|SerialPort):seq[char] :
<br> Use for read data from ModBus RTU devices (mb fn: 1,2,3,4). Example:
<br> mb_read_rtu (1,0,7,mb_fucntion.r_coils,serial) -> sequence of chars: Read state of coils 0-6 from device '1' over serial port.
<br> Result will be sequence contain 1 char(1 byte): 7 coils state packed to 1 byte.


