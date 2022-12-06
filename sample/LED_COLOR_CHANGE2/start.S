
        .section .text.init
        .globl _start
_start: /* 汎用レジスタの初期化 */
  li x1, 0
  li x2, 0xffc /* スタックポインタをメインメモリの最終番地に設定 */
  li x3, 0
  li x4, 0
  li x5, 0
  li x6, 0
  li x7, 0 
  li x8, 0
  li x9, 0
  li x10, 0
  li x11, 0
  li x12, 0
  li x13, 0
  li x14, 0
  li x15, 0
  li x16, 0
  li x17, 0
  li x18, 0
  li x19, 0
  li x20, 0
  li x21, 0
  li x22, 0
  li x23, 0
  li x24, 0
  li x25, 0
  li x26, 0
  li x27, 0
  li x28, 0
  li x29, 0
  li x30, 0
  li x31, 0
  call main

        .align 4
        .global _interrupt_entry
_interrupt_entry: /*    割り込み処理のエントリーポイント
                        ダンプして、ここのアドレスをINT_VECTORにセットする */
  addi sp, sp, -4*32 # sp =sp1 -4*32mm
  sw x1, 0*4(sp)
  sw x3, 1*4(sp)
  sw x4, 2*4(sp)
  sw x5, 3*4(sp)
  sw x6, 4*4(sp)
  sw x7, 5*4(sp)
  sw x8, 6*4(sp)
  sw x9, 7*4(sp)
  sw x10, 8*4(sp)
  sw x11, 9*4(sp)
  sw x12, 10*4(sp)
  sw x13, 11*4(sp)
  sw x14, 12*4(sp)
  sw x15, 13*4(sp)
  sw x16, 14*4(sp)
  sw x17, 15*4(sp)
  sw x18, 16*4(sp)
  sw x19, 17*4(sp)
  sw x20, 18*4(sp)
  sw x21, 19*4(sp)
  sw x22, 20*4(sp)
  sw x23, 21*4(sp)
  sw x24, 22*4(sp)
  sw x25, 23*4(sp)
  sw x26, 24*4(sp)
  sw x27, 25*4(sp)
  sw x28, 26*4(sp)
  sw x29, 27*4(sp)
  sw x30, 28*4(sp)
  sw x31, 29*4(sp)

  call  interrupt_hander // C言語の割り込み処理を呼び出し

  lw x1, 0*4(sp)
  lw x3, 1*4(sp)
  lw x4, 2*4(sp)
  lw x5, 3*4(sp)
  lw x6, 4*4(sp)
  lw x7, 5*4(sp)
  lw x8, 6*4(sp)
  lw x9, 7*4(sp)
  lw x10, 8*4(sp)
  lw x11, 9*4(sp)
  lw x12, 10*4(sp)
  lw x13, 11*4(sp)
  lw x14, 12*4(sp)
  lw x15, 13*4(sp)
  lw x16, 14*4(sp)
  lw x17, 15*4(sp)
  lw x18, 16*4(sp)
  lw x19, 17*4(sp)
  lw x20, 18*4(sp)
  lw x21, 19*4(sp)
  lw x22, 20*4(sp)
  lw x23, 21*4(sp)
  lw x24, 22*4(sp)
  lw x25, 23*4(sp)
  lw x26, 24*4(sp)
  lw x27, 25*4(sp)
  lw x28, 26*4(sp)
  lw x29, 27*4(sp)
  lw x30, 28*4(sp)
  lw x31, 29*4(sp)
  addi sp, sp, 4*32 # sp =sp1 -4*32mm

  mret; // 割り込みからの復帰

