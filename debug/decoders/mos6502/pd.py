##
## This file is part of the libsigrokdecode project.
##
## Copyright (C) 2017 David Banks <dave@hoglet.com>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.
##

import sigrokdecode as srd
from functools import reduce
from .tables import addr_mode_len_map, instr_table, AddrMode
import string

class Ann:
    DATA, FETCH, OP1, OP2, MEMRD, MEMWR, INSTR, INTR, ADDR = range(9)

class Row:
    DATABUS, INSTRUCTIONS, ADDRESS = range(3)

class Pin:
    D0, D7 = 0, 7
    RNW, SYNC, RDY, PHI2, IRQN, NMIN, RSTN = range(8, 15)
    A0, A15 = 15, 30

class Cycle:
    FETCH, OP1, OP2, MEMRD, MEMWR = range(5)

cycle_to_ann_map = {
    Cycle.FETCH: Ann.FETCH,
    Cycle.OP1:   Ann.OP1,
    Cycle.OP2:   Ann.OP2,
    Cycle.MEMRD: Ann.MEMRD,
    Cycle.MEMWR: Ann.MEMWR,
}

cycle_to_name_map = {
    Cycle.FETCH: 'Fetch',
    Cycle.OP1:   'Op1',
    Cycle.OP2:   'Op2',
    Cycle.MEMRD: 'Read',
    Cycle.MEMWR: 'Write',
}

def signed_byte(byte):
    return byte if byte < 128 else byte - 256

def reduce_bus(bus):
    if 0xFF in bus:
        return None # unassigned bus channels
    else:
        return reduce(lambda a, b: (a << 1) | b, reversed(bus))

class Decoder(srd.Decoder):
    api_version = 3
    id       = 'mos6502'
    name     = 'MOS6502'
    longname = 'Mostek 6502 CPU'
    desc     = 'Mostek 6502 microprocessor disassembly.'
    license  = 'gplv3+'
    inputs   = ['logic']
    outputs  = ['mos6502']
    channels = tuple({
            'id': 'd%d' % i,
            'name': 'D%d' % i,
            'desc': 'Data bus line %d' % i
            } for i in range(8)
    ) + (
        {'id': 'rnw', 'name': 'RNW', 'desc': 'Memory read or write'},
        {'id': 'sync', 'name': 'SYNC', 'desc': 'Sync - opcode fetch'},
    )
    optional_channels = (
         {'id': 'rdy',  'name': 'RDY',  'desc': 'Ready, allows for wait states'},
         {'id': 'phi2', 'name': 'PHI2', 'desc': 'Phi2 clock, falling edge active'},
#        {'id': 'irq',  'name': 'IRQN', 'desc': 'Maskable interrupt'},
#        {'id': 'nmi',  'name': 'NMIN', 'desc': 'Non-maskable interrupt'},
#        {'id': 'rst',  'name': 'RSTN', 'desc': 'Reset'},
#    ) + tuple({
#        'id': 'a%d' % i,
#        'name': 'A%d' % i,
#        'desc': 'Address bus line %d' % i
#        } for i in range(16)
    )
    annotations = (
        ('data',   'Data bus'),
        ('fetch',  'Fetch opcode'),
        ('op1',    'Operand 1'),
        ('op2',    'Operand 2'),
        ('memrd',  'Memory Read'),
        ('memwr',  'Memory Write'),
        ('instr',  'Instruction'),
        ('intr',  'Interrupt'),
    )
    annotation_rows = (
        ('databus', 'Data bus', (Ann.DATA,)),
        ('cycle', 'Cycle', (Ann.FETCH, Ann.OP1, Ann.OP2, Ann.MEMRD, Ann.MEMWR)),
        ('instructions', 'Instructions', (Ann.INSTR, Ann.INTR)),
#        ('addrbus', 'Address bus', (Ann.ADDR,)),
    )

