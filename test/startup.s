$CASE ON

        ;; Begin startup code
	DEFSECT	".startup", CODE, SHORT
	SECT	".startup"

SWAP_MEM MACRO REG1,REG2 ;swap memory contents
         LD A,[_lab\?REG1] ;using A as temp
         LD B,[_lab\?REG2] ;using B as temp
         LD [_lab\?REG1],B
         LD [_lab\?REG2],A
         ENDM

__start_cpt:
__START:
        ;==========================================================================
        ;===================  system initialization  ==============================
        ;==========================================================================
        LD      SP, #02000h                      ; stack pointer initialize
        LD      BR, #020h                        ; BR register initialize to I/O area
        LD      [BR:21h], #0Ch
        LD      [BR:25h], #080h
        LD      [BR:80h], #08h
        LD      [BR:81h], #08h

        LD      [BR:27h], #0FFh                 ; Flush interrupts
        LD      [BR:28h], #0FFh
        LD      [BR:29h], #0FFh
        LD      [BR:2Ah], #0FFh

	CARL	__copytable
	CARL	_main
	CARL	__exit
	RETE

        GLOBAL  __start_cpt
        GLOBAL  __START
	EXTERN	(CODE) __copytable
	EXTERN	(CODE) _main
        EXTERN  (CODE) __exit
	CALLS	'_start_cpt', '_copytable'
	CALLS	'_start_cpt', 'main'
	CALLS	'_start_cpt', '_exit'

        END

        IF (1 + 2)
                ;JP [HL]
        else
                ;EXITM
        ENDIF
