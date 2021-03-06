/*
 * Copyright (C) 2008 The Android Open Source Project
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <machine/asm.h>
#include "private/libc_events.h"

/*
 * This code assumes it is running on a processor that supports all arm v7
 * instructions, that supports neon instructions, and that has a 32 byte
 * cache line.
 */

        .syntax unified
        .fpu    neon
        .thumb
        .thumb_func

ENTRY(__memcpy_chk)
        cmp         r2, r3
        bhi         __memcpy_chk_fail

        // Fall through to memcpy...
END(__memcpy_chk)

ENTRY(memcpy)
        pld     [r1, #0]
        stmfd   sp!, {r0, lr}
        .save   {r0, lr}
        .cfi_def_cfa_offset 8
        .cfi_rel_offset r0, 0
        .cfi_rel_offset lr, 4
        pld     [r1, #64]
END(memcpy)

#define MEMCPY_BASE         __memcpy_base
#define MEMCPY_BASE_ALIGNED __memcpy_base_aligned
#include "memcpy_base.S"

ENTRY_PRIVATE(__memcpy_chk_fail)
        // Preserve lr for backtrace.
        push    {lr}
        .save   {lr}
        .cfi_def_cfa_offset 4
        .cfi_rel_offset lr, 0

        ldr     r0, error_message
        ldr     r1, error_code
1:
        add     r0, pc
        bl      __fortify_chk_fail
error_code:
        .word   BIONIC_EVENT_MEMCPY_BUFFER_OVERFLOW
error_message:
        .word   error_string-(1b+4)
END(__memcpy_chk_fail)

        .data
error_string:
        .string     "memcpy: prevented write past end of buffer"