#    def __init__(self):

    def start(self):
        self.out_ann    = self.register(srd.OUTPUT_ANN)
        self.ann_data   = None

    def reset(self):
        # Reset decoder state here
        pass  # Even an empty method is fine if you don't need anything

    def decode(self):
        cyclenum             = 0
        last_sync_cyclenum   = 0
        last_sync_samplenum  = -1
        last_cycle_samplenum = -1
        opcount              = 0
        cycle                = Cycle.MEMRD
        mnemonic             = '???'
        opcode               = -1
        op1                  = 0
        op2                  = 0
        write_count          = 0
        pc                   = -1
        read_accumulator     = 0
        write_accumulator    = 0
        last_phi2            = None
        bus_data             = 0
        fmt                  = 'xxx'

        while True:
            # TODO: Come up with more appropriate self.wait() conditions.
            pins = self.wait()

            # Phi2 is optional
            # - if asynchronous capture is used, it must be connected
            # - if synchronous capture is used, it must not connected
            pin_phi2 = pins[Pin.PHI2]
            if pin_phi2 in (0, 1):
                # If Phi2 is present, look for the falling edge, and proceed with the previous sample
                if pin_phi2 == 1 or last_phi2 != 1:
                    last_phi2 = pin_phi2
                    pin_rdy   = pins[Pin.RDY]
                    pin_sync  = pins[Pin.SYNC]
                    pin_rnw   = pins[Pin.RNW]
                    continue
            else:
                # If Phi2 is not present, use the pins directly
                pin_rdy   = pins[Pin.RDY]
                pin_sync  = pins[Pin.SYNC]
                pin_rnw   = pins[Pin.RNW]

            # Sample data just after the falling edge, as there should be reasonable hold time
            pin_data  = pins[Pin.D0:Pin.D7+1]

            # At this point, either phi2 is not connected, or last_phi2 = 1 and phi2 = 0 (i.e. falling edge)
            last_phi2 = 0

            # Calculate the next data bus value
            bus_data = reduce_bus(pin_data)
            #print('bus data = ' + str(bus_data))

            # Ignore the cycle if RDY is low
            if pin_rdy == 0:
                continue

            # Sync indicates the start of a new instruction
            if pin_sync == 1:

                # For instructions that push the current address to the stack we
                # can use the stacked address to determine the current PC
                newpc = -1
                if write_count == 3:
                    # IRQ/NMI/RST
                    newpc = (write_accumulator >> 8) & 0xffff
                elif opcode == 0x20:
                    # JSR
                    newpc = (write_accumulator - 2) & 0xffff

                # Sanity check the current pc prediction has not gone awry
                if newpc >= 0:
                    if pc >= 0 and pc != newpc:
                        print('pc: prediction failed at ' + format(newpc, '04X') + ' old pc was ' + format(pc, '04X'))
                    pc = newpc

                pcs = '????' if pc < 0 else format(pc, '04X')
                if write_count == 3 and opcode != 0:
                    # Annotate an interrupt
                    self.put(last_sync_samplenum, last_cycle_samplenum, self.out_ann, [Ann.INTR, [pcs + ': ' + 'INTERRUPT !!']])
                else:
                    # Calculate branch target using op1 for normal branches and op2 for BBR/BBS
                    offset = signed_byte(op2 if (opcode & 0x0f == 0x0f) else op1)
                    if pc < 0:
                        if offset < 0:
                            target = 'pc-' + str(-offset)
                        else:
                            target = 'pc+' + str(offset)
                    else:
                        target = format(pc + 2 + offset, '04X')
                    # Annotate a normal instruction
                    self.put(last_sync_samplenum, last_cycle_samplenum, self.out_ann, [Ann.INSTR, [pcs + ': ' + fmt.format(mnemonic, op1, op2, target)]])

                # Look for control flow changes and update the PC
                if opcode == 0x40 or opcode == 0x00 or opcode == 0x6c or opcode == 0x7c or write_count == 3:
                    # RTI, BRK, INTR, JMP (ind), JMP (ind, X), IRQ/NMI/RST
                    pc = (read_accumulator >> 8) & 0xffff
                elif opcode == 0x20 or opcode == 0x4c:
                    # JSR abs, JMP abs
                    pc = op2 << 8 | op1
                elif opcode == 0x60:
                    # RTS
                    pc = (read_accumulator + 1) & 0xffff
                elif pc < 0:
                    # PC value is not known yet, everything below this point is relative
                    pc = -1
                elif opcode == 0x80:
                    # BRA
                    pc += signed_byte(op1) + 2
                elif (opcode & 0x0f) == 0x0f and cyclenum - last_sync_cyclenum != 2:
                    # BBR/BBS
                    pc += signed_byte(op2) + 2
                elif (opcode & 0x1f) == 0x10 and cyclenum - last_sync_cyclenum != 2:
                    # BXX: op1 if taken
                    pc += signed_byte(op1) + 2
                else:
                    # Otherwise, increment pc by length of instuction
                    pc += len

                last_sync_samplenum = last_cycle_samplenum
                last_sync_cyclenum  = cyclenum

                cycle    = Cycle.FETCH
                opcode   = bus_data
                instr    = instr_table[opcode]
                mnemonic = instr[0]
                mode     = instr[1]
                len      = addr_mode_len_map[mode][0]
                fmt      = addr_mode_len_map[mode][1]
                opcount  = len - 1
                write_count = 0
                read_accumulator = 0
                write_accumulator = 0

            elif pin_rnw == 0:
                cycle = Cycle.MEMWR
                write_count += 1
                write_accumulator = (write_accumulator << 8) | bus_data

            elif cycle == Cycle.FETCH and opcount > 0:
                cycle = Cycle.OP1
                opcount -= 1
                op1 = bus_data;

            elif cycle == Cycle.OP1 and opcount > 0:
                if (opcode == 0x20): # JSR is <opcode> <op1> <dummp stack rd> <stack wr> <stack wr> <op2>
                    cycle = Cycle.MEMRD
                else:
                    cycle = Cycle.OP2
                    opcount -= 1
                    op2 = bus_data

            else:
                if (opcode == 0x20): # JSR, see above
                    cycle = Cycle.OP2
                    opcount -= 1
                    op2 = bus_data
                else:
                    cycle = Cycle.MEMRD
                    read_accumulator = (read_accumulator >> 8) | (bus_data << 16)

            # Increment the cycle number (used only to detect taken branches)
            cyclenum += 1

            # In synchronus sampling, the alignment looks better with an offset of 1 cycle
            if pin_phi2 != 0:
                now = self.samplenum + 1
            else:
                now = self.samplenum

            # Output the per-cycle annotations for the last cycle
            self.put(last_cycle_samplenum, now, self.out_ann, [cycle_to_ann_map[cycle], [cycle_to_name_map[cycle]]])
            self.put(last_cycle_samplenum, now, self.out_ann, [Ann.DATA, [format(bus_data, '02X')]])

            last_cycle_samplenum = now
