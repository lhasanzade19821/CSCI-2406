To decode each instruction, I first converted every hexadecimal value into its 32-bit binary form.
In ARM32, every instruction begins with a 4-bit condition field followed by bits that identify the instruction type.
Once the instruction type is known, the remaining bits can be split into fields (opcode, registers, immediate values, offsets),
which makes it possible to understand what each part of the instruction does.

------------------------------------------------------------

e3a01000

Binary:
1110 00 1 1101 0 0000 0001 000000000000

Cond = AL (always)
Instruction type = Data processing
Immediate bit = 1 (immediate value is used)
Opcode = MOV
Rd = r1
Src2 = #0

Final instruction:
MOV r1, #0

------------------------------------------------------------

e3a0200a

Binary:
1110 00 1 1101 0 0000 0010 000000001010

Cond = AL
Data processing instruction
Immediate value present
Opcode = MOV
Rd = r2
Src2 = #10

Final instruction:
MOV r2, #10

------------------------------------------------------------

From this point, I noticed that the first part of the instruction (condition, instruction type, opcode, immediate bit)
is the same as in the previous MOV instructions. Therefore, only the destination register and the immediate value change.

e3a03000

Binary:
1110 00 1 1101 0 0000 0011 000000000000

Final instruction:
MOV r3, #0

------------------------------------------------------------

e3a04005

Binary:
1110 00 1 1101 0 0000 0100 000000000101

Using the same decoding logic as before:

Final instruction:
MOV r4, #5

------------------------------------------------------------

e0535004

Binary:
1110 00 0 0010 1 0011 0101 000000000100

Cond = AL
Instruction type = Data processing
Immediate bit = 0 (register operand)
Opcode = SUB
S bit = 1 (NZCV flags are updated)
Rn = r3
Rd = r5
Src2 = r4

Final instruction:
SUBS r5, r3, r4

------------------------------------------------------------

b0800002

Binary:
1011 00 0 0100 0 0000 0000 000000000010

Cond = LT (less than)
Data processing instruction
Immediate bit = 0
Opcode = ADD
Rn = r0
Rd = r0
Src2 = r2

Final instruction:
ADDLT r0,r0,r2

------------------------------------------------------------

b2833001

Binary:
1011 00 1 0100 0 0011 0011 000000000001

Cond = LT
Data processing instruction
Immediate bit = 1
Opcode = ADD
Rn = r3
Rd = r3
Src2 = #1

Final instruction:
ADDLt r3,r3,#1

------------------------------------------------------------

bafffffb

Binary:
1011 10 10 111111111111111111111011

Cond = LT
Instruction type = Branch

The 24-bit offset is negative.
To find its value: we should invert all bits, Add 1

Result = −5 (decimal)

This means the branch jumps 5 instructions back relative to the PC.
Because the PC already points two instructions ahead during execution,
the actual target must be represented using a label in the final code.

Final instruction:
BLT <label>

------------------------------------------------------------

ebffffff

Binary:
1110 10 11 111111111111111111111111

Cond = AL
Instruction type = Branch with link (BL)

Offset field is −1, meaning execution continues at the next instruction,
but the link register (LR) is updated.
This also requires a label when reconstructing the program.

Final instruction:
BL <label>

------------------------------------------------------------

e52de004

Binary:
1110 01 0 1 0 0 1 0 1101 1110 000000000100

Cond = AL
Instruction type = Single data transfer
Immediate offset
Pre-indexed addressing
Write-back enabled
Opcode = STR
Base register = r13 (sp)
Destination register = r14 (lr)
Offset = −4

Final instruction:
STR lr, [sp, #-4]!

------------------------------------------------------------

e3a0400f

Binary:
1110 00 1 1101 0 0000 0100 000000001111

Cond = AL
Data processing instruction
Immediate value present
Opcode = MOV
Rd = r4
Src2 = #15

Final instruction:
MOV  r4, #15

------------------------------------------------------------

e3a0500a

Binary:
1110 00 1 1101 0 0000 0101 000000001010

Decoded using the same method as previous MOV instructions.

Final instruction:
MOV r5, #10

------------------------------------------------------------

e0856004

Binary:
1110 00 0 0100 0 0101 0110 000000000100

Cond = AL
Data processing instruction
Immediate bit = 0
Opcode = ADD
Rn = r5
Rd = r6
Src2 = r4

Final instruction:
ADD r6, r5, r4

------------------------------------------------------------

e0535004

This instruction is identical to the earlier SUBS instruction.

Final instruction:
SUBS r5, r3, r4

------------------------------------------------------------

eafffff9

Binary:
1110 10 10 111111111111111111111001

Cond = AL
Instruction type = Branch

Offset calculation gives −7 (decimal).
This causes a jump several instructions back, which again requires a label.

Final instruction:
B <label>

------------------------------------------------------------

Reconstruction of the Program Logic

Draft structure (before adding labels):

_start:
    mov r1, #0
    mov r2, #10
    mov r3, #0
    mov r4, #5
    subs r5, r3, r4
    addlt r0, r0, r2
    addlt r3, r3, #1
    blt back
    bl forward
    str lr, [sp, #-4]!
    mov r4, #15
    mov r5, #10
    add r6, r5, r4
    subs r5, r3, r4
    b loop

From the branch offsets, two labels are required.
Two different branch instructions jump to the same location, so one label is reused.

------------------------------------------------------------

Final reconstructed code:

_start:
    mov r1, #0
    mov r2, #10
    mov r3, #0
    mov r4, #5

loop1:
    subs r5, r3, r4
    addlt r0, r0, r2
    addlt r3, r3, #1
    blt loop1
    bl loop2

loop2:
    str lr, [sp, #-4]!
    mov r4, #15
    mov r5, #10
    add r6, r5, r4
    subs r5, r3, r4
    b loop2

------------------------------------------------------------

Explanation of the Crash:

The crash happens because 

    STR lr, [sp, #-4]!

pushes a word onto the stack on every iteration of the loop. Since the loop is infinite and there is no corresponding pop instruction to restore the stack pointer, the stack keeps growing downward without bound. This results in a stack overflow, where the stack eventually exceeds its allocated memory region. When the program then attempts to write to an invalid memory address, a memory fault occurs and the program crashes.


Youtube Video link: 
https://youtu.be/RRnSibGoVHM 