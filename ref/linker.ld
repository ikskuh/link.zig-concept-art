
/* SPDX-License-Identifier: MIT */

PHDRS
{
	hdrseg    PT_LOAD;
	codeseg   PT_LOAD;
	rodataseg PT_LOAD;
	dataseg   PT_LOAD;
}

SECTIONS
{
	__start_xip  = 0x42000000;
	__start_sram = 0x40800000;
	__section_alignment = 8;
	
	/* RAM sections. */
	. = __start_sram;
	__start_data = .;
	.data : AT(SIZEOF(.esphdr) + SIZEOF(.espseg.0)) {
		__global_pointer$ = .;
		*(.data) *(.data*)
		*(.sdata) *(.sdata*)
		. = ALIGN(__section_alignment);
	} :dataseg
	__stop_data = .;
	
	__start_bss = .;
	.bss : {
		*(.bss) *(.bss*)
		 *(.sbss*)
		. = ALIGN(__section_alignment);
	} :NONE
	__stop_bss = .;
	
	/* FLASH sections. */
	. = __start_xip;
	
	/* ESP image header. */
	.esphdr : AT(0) {
		BYTE(0xE9);			/* Magic byte. */
		BYTE(3);			/* Segment count. */
		BYTE(0x02);			/* SPI mode. */
		BYTE(0x10);			/* SPI speed/size. */
		LONG(_start);		/* Entrypoint. */
		BYTE(0xee);			/* WP pin state. */
		BYTE(0x00);			/* Drive settings. */
		BYTE(0x00);
		BYTE(0x00);
		SHORT(0x000D);		/* Chip (ESP32-C6). */
		BYTE(0x00);			/* (deprecated) */
		SHORT(0x0000);		/* Min chip rev. */
		SHORT(0x0000);		/* Max chip rev. */
		LONG(0x00000000);	/* (reserved) */
		BYTE(0x00);			/* SHA256 appended (not appended). */
	} :hdrseg
	
	/* ESP image segment 0. */
	.espseg.0 : AT(LOADADDR(.esphdr) + SIZEOF(.esphdr)) {
		LONG(__start_data);
		LONG(__stop_data - __start_data);
	} :hdrseg
	
	/* Defined above: Initialised data segment. */
	. = . + SIZEOF(.data);
	
	/* ESP image segment 1. */
	.espseg.1 : AT(LOADADDR(.data) + SIZEOF(.data)) {
		LONG(__start_text);
		LONG(__stop_text - __start_text);
	} :codeseg
	
	/* Code sections. */
	__start_text = .;
	.text : AT(LOADADDR(.espseg.1) + SIZEOF(.espseg.1)) {
		. = ALIGN(256);
		*(.interrupt_vector_table)
		*(.text) *(.text*)
		. = ALIGN(__section_alignment);
	} :codeseg
	__stop_text = .;
	
	/* ESP image segment 2. */
	.espseg.2 : AT(LOADADDR(.text) + SIZEOF(.text)) {
		LONG(__start_rodata);
		LONG(__stop_rodata - __start_rodata);
	} :rodataseg
	
	/* Read-only data sections. */
	__start_rodata = .;
	.init_array : AT(LOADADDR(.espseg.2) + SIZEOF(.espseg.2)) {
		/* Create symbols to keep track of `.init_array`. */
		__start_init_array = .;
		KEEP(*(.init_array))
		__stop_init_array = .;
	} :rodataseg
    
	.rodata : AT(LOADADDR(.init_array) + SIZEOF(.init_array)) {
		*(.rodata) *(.rodata*)
		*(.srodata) *(.srodata*)
		. = ALIGN(__section_alignment);
	} :rodataseg
	__stop_rodata = .;
}

ENTRY(_start)