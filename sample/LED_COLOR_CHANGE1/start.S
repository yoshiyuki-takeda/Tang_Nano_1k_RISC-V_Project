
.extern _stack_top        /* スタック先頭アドレス */
.extern _load_data_top    /* .dataセクションのコピー元のアドレス */
.extern _start_data_addr  /* .dataセクションの先頭アドレス */
.extern _end_data_addr    /* .dataセクションの終端アドレス 兼 .bssセクションの先頭アドレス */
.extern _end_bss_addr     /* .dataセクションの終端アドレス */
.extern main              /* メイン関数 */

        .section .text.init
        .globl _start
  /* li 即値,la ラベル値 */
_start:
  la sp,_stack_top   /* スタックポインタをメインメモリの最終番地に設定 */
  
_copy_initial_data:  /* .dataセクションの初期化 */
  la t0,_load_data_top
  la t1,_start_data_addr
  la t2,_end_data_addr
_loop_copy_initial_data:
  beq t1,t2,_init_bss
  lw  t3,0(t0)
  sw  t3,0(t1)
  addi t0,t0,4
  addi t1,t1,4
  j _loop_copy_initial_data
  
_init_bss:  /* .bssセクションの初期化 */
  la t1,_end_bss_addr
_loop_init_bss:
  beq t1,t2,_goto_main
  sw  zero,0(t2)
  addi t2,t2,4
  j  _loop_init_bss
  
_goto_main:
  j  main            /* メイン関数呼び出し */

_infinite_loop:
  j  _infinite_loop

