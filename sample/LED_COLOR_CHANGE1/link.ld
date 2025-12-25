OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
  RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 4K
}

SECTIONS
{
  . = 0x00000000;
  .text.init : 
  { 
    *(.text.init*) 
	 . = ALIGN(4);
  } > RAM

  .tohost : 
  {
    *(.tohost*) 
	 . = ALIGN(4);
  } > RAM
  
  .text : 
  {
    *(.text*)
	 . = ALIGN(4);
  } > RAM

  .rodata : {
    *(.rodata*)
    *(.srodata*)
    . = ALIGN(4);
  } > RAM

  _end_rodata_addr = .;

  .data _end_rodata_addr + SIZEOF(.data) : #AT ( _end_rodata_addr )
  { 
	 _start_data_addr = .;
    *(.data*)
    *(.sdata*)
    . = ALIGN(4);
  } > RAM AT > RAM
	 _end_data_addr = .;
  
   _load_data_top = LOADADDR(.data) ;

  .bss : {
    *(.bss*)
    *(.sbss*)
    . = ALIGN(4);
  } > RAM
    _end_bss_addr = .;
  
  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
