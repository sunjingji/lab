/*
            Copyright Oliver Kowalke 2009.
   Distributed under the Boost Software License, Version 1.0.
      (See accompanying file LICENSE_1_0.txt or copy at
            http://www.boost.org/LICENSE_1_0.txt)
*/

/****************************************************************************************
 *                                                                                      *
 *  ----------------------------------------------------------------------------------  *
 *  |    0    |    1    |    2    |    3    |    4     |    5    |    6    |    7    |  *
 *  ----------------------------------------------------------------------------------  *
 *  |   0x0   |   0x4   |   0x8   |   0xc   |   0x10   |   0x14  |   0x18  |   0x1c  |  *
 *  ----------------------------------------------------------------------------------  *
 *  | fc_mxcsr|fc_x87_cw|        R12        |         R13        |        R14        |  *
 *  ----------------------------------------------------------------------------------  *
 *  ----------------------------------------------------------------------------------  *
 *  |    8    |    9    |   10    |   11    |    12    |    13   |    14   |    15   |  *
 *  ----------------------------------------------------------------------------------  *
 *  |   0x20  |   0x24  |   0x28  |  0x2c   |   0x30   |   0x34  |   0x38  |   0x3c  |  *
 *  ----------------------------------------------------------------------------------  *
 *  |        R15        |        RBX        |         RBP        |        RIP        |  *
 *  ----------------------------------------------------------------------------------  *
 *                                                                                      *
 ****************************************************************************************/

.file "jump_x86_64_sysv_elf_gas.S"
.text
.globl jump_fcontext
.type jump_fcontext,@function
.align 16
jump_fcontext:
    /* 栈上有调用函数压入的返回地址, 无需再分配空间 */
    leaq  -0x38(%rsp), %rsp /* prepare stack */

#if !defined(BOOST_USE_TSX)
    stmxcsr  (%rsp)     /* save MMX control- and status-word */
    fnstcw   0x4(%rsp)  /* save x87 control-word */
#endif

    movq  %r12, 0x8(%rsp)  /* save R12 */
    movq  %r13, 0x10(%rsp)  /* save R13 */
    movq  %r14, 0x18(%rsp)  /* save R14 */
    movq  %r15, 0x20(%rsp)  /* save R15 */
    movq  %rbx, 0x28(%rsp)  /* save RBX */
    movq  %rbp, 0x30(%rsp)  /* save RBP */

    /* store RSP (pointing to context-data) in RAX */
    movq  %rsp, %rax

    /* restore RSP (pointing to context-data) from RDI */
    movq  %rdi, %rsp

    movq  0x38(%rsp), %r8  /* restore return-address */

#if !defined(BOOST_USE_TSX)
    ldmxcsr  (%rsp)     /* restore MMX control- and status-word */
    fldcw    0x4(%rsp)  /* restore x87 control-word */
#endif

    movq  0x8(%rsp), %r12  /* restore R12 */
    movq  0x10(%rsp), %r13  /* restore R13 */
    movq  0x18(%rsp), %r14  /* restore R14 */
    movq  0x20(%rsp), %r15  /* restore R15 */
    movq  0x28(%rsp), %rbx  /* restore RBX */
    movq  0x30(%rsp), %rbp  /* restore RBP */

    leaq  0x40(%rsp), %rsp /* prepare stack */

    /* return transfer_t from jump */
    /* RAX == fctx, RDX == data */
		/* example:
		 *   co_a:                            co_b:
		 *                                    ......
		 *	      														t = jump_fcontext(to_co_x, ...);
		 *   jump_fcontext(to_co_b, data1);
		 *			                              t.fctx ==> co_a
		 *																		t.data = data1
		 * 注1: 从co_b跳转到co_x,一段时间以后co_a被激活,co_a又跳转到co_b执行.
		 * 注2: 可以看出,jump_fcontext跳转的目的co,和返回的co不一定是同一个co.
		 */
    movq  %rsi, %rdx
    /* pass transfer_t as first arg in context function */
    /* RDI == fctx, RSI == data */
		/* 初次进入context function函数时有用 */
    movq  %rax, %rdi

    /* indirect jump to context */
    jmp  *%r8
.size jump_fcontext,.-jump_fcontext

/* Mark that we don't need executable stack.  */
.section .note.GNU-stack,"",%progbits
