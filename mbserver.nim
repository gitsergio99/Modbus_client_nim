import modbusutil
var
    discret_inputs_bank : array[0..65635,uint8]
    coils_bank : array[0..65535,uint8]
    input_registers_bank : array[0..65535,uint16]
    holding_registers_bank : array[0..65535,uint16]