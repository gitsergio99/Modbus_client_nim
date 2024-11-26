# Modbus_client_nim
Modbus rtu, tcp client lib for nim programming language.
# Supported ModBus fucntions: 
<                        01 (0x01) Read Coils>
                            02 (0x02) Read Discrete Inputs
                            03 (0x03) Read Holding Registers
                            04 (0x04) Read Input Registers
                            05 (0x05) Write Single Coil
                            06 (0x06) Write Single Register
                            15 (0x0F) Write Multiple Coils
                            16 (0x10) Write Multiple registers
                            22 (0x16) Mask Write Register
                            23 (0x17) Read/Write Multiple registers
ModBus TCP use std\net Socket. ModBus RTU use SerialPort from serial lib or std\net Socket for RTU over TCP.


