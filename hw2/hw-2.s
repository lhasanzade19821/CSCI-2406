.text
        .global _start        @ Make _start visible to the linker (program entry point)

_start:
        mov     r1, #0        @ r1 = 0 (initialize register, not used later)
        mov     r2, #10       @ r2 = 10 (constant value used for addition)
        mov     r3, #0        @ r3 = 0 (loop counter / index)
        mov     r4, #5        @ r4 = 5 (loop limit)

L1:
        subs    r5, r3, r4    @ r5 = r3 - r4, sets condition flags
                             @ If r3 < r4 → result is negative

        addlt   r0, r0, r2    @ If r3 < r4: r0 = r0 + 10
        addlt   r3, r3, #1   @ If r3 < r4: increment r3 by 1
        blt     L1            @ If r3 < r4: branch back to label L1

        bl      L2            @ Call subroutine L2 (branch with link)

L2:
        str     lr, [sp, #-4]! @ Push link register onto stack (save return address)
        mov     r4, #15       @ r4 = 15
        mov     r5, #10       @ r5 = 10
        add     r6, r5, r4    @ r6 = r5 + r4 = 25
        subs    r5, r3, r4    @ r5 = r3 - r4, updates flags
        b       L2            @ Infinite loop: branch back to L2