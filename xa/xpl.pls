
main.a65

    1 A:1000                                    ;;; __   ________ _      ___  ___            _ _             
    2 A:1000                                    ;;; \ \ / /| ___ \ |     |  \/  |           (_) |            
    3 A:1000                                    ;;;  \ V / | |_/ / |     | .  . | ___  _ __  _| |_ ___  _ __ 
    4 A:1000                                    ;;;  /   \ |  __/| |     | |\/| |/ _ \| '_ \| | __/ _ \| '__|
    5 A:1000                                    ;;; / /^\ \| |   | |_32_ | |  | | (_) | | | | | || (_) | |   
    6 A:1000                                    ;;; \/   \/\_|   \_____/ \_|  |_/\___/|_| |_|_|\__\___/|_|   
    7 A:1000                                    ;;;
    8 A:1000                                    ;;; XPL-32 Monitor (Originally mitemon)
    9 A:1000                                    ;;; 
   10 A:1000                                    ;;; Very simple ROM monitor for the 6502 Mite single-board computer..
   11 A:1000                                    ;;; But this version is for the XPL-32.
   12 A:1000                                    ;;; Originally enough to poke around and make sure that things
   13 A:1000                                    ;;; are working.
   14 A:1000                                    ;;;
   15 A:1000                                    ;;; There are also some loading and saving stuff as well.
   16 A:1000                                    ;;;
   17 A:1000                                    ;;; This also technically acts as an OS for the XPL...
   18 A:1000                                    ;;;
   19 A:1000                                    ;;; v3 parses command line arguments
   20 A:1000                                    ;;; v4 does basic command dispatch and some simple commands
   21 A:1000                                    ;;; v5 rebuilding around a stack-based calling convention
   22 A:1000                                    ;;; v6 adding XMODEM to upload files and a memory test
   23 A:1000                                    ;;; v7 finished XMODEM, added "zero" command, rationalized code, squashed bugs
   24 A:1000                                    ;;; v8 added input command
   25 A:1000                                    ;;; v9 added disassembler
   26 A:1000                                    ;;; v10 software interrupt handling
   27 A:1000                                    ;;; v11 xpl-32 support, xplDOS, kansas city tape, and serial loading
   28 A:1000                                    ;;;
   29 A:1000                                    ;;; Paul Dourish, March-October 2017
   30 A:1000                                    ;;; Waverider, 2020-2023

   32 A:1000                                    ;;; My ROM is actually 32K, but half of the ROM is only visible at once.
   33 A:1000                                    ;;; So, everything starts at $C000.
   34 A:1000                                    ;;;

   36 A:1000                                    ;; TODO NEW COMMAND IDEA! Inputting ascii chars at an address (prototype text editing)

   38 A:1000                                     *= $c000

   40 A:c000                                    LCD_E=%10000000
   41 A:c000                                    LCD_RW=%01000000
   42 A:c000                                    LCD_RS=%00100000

   44 A:c000                                    SD_CS=%00010000
   45 A:c000                                    SD_SCK=%00001000
   46 A:c000                                    SD_MOSI=%00000100
   47 A:c000                                    SD_MISO=%00000010

   49 A:c000                                    PORTA_OUTPUTPINS=SD_CS|SD_SCK|SD_MOSI

   51 A:c000                                    ;;;;;;;;;;;;;;;;;
   52 A:c000                                    ;;;
   53 A:c000                                    ;;; Zero page and other storage areas. Various parts of the zero page
   54 A:c000                                    ;;; are used for scratch and for key data.
   55 A:c000                                    ;;;
   56 A:c000                                    ;;; A line of entered text is stored in INPUT. ARGINDEX is used
   57 A:c000                                    ;;; by the parser to record where each individual argument begins.
   58 A:c000                                    ;;; ARGINDEX[0] is a count of the number of words on the command
   59 A:c000                                    ;;; line. ARGINDEX[1-n] are pointers into where, inside INDEX, each
   60 A:c000                                    ;;; word begins (ie, ARGINDEX[1] is the index inside INPUT where
   61 A:c000                                    ;;; the first argument string begins).
   62 A:c000                                    ;;;
   63 A:c000                                    ;;;;;;;;;;;;;;;;;;

   65 A:c000                                    ;; these 16 address are basic scratch memory, for use only inside
   66 A:c000                                    ;; a few instructions... not guaranteed safe across a subroutine call,
   67 A:c000                                    ;; for instance.
   68 A:c000                                    ;;
   69 A:c000                                    SCRATCH=$10           ; through to $001F

   71 A:c000                                    ARGINDEX=$20           ; and on to $002F for up to 16 arguments
   72 A:c000                                    ;; block $0030-003F for xmodem variables
   73 A:c000                                    ;; $0040 is free
   74 A:c000                                    ;; $0041 is free
   75 A:c000                                    PRINTVEC=$42           ; and $0043. for printing routine.
   76 A:c000                                    ENTRY=$44           ; and $0045
   77 A:c000                                    MEMTESTBASE=$46           ; and $0047
   78 A:c000                                    ENDVEC=$0e           ; and $000f. for help and about routines
   79 A:c000                                    ; memory copy
   79 A:c000                                    
   80 A:c000                                    mem_source=$0a           ; and $0b
   81 A:c000                                    mem_copy=$0c           ; and $0d
   82 A:c000                                    mem_end=$0e           ; and $0f
   83 A:c000                                    ; sd card
   83 A:c000                                    
   84 A:c000                                    zp_sd_address=$48           ; 2 bytes
   85 A:c000                                    zp_sd_currentsector=$4a           ; 4 bytes
   86 A:c000                                    zp_fat32_variables=$4e           ; 49 bytes
   87 A:c000                                    ; only used during fat32 processing
   88 A:c000                                    path=$0400           ; page
   89 A:c000                                    fat32_workspace=$0500           ; two pages
   90 A:c000                                    buffer=$0700           ; 24 bytes
   91 A:c000                                    ; now, addresses $0705-$7ffc are free.

   93 A:c000                                    ;; $0080-00FF is my operand stack
   94 A:c000                                    ;; $0100-01FF is 6502 stack
   95 A:c000                                    INPUT=$0200           ; block out this page for monitor command input
   96 A:c000                                    ;; $0300-03FF is blocked for xmodem buffer
   97 A:c000                                    ;; $0400-04FF is blocked for xmodem testing (temporary)
   98 A:c000                                    ;;
   99 A:c000                                    ;; names of variables used in the scratchpad
  100 A:c000                                    ;;XYLODSAV2 = $10  ; temporary address for save command
  101 A:c000                                    STARTADDR=$12           ; for start addr for receive
  102 A:c000                                    ENDADDR=$14
  103 A:c000                                    serialvar=$16
  104 A:c000                                    ; only used in tape
  104 A:c000                                    
  105 A:c000                                    thing=$10           ; 1byt
  106 A:c000                                    tapest=$11           ; 1byt
  107 A:c000                                    cnt=$12           ; 2byt
  108 A:c000                                    len=$14           ; 2byt
  109 A:c000                                    cnt2=$15           ; 2byt
  110 A:c000                                    tapespeed=$17           ; 1byt
  111 A:c000                                    ;; xplDOS
  112 A:c000                                    fileext=$14           ; 1byt
  113 A:c000                                    filetype=$15           ; 1byt
  114 A:c000                                    folderpointer=$11           ; 2byt
  115 A:c000                                    pathindex=$16           ; 2byt
  116 A:c000                                    backdir=$18           ; 1byt
  117 A:c000                                    sc=$19           ; 1byt
  118 A:c000                                    ;dircnt  = $1a ; 1byt
  119 A:c000                                    savestart=$1a           ; 2byt
  120 A:c000                                    saveend=$10           ; 2byt
  121 A:c000                                    savepoint=$1c           ; 2byt
  122 A:c000                                    ;; vi..?
  123 A:c000                                    viaddr=$1a           ; 2byt
  124 A:c000                                    cursor_x=$1c           ; 1byt
  125 A:c000                                    cursor_y=$1d           ; 1byt
  126 A:c000                                    vif_end=$1e           ; 2byt

  128 A:c000                                    ;; startup enable
  129 A:c000                                    SEN=$7ffd
  130 A:c000                                    ;; after startup enable, there is a irq address.
  131 A:c000                                    ;; BUG THERE IS NO NMI! this is due to there being no NMI on the XPL-32 PCB. (not yet implemented)
  132 A:c000                                    ; 

  134 A:c000                                    ;;;;;;;;;;;;;;;;;
  135 A:c000                                    ;;;
  136 A:c000                                    ;;; Include standard startup code
  137 A:c000                                    ;;;
  138 A:c000                                    ;;;;;;;;;;;;;;;;;

  140 A:c000                           reset     

decl.a65

    1 A:c000                                    ;; Declarations of general use
    2 A:c000                                    ;; Mainly, these define where things are in the memory map of the
    3 A:c000                                    ;; 6502 Mite.
    4 A:c000                                    ;;
    5 A:c000                                    ;; Paul Dourish, January 1, 2017
    6 A:c000                                    ;;

    9 A:c000                                    ;; ACIA (6551) registers
   10 A:c000                                    ;;
   11 A:c000                                    ACIA_DATA=$8000
   12 A:c000                                    ACIA_STATUS=$8001
   13 A:c000                                    ACIA_COMMAND=$8002
   14 A:c000                                    ACIA_CONTROL=$8003

   16 A:c000                                    ;; VIA (6522) registers
   17 A:c000                                    ;;
   18 A:c000                                    VIA_PORTB=$b000
   19 A:c000                                    VIA_PORTA=$b001
   20 A:c000                                    VIA_DDRB=$b002
   21 A:c000                                    VIA_DDRA=$b003
   22 A:c000                                    VIA_T1CL=$b004
   23 A:c000                                    VIA_T1CH=$b005
   24 A:c000                                    VIA_T1LL=$b006
   25 A:c000                                    VIA_T1LH=$b007
   26 A:c000                                    VIA_T2LL=$b008
   27 A:c000                                    VIA_T2CL=$b008
   28 A:c000                                    VIA_T2CH=$b009
   29 A:c000                                    VIA_SR=$b00a
   30 A:c000                                    VIA_ACR=$b00b
   31 A:c000                                    VIA_PCR=$b00c
   32 A:c000                                    VIA_IFR=$b00d
   33 A:c000                                    VIA_IER=$b00e
   34 A:c000                                    VIA_ORAX=$b00f
   35 A:c000                                    PORTB=VIA_PORTB
   36 A:c000                                    PORTA=VIA_PORTA
   37 A:c000                                    DDRB=VIA_DDRB
   38 A:c000                                    DDRA=VIA_DDRA

main.a65

    1 A:c000  4c 80 c3                           jmp startup

  144 A:c003                                    ;;; Dispatch table
  145 A:c003                                    ;;;
  146 A:c003                                    ;;; each entry has a two-byte pointer to the next entry (or $0000 on end)
  147 A:c003                                    ;;; then a null-terminated string that names the command
  148 A:c003                                    ;;; then a two-type pointer for the code to execute the command
  149 A:c003                                    ;;;
  150 A:c003                           table     
  151 A:c003  0d c0                              .word table1
  152 A:c005  61 62 6f 75 74 00                  .byt "about",$00
  153 A:c00b  9b c7                              .word aboutcmd
  154 A:c00d                           table1    
  155 A:c00d  16 c0                              .word table2
  156 A:c00f  68 65 6c 70 00                     .byt "help",$00
  157 A:c014  ae c7                              .word helpcmd
  158 A:c016                           table2    
  159 A:c016  1f c0                              .word table3
  160 A:c018  64 75 6d 70 00                     .byt "dump",$00
  161 A:c01d  3c c8                              .word dumpcmd
  162 A:c01f                           table3    
  163 A:c01f  28 c0                              .word table4
  164 A:c021  65 63 68 6f 00                     .byt "echo",$00
  165 A:c026  cd c7                              .word echocmd
  166 A:c028                           table4    
  167 A:c028  31 c0                              .word table5
  168 A:c02a  70 6f 6b 65 00                     .byt "poke",$00
  169 A:c02f  f6 c7                              .word pokecmd
  170 A:c031                           table5    
  171 A:c031  38 c0                              .word table6
  172 A:c033  67 6f 00                           .byt "go",$00
  173 A:c036  71 c9                              .word gocmd
  174 A:c038                           table6    
  175 A:c038  41 c0                              .word table7
  176 A:c03a  74 65 73 74 00                     .byt "test",$00
  177 A:c03f  bb cc                              .word testcmd
  178 A:c041                           table7    
  179 A:c041  4d c0                              .word table8
  180 A:c043  6d 65 6d 74 65 73 74 00            .byt "memtest",$00
  181 A:c04b  6a e9                              .word memtestcmd
  182 A:c04d                           table8    
  183 A:c04d  55 c0                              .word table9
  184 A:c04f  64 69 73 00                        .byt "dis",$00
  185 A:c053  17 cf                              .word discmd
  186 A:c055                           table9    
  187 A:c055  62 c0                              .word table10
  188 A:c057  78 72 65 63 65 69 76 ...           .byt "xreceive",$00
  189 A:c060  bc cc                              .word xreceivecmd
  190 A:c062                           table10   
  191 A:c062  6b c0                              .word table11
  192 A:c064  7a 65 72 6f 00                     .byt "zero",$00
  193 A:c069  0a c9                              .word zerocmd
  194 A:c06b                           table11   
  195 A:c06b  75 c0                              .word table12
  196 A:c06d  69 6e 70 75 74 00                  .byt "input",$00
  197 A:c073  7f ce                              .word inputcmd
  198 A:c075                           table12   
  199 A:c075                                    ;.word table13
  200 A:c075                                    ;.byte "receive", $00
  201 A:c075                                    ;.word receivecmd
  202 A:c075                                    ;table13
  203 A:c075  7c c0                              .word table13
  204 A:c077  76 69 00                           .byt "vi",$00
  205 A:c07a  11 e8                              .word vicmd
  206 A:c07c                           table13   
  207 A:c07c  85 c0                              .word table14
  208 A:c07e  6c 6f 61 64 00                     .byt "load",$00
  209 A:c083  97 e4                              .word loadcmd
  210 A:c085                           table14   
  211 A:c085  8f c0                              .word table15
  212 A:c087  74 73 61 76 65 00                  .byt "tsave",$00
  213 A:c08d  a6 c9                              .word tsavecmd
  214 A:c08f                           table15   
  215 A:c08f  99 c0                              .word table16
  216 A:c091  74 6c 6f 61 64 00                  .byt "tload",$00
  217 A:c097  b7 cb                              .word tloadcmd
  218 A:c099                           table16   
  219 A:c099  a0 c0                              .word table17
  220 A:c09b  6c 73 00                           .byt "ls",$00
  221 A:c09e  03 e4                              .word lscmd
  222 A:c0a0                           table17   
  223 A:c0a0  a7 c0                              .word table18
  224 A:c0a2  63 64 00                           .byt "cd",$00
  225 A:c0a5  8f e2                              .word cdcmd
  226 A:c0a7                           table18   
  227 A:c0a7  af c0                              .word table19
  228 A:c0a9  63 61 74 00                        .byt "cat",$00
  229 A:c0ad  e4 e2                              .word catcmd
  230 A:c0af                           table19   
  231 A:c0af  b9 c0                              .word table20
  232 A:c0b1  63 6c 65 61 72 00                  .byt "clear",$00
  233 A:c0b7  a0 c9                              .word clearcmd
  234 A:c0b9                           table20   
  235 A:c0b9  c2 c0                              .word table21
  236 A:c0bb  73 61 76 65 00                     .byt "save",$00
  237 A:c0c0  b1 e5                              .word savecmd
  238 A:c0c2                           table21   
  239 A:c0c2  c9 c0                              .word table22
  240 A:c0c4  72 6d 00                           .byt "rm",$00
  241 A:c0c7  81 e6                              .word rmcmd
  242 A:c0c9                           table22   
  243 A:c0c9  d0 c0                              .word table23
  244 A:c0cb  6d 76 00                           .byt "mv",$00
  245 A:c0ce  bf e6                              .word mvcmd
  246 A:c0d0                           table23   
  247 A:c0d0  00 00                              .word $00              ; this signals it's the last entry in the table
  248 A:c0d2  72 74 69 00                        .byt "rti",$00
  249 A:c0d6  7c ce                              .word rticmd

  251 A:c0d8                                    ;; More utility routines
  252 A:c0d8                                    ;;

stack.a65

    1 A:c0d8                                    ;; 16-bit stack stuff -- core functionality

    3 A:c0d8                                    ;; Rather like the hadware stack, this stack lives on a dedicated page, and
    4 A:c0d8                                    ;; grows downwards. Unlike the regular stack, this one is a 16-bit stack, used
    5 A:c0d8                                    ;; for operands and parameters.
    6 A:c0d8                                    ;;
    7 A:c0d8                                    ;; the stack lives in the top half of the zero page, and grows downward,
    8 A:c0d8                                    ;; indexed by the x register (so $80+x indicates the next free byte).
    9 A:c0d8                                    ;; $80 and $81 hold the 16-bit value that is either going on to or coming
   10 A:c0d8                                    ;; off the stack.
   11 A:c0d8                                    ;;
   12 A:c0d8                                    ;; since $80,x gives us the next available stack slot, $81,x is the item
   13 A:c0d8                                    ;; on the top of the stack
   14 A:c0d8                                    ;;
   15 A:c0d8                                    ;; We push the big end first, so that the data is on the stack in little-
   16 A:c0d8                                    ;; endian format, which means we can do indirect addressing directly
   17 A:c0d8                                    ;; through objects on the stack.

   19 A:c0d8                                    stackaccess=$80
   20 A:c0d8                                    stackbase=$00

   23 A:c0d8                           initstack 
   24 A:c0d8  a2 ff                              ldx #$ff
   25 A:c0da  60                                 rts 

   27 A:c0db                           push16    
   28 A:c0db  a5 81                              lda stackaccess+1          ; first byte (big end)
   29 A:c0dd  95 00                              sta stackbase,x
   30 A:c0df  ca                                 dex 
   31 A:c0e0  a5 80                              lda stackaccess                ; second byte (little end)
   32 A:c0e2  95 00                              sta stackbase,x
   33 A:c0e4  ca                                 dex 
   34 A:c0e5  60                                 rts 

   36 A:c0e6                           pop16     
   37 A:c0e6  b5 01                              lda stackbase+1,x          ; the little end
   38 A:c0e8  85 80                              sta stackaccess
   39 A:c0ea  e8                                 inx 
   40 A:c0eb  b5 01                              lda stackbase+1,x          ; retrieve second byte
   41 A:c0ed  85 81                              sta stackaccess+1
   42 A:c0ef  e8                                 inx 
   43 A:c0f0  60                                 rts 

   45 A:c0f1                           dup16     
   46 A:c0f1  b5 02                              lda stackbase+2,x          ; copy big end byte to next available slot
   47 A:c0f3  95 00                              sta stackbase,x
   48 A:c0f5  ca                                 dex 
   49 A:c0f6  b5 02                              lda stackbase+2,x          ; do again for little end
   50 A:c0f8  95 00                              sta stackbase,x
   51 A:c0fa  ca                                 dex 
   52 A:c0fb  60                                 rts 

   54 A:c0fc                           swap16    

   56 A:c0fc  b5 02                              lda stackbase+2,x          ; copy big end byte to next available slot
   57 A:c0fe  95 00                              sta stackbase,x
   58 A:c100  ca                                 dex 
   59 A:c101  b5 02                              lda stackbase+2,x          ; do again for little end
   60 A:c103  95 00                              sta stackbase,x
   61 A:c105  ca                                 dex 

   65 A:c106  b5 05                              lda stackbase+5,x
   66 A:c108  95 03                              sta stackbase+3,x
   67 A:c10a  b5 06                              lda stackbase+6,x
   68 A:c10c  95 04                              sta stackbase+4,x

   70 A:c10e  b5 01                              lda stackbase+1,x
   71 A:c110  95 05                              sta stackbase+5,x
   72 A:c112  b5 02                              lda stackbase+2,x
   73 A:c114  95 06                              sta stackbase+6,x

   75 A:c116  e8                                 inx 
   76 A:c117  e8                                 inx 
   77 A:c118  60                                 rts 

   79 A:c119                                    ;; Add the two 16-byte words on the top of the stack, leaving
   80 A:c119                                    ;; the result on the stack in their place.
   81 A:c119                           add16     
   82 A:c119  18                                 clc                    ; clear carry
   83 A:c11a  b5 01                              lda stackbase+1,x          ; add the lower byte
   84 A:c11c  75 03                              adc stackbase+3,x
   85 A:c11e  95 03                              sta stackbase+3,x          ; put it back in the second slot
   86 A:c120  b5 02                              lda stackbase+2,x          ; then the upper byte
   87 A:c122  75 04                              adc stackbase+4,x
   88 A:c124  95 04                              sta stackbase+4,x          ; again, back in the second slot
   89 A:c126  e8                                 inx                    ; shink the stack so that sum is now
   90 A:c127  e8                                 inx                    ; in the top slot
   91 A:c128  60                                 rts 

   93 A:c129                                    ;; Subtract the two 16-byte words on the top of the stack, leaving
   94 A:c129                                    ;; the result on the stack in their place.
   95 A:c129                           sub16     
   96 A:c129  38                                 sec                    ; set the carry
   97 A:c12a  b5 03                              lda stackbase+3,x          ; substract the lower byte
   98 A:c12c  f5 01                              sbc stackbase+1,x
   99 A:c12e  95 03                              sta stackbase+3,x          ; put it back in the second slot
  100 A:c130  b5 04                              lda stackbase+4,x          ; then the upper byte
  101 A:c132  f5 02                              sbc stackbase+2,x
  102 A:c134  95 04                              sta stackbase+4,x          ; again, back in the second slot
  103 A:c136  e8                                 inx                    ; shink the stack so that result is now
  104 A:c137  e8                                 inx                    ; in the top slot
  105 A:c138  60                                 rts 

stackext.a65

    1 A:c139                                    ;; 16-bit stack stuff -- extended functionality

    3 A:c139                                    ;; Multiply the two 16-byte words on the top of the stack, leaving
    4 A:c139                                    ;; the result on the stack in their place.
    5 A:c139                           mult16    
    6 A:c139                                     .( 
    7 A:c139                                    ;; make some temporary space on the stack
    8 A:c139  ca                                 dex 
    9 A:c13a  ca                                 dex 

   11 A:c13b                                    ;stz templsb
   12 A:c13b                                    ;stz tempmsb
   13 A:c13b  74 01                              stz stackbase+1,x
   14 A:c13d  74 02                              stz stackbase+2,x

   16 A:c13f                                    ;; n1lsb stackbase+3,x
   17 A:c13f                                    ;; n1msb stackbase+4,x
   18 A:c13f                                    ;; n2lsb stackbase+5,x
   19 A:c13f                                    ;; n2msb stackbase+6,x
   20 A:c13f                           nextbit   
   21 A:c13f                                    ; first bit
   22 A:c13f  a9 01                              lda #$01
   23 A:c141  34 05                              bit stackbase+5,x
   24 A:c143  f0 0d                              beq nextshift
   25 A:c145                                    ; do addition
   26 A:c145  18                                 clc 
   27 A:c146  b5 03                              lda stackbase+3,x
   28 A:c148  75 01                              adc stackbase+1,x
   29 A:c14a  95 01                              sta stackbase+1,x
   30 A:c14c  b5 04                              lda stackbase+4,x
   31 A:c14e  75 02                              adc stackbase+2,x
   32 A:c150  95 02                              sta stackbase+2,x
   33 A:c152                           nextshift 
   34 A:c152                                    ; shift n1 left
   35 A:c152  16 03                              asl stackbase+3,x
   36 A:c154  36 04                              rol stackbase+4,x
   37 A:c156                                    ; shift n2 right
   38 A:c156  18                                 clc 
   39 A:c157  76 06                              ror stackbase+6,x
   40 A:c159  76 05                              ror stackbase+5,x
   41 A:c15b  d0 e2                              bne nextbit
   42 A:c15d  b5 06                              lda stackbase+6,x
   43 A:c15f  d0 de                              bne nextbit
   44 A:c161                           done      
   45 A:c161                                     .) 
   46 A:c161                                    ;; clean up the mess we made on the stack
   47 A:c161                                    ;; first, put the result back in the right place
   48 A:c161  b5 01                              lda stackbase+1,x
   49 A:c163  95 05                              sta stackbase+5,x
   50 A:c165  b5 02                              lda stackbase+2,x
   51 A:c167  95 06                              sta stackbase+6,x
   52 A:c169                                    ;; then, discard our temporary space
   53 A:c169  e8                                 inx 
   54 A:c16a  e8                                 inx 
   55 A:c16b                                    ;; finally, discard multiplicand
   56 A:c16b  e8                                 inx 
   57 A:c16c  e8                                 inx 
   58 A:c16d  60                                 rts 

   60 A:c16e                                    ;; divide top of stack into second-top of stack, popping both off
   61 A:c16e                                    ;; and leaving quotient in their place
   62 A:c16e                           div16     
   63 A:c16e                                     .( 
   64 A:c16e  20 97 c1                           jsr divmod16

   66 A:c171                                    ;; remainder is in stackbase+1 and +2; quotient is in stackbase+3 and +4
   67 A:c171                           enddiv    
   68 A:c171                                     .) 
   69 A:c171                                    ;; clean up. start by putting result in the right place
   70 A:c171  b5 03                              lda stackbase+3,x
   71 A:c173  95 07                              sta stackbase+7,x
   72 A:c175  b5 04                              lda stackbase+4,x
   73 A:c177  95 08                              sta stackbase+8,x

   75 A:c179                                    ;; then reset the stack pointer, dropping three words (two
   76 A:c179                                    ;; used for working and one used for parameter).
   77 A:c179  e8                                 inx 
   78 A:c17a  e8                                 inx 
   79 A:c17b  e8                                 inx 
   80 A:c17c  e8                                 inx 
   81 A:c17d  e8                                 inx 
   82 A:c17e  e8                                 inx 

   84 A:c17f                                    ;; if the lowest bit of SCRATCH is set, then negate the result
   85 A:c17f  a5 10                              lda SCRATCH
   86 A:c181  89 01                              bit #1
   87 A:c183  f0 11                              beq donediv
   88 A:c185  18                                 clc 
   89 A:c186  b5 01                              lda stackbase+1,x
   90 A:c188  49 ff                              eor #$ff
   91 A:c18a  69 01                              adc #1
   92 A:c18c  95 01                              sta stackbase+1,x
   93 A:c18e  b5 02                              lda stackbase+2,x
   94 A:c190  49 ff                              eor #$ff
   95 A:c192  69 00                              adc #0
   96 A:c194  95 02                              sta stackbase+2,x

   98 A:c196                           donediv   
   99 A:c196  60                                 rts 

  101 A:c197                                    ;; divide top of stack into second-top of stack, calculating both
  102 A:c197                                    ;; result and remainder
  103 A:c197                           divmod16  
  104 A:c197                                     .( 
  105 A:c197  5a                                 phy                    ; preserve Y

  107 A:c198                                    ;; handle negative numbers. we convert everything to positive and
  108 A:c198                                    ;; keep a note of whether we need to negate the result.
  109 A:c198  64 10                              stz SCRATCH

  111 A:c19a                                    ;; BUG can I combine these two operations to do this faster?
  112 A:c19a  b5 02                              lda stackbase+2,x
  113 A:c19c  89 80                              bit #%10000000
  114 A:c19e  f0 19                              beq next
  115 A:c1a0  49 ff                              eor #$ff
  116 A:c1a2  95 02                              sta stackbase+2,x
  117 A:c1a4  b5 01                              lda stackbase+1,x
  118 A:c1a6  49 ff                              eor #$ff
  119 A:c1a8  95 01                              sta stackbase+1,x
  120 A:c1aa  18                                 clc 
  121 A:c1ab  b5 01                              lda stackbase+1,x
  122 A:c1ad  69 01                              adc #1
  123 A:c1af  95 01                              sta stackbase+1,x
  124 A:c1b1  b5 02                              lda stackbase+2,x
  125 A:c1b3  69 00                              adc #0
  126 A:c1b5  95 02                              sta stackbase+2,x
  127 A:c1b7  e6 10                              inc SCRATCH

  129 A:c1b9                           next      
  130 A:c1b9                                    ;; BUG can I combine these two operations to do this faster?
  131 A:c1b9  b5 04                              lda stackbase+4,x
  132 A:c1bb  89 80                              bit #%10000000
  133 A:c1bd  f0 19                              beq continue
  134 A:c1bf  49 ff                              eor #$ff
  135 A:c1c1  95 04                              sta stackbase+4,x
  136 A:c1c3  b5 03                              lda stackbase+3,x
  137 A:c1c5  49 ff                              eor #$ff
  138 A:c1c7  95 03                              sta stackbase+3,x
  139 A:c1c9  18                                 clc 
  140 A:c1ca  b5 03                              lda stackbase+3,x
  141 A:c1cc  69 01                              adc #1
  142 A:c1ce  95 03                              sta stackbase+3,x
  143 A:c1d0  b5 04                              lda stackbase+4,x
  144 A:c1d2  69 00                              adc #0
  145 A:c1d4  95 04                              sta stackbase+4,x
  146 A:c1d6  e6 10                              inc SCRATCH

  148 A:c1d8                           continue  
  149 A:c1d8                                    ;; make some working space on the stack. two 16-bit values needed.
  150 A:c1d8  ca                                 dex 
  151 A:c1d9  ca                                 dex 
  152 A:c1da  ca                                 dex 
  153 A:c1db  ca                                 dex 

  155 A:c1dc                                    ;; zero out those spaces
  156 A:c1dc  74 01                              stz stackbase+1,x        ; stackbase+1 and +2 are remainlsb, remainmsb
  157 A:c1de  74 02                              stz stackbase+2,x
  158 A:c1e0  74 03                              stz stackbase+3,x        ; stackbase+3 and +4 are resultlsb, resultmsb
  159 A:c1e2  74 04                              stz stackbase+4,x

  161 A:c1e4                                    ; divisor (n1) is stackbase+5 and +6
  162 A:c1e4                                    ; divisand (n2) is stackbase+7 and +8

  164 A:c1e4  a0 10                              ldy #$10             ; loop count, going 16 times (one per bit)
  165 A:c1e6                           nextbit   
  166 A:c1e6                                    ; shift n2 (divisand) left, rotating top bit into temp
  167 A:c1e6  16 07                              asl stackbase+7,x
  168 A:c1e8  36 08                              rol stackbase+8,x
  169 A:c1ea  36 01                              rol stackbase+1,x
  170 A:c1ec  36 02                              rol stackbase+2,x
  171 A:c1ee                                    ; is temp larger than/equal to n1?
  172 A:c1ee  b5 02                              lda stackbase+2,x        ; msb first -- does that resolve it?
  173 A:c1f0  d5 06                              cmp stackbase+6,x
  174 A:c1f2  90 1e                              bcc shift0
  175 A:c1f4  d0 08                              bne subtract
  176 A:c1f6  b5 01                              lda stackbase+1,x
  177 A:c1f8  d5 05                              cmp stackbase+5,x
  178 A:c1fa  b0 02                              bcs subtract
  179 A:c1fc  80 14                              bra shift0
  180 A:c1fe                                    ; yes so subtract n1 from temp
  181 A:c1fe                           subtract  
  182 A:c1fe  38                                 sec 
  183 A:c1ff                                    ;  lda stackbase+2,x
  184 A:c1ff                                    ;  sbc stackbase+6,x
  185 A:c1ff                                    ;  sta stackbase+2,x
  186 A:c1ff                                    ;  lda stackbase+1,x
  187 A:c1ff                                    ;  sbc stackbase+5,x
  188 A:c1ff                                    ;  sta stackbase+1,x
  189 A:c1ff  b5 01                              lda stackbase+1,x
  190 A:c201  f5 05                              sbc stackbase+5,x
  191 A:c203  95 01                              sta stackbase+1,x
  192 A:c205  b5 02                              lda stackbase+2,x
  193 A:c207  f5 06                              sbc stackbase+6,x
  194 A:c209  95 02                              sta stackbase+2,x
  195 A:c20b                                    ; shift and test
  196 A:c20b                           shift1    
  197 A:c20b                                    ; shift result one place left, shifting in a 1 at the bottom
  198 A:c20b  38                                 sec 
  199 A:c20c  36 03                              rol stackbase+3,x
  200 A:c20e  36 04                              rol stackbase+4,x
  201 A:c210  80 05                              bra test
  202 A:c212                           shift0    
  203 A:c212                                    ; shift result one place left, shifting in a 1 at the bottom
  204 A:c212  18                                 clc 
  205 A:c213  36 03                              rol stackbase+3,x
  206 A:c215  36 04                              rol stackbase+4,x
  207 A:c217                           test      
  208 A:c217                                    ; test-- are we done (all 16 bits)?
  209 A:c217  88                                 dey 
  210 A:c218  d0 cc                              bne nextbit
  211 A:c21a                                    ;; we are now done.
  212 A:c21a                                    ;; remainder is in stackbase+1 and +2; quotient is in stackbase+3 and +4
  213 A:c21a                           enddiv    
  214 A:c21a                                     .) 

  216 A:c21a  7a                                 ply                    ; restore y
  217 A:c21b  60                                 rts 

  221 A:c21c                                    ;; divide top of stack into second-top of stack, popping both off
  222 A:c21c                                    ;; and leaving remainder in their place
  223 A:c21c                           mod16     
  224 A:c21c                                     .( 
  225 A:c21c  20 97 c1                           jsr divmod16

  227 A:c21f                                    ;; remainder is in stackbase+1 and +2; quotient is in stackbase+3 and +4
  228 A:c21f                           enddiv    
  229 A:c21f                                     .) 
  230 A:c21f                                    ;; clean up. start by putting result in the right place
  231 A:c21f  b5 01                              lda stackbase+1,x
  232 A:c221  95 07                              sta stackbase+7,x
  233 A:c223  b5 02                              lda stackbase+2,x
  234 A:c225  95 08                              sta stackbase+8,x

  236 A:c227                                    ;; then reset the stack pouinter, dropping three words (two
  237 A:c227                                    ;; used for working and one used for parameter).
  238 A:c227  e8                                 inx 
  239 A:c228  e8                                 inx 
  240 A:c229  e8                                 inx 
  241 A:c22a  e8                                 inx 
  242 A:c22b  e8                                 inx 
  243 A:c22c  e8                                 inx 

  245 A:c22d  60                                 rts 

  247 A:c22e                                    ;; at the address denoted by the top of the stack, read a two-character
  248 A:c22e                                    ;; string and interpret it as a hex byte, decode, and leave the result
  249 A:c22e                                    ;; on the stack.
  250 A:c22e                                    ;; BUG fails if string crosses page boundary
  251 A:c22e                                    ;;
  252 A:c22e                           read8hex  
  253 A:c22e  20 e6 c0                           jsr pop16                ; address into stackaccess (and off stack)
  254 A:c231  b2 80                              lda (stackaccess)              ; first nybble
  255 A:c233                                     .( 
  256 A:c233  c9 60                              cmp #$60
  257 A:c235  90 05                              bcc upper
  258 A:c237                                    ;; lower case character, so substract $57
  259 A:c237  38                                 sec 
  260 A:c238  e9 57                              sbc #$57
  261 A:c23a  80 0c                              bra next
  262 A:c23c                           upper     
  263 A:c23c  c9 40                              cmp #$40
  264 A:c23e  90 05                              bcc number
  265 A:c240                                    ;; upper case character, so substract $37
  266 A:c240  38                                 sec 
  267 A:c241  e9 37                              sbc #$37
  268 A:c243  80 03                              bra next
  269 A:c245                           number    
  270 A:c245                                    ;; numeric character, so subtract $30
  271 A:c245  38                                 sec 
  272 A:c246  e9 30                              sbc #$30
  273 A:c248                           next      
  274 A:c248  0a                                 asl 
  275 A:c249  0a                                 asl 
  276 A:c24a  0a                                 asl 
  277 A:c24b  0a                                 asl 
  278 A:c24c  85 14                              sta SCRATCH+4          ; assembling result here
  279 A:c24e                                     .) 
  280 A:c24e  e6 80                              inc stackaccess                ; BUG won't work if string crosses a page boundary
  281 A:c250  b2 80                              lda (stackaccess)              ; second nybble
  282 A:c252                                     .( 
  283 A:c252  c9 60                              cmp #$60
  284 A:c254  90 06                              bcc upper
  285 A:c256                                    ;; lower case character, so substract $57
  286 A:c256  38                                 sec 
  287 A:c257  e9 57                              sbc #$57
  288 A:c259  4c 69 c2                           jmp next
  289 A:c25c                           upper     
  290 A:c25c  c9 40                              cmp #$40
  291 A:c25e  90 06                              bcc number
  292 A:c260                                    ;; upper case character, so substract $37
  293 A:c260  38                                 sec 
  294 A:c261  e9 37                              sbc #$37
  295 A:c263  4c 69 c2                           jmp next
  296 A:c266                           number    
  297 A:c266                                    ;; numeric character, so subtract $30
  298 A:c266  38                                 sec 
  299 A:c267  e9 30                              sbc #$30
  300 A:c269                           next      
  301 A:c269  18                                 clc 
  302 A:c26a  65 14                              adc SCRATCH+4
  303 A:c26c  85 14                              sta SCRATCH+4
  304 A:c26e                                     .) 
  305 A:c26e  85 80                              sta stackaccess
  306 A:c270  64 81                              stz stackaccess+1
  307 A:c272  20 db c0                           jsr push16
  308 A:c275  60                                 rts 

  311 A:c276                                    ;; at the address denoted by the top of the stack, read a four-character
  312 A:c276                                    ;; string and interpret it as a 16-bit word, decode, and leave the result
  313 A:c276                                    ;; on the stack.
  314 A:c276                                    ;; BUG fails if string crosses page boundary
  315 A:c276                                    ;;
  316 A:c276                           read16hex 
  317 A:c276                                    ;;
  318 A:c276                                    ;; here's the logic
  318 A:c276                                    
  319 A:c276                                    ;; if char code < 0x40 then subtractand is 0x30
  320 A:c276                                    ;; else if char code < 0x60 then subtractand is 0x37
  321 A:c276                                    ;; else subtractand is 0x57
  322 A:c276                                    ;;

  324 A:c276  20 e6 c0                           jsr pop16                ; address into stackaccess (and off stack)
  325 A:c279  b2 80                              lda (stackaccess)              ; first nybble
  326 A:c27b                                     .( 
  327 A:c27b  c9 60                              cmp #$60
  328 A:c27d  90 05                              bcc upper
  329 A:c27f                                    ;; lower case character, so substract $57
  330 A:c27f  38                                 sec 
  331 A:c280  e9 57                              sbc #$57
  332 A:c282  80 0c                              bra next
  333 A:c284                           upper     
  334 A:c284  c9 40                              cmp #$40
  335 A:c286  90 05                              bcc number
  336 A:c288                                    ;; upper case character, so substract $37
  337 A:c288  38                                 sec 
  338 A:c289  e9 37                              sbc #$37
  339 A:c28b  80 03                              bra next
  340 A:c28d                           number    
  341 A:c28d                                    ;; numeric character, so subtract $30
  342 A:c28d  38                                 sec 
  343 A:c28e  e9 30                              sbc #$30
  344 A:c290                           next      
  345 A:c290  0a                                 asl 
  346 A:c291  0a                                 asl 
  347 A:c292  0a                                 asl 
  348 A:c293  0a                                 asl 
  349 A:c294  85 13                              sta SCRATCH+3          ; assembling result here
  350 A:c296                                     .) 
  351 A:c296  e6 80                              inc stackaccess                ; BUG won't work if string crosses page boundary
  352 A:c298  b2 80                              lda (stackaccess)              ; second nybble
  353 A:c29a                                     .( 
  354 A:c29a  c9 60                              cmp #$60
  355 A:c29c  90 05                              bcc upper
  356 A:c29e                                    ;; lower case character, so substract $57
  357 A:c29e  38                                 sec 
  358 A:c29f  e9 57                              sbc #$57
  359 A:c2a1  80 0c                              bra next
  360 A:c2a3                           upper     
  361 A:c2a3  c9 40                              cmp #$40
  362 A:c2a5  90 05                              bcc number
  363 A:c2a7                                    ;; upper case character, so substract $37
  364 A:c2a7  38                                 sec 
  365 A:c2a8  e9 37                              sbc #$37
  366 A:c2aa  80 03                              bra next
  367 A:c2ac                           number    
  368 A:c2ac                                    ;; numeric character, so subtract $30
  369 A:c2ac  38                                 sec 
  370 A:c2ad  e9 30                              sbc #$30
  371 A:c2af                           next      
  372 A:c2af  18                                 clc 
  373 A:c2b0  65 13                              adc SCRATCH+3
  374 A:c2b2  85 13                              sta SCRATCH+3
  375 A:c2b4                                     .) 
  376 A:c2b4  e6 80                              inc stackaccess                ; BUG see above
  377 A:c2b6  b2 80                              lda (stackaccess)              ; third nybble
  378 A:c2b8                                     .( 
  379 A:c2b8  c9 60                              cmp #$60
  380 A:c2ba  90 05                              bcc upper
  381 A:c2bc                                    ;; lower case character, so substract $57
  382 A:c2bc  38                                 sec 
  383 A:c2bd  e9 57                              sbc #$57
  384 A:c2bf  80 0c                              bra next
  385 A:c2c1                           upper     
  386 A:c2c1  c9 40                              cmp #$40
  387 A:c2c3  90 05                              bcc number
  388 A:c2c5                                    ;; upper case character, so substract $37
  389 A:c2c5  38                                 sec 
  390 A:c2c6  e9 37                              sbc #$37
  391 A:c2c8  80 03                              bra next
  392 A:c2ca                           number    
  393 A:c2ca                                    ;; numeric character, so subtract $30
  394 A:c2ca  38                                 sec 
  395 A:c2cb  e9 30                              sbc #$30
  396 A:c2cd                           next      
  397 A:c2cd  0a                                 asl 
  398 A:c2ce  0a                                 asl 
  399 A:c2cf  0a                                 asl 
  400 A:c2d0  0a                                 asl 
  401 A:c2d1  85 12                              sta SCRATCH+2          ; assembling result here (little-endian, so earlier)
  402 A:c2d3                                     .) 
  403 A:c2d3  e6 80                              inc stackaccess                ; BUG see above
  404 A:c2d5  b2 80                              lda (stackaccess)              ; fourth nybble
  405 A:c2d7                                     .( 
  406 A:c2d7  c9 60                              cmp #$60
  407 A:c2d9  90 05                              bcc upper
  408 A:c2db                                    ;; lower case character, so substract $57
  409 A:c2db  38                                 sec 
  410 A:c2dc  e9 57                              sbc #$57
  411 A:c2de  80 0c                              bra next
  412 A:c2e0                           upper     
  413 A:c2e0  c9 40                              cmp #$40
  414 A:c2e2  90 05                              bcc number
  415 A:c2e4                                    ;; upper case character, so substract $37
  416 A:c2e4  38                                 sec 
  417 A:c2e5  e9 37                              sbc #$37
  418 A:c2e7  80 03                              bra next
  419 A:c2e9                           number    
  420 A:c2e9                                    ;; numeric character, so subtract $30
  421 A:c2e9  38                                 sec 
  422 A:c2ea  e9 30                              sbc #$30
  423 A:c2ec                           next      
  424 A:c2ec  18                                 clc 
  425 A:c2ed  65 12                              adc SCRATCH+2
  426 A:c2ef  85 12                              sta SCRATCH+2
  427 A:c2f1                                     .) 
  428 A:c2f1  85 80                              sta stackaccess
  429 A:c2f3  a5 13                              lda SCRATCH+3
  430 A:c2f5  85 81                              sta stackaccess+1
  431 A:c2f7  20 db c0                           jsr push16
  432 A:c2fa  60                                 rts 

  434 A:c2fb                                    ;; read a 16-bit number in decimal. need to allow for the fact that
  435 A:c2fb                                    ;; there may be a variable number of digits (but presume that
  436 A:c2fb                                    ;; there is always one).
  437 A:c2fb                                    ;; NOTE changed the label because it was calling the wrong place!
  438 A:c2fb                           readdec16 
  439 A:c2fb                                     .( 
  440 A:c2fb  20 e6 c0                           jsr pop16                ; move the string address into stackaccess

  442 A:c2fe  ca                                 dex                    ; make some workspace on the stack. need two 16-byte
  443 A:c2ff  ca                                 dex                    ; words, one of which will eventually be our result
  444 A:c300  ca                                 dex                    ; so, workspace space is stackbase+1,x to stackbase+4,x
  445 A:c301  ca                                 dex 
  446 A:c302  74 01                              stz stackbase+1,x        ; zero out both 16-bit values
  447 A:c304  74 02                              stz stackbase+2,x
  448 A:c306  74 03                              stz stackbase+3,x
  449 A:c308  74 04                              stz stackbase+4,x

  451 A:c30a  5a                                 phy                    ; preserve y
  452 A:c30b  a0 00                              ldy #0             ; y indexes digits of the input string
  453 A:c30d                           nextdigit 
  454 A:c30d  b1 80                              lda (stackaccess),y

  456 A:c30f  38                                 sec 
  457 A:c310  e9 30                              sbc #$30             ; turn from ascii digit into a number
  458 A:c312  18                                 clc                    ; add it to our partial result
  459 A:c313  75 03                              adc stackbase+3,x
  460 A:c315  95 03                              sta stackbase+3,x
  461 A:c317  b5 04                              lda stackbase+4,x
  462 A:c319  69 00                              adc #0
  463 A:c31b  95 04                              sta stackbase+4,x
  464 A:c31d  c8                                 iny                    ; bump the character count
  465 A:c31e  c0 05                              cpy #5             ; was that the last digit to be read? (max 5)
  466 A:c320  f0 27                              beq donelastdigit
  467 A:c322  b1 80                              lda (stackaccess),y
  468 A:c324  f0 23                              beq donelastdigit                ; stop stop if we hit null-terminator

  470 A:c326                           mult10                     ; more digits, so multiply by ten and go around
  471 A:c326  16 03                              asl stackbase+3,x        ; shift left to multiply by two
  472 A:c328  36 04                              rol stackbase+4,x

  474 A:c32a  b5 03                              lda stackbase+3,x        ; make a copy in the other temporary slot
  475 A:c32c  95 01                              sta stackbase+1,x
  476 A:c32e  b5 04                              lda stackbase+4,x
  477 A:c330  95 02                              sta stackbase+2,x
  478 A:c332  16 01                              asl stackbase+1,x        ; shift the copy left twice more, so x8 in total
  479 A:c334  36 02                              rol stackbase+2,x
  480 A:c336  16 01                              asl stackbase+1,x
  481 A:c338  36 02                              rol stackbase+2,x

  483 A:c33a  18                                 clc                    ; add them (8x + 2x = 10x)
  484 A:c33b  b5 01                              lda stackbase+1,x
  485 A:c33d  75 03                              adc stackbase+3,x
  486 A:c33f  95 03                              sta stackbase+3,x
  487 A:c341  b5 02                              lda stackbase+2,x
  488 A:c343  75 04                              adc stackbase+4,x
  489 A:c345  95 04                              sta stackbase+4,x

  491 A:c347  80 c4                              bra nextdigit

  493 A:c349                           donelastdigit 
  494 A:c349  e8                                 inx                    ; drop one of the temporary variables
  495 A:c34a  e8                                 inx                    ; but leave the other, which is our result
  496 A:c34b  7a                                 ply                    ; restore y
  497 A:c34c                                     .) 
  498 A:c34c  60                                 rts 

  502 A:c34d                           print16hex 
  503 A:c34d  20 e6 c0                           jsr pop16
  504 A:c350  a5 81                              lda stackaccess+1
  505 A:c352  20 6d d6                           jsr putax
  506 A:c355  a5 80                              lda stackaccess
  507 A:c357  20 6d d6                           jsr putax
  508 A:c35a  60                                 rts 

  510 A:c35b                           print8hex 
  511 A:c35b  20 e6 c0                           jsr pop16
  512 A:c35e  a5 80                              lda stackaccess
  513 A:c360  20 6d d6                           jsr putax
  514 A:c363  60                                 rts 

  516 A:c364                                    ;;; This routine is only called from my Forth, so I've modified it to
  517 A:c364                                    ;;; suit. Mainly, that means printing a space before the number.
  518 A:c364                                    ;;; NOTE commented out for now since it's reproduced in FORTH.
  519 A:c364                                    ;print16dec
  520 A:c364                                    ;.(
  521 A:c364                                    ;  ;; create myself three bytes of storage on the stack
  522 A:c364                                    ;  dex
  523 A:c364                                    ;  dex
  524 A:c364                                    ;  dex
  525 A:c364                                    ;  
  526 A:c364                                    ;  ;; that leaves the data to be read at stackbase+4,x and stackbase+5,x
  527 A:c364                                    ;  
  528 A:c364                                    ;  stz stackbase+1,x ; dec0
  529 A:c364                                    ;  stz stackbase+2,x ; dec1
  530 A:c364                                    ;  stx stackbase+3,x ; dec2
  531 A:c364                                    ;
  532 A:c364                                    ;  phy               ; preserve Y
  533 A:c364                                    ;  lda #0
  534 A:c364                                    ;  sed
  535 A:c364                                    ;  ldy #16           ; count of bits we are processing
  536 A:c364                                    ;
  537 A:c364                                    ;.(
  538 A:c364                                    ;loop
  539 A:c364                                    ;  asl stackbase+4,x
  540 A:c364                                    ;  rol stackbase+5,x
  541 A:c364                                    ;  lda stackbase+1,x
  542 A:c364                                    ;  adc stackbase+1,x
  543 A:c364                                    ;  sta stackbase+1,x
  544 A:c364                                    ;  lda stackbase+2,x
  545 A:c364                                    ;  adc stackbase+2,x
  546 A:c364                                    ;  sta stackbase+2,x
  547 A:c364                                    ;  rol stackbase+3,x
  548 A:c364                                    ;  dey
  549 A:c364                                    ;  bne loop
  550 A:c364                                    ;.)
  551 A:c364                                    ;  cld
  552 A:c364                                    ;
  553 A:c364                                    ;  ;; we have the result in the temporary storage, as BCD. now print that as
  554 A:c364                                    ;  ;; a five-character string (since max is 65535).
  555 A:c364                                    ;  ;; could do this using y as an index and looping.. rather than unrolling
  556 A:c364                                    ;  ;; as here
  557 A:c364                                    ;
  558 A:c364                                    ;  ;; set a flag to determine whether we've printed anything non-zero
  559 A:c364                                    ;  stz SCRATCH
  560 A:c364                                    ;
  561 A:c364                                    ;  ;; print leading space
  562 A:c364                                    ;  lda #$20
  563 A:c364                                    ;  jsr puta
  564 A:c364                                    ;
  565 A:c364                                    ;  ;; decimal 2
  566 A:c364                                    ;  ;; mask off lower four bits
  567 A:c364                                    ;  lda stackbase+3,x
  568 A:c364                                    ;  and #%00001111
  569 A:c364                                    ;  clc
  570 A:c364                                    ;  adc #'0
  571 A:c364                                    ;.(
  572 A:c364                                    ;  cmp #'0
  573 A:c364                                    ;  bne continue      ; not a zero, so proceed to printing
  574 A:c364                                    ;  bit SCRATCH       ; is this a leading zero (have we printed anything?)
  575 A:c364                                    ;  beq dec1up        ; nothing printed yet, so skip this digit
  576 A:c364                                    ;continue
  577 A:c364                                    ;  jsr puta          ; print the digit
  578 A:c364                                    ;.)
  579 A:c364                                    ;  lda #$ff          ; note that printing has begun (no more leading zeros)
  580 A:c364                                    ;  sta SCRATCH
  581 A:c364                                    ;
  582 A:c364                                    ;dec1up
  583 A:c364                                    ;  ;; decimal 1
  584 A:c364                                    ;  ;; first, upper four bits
  585 A:c364                                    ;  lda stackbase+2,x
  586 A:c364                                    ;  and #%11110000
  587 A:c364                                    ;  clc
  588 A:c364                                    ;  ror
  589 A:c364                                    ;  ror
  590 A:c364                                    ;  ror
  591 A:c364                                    ;  ror
  592 A:c364                                    ;  clc
  593 A:c364                                    ;  adc #'0
  594 A:c364                                    ;.(
  595 A:c364                                    ;  cmp #'0
  596 A:c364                                    ;  bne continue      ; not a zero, so proceed to printing
  597 A:c364                                    ;  bit SCRATCH       ; is this a leading zero (have we printed anything?)
  598 A:c364                                    ;  beq dec1low       ; nothing printed yet, so skip this digit
  599 A:c364                                    ;continue
  600 A:c364                                    ;  jsr puta          ; print the digit
  601 A:c364                                    ;.)
  602 A:c364                                    ;  lda #$ff          ; note that printing has begun (no more leading zeros)
  603 A:c364                                    ;  sta SCRATCH
  604 A:c364                                    ;
  605 A:c364                                    ;dec1low
  606 A:c364                                    ;  ;; and then lower four bits
  607 A:c364                                    ;  lda stackbase+2,x
  608 A:c364                                    ;  and #%00001111
  609 A:c364                                    ;  clc
  610 A:c364                                    ;  adc #'0
  611 A:c364                                    ;.(
  612 A:c364                                    ;  cmp #'0
  613 A:c364                                    ;  bne continue      ; not a zero, so proceed to printing
  614 A:c364                                    ;  bit SCRATCH       ; is this a leading zero (have we printed anything?)
  615 A:c364                                    ;  beq dec0up        ; nothing printed yet, so skip this digit
  616 A:c364                                    ;continue
  617 A:c364                                    ;  jsr puta          ; print the digit
  618 A:c364                                    ;.)
  619 A:c364                                    ;  lda #$ff          ; note that printing has begun (no more leading zeros)
  620 A:c364                                    ;  sta SCRATCH
  621 A:c364                                    ;
  622 A:c364                                    ;dec0up
  623 A:c364                                    ;  ;; and finally decimal 0
  624 A:c364                                    ;  ;; first, upper four bits
  625 A:c364                                    ;  lda stackbase+1,x
  626 A:c364                                    ;  and #%11110000
  627 A:c364                                    ;  clc
  628 A:c364                                    ;  ror
  629 A:c364                                    ;  ror
  630 A:c364                                    ;  ror
  631 A:c364                                    ;  ror
  632 A:c364                                    ;  clc
  633 A:c364                                    ;  adc #'0
  634 A:c364                                    ;.(
  635 A:c364                                    ;  cmp #'0
  636 A:c364                                    ;  bne continue      ; not a zero, so proceed to printing
  637 A:c364                                    ;  bit SCRATCH       ; is this a leading zero (have we printed anything?)
  638 A:c364                                    ;  beq dec0low       ; nothing printed yet, so skip this digit
  639 A:c364                                    ;continue
  640 A:c364                                    ;  jsr puta          ; print the digit
  641 A:c364                                    ;.)
  642 A:c364                                    ;  lda #$ff          ; note that printing has begun (no more leading zeros)
  643 A:c364                                    ;  sta SCRATCH
  644 A:c364                                    ;
  645 A:c364                                    ;dec0low
  646 A:c364                                    ;  ;; and then lower four bits -- last digit, so no check for zero
  647 A:c364                                    ;  lda stackbase+1,x
  648 A:c364                                    ;  and #%00001111
  649 A:c364                                    ;  clc
  650 A:c364                                    ;  adc #'0
  651 A:c364                                    ;  jsr puta
  652 A:c364                                    ;
  653 A:c364                                    ;  ;; clean up -- reclaim our temporary space and also pop item from stack
  654 A:c364                                    ;  ply              ; restore Y
  655 A:c364                                    ;  inx              ; clean up our three bytes
  656 A:c364                                    ;  inx
  657 A:c364                                    ;  inx
  658 A:c364                                    ;  inx              ; popping (discard result)
  659 A:c364                                    ;  inx              ; second byte
  660 A:c364                                    ;.)
  661 A:c364                                    ;  rts

  664 A:c364                           print8dec 
  665 A:c364                                    ;; to be implemented

  667 A:c364                           printstr  
  668 A:c364  20 e6 c0                           jsr pop16
  669 A:c367  5a                                 phy                    ; preserve Y
  670 A:c368  a0 00                              ldy #0
  671 A:c36a                                     .( 
  672 A:c36a                           next_char 
  673 A:c36a                           wait_txd_empty 
  674 A:c36a  ad 01 80                           lda ACIA_STATUS
  675 A:c36d  29 10                              and #$10
  676 A:c36f  f0 f9                              beq wait_txd_empty
  677 A:c371  b1 80                              lda (stackaccess),y
  678 A:c373  f0 06                              beq endstr
  679 A:c375  8d 00 80                           sta ACIA_DATA
  680 A:c378  c8                                 iny 
  681 A:c379  80 ef                              bra next_char
  682 A:c37b                           endstr    
  683 A:c37b  20 45 d6                           jsr crlf
  684 A:c37e                                     .) 
  685 A:c37e  7a                                 ply 
  686 A:c37f  60                                 rts 

main.a65


  256 A:c380                                    ;; Finally -- we actually start executing code
  257 A:c380                                    ;;
  258 A:c380                           startup   

  260 A:c380                                    ;; the very first thing we do is to clear the memory
  261 A:c380                                    ;; used to do this in a subrouting, but of course it trashes
  262 A:c380                                    ;; the stack!
  263 A:c380                                    ;clearmem
  264 A:c380                                    ;.(
  265 A:c380                                    ;  stz $00  
  266 A:c380                                    ;  stz $01
  267 A:c380                                    ;nextpage
  268 A:c380                                    ;  ldy #0
  269 A:c380                                    ;  lda #0
  270 A:c380                                    ;clearloop
  271 A:c380                                    ;  sta ($00),y
  272 A:c380                                    ;  iny
  273 A:c380                                    ;  bne clearloop
  274 A:c380                                    ;  inx
  275 A:c380                                    ;  stx $01
  276 A:c380                                    ;  cpx #$80
  277 A:c380                                    ;  bne nextpage
  278 A:c380                                    ;.)

init.a65

    1 A:c380                                    ;; Generic initialization code
    2 A:c380                                    ;;

    4 A:c380                           init      
    5 A:c380  a2 ff                              ldx #255
    6 A:c382  9a                                 txs 
    7 A:c383  d8                                 cld 
    8 A:c384  78                                 sei 

   10 A:c385                           setupvia  
   11 A:c385  a9 ff                              lda #%11111111
   12 A:c387  8d 03 b0                           sta VIA_DDRA

main.a65


  282 A:c38a  20 90 c3                           jsr dostartupsound
  283 A:c38d  4c 66 c6                           jmp init_acia

  285 A:c390                                    ;; Include Startup sound and sound effect engine
  286 A:c390                                    ;;

startupsound.a65

    1 A:c390                                    donefact=$00
    2 A:c390                                    irqcount=$01

    4 A:c390                                    ;;; Play a startup sound
    5 A:c390                                    ;;;
    6 A:c390                                    ;;;
    7 A:c390                                    ;;; (du du du!)

    9 A:c390                           dostartupsound 
    9 A:c390                                    
   10 A:c390  ad fd 7f                           lda SEN                ; check startup enable
   11 A:c393  c9 43                              cmp #$43
   12 A:c395  d0 03                              bne notender
   13 A:c397  4c 65 c6                           jmp ender
   14 A:c39a                           notender  
   14 A:c39a                                    
   15 A:c39a  a9 55                              lda #$55
   16 A:c39c  85 00                              sta donefact
   17 A:c39e  64 01                              stz irqcount

   19 A:c3a0  a9 0f                              lda #$0f
   20 A:c3a2  8d 18 b8                           sta $b818

   22 A:c3a5                                    ; copy

   24 A:c3a5  a9 06                              lda #$06
   25 A:c3a7  85 0c                              sta mem_copy
   26 A:c3a9  a9 10                              lda #$10
   27 A:c3ab  85 0d                              sta mem_copy+1

   29 A:c3ad  a9 09                              lda #<sounddata
   30 A:c3af  85 0a                              sta mem_source
   31 A:c3b1  a9 c4                              lda #>sounddata
   32 A:c3b3  85 0b                              sta mem_source+1

   34 A:c3b5  a9 46                              lda #$46
   35 A:c3b7  85 0e                              sta mem_end
   36 A:c3b9  a9 12                              lda #$12
   37 A:c3bb  85 0f                              sta mem_end+1

   39 A:c3bd  20 4b e9                           jsr memcopy

   41 A:c3c0                           runthesound 
   41 A:c3c0                                    ; thats done, now to play the sound
   42 A:c3c0  78                                 sei 
   43 A:c3c1  a9 de                              lda #<irq
   44 A:c3c3  8d fe 7f                           sta $7ffe
   45 A:c3c6  a9 c3                              lda #>irq
   46 A:c3c8  8d ff 7f                           sta $7fff
   47 A:c3cb  a9 c0                              lda #$c0
   48 A:c3cd  8d 0e b0                           sta $b00e
   49 A:c3d0  a9 00                              lda #0             ; Song Number
   50 A:c3d2  20 03 c4                           jsr InitSid
   51 A:c3d5  a9 40                              lda #$40
   52 A:c3d7  8d 0d b0                           sta $b00d
   53 A:c3da  58                                 cli 
   54 A:c3db  4c 43 c6                           jmp startupsoundloop

   56 A:c3de                           irq       
   56 A:c3de                                    
   57 A:c3de  20 f2 c3                           jsr putbut                ; refresh timers
   58 A:c3e1  78                                 sei 
   59 A:c3e2  e6 01                              inc irqcount                ; a irq has occurred
   60 A:c3e4  a5 01                              lda irqcount
   61 A:c3e6  c9 78                              cmp #120             ; if this amount of irqs (end of the startup sound)
   62 A:c3e8  d0 03                              bne continue24542                ; end the stream
   63 A:c3ea  64 00                              stz donefact                ; its done, tell the loop
   64 A:c3ec  78                                 sei 
   65 A:c3ed                           continue24542 
   65 A:c3ed                                    
   66 A:c3ed  20 06 10                           jsr $1006
   67 A:c3f0  58                                 cli 
   68 A:c3f1  40                                 rti                    ; exit

   70 A:c3f2                           putbut    
   70 A:c3f2                                    
   71 A:c3f2  a2 9e                              ldx #$9e
   72 A:c3f4  8e 04 b0                           stx $b004
   73 A:c3f7  8e 06 b0                           stx $b006
   74 A:c3fa  a2 0f                              ldx #$0f             ; 250Hz IRQ
   75 A:c3fc  8e 05 b0                           stx $b005
   76 A:c3ff  8e 07 b0                           stx $b007
   77 A:c402  60                                 rts 
   78 A:c403  20 f2 c3                 InitSid   jsr putbut
   79 A:c406  4c 03 11                           jmp $1103

   81 A:c409                           sounddata 
   81 A:c409                                    
   82 A:c409                                    ; Main deflemask engine
   83 A:c409                                    ; Stored at $1006
   84 A:c409  a2 18 b5 04 9d 00 b8 ...           .byt $a2,$18,$b5,$04,$9d,$00,$b8,$ca,$10,$f8,$c6,$02,$30,$01,$60,$86
   85 A:c419  02 a5 03 d0 18 20 1f ...           .byt $02,$a5,$03,$d0,$18,$20,$1f,$00,$f0,$18,$c9,$a0,$b0,$0a,$85,$2a
   86 A:c429  20 1f 00 85 29 4c 76 ...           .byt $20,$1f,$00,$85,$29,$4c,$76,$10,$38,$e9,$9f,$85,$03,$c6,$03,$4c
   87 A:c439  76 10 20 1f 00 c9 fd ...           .byt $76,$10,$20,$1f,$00,$c9,$fd,$f0,$2c,$c9,$fe,$f0,$1d,$c9,$ff,$f0
   88 A:c449  03 85 02 60 a9 00 8d ...           .byt $03,$85,$02,$60,$a9,$00,$8d,$04,$b8,$8d,$0b,$b8,$8d,$12,$b8,$a9
   89 A:c459  5e 85 26 a9 10 85 27 ...           .byt $5e,$85,$26,$a9,$10,$85,$27,$60,$ff,$00,$a5,$1d,$85,$26,$a5,$1e
   90 A:c469  85 27 4c 15 10 a5 26 ...           .byt $85,$27,$4c,$15,$10,$a5,$26,$85,$1d,$a5,$27,$85,$1e,$4c,$15,$10
   91 A:c479  20 a1 10 a9 f8 18 69 ...           .byt $20,$a1,$10,$a9,$f8,$18,$69,$07,$48,$aa,$20,$1f,$00,$4a,$08,$e8
   92 A:c489  4a b0 0a d0 fa 28 68 ...           .byt $4a,$b0,$0a,$d0,$fa,$28,$68,$b0,$ec,$20,$a1,$10,$60,$48,$bc,$ff
   93 A:c499  ff 20 1f 00 99 04 00 ...           .byt $ff,$20,$1f,$00,$99,$04,$00,$68,$4c,$85,$10,$a4,$26,$a6,$29,$84
   94 A:c4a9  29 86 26 a4 27 a6 2a ...           .byt $29,$86,$26,$a4,$27,$a6,$2a,$84,$2a,$86,$27,$60,$84,$26,$86,$27
   95 A:c4b9  a2 06 bd c6 10 95 1f ...           .byt $a2,$06,$bd,$c6,$10,$95,$1f,$ca,$10,$f8,$a9,$60,$85,$28,$d0,$0a
   96 A:c4c9  e6 26 d0 02 e6 27 ad ...           .byt $e6,$26,$d0,$02,$e6,$27,$ad,$ff,$ff,$60,$20,$1f,$00,$8d,$04,$dc
   97 A:c4d9  20 1f 00 8d 05 dc 20 ...           .byt $20,$1f,$00,$8d,$05,$dc,$20,$1f,$00,$85,$29,$20,$1f,$00,$85,$2a
   98 A:c4e9  e6 26 d0 02 e6 27 a5 ...           .byt $e6,$26,$d0,$02,$e6,$27,$a5,$26,$8d,$95,$10,$a5,$27,$8d,$96,$10
   99 A:c4f9  a2 1c a9 00 95 02 ca ...           .byt $a2,$1c,$a9,$00,$95,$02,$ca,$10,$fb,$20,$a1,$10,$60,$a0,$09,$a2
  100 A:c509  11 4c b2 10                        .byt $11,$4c,$b2,$10

  102 A:c50d                                    ; uncompressed sound data at $110a
  103 A:c50d                           startdat  
  103 A:c50d  f0 0f 88 11 04 05 01 ...           .byt $f0,$0f,$88,$11,$04,$05,$01,$00,$0d,$12,$0b,$14
  104 A:c519  08 09 07 06 0c 03 0e ...           .byt $08,$09,$07,$06,$0c,$03,$0e,$0f,$10,$11,$17,$13,$0a,$15,$16,$18
  105 A:c529  02 00 00 00 00 00 00 ...           .byt $02,$00,$00,$00,$00,$00,$00,$00,$ff,$41,$0c,$0b,$9d,$f0,$20,$20
  106 A:c539  ff f0 00 fd 00 00 00 ...           .byt $ff,$f0,$00,$fd,$00,$00,$00,$07,$ff,$00,$00,$fd,$07,$60,$00,$07
  107 A:c549  1e 07 05 4f fd 03 21 ...           .byt $1e,$07,$05,$4f,$fd,$03,$21,$01,$01,$08,$4f,$02,$41,$07,$21,$00
  108 A:c559  20 00 1e 41 0c 0e a2 ...           .byt $20,$00,$1e,$41,$0c,$0e,$a2,$1e,$41,$0c,$11,$66,$02,$40,$02,$20
  109 A:c569  e7 20 00 00 08 08 43 ...           .byt $e7,$20,$00,$00,$08,$08,$43,$00,$00,$40,$00,$ff,$41,$0c,$0b,$9d
  110 A:c579  f0 20 20 9f f0 00 fd ...           .byt $f0,$20,$20,$9f,$f0,$00,$fd,$00,$07,$bf,$00,$00,$fd,$07,$60,$07
  111 A:c589  06 07 05 11 2d 00 fd ...           .byt $06,$07,$05,$11,$2d,$00,$fd,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0
  112 A:c599  11 4a a0 11 4a a0 11 ...           .byt $11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11
  113 A:c5a9  4a a0 11 4a a0 11 4a ...           .byt $4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a
  114 A:c5b9  a2 11 4a a0 11 4a a0 ...           .byt $a2,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0
  115 A:c5c9  11 4a a0 11 4a a0 11 ...           .byt $11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11
  116 A:c5d9  4a a0 11 4a a0 11 4a ...           .byt $4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a1,$11,$5c,$11,$4a,$a0
  117 A:c5e9  11 4a a0 11 4a a0 11 ...           .byt $11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11
  118 A:c5f9  4a a0 11 4a a0 11 4a ...           .byt $4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a
  119 A:c609  a0 11 4a a0 11 4a a0 ...           .byt $a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$11,$61,$a0,$11,$61,$a0,$11
  120 A:c619  61 a0 11 61 a0 11 61 ...           .byt $61,$a0,$11,$61,$a0,$11,$61,$a0,$11,$61,$a0,$11,$61,$a0,$11,$61
  121 A:c629  a0 11 61 a0 11 61 a0 ...           .byt $a0,$11,$61,$a0,$11,$61,$a0,$11,$61,$a0,$11,$61,$a0,$11,$61,$a0
  122 A:c639  11 61 a0 11 61 11 65 ...           .byt $11,$61,$a0,$11,$61,$11,$65,$a0,$00,$fe
  123 A:c643                           endstart  
  123 A:c643                                    

  125 A:c643                           startupsoundloop 
  125 A:c643                                    
  126 A:c643  a5 00                              lda donefact                ; loop only if the sound is not done
  127 A:c645  d0 fc                              bne startupsoundloop
  128 A:c647  9c 0e b0                           stz $b00e              ; if done disable irqs
  129 A:c64a  9c 0d b0                           stz $b00d
  130 A:c64d  78                                 sei 
  131 A:c64e  a9 40                              lda #$40
  132 A:c650  8d fb 7f                           sta $7ffb              ; return irq
  133 A:c653  a9 7f                              lda #$7f             ; clear irq vectors
  134 A:c655  8d ff 7f                           sta $7fff
  135 A:c658  a9 fb                              lda #$fb
  136 A:c65a  8d fe 7f                           sta $7ffe
  137 A:c65d  20 5b e0                           jsr clear_sid
  138 A:c660  a9 43                              lda #$43
  139 A:c662  8d fd 7f                           sta SEN
  140 A:c665                           ender     
  140 A:c665                                    
  141 A:c665  60                                 rts 

main.a65


  290 A:c666                                    ;; Initialize the ACIA
  291 A:c666                                    ;;

  293 A:c666                           init_acia 
  294 A:c666  a9 0b                              lda #%00001011             ; No parity, no echo, no interrupt
  295 A:c668  8d 02 80                           sta ACIA_COMMAND
  296 A:c66b  a9 1f                              lda #%00011111             ; 1 stop bit, 8 data bits, 19200 baud
  297 A:c66d  8d 03 80                           sta ACIA_CONTROL

  299 A:c670  a9 02                              lda #$02
  300 A:c672  20 df df                           jsr print_chara                ; set cursor to _
  301 A:c675  a9 5f                              lda #$5f
  302 A:c677  20 df df                           jsr print_chara

  304 A:c67a  20 f0 d6                           jsr via_init
  305 A:c67d  20 05 d7                           jsr sd_init
  306 A:c680  90 06                              bcc load1
  307 A:c682  9c 00 04                           stz path
  308 A:c685  4c db c6                           jmp initf
  309 A:c688                           load1     
  310 A:c688  20 da d8                           jsr fat32_init
  311 A:c68b  b0 1f                              bcs initerror

  313 A:c68d                                    ; Open root directory
  314 A:c68d  20 9c db                           jsr fat32_openroot

  316 A:c690                                    ; Find subdirectory by name
  317 A:c690  a2 89                              ldx #<subdirname
  318 A:c692  a0 e1                              ldy #>subdirname
  319 A:c694  20 5b de                           jsr fat32_finddirent
  320 A:c697  90 0d                              bcc foundsubdirr

  322 A:c699                                    ; Subdirectory not found
  323 A:c699  a0 e7                              ldy #>submsg
  324 A:c69b  a2 66                              ldx #<submsg
  325 A:c69d  20 f0 df                           jsr w_acia_full
  326 A:c6a0  9c 00 04                           stz path
  327 A:c6a3  4c db c6                           jmp initf

  329 A:c6a6                           foundsubdirr 

  331 A:c6a6                                    ; Open subdirectory
  332 A:c6a6  20 e1 dc                           jsr fat32_opendirent                ; open folder

  334 A:c6a9  4c c7 c6                           jmp initdone

  336 A:c6ac                           initerror 
  337 A:c6ac                                    ; Error during FAT32 initialization

  339 A:c6ac  a0 e1                              ldy #>fat_error
  340 A:c6ae  a2 aa                              ldx #<fat_error
  341 A:c6b0  20 f0 df                           jsr w_acia_full
  342 A:c6b3  ad 62 00                           lda fat32_errorstage
  343 A:c6b6  20 b5 df                           jsr print_hex_acia
  344 A:c6b9  a9 21                              lda #'!'
  345 A:c6bb  20 df df                           jsr print_chara
  346 A:c6be  9c 00 04                           stz path
  347 A:c6c1  20 13 e0                           jsr error_sound
  348 A:c6c4  4c db c6                           jmp initf

  350 A:c6c7                           initdone  
  351 A:c6c7  a2 00                              ldx #0
  352 A:c6c9                           inlp      
  352 A:c6c9                                    
  353 A:c6c9  bd 89 e1                           lda subdirname,x
  354 A:c6cc  9d 01 04                           sta path+1,x
  355 A:c6cf  e8                                 inx 
  356 A:c6d0  e0 0b                              cpx #11
  357 A:c6d2  d0 f5                              bne inlp
  358 A:c6d4  e8                                 inx 
  359 A:c6d5  9e 00 04                           stz path,x
  360 A:c6d8  8e 00 04                           stx path

  362 A:c6db                           initf     
  362 A:c6db                                    

  364 A:c6db                                    ; if the init failed, just continue on with no SD card.

  366 A:c6db  a2 ff                              ldx #$ff

  368 A:c6dd                                    ;; done with initialization. start actually being a monitor
  369 A:c6dd                                    ;;

  371 A:c6dd                           main      
  372 A:c6dd                                    ;;;
  373 A:c6dd                                    ;;; first, display a greeting. through out a couple of newlines
  374 A:c6dd                                    ;;; first just in case there's other gunk on the screen.
  375 A:c6dd                                    ;;;
  376 A:c6dd                           sayhello  
  377 A:c6dd  a9 03                              lda #<greeting
  378 A:c6df  85 42                              sta PRINTVEC
  379 A:c6e1  a9 ea                              lda #>greeting
  380 A:c6e3  85 43                              sta PRINTVEC+1
  381 A:c6e5  a0 00                              ldy #0
  382 A:c6e7  20 c5 e9                           jsr printvecstr

  384 A:c6ea                                    ;  ldy #0
  385 A:c6ea                                    ;.(
  386 A:c6ea                                    ;next_char
  387 A:c6ea                                    ;wait_txd_empty  
  388 A:c6ea                                    ;  lda ACIA_STATUS
  389 A:c6ea                                    ;  and #$10
  390 A:c6ea                                    ;  beq wait_txd_empty
  391 A:c6ea                                    ;  lda greeting,y
  392 A:c6ea                                    ;  beq reploop
  393 A:c6ea                                    ;  sta ACIA_DATA
  394 A:c6ea                                    ;  iny
  395 A:c6ea                                    ;  jmp next_char
  396 A:c6ea                                    ;.)
  397 A:c6ea                                    ;; greeting has CRLF included, so we don't need to print those.

  400 A:c6ea                                    ;;;
  401 A:c6ea                                    ;;; now down to business. this is the main entrypoint for the
  402 A:c6ea                                    ;;; read/execution loop. print a prompt, read a line, parse, dispatch,
  403 A:c6ea                                    ;;; repeat.
  404 A:c6ea                                    ;;;
  405 A:c6ea                           reploop   
  406 A:c6ea                                     .( 
  407 A:c6ea                                    ;; is the sd card availible?
  408 A:c6ea  ad 00 04                           lda path
  409 A:c6ed  f0 03                              beq wait_txd_empty
  410 A:c6ef                                    ;; if so, print the current directory.
  411 A:c6ef  20 46 e2                           jsr printpath
  412 A:c6f2                                    ;; print the prompt
  413 A:c6f2                           wait_txd_empty 
  414 A:c6f2  ad 01 80                           lda ACIA_STATUS
  415 A:c6f5  29 10                              and #$10
  416 A:c6f7  f0 f9                              beq wait_txd_empty
  417 A:c6f9  ad 14 ea                           lda prompt
  418 A:c6fc  8d 00 80                           sta ACIA_DATA
  419 A:c6ff                                     .) 

  421 A:c6ff  20 9a d6                           jsr readline                ; read a line into INPUT
  422 A:c702  20 45 d6                           jsr crlf                ; echo line feed/carriage return

  424 A:c705                                    ;; nothing entered? loop again
  425 A:c705  c0 00                              cpy #0
  426 A:c707  f0 e1                              beq reploop

  428 A:c709                                    ;; parse and process the command line
  429 A:c709                                    ;;
  430 A:c709  a9 00                              lda #0
  431 A:c70b  99 00 02                           sta INPUT,y              ; null-terminate the string
  432 A:c70e  20 17 c7                           jsr parseinput                ; parse into individual arguments, indexed at ARGINDEX
  433 A:c711                                    ; jsr testparse     ; debugging output for test purposes
  434 A:c711  20 44 c7                           jsr matchcommand                ; match input command and execute
  435 A:c714  4c ea c6                           jmp reploop                ; loop around

  438 A:c717                           parseinput 
  439 A:c717  da                                 phx                    ; preserve x, since it's our private stack pointer
  440 A:c718  a2 00                              ldx #0
  441 A:c71a  a0 00                              ldy #0

  443 A:c71c                                     .( 
  444 A:c71c                                    ;; look for non-space
  445 A:c71c                           nextchar  
  446 A:c71c  bd 00 02                           lda INPUT,x
  447 A:c71f  c9 20                              cmp #32
  448 A:c721  d0 04                              bne nonspace
  449 A:c723  e8                                 inx 
  450 A:c724  4c 1c c7                           jmp nextchar

  452 A:c727                                    ;; mark the start of the word
  453 A:c727                           nonspace  
  454 A:c727  c8                                 iny                    ; maintain a count of words in y
  455 A:c728  96 20                              stx ARGINDEX,y
  456 A:c72a                                    ;; look for space
  457 A:c72a                           lookforspace 
  458 A:c72a  e8                                 inx 
  459 A:c72b  bd 00 02                           lda INPUT,x
  460 A:c72e  f0 10                              beq endofline                ; check for null termination
  461 A:c730  c9 20                              cmp #32             ; only looking for spaces. Tab?
  462 A:c732  f0 03                              beq endofword
  463 A:c734  4c 2a c7                           jmp lookforspace
  464 A:c737                                    ;; didn't hit a terminator, so there must be more.
  465 A:c737                                    ;; terminate this word with a zero and then continue
  466 A:c737                           endofword 
  467 A:c737  a9 00                              lda #0
  468 A:c739  9d 00 02                           sta INPUT,x              ; null-terminate
  469 A:c73c  e8                                 inx 
  470 A:c73d  4c 1c c7                           jmp nextchar                ; repeat
  471 A:c740                           endofline 
  472 A:c740                                    ;; we're done
  473 A:c740                                    ;; cache the arg count
  474 A:c740  84 20                              sty ARGINDEX

  476 A:c742                                    ;; restore x and return
  477 A:c742  fa                                 plx 
  478 A:c743  60                                 rts 
  479 A:c744                                     .) 

  482 A:c744                                    ;;;
  483 A:c744                                    ;;; just for testing. echo arguments, backwards.
  484 A:c744                                    ;;;

  486 A:c744                                    ; NOTE - we dont need this right now.

  488 A:c744                                    ;testparse
  489 A:c744                                    ;  phx               ; preserve x
  490 A:c744                                    ;  cpy #0            ; test for no arguments
  491 A:c744                                    ;  beq donetestparse
  492 A:c744                                    ;  iny               ; add one to get a guard value
  493 A:c744                                    ;  sty SCRATCH       ; store in SCRATCH. when we get to this value, we stop
  494 A:c744                                    ;  ldy #1            ; start at 1
  495 A:c744                                    ;nextarg
  496 A:c744                                    ;  clc
  497 A:c744                                    ;  tya               ; grab the argument number
  498 A:c744                                    ;  adc #$30          ; add 48 to make it an ascii value
  499 A:c744                                    ;  jsr puta
  500 A:c744                                    ;  lda #$3A          ; ascii for ":"
  501 A:c744                                    ;  jsr puta
  502 A:c744                                    ;  ldx ARGINDEX,y    ; load the index of the next argument into x
  503 A:c744                                    ;nextletter
  504 A:c744                                    ;  ;; print null-terminated string from INPUT+x
  505 A:c744                                    ;  lda INPUT,x
  506 A:c744                                    ;  beq donearg
  507 A:c744                                    ;  jsr puta
  508 A:c744                                    ;  inx
  509 A:c744                                    ;  bne nextletter    ; use this as "branch always," will never be 0
  510 A:c744                                    ;donearg
  511 A:c744                                    ;  ;; output carriage return/line feed and see if there are more arguments
  512 A:c744                                    ;  jsr crlf
  513 A:c744                                    ;  iny
  514 A:c744                                    ;  cpy SCRATCH
  515 A:c744                                    ;  bne nextarg       ; not hit guard yet, so repeat
  516 A:c744                                    ;donetestparse
  517 A:c744                                    ;  plx
  518 A:c744                                    ;  rts

  521 A:c744                                    ;;;;;;;;;;;;;
  522 A:c744                                    ;;;
  523 A:c744                                    ;;; Command lookup/dispatch
  524 A:c744                                    ;;;
  525 A:c744                                    ;;;;;;;;;;;;;

  528 A:c744                           matchcommand 
  529 A:c744  a9 03                              lda #<table              ; low byte of table address
  530 A:c746  85 44                              sta ENTRY
  531 A:c748  a9 c0                              lda #>table              ; high byte of table address
  532 A:c74a  85 45                              sta ENTRY+1

  534 A:c74c  da                                 phx                    ; preserve x, since it's our private stack pointer

  536 A:c74d                           testentry 
  537 A:c74d                           cacheptr  
  538 A:c74d                                    ;; grab the pointer to the next entry and cache it in scratchpad
  539 A:c74d  a0 00                              ldy #0
  540 A:c74f  b1 44                              lda (ENTRY),Y            ; first byte
  541 A:c751  85 10                              sta SCRATCH
  542 A:c753  c8                                 iny 
  543 A:c754  b1 44                              lda (ENTRY),Y            ; second byte
  544 A:c756  85 11                              sta SCRATCH+1
  545 A:c758  c8                                 iny 
  546 A:c759  a2 00                              ldx #0             ;; will use X and Yas index for string
  547 A:c75b                                     .( 
  548 A:c75b                           nextchar  
  549 A:c75b  bd 00 02                           lda INPUT,x
  550 A:c75e  f0 09                              beq endofword
  551 A:c760  d1 44                              cmp (ENTRY),y
  552 A:c762  d0 1b                              bne nextentry
  553 A:c764  e8                                 inx 
  554 A:c765  c8                                 iny 
  555 A:c766  4c 5b c7                           jmp nextchar
  556 A:c769                                     .) 

  558 A:c769                           endofword 
  559 A:c769                                    ;; we got here because we hit the end of the word in the buffer
  560 A:c769                                    ;; if it's also the end of the entry label, then we've found the right place
  561 A:c769  b1 44                              lda (ENTRY),y
  562 A:c76b  f0 03                              beq successful
  563 A:c76d                                    ;; but if it's not, then we haven't.
  564 A:c76d                                    ;; continue to the next entry
  565 A:c76d  4c 7f c7                           jmp nextentry

  567 A:c770                           successful 
  568 A:c770                                    ;; we got a match! copy out the destination address, jump to it
  569 A:c770  c8                                 iny 
  570 A:c771  b1 44                              lda (ENTRY),Y
  571 A:c773  85 12                              sta SCRATCH+2
  572 A:c775  c8                                 iny 
  573 A:c776  b1 44                              lda (ENTRY),Y
  574 A:c778  85 13                              sta SCRATCH+3
  575 A:c77a  fa                                 plx                    ; restore stack pointer
  576 A:c77b  6c 12 00                           jmp (SCRATCH+2)
  577 A:c77e  60                                 rts                    ;; never get here -- we rts from the command code

  579 A:c77f                           nextentry 
  579 A:c77f                                    
  580 A:c77f  a5 10                              lda SCRATCH                ;; copy the address of next entry from scratchpad
  581 A:c781  85 44                              sta ENTRY
  582 A:c783  a5 11                              lda SCRATCH+1
  583 A:c785  85 45                              sta ENTRY+1
  584 A:c787                                    ;; test for null here
  585 A:c787  05 10                              ora SCRATCH                ;; check if the entry was $0000
  586 A:c789  f0 03                              beq endoftable                ;; if so, we're at the end of table
  587 A:c78b  4c 4d c7                           jmp testentry

  589 A:c78e                           endoftable 
  590 A:c78e                                    ;; got to the end of the table with no match
  591 A:c78e                                    ;; print an error message, and return to line input
  592 A:c78e                                    ;; ...

  594 A:c78e                           printerror 
  595 A:c78e  a9 ec                              lda #<nocmderrstr
  596 A:c790  85 42                              sta PRINTVEC
  597 A:c792  a9 f1                              lda #>nocmderrstr
  598 A:c794  85 43                              sta PRINTVEC+1
  599 A:c796  20 c5 e9                           jsr printvecstr
  600 A:c799                                    ; no need for crlf
  601 A:c799                                    ;  ldy #0
  602 A:c799                                    ;.(
  603 A:c799                                    ;next_char
  604 A:c799                                    ;wait_txd_empty  
  605 A:c799                                    ;  lda ACIA_STATUS
  606 A:c799                                    ;  and #$10
  607 A:c799                                    ;  beq wait_txd_empty
  608 A:c799                                    ;  lda errorstring,y
  609 A:c799                                    ;  beq end
  610 A:c799                                    ;  sta ACIA_DATA
  611 A:c799                                    ;  iny
  612 A:c799                                    ;  jmp next_char
  613 A:c799                                    ;end
  614 A:c799                                    ;.)
  615 A:c799  fa                                 plx                    ; restore the stack pointer
  616 A:c79a  60                                 rts 

  620 A:c79b                                    ;;;;;;;;;;;;;
  621 A:c79b                                    ;;;
  622 A:c79b                                    ;;; Monitor commands
  623 A:c79b                                    ;;;
  624 A:c79b                                    ;;;;;;;;;;;;;

  626 A:c79b                           aboutcmd  
  627 A:c79b  a9 15                              lda #<aboutstring
  628 A:c79d  85 42                              sta PRINTVEC
  629 A:c79f  a9 ea                              lda #>aboutstring
  630 A:c7a1  85 43                              sta PRINTVEC+1
  631 A:c7a3  a9 86                              lda #<aboutstringend
  632 A:c7a5  85 0e                              sta ENDVEC
  633 A:c7a7  a9 ed                              lda #>aboutstringend
  634 A:c7a9  85 0f                              sta ENDVEC+1
  635 A:c7ab  4c d9 e9                           jmp printveclong

  637 A:c7ae                           helpcmd   
  638 A:c7ae  a9 87                              lda #<helpstring
  639 A:c7b0  85 42                              sta PRINTVEC
  640 A:c7b2  a9 ed                              lda #>helpstring
  641 A:c7b4  85 43                              sta PRINTVEC+1
  642 A:c7b6  a9 eb                              lda #<helpstringend
  643 A:c7b8  85 0e                              sta ENDVEC
  644 A:c7ba  a9 f1                              lda #>helpstringend
  645 A:c7bc  85 0f                              sta ENDVEC+1
  646 A:c7be  4c d9 e9                           jmp printveclong

  648 A:c7c1                           notimplcmd 
  649 A:c7c1  a9 05                              lda #<implementstring
  650 A:c7c3  85 42                              sta PRINTVEC
  651 A:c7c5  a9 f2                              lda #>implementstring
  652 A:c7c7  85 43                              sta PRINTVEC+1
  653 A:c7c9  20 c5 e9                           jsr printvecstr
  654 A:c7cc  60                                 rts 

  656 A:c7cd                           echocmd   
  657 A:c7cd                                     .( 
  658 A:c7cd  da                                 phx                    ; preserve x, since it's our private stack pointer
  659 A:c7ce  a0 01                              ldy #1             ; start at 1 because we ignore the command itself
  660 A:c7d0                           echonext  
  661 A:c7d0  c4 20                              cpy ARGINDEX                ; have we just done the last?
  662 A:c7d2  d0 03                              bne nottend                ; yes, so end
  663 A:c7d4  4c f1 c7                           jmp end
  664 A:c7d7                           nottend   
  665 A:c7d7  c8                                 iny                    ; no, so move on to the next
  666 A:c7d8  b6 20                              ldx ARGINDEX,y
  667 A:c7da                                    ;; not using printvecstr for this because we're printing
  668 A:c7da                                    ;; directly out of the input buffer  
  669 A:c7da                           next_char 
  670 A:c7da  20 d7 df                           jsr txpoll
  671 A:c7dd  bd 00 02                           lda INPUT,x
  672 A:c7e0  f0 07                              beq endofarg
  673 A:c7e2  8d 00 80                           sta ACIA_DATA
  674 A:c7e5  e8                                 inx 
  675 A:c7e6  4c da c7                           jmp next_char
  676 A:c7e9                           endofarg  
  677 A:c7e9  a9 20                              lda #32             ; put a space at the end
  678 A:c7eb  20 60 d6                           jsr puta
  679 A:c7ee  4c d0 c7                           jmp echonext
  680 A:c7f1                           end       
  681 A:c7f1  20 45 d6                           jsr crlf                ; carriage return/line feed
  682 A:c7f4  fa                                 plx                    ; restore the stack pointer
  683 A:c7f5  60                                 rts 
  684 A:c7f6                                     .) 

  688 A:c7f6                           pokecmd   
  689 A:c7f6                                     .( 
  690 A:c7f6                                    ;; check arguments
  691 A:c7f6  a5 20                              lda ARGINDEX
  692 A:c7f8  c9 03                              cmp #3
  693 A:c7fa  d0 31                              bne error                ; not three, so there's an error of some sort
  694 A:c7fc  18                                 clc 
  695 A:c7fd  a9 00                              lda #<INPUT
  696 A:c7ff  65 23                              adc ARGINDEX+3
  697 A:c801  85 80                              sta stackaccess
  698 A:c803  a9 02                              lda #>INPUT
  699 A:c805  85 81                              sta stackaccess+1
  700 A:c807  20 db c0                           jsr push16
  701 A:c80a  20 2e c2                           jsr read8hex
  702 A:c80d  18                                 clc 
  703 A:c80e  a9 00                              lda #<INPUT
  704 A:c810  65 22                              adc ARGINDEX+2
  705 A:c812  85 80                              sta stackaccess
  706 A:c814  a9 02                              lda #>INPUT
  707 A:c816  85 81                              sta stackaccess+1
  708 A:c818  20 db c0                           jsr push16
  709 A:c81b  20 76 c2                           jsr read16hex

  711 A:c81e  20 e6 c0                           jsr pop16
  712 A:c821  b5 01                              lda stackbase+1,x
  713 A:c823  92 80                              sta (stackaccess)
  714 A:c825  20 6d d6                           jsr putax
  715 A:c828  20 e6 c0                           jsr pop16
  716 A:c82b  80 0b                              bra ende

  718 A:c82d                           error     
  719 A:c82d  a9 3d                              lda #<pokeerrstring
  720 A:c82f  85 42                              sta PRINTVEC
  721 A:c831  a9 f2                              lda #>pokeerrstring
  722 A:c833  85 43                              sta PRINTVEC+1
  723 A:c835  20 c5 e9                           jsr printvecstr
  724 A:c838                           ende      
  725 A:c838                                     .) 
  726 A:c838  20 45 d6                           jsr crlf
  727 A:c83b  60                                 rts 

  729 A:c83c                           dumpcmd   
  730 A:c83c                                     .( 
  731 A:c83c                                    ;; check arguments
  732 A:c83c  a5 20                              lda ARGINDEX
  733 A:c83e  c9 02                              cmp #2
  734 A:c840  f0 07                              beq twoparam                ; two parameters (ie instruction plus address)
  735 A:c842  c9 03                              cmp #3
  736 A:c844  f0 0e                              beq threeparam                ; three parameters (instruction, address, count)
  737 A:c846  4c fb c8                           jmp error                ; neither 2 nor 3, so there's an error
  738 A:c849                           twoparam                   ; only two parameters specified, so fill in third
  739 A:c849  a9 10                              lda #$10             ; default number of bytes to dump
  740 A:c84b  85 80                              sta stackaccess
  741 A:c84d  64 81                              stz stackaccess+1
  742 A:c84f  20 db c0                           jsr push16
  743 A:c852  80 11                              bra finishparam
  744 A:c854                           threeparam                  ; grab both parameters and push them
  745 A:c854  18                                 clc 
  746 A:c855  a9 00                              lda #<INPUT
  747 A:c857  65 23                              adc ARGINDEX+3
  748 A:c859  85 80                              sta stackaccess
  749 A:c85b  a9 02                              lda #>INPUT
  750 A:c85d  85 81                              sta stackaccess+1
  751 A:c85f  20 db c0                           jsr push16
  752 A:c862  20 2e c2                           jsr read8hex
  753 A:c865                           finishparam                  ; process the (first) address parameter
  754 A:c865  18                                 clc 
  755 A:c866  a9 00                              lda #<INPUT
  756 A:c868  65 22                              adc ARGINDEX+2
  757 A:c86a  85 80                              sta stackaccess
  758 A:c86c  a9 02                              lda #>INPUT
  759 A:c86e  85 81                              sta stackaccess+1
  760 A:c870  20 db c0                           jsr push16
  761 A:c873  20 76 c2                           jsr read16hex

  763 A:c876                                    ;; now we actually do the work
  764 A:c876                                    ;; stash base address at SCRATCH
  765 A:c876  b5 01                              lda stackbase+1,x
  766 A:c878  85 10                              sta SCRATCH
  767 A:c87a  b5 02                              lda stackbase+2,x
  768 A:c87c  85 11                              sta SCRATCH+1

  770 A:c87e                           nextline  

  772 A:c87e  da                                 phx                    ; push x. X is only protected for PART of this code.

  774 A:c87f  a0 00                              ldy #0

  776 A:c881                                    ;; print one line

  778 A:c881                                    ;; print the address
  779 A:c881  a5 11                              lda SCRATCH+1
  780 A:c883  20 6d d6                           jsr putax
  781 A:c886  a5 10                              lda SCRATCH
  782 A:c888  20 6d d6                           jsr putax

  784 A:c88b                                    ;; print separator
  785 A:c88b  a9 3a                              lda #$3a             ; colon
  786 A:c88d  20 60 d6                           jsr puta
  787 A:c890  a9 20                              lda #$20             ; space
  788 A:c892  20 60 d6                           jsr puta

  790 A:c895                                    ;; print first eight bytes
  791 A:c895                           printbyte 
  792 A:c895  b1 10                              lda (SCRATCH),y
  793 A:c897  20 6d d6                           jsr putax
  794 A:c89a  a9 20                              lda #$20
  795 A:c89c  20 60 d6                           jsr puta
  796 A:c89f  c0 07                              cpy #$07             ; if at the eighth, print extra separator
  797 A:c8a1  d0 03                              bne nextbyte
  798 A:c8a3  20 60 d6                           jsr puta
  799 A:c8a6                           nextbyte                   ; inc and move on to next byte
  800 A:c8a6  c8                                 iny 
  801 A:c8a7  c0 10                              cpy #$10             ; stop when we get to 16
  802 A:c8a9  d0 ea                              bne printbyte

  804 A:c8ab                                    ;; print separator
  805 A:c8ab  a9 20                              lda #$20
  806 A:c8ad  20 60 d6                           jsr puta
  807 A:c8b0  20 60 d6                           jsr puta
  808 A:c8b3  a9 7c                              lda #$7c             ; vertical bar
  809 A:c8b5  20 60 d6                           jsr puta                ; faster to have that as a little character string!

  811 A:c8b8                                    ;; print ascii values for 16 bytes
  812 A:c8b8  a0 00                              ldy #0
  813 A:c8ba                           nextascii 
  814 A:c8ba  c0 10                              cpy #$10
  815 A:c8bc  f0 12                              beq endascii
  816 A:c8be  b1 10                              lda (SCRATCH),y
  817 A:c8c0                                    ;; it's printable if it's over 32 and under 127
  818 A:c8c0  c9 20                              cmp #32
  819 A:c8c2  30 04                              bmi unprintable
  820 A:c8c4  c9 7f                              cmp #127
  821 A:c8c6  30 02                              bmi printascii
  822 A:c8c8                           unprintable 
  823 A:c8c8  a9 2e                              lda #$2e             ; dot
  824 A:c8ca                           printascii 
  825 A:c8ca  20 60 d6                           jsr puta
  826 A:c8cd  c8                                 iny 
  827 A:c8ce  80 ea                              bra nextascii
  828 A:c8d0                           endascii  
  829 A:c8d0  a9 7c                              lda #$7c             ; vertical bar
  830 A:c8d2  20 60 d6                           jsr puta                ; faster to have that as a little character string!
  831 A:c8d5  20 45 d6                           jsr crlf

  833 A:c8d8                                    ;; now bump the address and check if we should go around again
  834 A:c8d8                                    ;;
  835 A:c8d8  fa                                 plx                    ; restore x so we can work with the stack again
  836 A:c8d9  18                                 clc 

  838 A:c8da                                    ;; subtract 16 from the count
  839 A:c8da  b5 03                              lda stackbase+3,x
  840 A:c8dc  e9 10                              sbc #$10
  841 A:c8de                                    ;; don't bother with the second byte, since it's always a single byte
  842 A:c8de  95 03                              sta stackbase+3,x
  843 A:c8e0  90 12                              bcc donedump
  844 A:c8e2  f0 10                              beq donedump

  846 A:c8e4                                    ;; going round again, so add 16 to the base address
  847 A:c8e4  18                                 clc 
  848 A:c8e5  a5 10                              lda SCRATCH
  849 A:c8e7  69 10                              adc #$10
  850 A:c8e9  85 10                              sta SCRATCH
  851 A:c8eb  a5 11                              lda SCRATCH+1
  852 A:c8ed  69 00                              adc #0
  853 A:c8ef  85 11                              sta SCRATCH+1
  854 A:c8f1  4c 7e c8                           jmp nextline

  856 A:c8f4                           donedump  
  857 A:c8f4                                    ;; throw away last two items on the stack
  858 A:c8f4  e8                                 inx 
  859 A:c8f5  e8                                 inx 
  860 A:c8f6  e8                                 inx 
  861 A:c8f7  e8                                 inx 
  862 A:c8f8  4c 09 c9                           jmp enddumpcmd

  864 A:c8fb                           error     
  865 A:c8fb  a9 1b                              lda #<dumperrstring
  866 A:c8fd  85 42                              sta PRINTVEC
  867 A:c8ff  a9 f2                              lda #>dumperrstring
  868 A:c901  85 43                              sta PRINTVEC+1
  869 A:c903  20 c5 e9                           jsr printvecstr
  870 A:c906                                    ;  ldy #0
  871 A:c906                                    ;  ;; do error
  872 A:c906                                    ;next_char
  873 A:c906                                    ;wait_txd_empty  
  874 A:c906                                    ;  lda ACIA_STATUS
  875 A:c906                                    ;  and #$10
  876 A:c906                                    ;  beq wait_txd_empty
  877 A:c906                                    ;  lda dumperrstring,y
  878 A:c906                                    ;  beq enderr
  879 A:c906                                    ;  sta ACIA_DATA
  880 A:c906                                    ;  iny
  881 A:c906                                    ;  jmp next_char
  882 A:c906                                    ;enderr
  883 A:c906  20 45 d6                           jsr crlf

  885 A:c909                           enddumpcmd 
  886 A:c909  60                                 rts 
  887 A:c90a                                     .) 

  889 A:c90a                                    ;;; zero command -- zero out a block of memory. Two parameters just
  890 A:c90a                                    ;;; like dump.
  891 A:c90a                                    ;;;
  892 A:c90a                           zerocmd   
  893 A:c90a                                     .( 
  894 A:c90a                                    ;; check arguments
  895 A:c90a  a5 20                              lda ARGINDEX
  896 A:c90c  c9 02                              cmp #2
  897 A:c90e  f0 07                              beq twoparam                ; two parameters (ie instruction plus address)
  898 A:c910  c9 03                              cmp #3
  899 A:c912  f0 0e                              beq threeparam                ; three parameters (instruction, address, count)
  900 A:c914  4c 60 c9                           jmp error                ; neither 2 nor 3, so there's an error
  901 A:c917                           twoparam                   ; only two parameters specified, so fill in third
  902 A:c917  a9 10                              lda #$10             ; default number of bytes to dump
  903 A:c919  85 80                              sta stackaccess
  904 A:c91b  64 81                              stz stackaccess+1
  905 A:c91d  20 db c0                           jsr push16
  906 A:c920  80 11                              bra finishparam
  907 A:c922                           threeparam                  ; grab both parameters and push them
  908 A:c922  18                                 clc 
  909 A:c923  a9 00                              lda #<INPUT
  910 A:c925  65 23                              adc ARGINDEX+3
  911 A:c927  85 80                              sta stackaccess
  912 A:c929  a9 02                              lda #>INPUT
  913 A:c92b  85 81                              sta stackaccess+1
  914 A:c92d  20 db c0                           jsr push16
  915 A:c930  20 2e c2                           jsr read8hex
  916 A:c933                           finishparam                  ; process the (first) address parameter
  917 A:c933  18                                 clc 
  918 A:c934  a9 00                              lda #<INPUT
  919 A:c936  65 22                              adc ARGINDEX+2
  920 A:c938  85 80                              sta stackaccess
  921 A:c93a  a9 02                              lda #>INPUT
  922 A:c93c  85 81                              sta stackaccess+1
  923 A:c93e  20 db c0                           jsr push16
  924 A:c941  20 76 c2                           jsr read16hex

  926 A:c944                                    ;; now we actually do the work
  927 A:c944                                    ;; stash base address at SCRATCH
  928 A:c944  b5 01                              lda stackbase+1,x
  929 A:c946  85 10                              sta SCRATCH
  930 A:c948  b5 02                              lda stackbase+2,x
  931 A:c94a  85 11                              sta SCRATCH+1

  934 A:c94c                           loop      
  935 A:c94c  b4 03                              ldy stackbase+3,x        ; the byte count is at stackbase+3,x
  936 A:c94e  f0 09                              beq donezero                ; if we're done, stop
  937 A:c950  88                                 dey                    ; otherwise, decrement the count in y
  938 A:c951  94 03                              sty stackbase+3,x        ; put it back
  939 A:c953  a9 00                              lda #0             ; and store a zero...
  940 A:c955  91 10                              sta (SCRATCH),y            ; in the base address plus y
  941 A:c957  80 f3                              bra loop

  943 A:c959                           donezero  
  944 A:c959                                    ;; finished, so pop two 16-bit values off the stack
  945 A:c959  e8                                 inx 
  946 A:c95a  e8                                 inx 
  947 A:c95b  e8                                 inx 
  948 A:c95c  e8                                 inx 
  949 A:c95d  4c 70 c9                           jmp endzerocmd

  951 A:c960                           error     
  952 A:c960  a0 00                              ldy #0
  953 A:c962  a9 72                              lda #<zeroerrstring
  954 A:c964  85 42                              sta PRINTVEC
  955 A:c966  a9 f2                              lda #>zeroerrstring
  956 A:c968  85 43                              sta PRINTVEC+1
  957 A:c96a  20 c5 e9                           jsr printvecstr
  958 A:c96d                                    ;  ;; do error
  959 A:c96d                                    ;next_char
  960 A:c96d                                    ;wait_txd_empty  
  961 A:c96d                                    ;  lda ACIA_STATUS
  962 A:c96d                                    ;  and #$10
  963 A:c96d                                    ;  beq wait_txd_empty
  964 A:c96d                                    ;  lda zeroerrstring,y
  965 A:c96d                                    ;  beq enderr
  966 A:c96d                                    ;  sta ACIA_DATA
  967 A:c96d                                    ;  iny
  968 A:c96d                                    ;  jmp next_char
  969 A:c96d                                    ;enderr
  970 A:c96d  20 45 d6                           jsr crlf

  972 A:c970                           endzerocmd 
  973 A:c970  60                                 rts 
  974 A:c971                                     .) 

  978 A:c971                                    ;;; NEW go command, using stack-based parameter processing
  979 A:c971                                    ;;;
  980 A:c971                           gocmd     
  981 A:c971                                     .( 
  982 A:c971                                    ;; check arguments
  983 A:c971  a5 20                              lda ARGINDEX
  984 A:c973  c9 02                              cmp #2
  985 A:c975  f0 03                              beq processparam
  986 A:c977  4c 91 c9                           jmp error

  988 A:c97a                           processparam                  ; process the (first) address parameter
  989 A:c97a  18                                 clc 
  990 A:c97b  a9 00                              lda #<INPUT
  991 A:c97d  65 22                              adc ARGINDEX+2
  992 A:c97f  85 80                              sta stackaccess
  993 A:c981  a9 02                              lda #>INPUT
  994 A:c983  85 81                              sta stackaccess+1
  995 A:c985  20 db c0                           jsr push16
  996 A:c988  20 76 c2                           jsr read16hex

  998 A:c98b  20 e6 c0                           jsr pop16                ; put the address into stackaccess
  999 A:c98e  6c 80 00                           jmp (stackaccess)              ; jump directly
 1000 A:c991                                    ;; no rts here because we'll rts from the subroutine

 1002 A:c991                           error     
 1003 A:c991  a9 5d                              lda #<goerrstring
 1004 A:c993  85 42                              sta PRINTVEC
 1005 A:c995  a9 f2                              lda #>goerrstring
 1006 A:c997  85 43                              sta PRINTVEC+1
 1007 A:c999  20 c5 e9                           jsr printvecstr

 1009 A:c99c  20 45 d6                           jsr crlf
 1010 A:c99f  60                                 rts 
 1011 A:c9a0                                     .) 

 1013 A:c9a0                                    ; Clear Screen
 1014 A:c9a0                           clearcmd  
 1014 A:c9a0                                    
 1015 A:c9a0  da                                 phx 
 1016 A:c9a1  20 cc df                           jsr cleardisplay
 1017 A:c9a4  fa                                 plx 
 1018 A:c9a5  60                                 rts 

 1020 A:c9a6                                    ; include cassette tape system

tape.a65

    1 A:c9a6                                    ; Audio-based data storage
    2 A:c9a6                                    ; commands
    2 A:c9a6                                    
    3 A:c9a6                                    ; tsave
    4 A:c9a6                                    ; tload
    5 A:c9a6                                    ;
    6 A:c9a6                                    ; BUG fast mode is not yet functional!

    8 A:c9a6                                    ; Save to cassette tape
    9 A:c9a6                                    ;
   10 A:c9a6                                    ; Argumented with a start and end address
   11 A:c9a6                                    ;

   13 A:c9a6                           tsavecmd  
   13 A:c9a6                                    
   14 A:c9a6                                     .( 
   15 A:c9a6                                    ;; check arguments
   16 A:c9a6  a5 20                              lda ARGINDEX
   17 A:c9a8  c9 03                              cmp #3
   18 A:c9aa  f0 1d                              beq processparamr
   19 A:c9ac  c9 04                              cmp #4
   20 A:c9ae  f0 03                              beq speedp
   21 A:c9b0  4c 1a cb                           jmp error
   22 A:c9b3                           speedp    
   22 A:c9b3                                    
   23 A:c9b3  18                                 clc 
   24 A:c9b4  a9 00                              lda #<INPUT
   25 A:c9b6  65 24                              adc ARGINDEX+4
   26 A:c9b8  85 80                              sta stackaccess
   27 A:c9ba  a9 02                              lda #>INPUT
   28 A:c9bc  85 81                              sta stackaccess+1
   29 A:c9be  b2 80                              lda (stackaccess)
   30 A:c9c0  c9 66                              cmp #'f'
   31 A:c9c2  d0 05                              bne processparamr
   32 A:c9c4  64 17                              stz tapespeed
   33 A:c9c6  4c cd c9                           jmp tsn
   34 A:c9c9                           processparamr 
   35 A:c9c9  a9 ff                              lda #$ff
   36 A:c9cb  85 17                              sta tapespeed
   37 A:c9cd                           tsn       
   37 A:c9cd                                    ; process the (second) address parameter
   38 A:c9cd  18                                 clc 
   39 A:c9ce  a9 00                              lda #<INPUT
   40 A:c9d0  65 23                              adc ARGINDEX+3
   41 A:c9d2  85 80                              sta stackaccess
   42 A:c9d4  a9 02                              lda #>INPUT
   43 A:c9d6  85 81                              sta stackaccess+1
   44 A:c9d8  20 db c0                           jsr push16
   45 A:c9db  20 76 c2                           jsr read16hex
   46 A:c9de  18                                 clc                    ; process the (first) address parameter
   47 A:c9df  a9 00                              lda #<INPUT
   48 A:c9e1  65 22                              adc ARGINDEX+2
   49 A:c9e3  85 80                              sta stackaccess
   50 A:c9e5  a9 02                              lda #>INPUT
   51 A:c9e7  85 81                              sta stackaccess+1
   52 A:c9e9  20 db c0                           jsr push16
   53 A:c9ec  20 76 c2                           jsr read16hex

   55 A:c9ef                                    ; stash the paramaters
   56 A:c9ef  20 e6 c0                           jsr pop16
   57 A:c9f2  a5 80                              lda stackaccess
   58 A:c9f4  85 12                              sta cnt
   59 A:c9f6  a5 81                              lda stackaccess+1
   60 A:c9f8  85 13                              sta cnt+1
   61 A:c9fa  20 e6 c0                           jsr pop16
   62 A:c9fd  a5 80                              lda stackaccess
   63 A:c9ff  85 14                              sta len
   64 A:ca01  a5 81                              lda stackaccess+1
   65 A:ca03  85 15                              sta len+1
   66 A:ca05                           tsavekernal 
   67 A:ca05  da                                 phx                    ; stash stack pointer

   69 A:ca06  a9 bf                              lda #%10111111
   70 A:ca08  8d 03 b0                           sta DDRA
   71 A:ca0b  9c 0e b0                           stz $b00e
   72 A:ca0e  64 11                              stz tapest

   74 A:ca10  a9 8f                              lda #$8f
   75 A:ca12  8d 18 b8                           sta $b818

   77 A:ca15  a2 00                              ldx #0
   78 A:ca17                           lp1       
   78 A:ca17                                    
   79 A:ca17  bd 06 cb                           lda reg,x
   80 A:ca1a  9d 10 b8                           sta $b810,x
   81 A:ca1d  e8                                 inx 
   82 A:ca1e  e0 05                              cpx #5
   83 A:ca20  d0 f5                              bne lp1
   84 A:ca22  a9 4c                              lda #$4c
   85 A:ca24  8d 0e b8                           sta $b80e
   86 A:ca27  a9 9d                              lda #$9d
   87 A:ca29  8d 0f b8                           sta $b80f

   89 A:ca2c  a2 4b                              ldx #<tsavemsg
   90 A:ca2e  a0 cb                              ldy #>tsavemsg              ; press rec and play
   91 A:ca30  20 f0 df                           jsr w_acia_full

   93 A:ca33  a9 18                              lda #$18             ; 4 seconds
   94 A:ca35  20 3c cb                           jsr tape_delay                ; (ye fumble)

   96 A:ca38  a2 91                              ldx #<saving_msg              ; Saving...
   97 A:ca3a  a0 cb                              ldy #>saving_msg
   98 A:ca3c  20 f0 df                           jsr w_acia_full

  100 A:ca3f  a0 40                              ldy #$40
  101 A:ca41  20 d5 ca                           jsr inout                ; intro sound

  103 A:ca44  a9 01                              lda #1
  104 A:ca46  85 10                              sta thing
  105 A:ca48  a0 00                              ldy #0
  106 A:ca4a                           beginn    
  106 A:ca4a                                    
  107 A:ca4a  20 0b cb                           jsr zero
  108 A:ca4d                           begin     
  108 A:ca4d                                    
  109 A:ca4d  b9 12 00                           lda cnt,y              ; read in the address param
  110 A:ca50  25 10                              and thing
  111 A:ca52  d0 0e                              bne head1
  112 A:ca54  20 0b cb                           jsr zero
  113 A:ca57                           head      
  113 A:ca57                                    
  114 A:ca57  a5 10                              lda thing
  115 A:ca59  c9 80                              cmp #$80
  116 A:ca5b  f0 0b                              beq header_done
  117 A:ca5d  06 10                              asl thing
  118 A:ca5f  4c 4d ca                           jmp begin
  119 A:ca62                           head1     
  119 A:ca62                                    
  120 A:ca62  20 e1 ca                           jsr one
  121 A:ca65  4c 57 ca                           jmp head
  122 A:ca68                           header_done 
  122 A:ca68                                    
  123 A:ca68  a9 01                              lda #1
  124 A:ca6a  85 10                              sta thing
  125 A:ca6c  20 e1 ca                           jsr one
  126 A:ca6f  20 e1 ca                           jsr one
  127 A:ca72  c8                                 iny 
  128 A:ca73  c0 04                              cpy #$04
  129 A:ca75  d0 d3                              bne beginn
  130 A:ca77  a0 20                              ldy #$20
  131 A:ca79  20 d5 ca                           jsr inout
  132 A:ca7c                                    ; now to send the actual data
  133 A:ca7c  20 0b cb                           jsr zero
  134 A:ca7f  a2 00                              ldx #0
  135 A:ca81  a9 01                              lda #1
  136 A:ca83  85 10                              sta thing                ; first bit
  137 A:ca85                           wop       
  137 A:ca85                                    
  138 A:ca85  b2 12                              lda (cnt)              ; load data
  139 A:ca87  25 10                              and thing                ; mask it
  140 A:ca89  d0 0e                              bne jsrone                ; one
  141 A:ca8b  20 0b cb                           jsr zero                ; or zero
  142 A:ca8e                           oner      
  142 A:ca8e                                    
  143 A:ca8e  a5 10                              lda thing                ; load the bitmask
  144 A:ca90  c9 80                              cmp #$80             ; end of byte?
  145 A:ca92  f0 0b                              beq noo
  146 A:ca94  06 10                              asl thing
  147 A:ca96  4c 85 ca                           jmp wop                ; next bit
  148 A:ca99                           jsrone    
  148 A:ca99                                    
  149 A:ca99  20 e1 ca                           jsr one                ; a one
  150 A:ca9c  4c 8e ca                           jmp oner
  151 A:ca9f                           noo       
  151 A:ca9f                                    
  152 A:ca9f  a9 01                              lda #1             ; byte done
  153 A:caa1  85 10                              sta thing
  154 A:caa3  20 e1 ca                           jsr one
  155 A:caa6  20 e1 ca                           jsr one
  156 A:caa9  e6 12                              inc cnt                ; inc pointer
  157 A:caab  d0 02                              bne notcnt
  158 A:caad  e6 13                              inc cnt+1
  159 A:caaf                           notcnt    
  159 A:caaf                                    
  160 A:caaf  a5 12                              lda cnt                ; are we done?
  161 A:cab1  c5 14                              cmp len
  162 A:cab3  f0 06                              beq nearly
  163 A:cab5  20 0b cb                           jsr zero
  164 A:cab8  4c 85 ca                           jmp wop                ; if not, go again for another byte
  165 A:cabb                           nearly    
  165 A:cabb                                    
  166 A:cabb  a5 13                              lda cnt+1
  167 A:cabd  c5 15                              cmp len+1
  168 A:cabf  f0 06                              beq savedone
  169 A:cac1  20 0b cb                           jsr zero
  170 A:cac4  4c 85 ca                           jmp wop
  171 A:cac7                           savedone  
  172 A:cac7  a0 40                              ldy #$40
  173 A:cac9  20 d5 ca                           jsr inout                ; we are done, ending sound  

  175 A:cacc                                    ; done
  176 A:cacc  a2 9b                              ldx #<msg2
  177 A:cace  a0 cb                              ldy #>msg2              ; "Done!"
  178 A:cad0  20 f0 df                           jsr w_acia_full

  180 A:cad3  fa                                 plx 
  181 A:cad4  60                                 rts                    ; return

  183 A:cad5                                    ; subs

  185 A:cad5                           inout     
  185 A:cad5                                    
  186 A:cad5                           outer     
  186 A:cad5                                    
  187 A:cad5  a2 10                              ldx #$10             ; $40 * $10 times make the sound
  188 A:cad7                           starter   
  188 A:cad7                                    
  189 A:cad7  20 e1 ca                           jsr one                ; sound
  190 A:cada  ca                                 dex 
  191 A:cadb  d0 fa                              bne starter
  192 A:cadd  88                                 dey 
  193 A:cade  d0 f5                              bne outer
  194 A:cae0  60                                 rts 

  196 A:cae1                           one       
  196 A:cae1                                    ; 2400hz sound 8 cyc
  197 A:cae1  08                                 php 
  198 A:cae2  48                                 pha 
  199 A:cae3  a9 4c                              lda #$4c
  200 A:cae5  8d 0e b8                           sta $b80e
  201 A:cae8  a9 9d                              lda #$9d
  202 A:caea  8d 0f b8                           sta $b80f
  203 A:caed  4c f0 ca                           jmp bitd

  205 A:caf0                           bitd      
  205 A:caf0                                    
  206 A:caf0  a5 17                              lda tapespeed
  207 A:caf2  f0 09                              beq onef
  208 A:caf4  20 29 cb                           jsr tx_delay
  209 A:caf7  20 29 cb                           jsr tx_delay
  210 A:cafa  68                                 pla 
  211 A:cafb  28                                 plp 
  212 A:cafc  60                                 rts 
  213 A:cafd                           onef      
  213 A:cafd                                    
  214 A:cafd  20 37 cb                           jsr ftx_delay
  215 A:cb00  20 37 cb                           jsr ftx_delay
  216 A:cb03  68                                 pla 
  217 A:cb04  28                                 plp 
  218 A:cb05  60                                 rts 

  220 A:cb06                           reg       
  220 A:cb06                                    
  221 A:cb06  00 08 41 00 f0                     .byt $00,$08,$41,$00,$f0

  223 A:cb0b                                    ;togtap
  223 A:cb0b                                    
  224 A:cb0b                                    ;  lda tapest
  225 A:cb0b                                    ;  eor #%10000000  ; data out on PA7
  226 A:cb0b                                    ;  sta tapest
  227 A:cb0b                                    ;  sta PORTA
  228 A:cb0b                                    ;  rts

  230 A:cb0b                           zero      
  230 A:cb0b                                    ; 1200hz sound 4 cyc
  231 A:cb0b  08                                 php 
  232 A:cb0c  48                                 pha 
  233 A:cb0d  a9 a6                              lda #$a6
  234 A:cb0f  8d 0e b8                           sta $b80e
  235 A:cb12  a9 4e                              lda #$4e
  236 A:cb14  8d 0f b8                           sta $b80f
  237 A:cb17  4c f0 ca                           jmp bitd

  239 A:cb1a                           error     
  240 A:cb1a  a9 af                              lda #<tsaveerrstring
  241 A:cb1c  85 42                              sta PRINTVEC
  242 A:cb1e  a9 f2                              lda #>tsaveerrstring
  243 A:cb20  85 43                              sta PRINTVEC+1
  244 A:cb22  20 c5 e9                           jsr printvecstr

  246 A:cb25  20 45 d6                           jsr crlf
  247 A:cb28  60                                 rts 

  249 A:cb29                                     .) 

  251 A:cb29                           tx_delay  
  251 A:cb29                                    
  252 A:cb29  da                                 phx 
  253 A:cb2a  a2 7e                              ldx #$7e
  254 A:cb2c                           tx_delay_inner 
  254 A:cb2c                                    
  255 A:cb2c  ad 1b b8                           lda $b81b
  256 A:cb2f  8d 01 b0                           sta PORTA
  257 A:cb32  ca                                 dex 
  258 A:cb33  d0 f7                              bne tx_delay_inner
  259 A:cb35  fa                                 plx 
  260 A:cb36  60                                 rts 

  262 A:cb37                           ftx_delay 
  262 A:cb37                                    
  263 A:cb37  da                                 phx 
  264 A:cb38  a2 3f                              ldx #$3f
  265 A:cb3a  80 f0                              bra tx_delay_inner

  267 A:cb3c                           tape_delay 
  267 A:cb3c                                    
  268 A:cb3c  a2 ff                              ldx #$ff             ; wait for ye fumble.
  269 A:cb3e                           rd1       
  269 A:cb3e                                    
  270 A:cb3e  a9 7a                              lda #$7a             ; (Y times through inner loop,
  271 A:cb40                           rd2       
  271 A:cb40                                    
  272 A:cb40  e9 01                              sbc #$01             ;  Y * $FF * 650uS = uS / 1e-6 = S )
  273 A:cb42  d0 fc                              bne rd2
  274 A:cb44                           rd3       
  274 A:cb44                                    
  275 A:cb44  ca                                 dex 
  276 A:cb45  d0 f7                              bne rd1
  277 A:cb47  88                                 dey 
  278 A:cb48  d0 f2                              bne tape_delay
  279 A:cb4a  60                                 rts 

  281 A:cb4b                           tsavemsg  
  281 A:cb4b                                    
  282 A:cb4b  02 ff 50 72 65 73 73 ...           .byt $02,$ff,"Press Record And play on Tape.",$0d,$0a,$00
  283 A:cb6e                           tloadmsg  
  283 A:cb6e                                    
  284 A:cb6e  02 ff 50 72 65 73 73 ...           .byt $02,$ff,"Press Play On Tape.",$0d,$0a,$00
  285 A:cb86                           loading_msg 
  285 A:cb86                                    
  286 A:cb86  4c 6f 61 64 69 6e 67 ...           .byt "Loading...",$00
  287 A:cb91                           saving_msg 
  287 A:cb91                                    
  288 A:cb91  53 61 76 69 6e 67 2e ...           .byt "Saving...",$00
  289 A:cb9b                           msg2      
  289 A:cb9b                                    
  290 A:cb9b  44 6f 6e 65 21 0d 0a ...           .byt "Done!",$0d,$0a,$02,$5f,$00
  291 A:cba5                           loadedmsg 
  291 A:cba5                                    
  292 A:cba5  4c 6f 61 64 65 64 20 ...           .byt "Loaded from ",$00
  293 A:cbb2                           tomsg     
  293 A:cbb2                                    
  294 A:cbb2  20 74 6f 20 00                     .byt " to ",$00

  296 A:cbb7                                    ; Load from a cassette tape.
  297 A:cbb7                                    ;
  298 A:cbb7                                    ; Needs no arguments because start and end addresses are encoded in tape.
  299 A:cbb7                                    ;

  301 A:cbb7                           tloadcmd  
  301 A:cbb7                                    
  302 A:cbb7                                    ;; check arguments
  303 A:cbb7  a5 20                              lda ARGINDEX
  304 A:cbb9  c9 01                              cmp #1
  305 A:cbbb  f0 17                              beq notf
  306 A:cbbd                                    ;cmp #2
  307 A:cbbd                                    ;bne error
  308 A:cbbd  18                                 clc 
  309 A:cbbe  a9 00                              lda #<INPUT
  310 A:cbc0  65 22                              adc ARGINDEX+2
  311 A:cbc2  85 80                              sta stackaccess
  312 A:cbc4  a9 02                              lda #>INPUT
  313 A:cbc6  85 81                              sta stackaccess+1
  314 A:cbc8  b2 80                              lda (stackaccess)
  315 A:cbca  c9 66                              cmp #'f'
  316 A:cbcc  d0 06                              bne notf
  317 A:cbce  64 17                              stz tapespeed
  318 A:cbd0  4c d8 cb                           jmp frl
  319 A:cbd3                           tload_kernal 
  319 A:cbd3                                    
  320 A:cbd3  da                                 phx 
  321 A:cbd4                           notf      
  321 A:cbd4                                    
  322 A:cbd4  a9 ff                              lda #$ff
  323 A:cbd6  85 17                              sta tapespeed
  324 A:cbd8                           frl       
  324 A:cbd8                                    
  325 A:cbd8                                     .( 
  326 A:cbd8  da                                 phx 
  327 A:cbd9  a9 bf                              lda #%10111111
  328 A:cbdb  8d 03 b0                           sta DDRA
  329 A:cbde  a9 ff                              lda #%11111111
  330 A:cbe0  8d 02 b0                           sta DDRB

  332 A:cbe3  a2 6e                              ldx #<tloadmsg              ; PRESS PLAY ON TAPE
  333 A:cbe5  a0 cb                              ldy #>tloadmsg
  334 A:cbe7  20 f0 df                           jsr w_acia_full

  336 A:cbea  a9 18                              lda #$18             ; ye fumble
  337 A:cbec  20 3c cb                           jsr tape_delay                ; 4 second delay

  339 A:cbef  a2 86                              ldx #<loading_msg              ; Loading...
  340 A:cbf1  a0 cb                              ldy #>loading_msg
  341 A:cbf3  20 f0 df                           jsr w_acia_full

  343 A:cbf6  a0 00                              ldy #0

  345 A:cbf8                                    ; thanks to ben eater for help with this code

  347 A:cbf8                           rx_wait_start 
  347 A:cbf8                                    
  348 A:cbf8  2c 01 b0                           bit PORTA                ; wait until PORTB.6 = 0 (start bit)
  349 A:cbfb  70 fb                              bvs rx_wait_start

  351 A:cbfd  20 9d cc                           jsr rx_delay                ; half-bit delay
  352 A:cc00  a2 08                              ldx #8
  353 A:cc02                           read_bita 
  353 A:cc02                                    
  354 A:cc02  20 9d cc                           jsr rx_delay                ; run full-bit delay for 300 baud serial stream
  355 A:cc05  20 9d cc                           jsr rx_delay
  356 A:cc08  2c 01 b0                           bit PORTA                ; read in the state
  357 A:cc0b  70 04                              bvs recv_1a                ; if it's not a one,
  358 A:cc0d  18                                 clc                    ; it's a zero.
  359 A:cc0e  4c 14 cc                           jmp rx_donea
  360 A:cc11                           recv_1a   
  360 A:cc11                                    ; otherwise,
  361 A:cc11  38                                 sec                    ; it's a one.
  362 A:cc12  ea                                 nop                    ; nops for timing
  363 A:cc13  ea                                 nop 
  364 A:cc14                           rx_donea  
  364 A:cc14                                    
  365 A:cc14  6a                                 ror                    ; rotate carry into accumulator
  366 A:cc15  ca                                 dex 
  367 A:cc16  d0 ea                              bne read_bita                ; repeat until 8 bits read
  368 A:cc18  99 12 00                           sta cnt,y
  369 A:cc1b  c8                                 iny 
  370 A:cc1c  c0 04                              cpy #$04
  371 A:cc1e  f0 0f                              beq got_len
  372 A:cc20  a5 12                              lda cnt
  373 A:cc22  48                                 pha 
  374 A:cc23  a5 13                              lda cnt+1
  375 A:cc25  48                                 pha 
  376 A:cc26  20 9d cc                           jsr rx_delay
  377 A:cc29  20 9d cc                           jsr rx_delay
  378 A:cc2c  4c f8 cb                           jmp rx_wait_start
  379 A:cc2f                           got_len   
  379 A:cc2f                                    
  380 A:cc2f  20 9d cc                           jsr rx_delay
  381 A:cc32  20 9d cc                           jsr rx_delay
  382 A:cc35                           rx_wait   
  382 A:cc35                                    
  383 A:cc35  2c 01 b0                           bit PORTA                ; wait until PORTB.6 = 0 (start bit)
  384 A:cc38  70 fb                              bvs rx_wait
  385 A:cc3a  20 9d cc                           jsr rx_delay
  386 A:cc3d  a2 08                              ldx #8
  387 A:cc3f                           read_bit  
  387 A:cc3f                                    
  388 A:cc3f  20 9d cc                           jsr rx_delay                ; run bit delay for 300 baud serial stream
  389 A:cc42  20 9d cc                           jsr rx_delay
  390 A:cc45  2c 01 b0                           bit PORTA                ; read in the state
  391 A:cc48  70 04                              bvs recv_1                ; if it's not a one,
  392 A:cc4a  18                                 clc                    ; it's a zero.
  393 A:cc4b  4c 51 cc                           jmp rx_done
  394 A:cc4e                           recv_1    
  394 A:cc4e                                    
  395 A:cc4e  38                                 sec                    ; it's a one.
  396 A:cc4f  ea                                 nop                    ; nops for timing
  397 A:cc50  ea                                 nop 
  398 A:cc51                           rx_done   
  398 A:cc51                                    
  399 A:cc51  6a                                 ror                    ; rotate carry into accumulator
  400 A:cc52  ca                                 dex 
  401 A:cc53  d0 ea                              bne read_bit                ; repeat until 8 bits read
  402 A:cc55  92 12                              sta (cnt)              ; store data
  403 A:cc57  20 9d cc                           jsr rx_delay
  404 A:cc5a  20 9d cc                           jsr rx_delay
  405 A:cc5d  e6 12                              inc cnt
  406 A:cc5f  d0 02                              bne declen
  407 A:cc61  e6 13                              inc cnt+1
  408 A:cc63                           declen    
  408 A:cc63                                    
  409 A:cc63  a5 12                              lda cnt                ; are we done?
  410 A:cc65  c5 14                              cmp len
  411 A:cc67  d0 2b                              bne rx_wait_delay
  412 A:cc69  a5 13                              lda cnt+1
  413 A:cc6b  c5 15                              cmp len+1
  414 A:cc6d  d0 25                              bne rx_wait_delay                ; if not, get another byte
  415 A:cc6f                           load_done 
  415 A:cc6f                                    
  416 A:cc6f  a2 a5                              ldx #<loadedmsg              ; Loaded from X to Y
  417 A:cc71  a0 cb                              ldy #>loadedmsg
  418 A:cc73  20 f0 df                           jsr w_acia_full
  419 A:cc76  68                                 pla 
  420 A:cc77  20 b5 df                           jsr print_hex_acia
  421 A:cc7a  68                                 pla 
  422 A:cc7b  20 b5 df                           jsr print_hex_acia
  423 A:cc7e  a2 b2                              ldx #<tomsg
  424 A:cc80  a0 cb                              ldy #>tomsg
  425 A:cc82  20 f0 df                           jsr w_acia_full
  426 A:cc85  a5 15                              lda len+1
  427 A:cc87  20 b5 df                           jsr print_hex_acia
  428 A:cc8a  a5 14                              lda len
  429 A:cc8c  20 b5 df                           jsr print_hex_acia
  430 A:cc8f  20 45 d6                           jsr crlf
  431 A:cc92  fa                                 plx 
  432 A:cc93  60                                 rts 

  434 A:cc94                           rx_wait_delay 
  434 A:cc94                                    
  435 A:cc94  20 9d cc                           jsr rx_delay
  436 A:cc97  20 9d cc                           jsr rx_delay
  437 A:cc9a  4c 35 cc                           jmp rx_wait
  438 A:cc9d                                     .) 

  440 A:cc9d                           rx_delay  
  440 A:cc9d                                    
  441 A:cc9d  48                                 pha 
  442 A:cc9e  a5 17                              lda tapespeed
  443 A:cca0  f0 10                              beq frx_delay
  444 A:cca2  da                                 phx 
  445 A:cca3  5a                                 phy 
  446 A:cca4  a0 02                              ldy #$02
  447 A:cca6                           rx_delay_outer 
  447 A:cca6                                    
  448 A:cca6  a2 a4                              ldx #$a4
  449 A:cca8                           rx_delay_inner 
  449 A:cca8                                    
  450 A:cca8  ca                                 dex 
  451 A:cca9  d0 fd                              bne rx_delay_inner
  452 A:ccab  88                                 dey 
  453 A:ccac  d0 f8                              bne rx_delay_outer
  454 A:ccae  7a                                 ply 
  455 A:ccaf  fa                                 plx 
  456 A:ccb0  68                                 pla 
  457 A:ccb1  60                                 rts 

  459 A:ccb2                           frx_delay 
  459 A:ccb2                                    
  460 A:ccb2  da                                 phx 
  461 A:ccb3  a2 a4                              ldx #$a4
  462 A:ccb5                           frx_delay_inner 
  462 A:ccb5                                    
  463 A:ccb5  ca                                 dex 
  464 A:ccb6  d0 fd                              bne frx_delay_inner
  465 A:ccb8  fa                                 plx 
  466 A:ccb9  68                                 pla 
  467 A:ccba  60                                 rts 

main.a65


 1023 A:ccbb                           testcmd   
 1024 A:ccbb                                    ;jsr xmodemtest
 1025 A:ccbb  60                                 rts 

 1027 A:ccbc                           xreceivecmd 
 1028 A:ccbc                                     .( 
 1029 A:ccbc                                    ;; check arguments
 1030 A:ccbc  a5 20                              lda ARGINDEX
 1031 A:ccbe  c9 02                              cmp #2
 1032 A:ccc0  f0 03                              beq processparam
 1033 A:ccc2  4c e9 cc                           jmp xerror

 1035 A:ccc5                           processparam                  ; process the address parameter
 1036 A:ccc5  18                                 clc 
 1037 A:ccc6  a9 00                              lda #<INPUT
 1038 A:ccc8  65 22                              adc ARGINDEX+2
 1039 A:ccca  85 80                              sta stackaccess
 1040 A:cccc  a9 02                              lda #>INPUT
 1041 A:ccce                                    ;; BUG?? shouldn't there be an ADC #0 in here?
 1042 A:ccce                                    ;; it works as long as INPUT starts low on a page and so the
 1043 A:ccce                                    ;; upper byte never changes.. but this is an error!
 1044 A:ccce  85 81                              sta stackaccess+1

 1046 A:ccd0  20 db c0                           jsr push16                ; put the string address on the stack
 1047 A:ccd3  20 76 c2                           jsr read16hex                ; convert string to a number value
 1048 A:ccd6  20 e6 c0                           jsr pop16                ; pop number, leave in stackaccess

 1050 A:ccd9  a5 80                              lda stackaccess                ; copy 16 bit address into XDESTADDR
 1051 A:ccdb  8d 34 00                           sta XDESTADDR
 1052 A:ccde  a5 81                              lda stackaccess+1
 1053 A:cce0  8d 35 00                           sta XDESTADDR+1

 1055 A:cce3  20 f8 cc                           jsr xmodemrecv                ; call the receive command
 1056 A:cce6  4c f7 cc                           jmp xmreturn

 1058 A:cce9                           xerror    
 1059 A:cce9  a9 94                              lda #<xrecverrstring
 1060 A:cceb  85 42                              sta PRINTVEC
 1061 A:cced  a9 f2                              lda #>xrecverrstring+1
 1062 A:ccef  85 43                              sta PRINTVEC+1
 1063 A:ccf1  20 c5 e9                           jsr printvecstr
 1064 A:ccf4  20 45 d6                           jsr crlf

 1066 A:ccf7                                     .) 
 1067 A:ccf7                           xmreturn  
 1068 A:ccf7  60                                 rts 

xmodem.a65


    3 A:ccf8                                    ;;;
    4 A:ccf8                                    ;;; Basic xmodem implementation (receive only)
    5 A:ccf8                                    ;;; Super simplistic. So far, this (1) doesn't implement any timeouts, and
    6 A:ccf8                                    ;;; (2) bascially presumes that everything goes great or all it all just
    7 A:ccf8                                    ;;; konks out... it presumes blocks will keep on going up and that there
    8 A:ccf8                                    ;;; will never be re-transmissions, etc. All these are reasonable
    9 A:ccf8                                    ;;; assumptions over a USB serial line that's only a couple of feet long.
   10 A:ccf8                                    ;;;
   11 A:ccf8                                    ;;; Paul Dourish, September 2017
   12 A:ccf8                                    ;;;

   14 A:ccf8                                    XBLOCKNO=$30
   15 A:ccf8                                    XBLOCKINV=$31
   16 A:ccf8                                    XBLOCKCOUNT=$32
   17 A:ccf8                                    XCHKSUM=$33
   18 A:ccf8                                    XDESTADDR=$34           ; and $0035
   19 A:ccf8                                    BUFFER=$36           ; and $0037

   23 A:ccf8                                    ;; entry point
   24 A:ccf8                                    ;;
   25 A:ccf8                           xmodemrecv 
   26 A:ccf8                                    ;; first, print a message announcing that we're listening
   27 A:ccf8  a0 00                              ldy #0
   28 A:ccfa                                     .( 
   29 A:ccfa                           next_char 
   30 A:ccfa                           wait_txd_empty 
   31 A:ccfa  ad 01 80                           lda ACIA_STATUS
   32 A:ccfd  29 10                              and #$10
   33 A:ccff  f0 f9                              beq wait_txd_empty
   34 A:cd01  b9 2c ce                           lda startstr,y
   35 A:cd04  f0 06                              beq endstr
   36 A:cd06  8d 00 80                           sta ACIA_DATA
   37 A:cd09  c8                                 iny 
   38 A:cd0a  80 ee                              bra next_char
   39 A:cd0c                           endstr    
   40 A:cd0c  20 45 d6                           jsr crlf
   41 A:cd0f                                     .) 

   43 A:cd0f                                     .( 
   44 A:cd0f  da                                 phx                    ; preserve operand stack pointer

   46 A:cd10  64 32                              stz XBLOCKCOUNT
   47 A:cd12  a0 00                              ldy #$00
   48 A:cd14  a2 00                              ldx #0

   50 A:cd16                                    ;; okay, now we wait for transmission to start. the deal here is that
   51 A:cd16                                    ;; we are meant to listen with 10-second timeouts, and sent a NACK
   52 A:cd16                                    ;; every ten seconds, one of which will signal to the other end that
   53 A:cd16                                    ;; we are ready to go. However, we don't have a timer set up anywhere.
   54 A:cd16                                    ;; so I'm going to cheat -- we will basically listen for 256x256 loops,
   55 A:cd16                                    ;; and send an ACK after that. it will actually just be a second or two.
   56 A:cd16                           waitstart 
   57 A:cd16  a0 00                              ldy #$00
   58 A:cd18  a2 00                              ldx #$00
   59 A:cd1a                                     .( 
   60 A:cd1a                           wait_rxd_full 
   61 A:cd1a  e8                                 inx                    ; counting up to 256
   62 A:cd1b  f0 0a                              beq bumpy                ; count cycled, so increment Y
   63 A:cd1d  ad 01 80                           lda ACIA_STATUS
   64 A:cd20  29 08                              and #$08
   65 A:cd22  f0 f6                              beq wait_rxd_full
   66 A:cd24  4c 33 cd                           jmp gotfirstchar
   67 A:cd27                           bumpy     
   68 A:cd27  c8                                 iny                    ; counting up to 256
   69 A:cd28  f0 02                              beq sendnack                ; Y has cycled, so we've looped 256*256 times
   70 A:cd2a  80 ee                              bra wait_rxd_full
   71 A:cd2c                           sendnack  
   72 A:cd2c                                    ;; send a nack
   73 A:cd2c  a9 15                              lda #$15
   74 A:cd2e  20 60 d6                           jsr puta
   75 A:cd31  80 e7                              bra wait_rxd_full
   76 A:cd33                                     .) 
   77 A:cd33                           gotfirstchar 
   78 A:cd33  a2 00                              ldx #$00             ; reset X and Y
   79 A:cd35  a0 00                              ldy #$00

   81 A:cd37                           nextblock 
   82 A:cd37                                    ;; check header data and block number
   83 A:cd37                           processbuffer 
   84 A:cd37  20 d9 cd                           jsr getserial                ; get first character (if we don't already have it)
   85 A:cd3a  c9 04                              cmp #$04             ; end-of-transmission?
   86 A:cd3c  f0 6d                              beq endoftransmission
   87 A:cd3e  c9 01                              cmp #$01             ; start-of-header?
   88 A:cd40  f0 06                              beq processblock
   89 A:cd42  20 fc cd                           jsr headererror
   90 A:cd45  4c d7 cd                           jmp xmerror

   92 A:cd48                           processblock 
   93 A:cd48                                    ;; get block number and inverse block number
   94 A:cd48  20 d9 cd                           jsr getserial
   95 A:cd4b  85 30                              sta XBLOCKNO
   96 A:cd4d  20 d9 cd                           jsr getserial
   97 A:cd50  85 31                              sta XBLOCKINV
   98 A:cd52  38                                 sec 
   99 A:cd53  a9 ff                              lda #255
  100 A:cd55  e5 30                              sbc XBLOCKNO
  101 A:cd57  c5 31                              cmp XBLOCKINV                ; does block number match inverse block number?
  102 A:cd59  f0 06                              beq checkblockcount
  103 A:cd5b  20 14 ce                           jsr blockcounterror
  104 A:cd5e  4c d7 cd                           jmp xmerror

  106 A:cd61                           checkblockcount 
  107 A:cd61  e6 32                              inc XBLOCKCOUNT
  108 A:cd63  a5 32                              lda XBLOCKCOUNT
  109 A:cd65  c5 30                              cmp XBLOCKNO                ; does it match what we were expecting?
  110 A:cd67  f0 06                              beq processdata
  111 A:cd69  20 14 ce                           jsr blockcounterror
  112 A:cd6c  4c d7 cd                           jmp xmerror

  114 A:cd6f                           processdata 
  115 A:cd6f  64 33                              stz XCHKSUM
  116 A:cd71  a0 00                              ldy #0
  117 A:cd73                           nextbyte  
  118 A:cd73  20 d9 cd                           jsr getserial
  119 A:cd76  91 34                              sta (XDESTADDR),y
  120 A:cd78  18                                 clc 
  121 A:cd79  65 33                              adc XCHKSUM
  122 A:cd7b  85 33                              sta XCHKSUM
  123 A:cd7d  c8                                 iny 
  124 A:cd7e  c0 80                              cpy #$80
  125 A:cd80  d0 f1                              bne nextbyte
  126 A:cd82                           endofblock 
  127 A:cd82  20 d9 cd                           jsr getserial
  128 A:cd85  c5 33                              cmp XCHKSUM
  129 A:cd87  f0 0e                              beq checksumok
  130 A:cd89  20 6d d6                           jsr putax
  131 A:cd8c  a5 33                              lda XCHKSUM
  132 A:cd8e  20 6d d6                           jsr putax
  133 A:cd91  20 e4 cd                           jsr checksumerror
  134 A:cd94  4c d7 cd                           jmp xmerror
  135 A:cd97                           checksumok 
  136 A:cd97                                    ;; send an ACK
  137 A:cd97  a9 06                              lda #$06
  138 A:cd99  20 60 d6                           jsr puta

  140 A:cd9c                                    ;; update the destination address by 128 ($80)
  141 A:cd9c  a9 80                              lda #$80
  142 A:cd9e  18                                 clc 
  143 A:cd9f  65 34                              adc XDESTADDR
  144 A:cda1  85 34                              sta XDESTADDR
  145 A:cda3  a5 35                              lda XDESTADDR+1
  146 A:cda5  69 00                              adc #0
  147 A:cda7  85 35                              sta XDESTADDR+1
  148 A:cda9                                    ;; and loop for next block

  150 A:cda9  80 8c                              bra nextblock

  152 A:cdab                                    ;; Send an ACK. Pause briefly to allow the connection to be torn down.
  153 A:cdab                                    ;; Then print a message to signal successful completion.
  154 A:cdab                           endoftransmission 
  155 A:cdab                                    ;; send an ACK
  156 A:cdab  a9 06                              lda #$06
  157 A:cdad  20 60 d6                           jsr puta

  159 A:cdb0                                     .( 
  160 A:cdb0                                    ;; this is just to generate a pause. entirely arbitrary.
  161 A:cdb0                                    ;; (had to make this longer after i upped the clock speed)
  162 A:cdb0                                    ;; i've seen other code flush the buffer and just wait until there's
  163 A:cdb0                                    ;; been no new transmission for a period of a second or so. that might
  164 A:cdb0                                    ;; work better...
  165 A:cdb0                                    ;;
  166 A:cdb0  a9 30                              lda #$30
  167 A:cdb2                           fullloop  
  168 A:cdb2  a0 00                              ldy #$00
  169 A:cdb4                           busywait  
  170 A:cdb4  c8                                 iny 
  171 A:cdb5  d0 fd                              bne busywait
  172 A:cdb7  3a                                 dec 
  173 A:cdb8  d0 f8                              bne fullloop
  174 A:cdba                                     .) 

  176 A:cdba  20 45 d6                           jsr crlf
  177 A:cdbd  a0 00                              ldy #0
  178 A:cdbf                                     .( 
  179 A:cdbf                           next_char 
  180 A:cdbf                           wait_txd_empty 
  181 A:cdbf  ad 01 80                           lda ACIA_STATUS
  182 A:cdc2  29 10                              and #$10
  183 A:cdc4  f0 f9                              beq wait_txd_empty
  184 A:cdc6  b9 3d ce                           lda recvdstr,y
  185 A:cdc9  f0 06                              beq endstr
  186 A:cdcb  8d 00 80                           sta ACIA_DATA
  187 A:cdce  c8                                 iny 
  188 A:cdcf  80 ee                              bra next_char
  189 A:cdd1                           endstr    
  190 A:cdd1  20 45 d6                           jsr crlf
  191 A:cdd4                                     .) 
  192 A:cdd4  4c d7 cd                           jmp endxmodem

  194 A:cdd7                           xmerror   

  196 A:cdd7                           endxmodem 
  197 A:cdd7  fa                                 plx                    ; restore operand stack pointer in x
  198 A:cdd8  60                                 rts 
  199 A:cdd9                                     .) 

  202 A:cdd9                                    ;; get a character from the serial port
  203 A:cdd9                                    ;;
  204 A:cdd9                           getserial 
  205 A:cdd9                                     .( 
  206 A:cdd9                           wait_rxd_full 
  207 A:cdd9  ad 01 80                           lda ACIA_STATUS
  208 A:cddc  29 08                              and #$08
  209 A:cdde  f0 f9                              beq wait_rxd_full
  210 A:cde0                                     .) 
  211 A:cde0  ad 00 80                           lda ACIA_DATA
  212 A:cde3  60                                 rts 

  215 A:cde4                           checksumerror 
  216 A:cde4  a0 00                              ldy #0
  217 A:cde6                                     .( 
  218 A:cde6                           next_char 
  219 A:cde6                           wait_txd_empty 
  220 A:cde6  ad 01 80                           lda ACIA_STATUS
  221 A:cde9  29 10                              and #$10
  222 A:cdeb  f0 f9                              beq wait_txd_empty
  223 A:cded  b9 5f ce                           lda chksmerrstr,y
  224 A:cdf0  f0 06                              beq endstr
  225 A:cdf2  8d 00 80                           sta ACIA_DATA
  226 A:cdf5  c8                                 iny 
  227 A:cdf6  80 ee                              bra next_char
  228 A:cdf8                           endstr    
  229 A:cdf8  20 45 d6                           jsr crlf
  230 A:cdfb                                     .) 
  231 A:cdfb  60                                 rts 

  233 A:cdfc                           headererror 
  234 A:cdfc  a0 00                              ldy #0
  235 A:cdfe                                     .( 
  236 A:cdfe                           next_char 
  237 A:cdfe                           wait_txd_empty 
  238 A:cdfe  ad 01 80                           lda ACIA_STATUS
  239 A:ce01  29 10                              and #$10
  240 A:ce03  f0 f9                              beq wait_txd_empty
  241 A:ce05  b9 6f ce                           lda headerrstr,y
  242 A:ce08  f0 06                              beq endstr
  243 A:ce0a  8d 00 80                           sta ACIA_DATA
  244 A:ce0d  c8                                 iny 
  245 A:ce0e  80 ee                              bra next_char
  246 A:ce10                           endstr    
  247 A:ce10  20 45 d6                           jsr crlf
  248 A:ce13                                     .) 
  249 A:ce13  60                                 rts 

  251 A:ce14                           blockcounterror 
  252 A:ce14  a0 00                              ldy #0
  253 A:ce16                                     .( 
  254 A:ce16                           next_char 
  255 A:ce16                           wait_txd_empty 
  256 A:ce16  ad 01 80                           lda ACIA_STATUS
  257 A:ce19  29 10                              and #$10
  258 A:ce1b  f0 f9                              beq wait_txd_empty
  259 A:ce1d  b9 4d ce                           lda blockerrstr,y
  260 A:ce20  f0 06                              beq endstr
  261 A:ce22  8d 00 80                           sta ACIA_DATA
  262 A:ce25  c8                                 iny 
  263 A:ce26  80 ee                              bra next_char
  264 A:ce28                           endstr    
  265 A:ce28  20 45 d6                           jsr crlf
  266 A:ce2b                                     .) 
  267 A:ce2b  60                                 rts 

  270 A:ce2c                           startstr  
  270 A:ce2c  78 6d 6f 64 65 6d 20 ...           .byt "xmodem listening",$00
  271 A:ce3d                           recvdstr  
  271 A:ce3d  78 6d 6f 64 65 6d 20 ...           .byt "xmodem received",$00
  272 A:ce4d                           blockerrstr 
  272 A:ce4d  62 6c 6f 63 6b 20 63 ...           .byt "block count error",$00
  273 A:ce5f                           chksmerrstr 
  273 A:ce5f  63 68 65 63 6b 73 75 ...           .byt "checksum errror",$00
  274 A:ce6f                           headerrstr 
  274 A:ce6f  68 65 61 64 65 72 20 ...           .byt "header error",$00

main.a65


 1072 A:ce7c                           rticmd    
 1073 A:ce7c                                    ;; we got here via a JSR, so we need to drop the return
 1074 A:ce7c                                    ;; address from the stack
 1075 A:ce7c  68                                 pla 
 1076 A:ce7d  68                                 pla 
 1077 A:ce7e                                    ;; now return from interrupt
 1078 A:ce7e  40                                 rti 

 1080 A:ce7f                           inputcmd  
 1081 A:ce7f                                     .( 
 1082 A:ce7f                                    ;; check arguments
 1083 A:ce7f  a5 20                              lda ARGINDEX
 1084 A:ce81  c9 02                              cmp #2
 1085 A:ce83  f0 03                              beq printhelp
 1086 A:ce85  4c 08 cf                           jmp inputerror

 1088 A:ce88                           printhelp 
 1089 A:ce88                                    ;; print a help message
 1090 A:ce88  a9 ce                              lda #<inputhelpstring
 1091 A:ce8a  85 42                              sta PRINTVEC
 1092 A:ce8c  a9 f2                              lda #>inputhelpstring
 1093 A:ce8e  85 43                              sta PRINTVEC+1
 1094 A:ce90  20 c5 e9                           jsr printvecstr
 1095 A:ce93  20 45 d6                           jsr crlf

 1097 A:ce96                           processparam                  ; process the address parameter
 1098 A:ce96  18                                 clc 
 1099 A:ce97  a9 00                              lda #<INPUT
 1100 A:ce99  65 22                              adc ARGINDEX+2
 1101 A:ce9b  85 80                              sta stackaccess
 1102 A:ce9d  a9 02                              lda #>INPUT
 1103 A:ce9f                                    ;; BUG?? shouldn't there be an ADC #0 in here?
 1104 A:ce9f                                    ;; it works as long as INPUT starts low on a page and so the
 1105 A:ce9f                                    ;; upper byte never changes.. but this is an error!
 1106 A:ce9f  85 81                              sta stackaccess+1

 1108 A:cea1  20 db c0                           jsr push16                ; put the string address on the stack
 1109 A:cea4  20 76 c2                           jsr read16hex                ; convert string to a number value
 1110 A:cea7  20 e6 c0                           jsr pop16                ; pop number, leave in stackaccess

 1112 A:ceaa  a5 80                              lda stackaccess                ; copy 16 bit address into SCRATCH
 1113 A:ceac  85 10                              sta SCRATCH
 1114 A:ceae  a5 81                              lda stackaccess+1
 1115 A:ceb0  85 11                              sta SCRATCH+1

 1117 A:ceb2                           start     
 1118 A:ceb2  a5 10                              lda SCRATCH                ; first, print the current address as a prompt
 1119 A:ceb4  85 80                              sta stackaccess
 1120 A:ceb6  a5 11                              lda SCRATCH+1
 1121 A:ceb8  85 81                              sta stackaccess+1
 1122 A:ceba  20 db c0                           jsr push16                ; put it onto the stack
 1123 A:cebd  20 4d c3                           jsr print16hex                ; print it in hex
 1124 A:cec0  a9 20                              lda #$20             ; output a space
 1125 A:cec2  20 60 d6                           jsr puta

 1127 A:cec5  20 9a d6                           jsr readline                ; read a line of input into the buffer
 1128 A:cec8  20 45 d6                           jsr crlf                ; echo newline

 1130 A:cecb  c0 00                              cpy #0             ; is the line blank?
 1131 A:cecd  f0 36                              beq endinput                ; if so, then end the routine
 1132 A:cecf  20 17 c7                           jsr parseinput                ; otherwise, parse the input into byte strings

 1134 A:ced2                                    ;; write those bytes into memory starting at the address
 1135 A:ced2                                    ;; begin a new line with the next address
 1136 A:ced2  a0 01                              ldy #1
 1137 A:ced4  e6 20                              inc ARGINDEX                ; change from count to sentinel value

 1139 A:ced6                           nextbyte  
 1140 A:ced6  c4 20                              cpy ARGINDEX                ; have we done all the arguments?
 1141 A:ced8  f0 29                              beq donebytes                ; if so, jump to the end of this round

 1143 A:ceda  18                                 clc 
 1144 A:cedb  a9 00                              lda #<INPUT              ; load the base address for the input buffer
 1145 A:cedd  79 20 00                           adc ARGINDEX,y              ; and add the offset to the y'th argument
 1146 A:cee0  85 80                              sta stackaccess                ; store at stackaccess
 1147 A:cee2  a9 02                              lda #>INPUT              ; then the upper byte
 1148 A:cee4  69 00                              adc #0             ; in case we cross page boundary (but we shouldn't)
 1149 A:cee6  85 81                              sta stackaccess+1
 1150 A:cee8  20 db c0                           jsr push16                ; push the address for the byte string
 1151 A:ceeb  20 2e c2                           jsr read8hex                ; interpret as an eight-bit hex value
 1152 A:ceee  20 e6 c0                           jsr pop16                ; pull off the stack
 1153 A:cef1  a5 80                              lda stackaccess                ; this is the byte, in the lower 8 bits
 1154 A:cef3  da                                 phx 
 1155 A:cef4  a2 00                              ldx #0             ; needed  because there's no non-index indirect mode
 1156 A:cef6  81 10                              sta (SCRATCH,x)            ; store it at the address pointed to by SCRATCH
 1157 A:cef8  e6 10                              inc SCRATCH                ; increment SCRATCH (and possibly SCRATCH+1)
 1158 A:cefa  d0 02                              bne endloop
 1159 A:cefc  e6 11                              inc SCRATCH+1
 1160 A:cefe                           endloop   
 1161 A:cefe  fa                                 plx                    ; restore X before we use the stack routines again
 1162 A:ceff  c8                                 iny                    ; move on to next entered type
 1163 A:cf00  4c d6 ce                           jmp nextbyte

 1165 A:cf03                           donebytes 
 1166 A:cf03  80 ad                              bra start                ; again with the next line

 1168 A:cf05                           endinput  
 1169 A:cf05  4c 16 cf                           jmp inputreturn

 1171 A:cf08                           inputerror 
 1172 A:cf08  a9 fc                              lda #<inputerrstring
 1173 A:cf0a  85 42                              sta PRINTVEC
 1174 A:cf0c  a9 f2                              lda #>inputerrstring+1
 1175 A:cf0e  85 43                              sta PRINTVEC+1
 1176 A:cf10  20 c5 e9                           jsr printvecstr
 1177 A:cf13  20 45 d6                           jsr crlf
 1178 A:cf16                           inputreturn 
 1179 A:cf16  60                                 rts                    ; return (x already restored)
 1180 A:cf17                                     .) 

 1183 A:cf17                                    ;;;;;;;;;;;;;
 1184 A:cf17                                    ;;;
 1185 A:cf17                                    ;;; Disassembler
 1186 A:cf17                                    ;;;
 1187 A:cf17                                    ;;; Handles all original 6502 opcodes and (almost) all of the 65C02
 1188 A:cf17                                    ;;; opcodes. It may occasionally interpret things overly generously,
 1189 A:cf17                                    ;;; ie take a nonsense byte and give it a meaning... but such a byte
 1190 A:cf17                                    ;;; shouldn't be in a program anyway, right?
 1191 A:cf17                                    ;;;
 1192 A:cf17                                    ;;; Paul Dourish, October 2017
 1193 A:cf17                                    ;;;
 1194 A:cf17                                    ;;;
 1195 A:cf17                                    ;;;;;;;;;;;;;

 1197 A:cf17                           discmd    
 1198 A:cf17                                     .( 
 1199 A:cf17                                    ;; check arguments
 1200 A:cf17  a5 20                              lda ARGINDEX
 1201 A:cf19  c9 02                              cmp #2
 1202 A:cf1b  f0 07                              beq twoparam                ; two parameters (ie instruction plus address)
 1203 A:cf1d  c9 03                              cmp #3
 1204 A:cf1f  f0 0e                              beq threeparam                ; three parameters (instruction, address, count)
 1205 A:cf21  4c 60 cf                           jmp diserror                ; neither 2 nor 3, so there's an error
 1206 A:cf24                           twoparam                   ; only two parameters specified, so fill in third
 1207 A:cf24  a9 10                              lda #$10             ; default number of instructions to decode
 1208 A:cf26  85 80                              sta stackaccess
 1209 A:cf28  64 81                              stz stackaccess+1
 1210 A:cf2a  20 db c0                           jsr push16
 1211 A:cf2d  80 11                              bra finishparam
 1212 A:cf2f                           threeparam                  ; grab both parameters and push them
 1213 A:cf2f  18                                 clc 
 1214 A:cf30  a9 00                              lda #<INPUT
 1215 A:cf32  65 23                              adc ARGINDEX+3
 1216 A:cf34  85 80                              sta stackaccess
 1217 A:cf36  a9 02                              lda #>INPUT
 1218 A:cf38  85 81                              sta stackaccess+1
 1219 A:cf3a  20 db c0                           jsr push16
 1220 A:cf3d  20 2e c2                           jsr read8hex
 1221 A:cf40                           finishparam                  ; process the (first) address parameter
 1222 A:cf40  18                                 clc 
 1223 A:cf41  a9 00                              lda #<INPUT
 1224 A:cf43  65 22                              adc ARGINDEX+2
 1225 A:cf45  85 80                              sta stackaccess
 1226 A:cf47  a9 02                              lda #>INPUT
 1227 A:cf49  85 81                              sta stackaccess+1
 1228 A:cf4b  20 db c0                           jsr push16
 1229 A:cf4e  20 76 c2                           jsr read16hex

 1231 A:cf51                                    ;; now we actually do the work
 1232 A:cf51                                    ;; stash base address at BASE (upper area of scratch memory)

 1234 A:cf51                                    BASE=SCRATCH+$0a
 1235 A:cf51  b5 01                              lda stackbase+1,x
 1236 A:cf53  85 1a                              sta BASE
 1237 A:cf55  b5 02                              lda stackbase+2,x
 1238 A:cf57  85 1b                              sta BASE+1

 1240 A:cf59                                    ;; and stash the count at COUNT (also upper area of scratch memory)
 1241 A:cf59                                    COUNT=SCRATCH+$0c
 1242 A:cf59  b5 03                              lda stackbase+3,x
 1243 A:cf5b  85 1c                              sta COUNT
 1244 A:cf5d  4c 6e cf                           jmp begindis

 1246 A:cf60                           diserror  
 1247 A:cf60  a9 27                              lda #<diserrorstring
 1248 A:cf62  85 42                              sta PRINTVEC
 1249 A:cf64  a9 f3                              lda #>diserrorstring
 1250 A:cf66  85 43                              sta PRINTVEC+1
 1251 A:cf68  20 c5 e9                           jsr printvecstr

 1253 A:cf6b                           enddis    
 1254 A:cf6b  4c bf d4                           jmp exitdis

 1258 A:cf6e                                    ;;; I'm following details and logic from
 1259 A:cf6e                                    ;;; http
 1259 A:cf6e                                    
 1260 A:cf6e                                    ;;;
 1261 A:cf6e                                    ;;; Most instructions are of the form aaabbbcc, where cc signals
 1262 A:cf6e                                    ;;; a block of instructons that operate in a similar way, with aaa
 1263 A:cf6e                                    ;;; indicating the instructoon and bbb indicating the addressing mode.
 1264 A:cf6e                                    ;;; Each of those blocks is handled by two tables, one of which
 1265 A:cf6e                                    ;;; indicates the opcode strings and one of which handles the
 1266 A:cf6e                                    ;;; addressing modes (by storing entry points into the processing
 1267 A:cf6e                                    ;;; routines).
 1268 A:cf6e                                    ;;;

 1270 A:cf6e                           begindis  
 1271 A:cf6e  da                                 phx                    ; preserve X (it's a stack pointer elsewhere)
 1272 A:cf6f  a0 00                              ldy #0             ; y will track bytes as we go

 1274 A:cf71                           start     
 1275 A:cf71                           nextinst  
 1276 A:cf71                                    ;; start the line by printing the address and a couple of spaces
 1277 A:cf71                                    ;;
 1278 A:cf71  a5 1b                              lda BASE+1
 1279 A:cf73  20 6d d6                           jsr putax
 1280 A:cf76  a5 1a                              lda BASE
 1281 A:cf78  20 6d d6                           jsr putax
 1282 A:cf7b  a9 20                              lda #$20
 1283 A:cf7d  20 60 d6                           jsr puta
 1284 A:cf80  20 60 d6                           jsr puta
 1285 A:cf83  20 60 d6                           jsr puta

 1287 A:cf86                                    ;; before we handle the regular cases, check the table
 1288 A:cf86                                    ;; of special cases which are harder to detect via regular
 1289 A:cf86                                    ;; patterns
 1290 A:cf86  a2 00                              ldx #0
 1291 A:cf88                           nextspecial 
 1292 A:cf88  bd 64 d5                           lda specialcasetable,x              ; load item from table
 1293 A:cf8b  c9 ff                              cmp #$ff             ; check if it's the end of the table
 1294 A:cf8d  f0 0d                              beq endspecial                ; if so, exit
 1295 A:cf8f  d1 1a                              cmp (BASE),y            ; compare table item to instruction
 1296 A:cf91  f0 05                              beq foundspecial                ; match?
 1297 A:cf93  e8                                 inx                    ; move on to next table -- three bytes
 1298 A:cf94  e8                                 inx 
 1299 A:cf95  e8                                 inx 
 1300 A:cf96  80 f0                              bra nextspecial                ; loop
 1301 A:cf98                           foundspecial 
 1302 A:cf98  e8                                 inx                    ; when we find a match, jump to address in table
 1303 A:cf99  7c 64 d5                           jmp (specialcasetable,x)
 1304 A:cf9c                           endspecial                  ; got to the end of the table without a match
 1305 A:cf9c  b1 1a                              lda (BASE),y            ; re-load instruction

 1307 A:cf9e  29 1f                              and #%00011111             ; checking if it's a branch
 1308 A:cfa0  c9 10                              cmp #%00010000
 1309 A:cfa2  f0 2d                              beq jbranch                ; jump to code for branches

 1311 A:cfa4                                    ;; block of single byte instructions where the lower nybble is 8
 1312 A:cfa4                                    ;;
 1313 A:cfa4                           testlow8  
 1314 A:cfa4  b1 1a                              lda (BASE),y            ; get the instruction again (last test was destructive)
 1315 A:cfa6  29 0f                              and #%00001111
 1316 A:cfa8  c9 08                              cmp #$08             ; single-byte instructions with 8 in lower nybble
 1317 A:cfaa  d0 03                              bne testxa
 1318 A:cfac  4c cb d2                           jmp single8

 1320 A:cfaf                                    ;; block of single byte instructions at 8A, 9A, etc
 1321 A:cfaf                           testxa    
 1322 A:cfaf  b1 1a                              lda (BASE),y            ; get the instruction again (last test was destructive)
 1323 A:cfb1  29 8f                              and #%10001111
 1324 A:cfb3  c9 8a                              cmp #$8a             ; 8A, 9A, etc
 1325 A:cfb5  d0 03                              bne testcc00
 1326 A:cfb7  4c fa d2                           jmp singlexa

 1328 A:cfba                                    ;; otherwise, process according to the regular scheme of aaabbbcc
 1329 A:cfba                                    ;;
 1330 A:cfba                           testcc00  
 1331 A:cfba  b1 1a                              lda (BASE),y            ; get the instruction again (last test was destructive)
 1332 A:cfbc  29 03                              and #%00000011             ; look at the "cc" bits -- what sort of opcode?
 1333 A:cfbe  d0 03                              bne testcc10
 1334 A:cfc0  4c 39 d2                           jmp branch00                ; go to branch for cc=00
 1335 A:cfc3                           testcc10  
 1336 A:cfc3  c9 02                              cmp #%00000010
 1337 A:cfc5  d0 03                              bne testcc01
 1338 A:cfc7  4c c5 d1                           jmp branch10                ; go to branch for cc=10
 1339 A:cfca                           testcc01  
 1340 A:cfca  c9 01                              cmp #%00000001
 1341 A:cfcc  d0 06                              bne jothers                ; go to branch for remaining opcodes
 1342 A:cfce  4c d7 cf                           jmp branch01

 1344 A:cfd1                           jbranch   
 1345 A:cfd1  4c 9b d2                           jmp branch
 1346 A:cfd4                           jothers   
 1347 A:cfd4  4c 29 d3                           jmp others

 1349 A:cfd7                                    ;;; interpret according to the pattern for cc=01
 1350 A:cfd7                                    ;;;
 1351 A:cfd7                           branch01  
 1352 A:cfd7  b1 1a                              lda (BASE),y            ; reload instruction
 1353 A:cfd9  29 e0                              and #%11100000             ; grab top three bits
 1354 A:cfdb  4a                                 lsr                    ; shift right for times
 1355 A:cfdc  4a                                 lsr 
 1356 A:cfdd  4a                                 lsr                    ; result is the aaa code * 2, ...
 1357 A:cfde  4a                                 lsr                    ; ... the better to use as index into opcode table
 1358 A:cfdf  aa                                 tax 
 1359 A:cfe0                                    ; so now cc01optable,x is the pointer to the right string
 1360 A:cfe0  bd c4 d4                           lda cc01optable,x
 1361 A:cfe3  85 10                              sta SCRATCH
 1362 A:cfe5  bd c5 d4                           lda cc01optable+1,x
 1363 A:cfe8  85 11                              sta SCRATCH+1
 1364 A:cfea  5a                                 phy 
 1365 A:cfeb                                    ; print the three characters pointed to there
 1366 A:cfeb  a0 00                              ldy #0
 1367 A:cfed  b1 10                              lda (SCRATCH),y            ; first character...
 1368 A:cfef  20 60 d6                           jsr puta                ; print it
 1369 A:cff2  c8                                 iny 
 1370 A:cff3  b1 10                              lda (SCRATCH),y            ; second character...
 1371 A:cff5  20 60 d6                           jsr puta                ; print it
 1372 A:cff8  c8                                 iny 
 1373 A:cff9  b1 10                              lda (SCRATCH),y            ; third character...
 1374 A:cffb  20 60 d6                           jsr puta                ; print it
 1375 A:cffe  a9 20                              lda #$20             ; print a space
 1376 A:d000  20 60 d6                           jsr puta
 1377 A:d003  7a                                 ply 

 1379 A:d004                                    ;; handle each addressing mode
 1380 A:d004                                    ;; the addressing mode is going to determine how many
 1381 A:d004                                    ;; bytes we need to consume overall
 1382 A:d004                                    ;; so we do something similar... grab the bits, shift them down
 1383 A:d004                                    ;; and use that to look up a table which will tell us where
 1384 A:d004                                    ;; to jump to to interpret it correctly.

 1386 A:d004  b1 1a                              lda (BASE),y            ; get the instruction again
 1387 A:d006  29 1c                              and #%00011100             ; extract the bbb bits -- addressing mode
 1388 A:d008  4a                                 lsr                    ; shift just once
 1389 A:d009                                    ;; acc now holds the offset of the right entry in the table
 1390 A:d009                                    ;; now add in the base address of the table, and store it in SCRATCH
 1391 A:d009  18                                 clc 
 1392 A:d00a  69 d4                              adc #<cc01adtable
 1393 A:d00c  85 10                              sta SCRATCH                ; less significant byte
 1394 A:d00e  a9 d4                              lda #>cc01adtable
 1395 A:d010  69 00                              adc #0
 1396 A:d012  85 11                              sta SCRATCH+1          ; most significant byte
 1397 A:d014                                    ;; one more level of indirection -- fetch the address listed there
 1398 A:d014  5a                                 phy 
 1399 A:d015  a0 00                              ldy #0
 1400 A:d017  b1 10                              lda (SCRATCH),y
 1401 A:d019  85 12                              sta SCRATCH+2
 1402 A:d01b  c8                                 iny 
 1403 A:d01c  b1 10                              lda (SCRATCH),y
 1404 A:d01e  85 13                              sta SCRATCH+3
 1405 A:d020  7a                                 ply 
 1406 A:d021  6c 12 00                           jmp (SCRATCH+2)        ; jump to address specified in table

 1409 A:d024                                    ;;;
 1410 A:d024                                    ;;; Routines to handle the output for different addressing modes.
 1411 A:d024                                    ;;; Each addressing mode has its own entry point; entries in the
 1412 A:d024                                    ;;; addressing tables for each instruction block point here directly.
 1413 A:d024                                    ;;; On entry and exit, Y indicates the last byte processed.
 1414 A:d024                                    ;;;

 1416 A:d024                           acc       
 1417 A:d024                                    ;; accumulator
 1418 A:d024  a9 41                              lda #'A'
 1419 A:d026  20 60 d6                           jsr puta
 1420 A:d029  4c a5 d4                           jmp endline

 1422 A:d02c                           absx                       ; absolute, X -- consumes two more bytes
 1423 A:d02c  a9 24                              lda #'$'
 1424 A:d02e  20 60 d6                           jsr puta
 1425 A:d031  c8                                 iny                    ; get the second (most-sig) byte first
 1426 A:d032  c8                                 iny 
 1427 A:d033  b1 1a                              lda (BASE),y
 1428 A:d035  20 6d d6                           jsr putax
 1429 A:d038  88                                 dey                    ; then the less-significant byte
 1430 A:d039  b1 1a                              lda (BASE),y
 1431 A:d03b  20 6d d6                           jsr putax
 1432 A:d03e  c8                                 iny                    ; leave Y pointing to last byte consumed
 1433 A:d03f  a9 2c                              lda #','
 1434 A:d041  20 60 d6                           jsr puta
 1435 A:d044  a9 58                              lda #'X'
 1436 A:d046  20 60 d6                           jsr puta
 1437 A:d049  4c a5 d4                           jmp endline

 1439 A:d04c                           izpx                       ; (zero page,X), consumes one more byte
 1440 A:d04c  c8                                 iny 
 1441 A:d04d  a9 28                              lda #'('
 1442 A:d04f  20 60 d6                           jsr puta
 1443 A:d052  a9 24                              lda #'$'
 1444 A:d054  20 60 d6                           jsr puta
 1445 A:d057  a9 30                              lda #'0'
 1446 A:d059  20 60 d6                           jsr puta
 1447 A:d05c  20 60 d6                           jsr puta
 1448 A:d05f  b1 1a                              lda (BASE),y
 1449 A:d061  20 6d d6                           jsr putax
 1450 A:d064  a9 2c                              lda #','
 1451 A:d066  20 60 d6                           jsr puta
 1452 A:d069  a9 58                              lda #'X'
 1453 A:d06b  20 60 d6                           jsr puta
 1454 A:d06e  a9 29                              lda #')'
 1455 A:d070  20 60 d6                           jsr puta
 1456 A:d073  4c a5 d4                           jmp endline

 1458 A:d076                           zp                         ; zero page, consumes one more byte
 1459 A:d076  c8                                 iny 
 1460 A:d077  a9 24                              lda #'$'
 1461 A:d079  20 60 d6                           jsr puta
 1462 A:d07c  a9 30                              lda #'0'
 1463 A:d07e  20 60 d6                           jsr puta
 1464 A:d081  20 60 d6                           jsr puta
 1465 A:d084  b1 1a                              lda (BASE),y
 1466 A:d086  20 6d d6                           jsr putax
 1467 A:d089  4c a5 d4                           jmp endline

 1469 A:d08c                           izp                        ; indirect zero page, only on 65C02, consumes 1 byte
 1470 A:d08c  c8                                 iny 
 1471 A:d08d  a9 28                              lda #'('
 1472 A:d08f  20 60 d6                           jsr puta
 1473 A:d092  a9 24                              lda #'$'
 1474 A:d094  20 60 d6                           jsr puta
 1475 A:d097  a9 30                              lda #'0'
 1476 A:d099  20 60 d6                           jsr puta
 1477 A:d09c  20 60 d6                           jsr puta
 1478 A:d09f  b1 1a                              lda (BASE),y
 1479 A:d0a1  20 6d d6                           jsr putax
 1480 A:d0a4  a9 29                              lda #')'
 1481 A:d0a6  20 60 d6                           jsr puta
 1482 A:d0a9  4c a5 d4                           jmp endline

 1484 A:d0ac                           imm                        ; immediate mode, consumes one byte
 1485 A:d0ac  c8                                 iny 
 1486 A:d0ad  a9 23                              lda #'#'
 1487 A:d0af  20 60 d6                           jsr puta
 1488 A:d0b2  a9 24                              lda #'$'
 1489 A:d0b4  20 60 d6                           jsr puta
 1490 A:d0b7  b1 1a                              lda (BASE),y
 1491 A:d0b9  20 6d d6                           jsr putax
 1492 A:d0bc  4c a5 d4                           jmp endline

 1494 A:d0bf                           immb                       ; like immediate, but for branches (so ditch the "#")
 1495 A:d0bf  c8                                 iny 
 1496 A:d0c0  a9 24                              lda #'$'
 1497 A:d0c2  20 60 d6                           jsr puta
 1498 A:d0c5  b1 1a                              lda (BASE),y
 1499 A:d0c7  20 6d d6                           jsr putax
 1500 A:d0ca  4c a5 d4                           jmp endline

 1502 A:d0cd                           abs       
 1503 A:d0cd                                    ;; absolute -- consumes two more bytes
 1504 A:d0cd  a9 24                              lda #'$'
 1505 A:d0cf  20 60 d6                           jsr puta
 1506 A:d0d2  c8                                 iny                    ; get the second (most-sig) byte first
 1507 A:d0d3  c8                                 iny 
 1508 A:d0d4  b1 1a                              lda (BASE),y
 1509 A:d0d6  20 6d d6                           jsr putax
 1510 A:d0d9  88                                 dey                    ; then the less-significant byte
 1511 A:d0da  b1 1a                              lda (BASE),y
 1512 A:d0dc  20 6d d6                           jsr putax
 1513 A:d0df  c8                                 iny 
 1514 A:d0e0  4c a5 d4                           jmp endline

 1516 A:d0e3                           izpy      
 1517 A:d0e3                                    ;; (zero page),Y -- consumes one more byte
 1518 A:d0e3  c8                                 iny 
 1519 A:d0e4  a9 28                              lda #'('
 1520 A:d0e6  20 60 d6                           jsr puta
 1521 A:d0e9  a9 24                              lda #'$'
 1522 A:d0eb  20 60 d6                           jsr puta
 1523 A:d0ee  a9 30                              lda #'0'
 1524 A:d0f0  20 60 d6                           jsr puta
 1525 A:d0f3  20 60 d6                           jsr puta
 1526 A:d0f6  b1 1a                              lda (BASE),y
 1527 A:d0f8  20 6d d6                           jsr putax
 1528 A:d0fb  a9 29                              lda #')'
 1529 A:d0fd  20 60 d6                           jsr puta
 1530 A:d100  a9 2c                              lda #','
 1531 A:d102  20 60 d6                           jsr puta
 1532 A:d105  a9 59                              lda #'Y'
 1533 A:d107  20 60 d6                           jsr puta
 1534 A:d10a  4c a5 d4                           jmp endline

 1536 A:d10d                           ind       
 1537 A:d10d                                    ;; (addr) -- consumes two more bytes
 1538 A:d10d  c8                                 iny 
 1539 A:d10e  c8                                 iny 
 1540 A:d10f  a9 28                              lda #'('
 1541 A:d111  20 60 d6                           jsr puta
 1542 A:d114  a9 24                              lda #'$'
 1543 A:d116  20 60 d6                           jsr puta
 1544 A:d119  b1 1a                              lda (BASE),y
 1545 A:d11b  20 6d d6                           jsr putax
 1546 A:d11e  88                                 dey 
 1547 A:d11f  b1 1a                              lda (BASE),y
 1548 A:d121  20 6d d6                           jsr putax
 1549 A:d124  a9 29                              lda #')'
 1550 A:d126  20 60 d6                           jsr puta
 1551 A:d129  c8                                 iny 
 1552 A:d12a  4c a5 d4                           jmp endline

 1554 A:d12d                           indx                       ; only the JMP on 65C02?
 1555 A:d12d  c8                                 iny 
 1556 A:d12e  c8                                 iny 
 1557 A:d12f  a9 28                              lda #'('
 1558 A:d131  20 60 d6                           jsr puta
 1559 A:d134  a9 24                              lda #'$'
 1560 A:d136  20 60 d6                           jsr puta
 1561 A:d139  b1 1a                              lda (BASE),y
 1562 A:d13b  20 6d d6                           jsr putax
 1563 A:d13e  88                                 dey 
 1564 A:d13f  b1 1a                              lda (BASE),y
 1565 A:d141  20 6d d6                           jsr putax
 1566 A:d144  a9 2c                              lda #','
 1567 A:d146  20 60 d6                           jsr puta
 1568 A:d149  a9 58                              lda #'X'
 1569 A:d14b  20 60 d6                           jsr puta
 1570 A:d14e  a9 29                              lda #')'
 1571 A:d150  20 60 d6                           jsr puta
 1572 A:d153  c8                                 iny 
 1573 A:d154  4c a5 d4                           jmp endline

 1575 A:d157                           zpx       
 1576 A:d157                                    ;; zero page,X -- consumes one more byte
 1577 A:d157  c8                                 iny 
 1578 A:d158  a9 24                              lda #'$'
 1579 A:d15a  20 60 d6                           jsr puta
 1580 A:d15d  a9 30                              lda #'0'
 1581 A:d15f  20 60 d6                           jsr puta
 1582 A:d162  20 60 d6                           jsr puta
 1583 A:d165  b1 1a                              lda (BASE),y
 1584 A:d167  20 6d d6                           jsr putax
 1585 A:d16a  a9 2c                              lda #','
 1586 A:d16c  20 60 d6                           jsr puta
 1587 A:d16f  a9 58                              lda #'X'
 1588 A:d171  20 60 d6                           jsr puta
 1589 A:d174  4c a5 d4                           jmp endline

 1591 A:d177                           zpy       
 1592 A:d177                                    ;; zero page,Y -- consumes one more byte
 1593 A:d177  c8                                 iny 
 1594 A:d178  a9 24                              lda #'$'
 1595 A:d17a  20 60 d6                           jsr puta
 1596 A:d17d  a9 30                              lda #'0'
 1597 A:d17f  20 60 d6                           jsr puta
 1598 A:d182  20 60 d6                           jsr puta
 1599 A:d185  b1 1a                              lda (BASE),y
 1600 A:d187  20 6d d6                           jsr putax
 1601 A:d18a  a9 2c                              lda #','
 1602 A:d18c  20 60 d6                           jsr puta
 1603 A:d18f  a9 59                              lda #'Y'
 1604 A:d191  20 60 d6                           jsr puta
 1605 A:d194  4c a5 d4                           jmp endline

 1607 A:d197                           absy      
 1608 A:d197                                    ;; absolute,Y -- consumes two more bytes
 1609 A:d197  a9 24                              lda #'$'
 1610 A:d199  20 60 d6                           jsr puta
 1611 A:d19c  c8                                 iny                    ; get the second (most-sig) byte first
 1612 A:d19d  c8                                 iny 
 1613 A:d19e  b1 1a                              lda (BASE),y
 1614 A:d1a0  20 6d d6                           jsr putax
 1615 A:d1a3  88                                 dey                    ; then the less-significant byte
 1616 A:d1a4  b1 1a                              lda (BASE),y
 1617 A:d1a6  20 6d d6                           jsr putax
 1618 A:d1a9  c8                                 iny                    ; leave Y pointing to last byte consumed
 1619 A:d1aa  a9 2c                              lda #','
 1620 A:d1ac  20 60 d6                           jsr puta
 1621 A:d1af  a9 59                              lda #'Y'
 1622 A:d1b1  20 60 d6                           jsr puta
 1623 A:d1b4  4c a5 d4                           jmp endline

 1625 A:d1b7                           err       
 1626 A:d1b7                                    ;; can't interpret the opcode
 1627 A:d1b7  a9 3f                              lda #'?'
 1628 A:d1b9  20 60 d6                           jsr puta
 1629 A:d1bc  20 60 d6                           jsr puta
 1630 A:d1bf  20 60 d6                           jsr puta
 1631 A:d1c2  4c a5 d4                           jmp endline

 1633 A:d1c5                                    ;;; the next major block of addresses is those where the two
 1634 A:d1c5                                    ;;; bottom bits are 10. Processing is very similar to those
 1635 A:d1c5                                    ;;; where cc=01, above.
 1636 A:d1c5                                    ;;; almost all this code is just reproduced from above.
 1637 A:d1c5                                    ;;; TODO-- restructure to share more of the mechanics.
 1638 A:d1c5                                    ;;;
 1639 A:d1c5                           branch10  

 1641 A:d1c5                                    ;; first, take care of the unusual case of the 65C02 instructions
 1642 A:d1c5                                    ;; which use a different logic

 1644 A:d1c5                                    ;; look up and process opcode
 1645 A:d1c5                                    ;;
 1646 A:d1c5  b1 1a                              lda (BASE),y            ; reload instruction
 1647 A:d1c7  29 e0                              and #%11100000             ; grab top three bits
 1648 A:d1c9  4a                                 lsr                    ; shift right for times
 1649 A:d1ca  4a                                 lsr 
 1650 A:d1cb  4a                                 lsr                    ; result is the aaa code * 2, ...
 1651 A:d1cc  4a                                 lsr                    ; ... the better to use as index into opcode table
 1652 A:d1cd  aa                                 tax 

 1654 A:d1ce                                    ;; before we proceed, decide which table to look up. the 65C02 codes
 1655 A:d1ce                                    ;; in the range bbb=100 use a differnt logic
 1656 A:d1ce  b1 1a                              lda (BASE),y
 1657 A:d1d0  29 1c                              and #%00011100
 1658 A:d1d2  c9 10                              cmp #%00010000
 1659 A:d1d4  f0 0d                              beq specialb10

 1661 A:d1d6                                    ; so now cc10optable,x is the pointer to the right string
 1662 A:d1d6  bd e4 d4                           lda cc10optable,x
 1663 A:d1d9  85 10                              sta SCRATCH
 1664 A:d1db  bd e5 d4                           lda cc10optable+1,x
 1665 A:d1de  85 11                              sta SCRATCH+1
 1666 A:d1e0  4c ed d1                           jmp b10opcode

 1668 A:d1e3                           specialb10 
 1669 A:d1e3  bd c4 d4                           lda cc01optable,x              ; not an error... we're using the cc01 table for 65c02
 1670 A:d1e6  85 10                              sta SCRATCH
 1671 A:d1e8  bd c5 d4                           lda cc01optable+1,x
 1672 A:d1eb  85 11                              sta SCRATCH+1

 1674 A:d1ed                           b10opcode 
 1675 A:d1ed  5a                                 phy 
 1676 A:d1ee                                    ; print the three characters pointed to there
 1677 A:d1ee  a0 00                              ldy #0
 1678 A:d1f0  b1 10                              lda (SCRATCH),y            ; first character...
 1679 A:d1f2  20 60 d6                           jsr puta                ; print it
 1680 A:d1f5  c8                                 iny 
 1681 A:d1f6  b1 10                              lda (SCRATCH),y            ; second character...
 1682 A:d1f8  20 60 d6                           jsr puta                ; print it
 1683 A:d1fb  c8                                 iny 
 1684 A:d1fc  b1 10                              lda (SCRATCH),y            ; third character...
 1685 A:d1fe  20 60 d6                           jsr puta                ; print it
 1686 A:d201  a9 20                              lda #$20             ; print a space
 1687 A:d203  20 60 d6                           jsr puta
 1688 A:d206  7a                                 ply 

 1690 A:d207                                    ;; handle each addressing mode
 1691 A:d207                                    ;;
 1692 A:d207  b1 1a                              lda (BASE),y            ; get the instruction again
 1693 A:d209  c9 96                              cmp #$96             ; check fos special cases
 1694 A:d20b  f0 26                              beq specialstx                ; STX in ZP,X mode becomes ZP,Y
 1695 A:d20d  c9 b6                              cmp #$b6
 1696 A:d20f  f0 22                              beq specialldx1                ; LDX in ZP,X mode becomes ZP,Y
 1697 A:d211  c9 be                              cmp #$be
 1698 A:d213  f0 21                              beq specialldx2                ; LDX in ZP,X mode becomes ZP,Y

 1700 A:d215                                    ;; otherwise, proceed as usual
 1701 A:d215  29 1c                              and #%00011100             ; extract the bbb bits -- addressing mode
 1702 A:d217  4a                                 lsr                    ; shift just once
 1703 A:d218                                    ;; acc now holds the offset of the right entry in the table
 1704 A:d218                                    ;; now add in the base address of the table, and store it in SCRATCH
 1705 A:d218  18                                 clc 
 1706 A:d219  69 f4                              adc #<cc10adtable
 1707 A:d21b  85 10                              sta SCRATCH                ; less significant byte
 1708 A:d21d  a9 d4                              lda #>cc10adtable
 1709 A:d21f  69 00                              adc #0
 1710 A:d221  85 11                              sta SCRATCH+1          ; most significant byte
 1711 A:d223                                    ;; one more level of indirection -- fetch the address listed there
 1712 A:d223  5a                                 phy 
 1713 A:d224  a0 00                              ldy #0
 1714 A:d226  b1 10                              lda (SCRATCH),y
 1715 A:d228  85 12                              sta SCRATCH+2
 1716 A:d22a  c8                                 iny 
 1717 A:d22b  b1 10                              lda (SCRATCH),y
 1718 A:d22d  85 13                              sta SCRATCH+3
 1719 A:d22f  7a                                 ply 
 1720 A:d230  6c 12 00                           jmp (SCRATCH+2)        ; jump to address specified in table

 1722 A:d233                           specialstx 
 1723 A:d233                           specialldx1 
 1724 A:d233  4c 77 d1                           jmp zpy
 1725 A:d236                           specialldx2 
 1726 A:d236  4c 97 d1                           jmp absy

 1728 A:d239                                    ;;; This code for the block of instructions with cc=00. Note again
 1729 A:d239                                    ;;; that this is simply repeated from above and should be fixed.
 1730 A:d239                                    ;;; TODO-- refactor this code to eliminate duplication
 1731 A:d239                                    ;;;
 1732 A:d239                           branch00  
 1733 A:d239  b1 1a                              lda (BASE),y            ; reload instruction
 1734 A:d23b  29 e0                              and #%11100000             ; grab top three bits
 1735 A:d23d  4a                                 lsr                    ; shift right for times
 1736 A:d23e  4a                                 lsr 
 1737 A:d23f  4a                                 lsr                    ; result is the aaa code * 2, ...
 1738 A:d240  4a                                 lsr                    ; ... the better to use as index into opcode table
 1739 A:d241  aa                                 tax 
 1740 A:d242                                    ; so now cc00optable,x is the pointer to the right string
 1741 A:d242  bd 04 d5                           lda cc00optable,x
 1742 A:d245  85 10                              sta SCRATCH
 1743 A:d247  bd 05 d5                           lda cc00optable+1,x
 1744 A:d24a  85 11                              sta SCRATCH+1
 1745 A:d24c  5a                                 phy 
 1746 A:d24d                                    ; print the three characters pointed to there
 1747 A:d24d  a0 00                              ldy #0
 1748 A:d24f  b1 10                              lda (SCRATCH),y            ; first character...
 1749 A:d251  20 60 d6                           jsr puta                ; print it
 1750 A:d254  c8                                 iny 
 1751 A:d255  b1 10                              lda (SCRATCH),y            ; second character...
 1752 A:d257  20 60 d6                           jsr puta                ; print it
 1753 A:d25a  c8                                 iny 
 1754 A:d25b  b1 10                              lda (SCRATCH),y            ; third character...
 1755 A:d25d  20 60 d6                           jsr puta                ; print it
 1756 A:d260  a9 20                              lda #$20             ; print a space
 1757 A:d262  20 60 d6                           jsr puta
 1758 A:d265  7a                                 ply 

 1760 A:d266                                    ;; handle each addressing mode
 1761 A:d266                                    ;;
 1762 A:d266  b1 1a                              lda (BASE),y            ; get the instruction again
 1763 A:d268  c9 89                              cmp #$89             ; special case for BIT #
 1764 A:d26a  f0 26                              beq specialbit
 1765 A:d26c  c9 6c                              cmp #$6c             ; indirect JMP is a special case, handle separately
 1766 A:d26e  f0 25                              beq specialindjmp
 1767 A:d270  c9 7c                              cmp #$7c             ; similarly for indirect JMP,X
 1768 A:d272  f0 24                              beq specialindxjmp
 1769 A:d274  29 1c                              and #%00011100             ; extract the bbb bits -- addressing mode
 1770 A:d276  4a                                 lsr                    ; shift just once
 1771 A:d277                                    ;; acc now holds the offset of the right entry in the table
 1772 A:d277                                    ;; now add in the base address of the table, and store it in SCRATCH
 1773 A:d277  18                                 clc 
 1774 A:d278  69 14                              adc #<cc00adtable
 1775 A:d27a  85 10                              sta SCRATCH                ; less significant byte
 1776 A:d27c  a9 d5                              lda #>cc00adtable
 1777 A:d27e  69 00                              adc #0
 1778 A:d280  85 11                              sta SCRATCH+1          ; most significant byte
 1779 A:d282                                    ;; one more level of indirection -- fetch the address listed there
 1780 A:d282  5a                                 phy 
 1781 A:d283  a0 00                              ldy #0
 1782 A:d285  b1 10                              lda (SCRATCH),y
 1783 A:d287  85 12                              sta SCRATCH+2
 1784 A:d289  c8                                 iny 
 1785 A:d28a  b1 10                              lda (SCRATCH),y
 1786 A:d28c  85 13                              sta SCRATCH+3
 1787 A:d28e  7a                                 ply 
 1788 A:d28f  6c 12 00                           jmp (SCRATCH+2)        ; jump to address specified in table

 1790 A:d292                           specialbit 
 1791 A:d292                                    ;; treat this specially -- 65C02 opcode slightly out of place
 1792 A:d292  4c ac d0                           jmp imm

 1794 A:d295                           specialindjmp 
 1795 A:d295                                    ;; treat JMP (address) specially
 1796 A:d295  4c 0d d1                           jmp ind

 1798 A:d298                           specialindxjmp 
 1799 A:d298                                    ;; treat JMP (address,X) specially
 1800 A:d298  4c 2d d1                           jmp indx

 1803 A:d29b                                    ;;; branch instructions -- actually, these don't follow pattern so do FIRST
 1804 A:d29b                                    ;;; branches have the form xxy10000
 1805 A:d29b                                    ;;; xxy*2 should index into branchtable
 1806 A:d29b                           branch    
 1807 A:d29b  b1 1a                              lda (BASE),y
 1808 A:d29d  29 e0                              and #%11100000
 1809 A:d29f  4a                                 lsr 
 1810 A:d2a0  4a                                 lsr 
 1811 A:d2a1  4a                                 lsr 
 1812 A:d2a2  4a                                 lsr 
 1813 A:d2a3  aa                                 tax 

 1815 A:d2a4                                    ;; now index into table
 1816 A:d2a4                                    ; so now branchoptable,x is the pointer to the right string
 1817 A:d2a4  bd 24 d5                           lda branchoptable,x
 1818 A:d2a7  85 10                              sta SCRATCH
 1819 A:d2a9  bd 25 d5                           lda branchoptable+1,x
 1820 A:d2ac  85 11                              sta SCRATCH+1
 1821 A:d2ae  5a                                 phy 
 1822 A:d2af                                    ; print the three characters pointed to there
 1823 A:d2af  a0 00                              ldy #0
 1824 A:d2b1  b1 10                              lda (SCRATCH),y            ; first character...
 1825 A:d2b3  20 60 d6                           jsr puta                ; print it
 1826 A:d2b6  c8                                 iny 
 1827 A:d2b7  b1 10                              lda (SCRATCH),y            ; second character...
 1828 A:d2b9  20 60 d6                           jsr puta                ; print it
 1829 A:d2bc  c8                                 iny 
 1830 A:d2bd  b1 10                              lda (SCRATCH),y            ; third character...
 1831 A:d2bf  20 60 d6                           jsr puta                ; print it
 1832 A:d2c2  a9 20                              lda #$20             ; print a space
 1833 A:d2c4  20 60 d6                           jsr puta
 1834 A:d2c7  7a                                 ply 

 1836 A:d2c8                                    ;; we use a variant form of immediate mode to print the operand
 1837 A:d2c8                                    ;; for branch instructions
 1838 A:d2c8  4c bf d0                           jmp immb

 1840 A:d2cb                                    ;;; these are the single-byte instructions with 8 in their lower nybble
 1841 A:d2cb                                    ;;; again, code borrowed from above (branch) -- TODO -- refactor.
 1842 A:d2cb                           single8   
 1843 A:d2cb  b1 1a                              lda (BASE),y
 1844 A:d2cd  29 f0                              and #%11110000
 1845 A:d2cf  4a                                 lsr 
 1846 A:d2d0  4a                                 lsr 
 1847 A:d2d1  4a                                 lsr 
 1848 A:d2d2  aa                                 tax 

 1850 A:d2d3                                    ;; now index into table
 1851 A:d2d3                                    ;; so now single08table,x is the pointer to the right string
 1852 A:d2d3  bd 34 d5                           lda single08table,x
 1853 A:d2d6  85 10                              sta SCRATCH
 1854 A:d2d8  bd 35 d5                           lda single08table+1,x
 1855 A:d2db  85 11                              sta SCRATCH+1
 1856 A:d2dd  5a                                 phy 
 1857 A:d2de                                    ; print the three characters pointed to there
 1858 A:d2de  a0 00                              ldy #0
 1859 A:d2e0  b1 10                              lda (SCRATCH),y            ; first character...
 1860 A:d2e2  20 60 d6                           jsr puta                ; print it
 1861 A:d2e5  c8                                 iny 
 1862 A:d2e6  b1 10                              lda (SCRATCH),y            ; second character...
 1863 A:d2e8  20 60 d6                           jsr puta                ; print it
 1864 A:d2eb  c8                                 iny 
 1865 A:d2ec  b1 10                              lda (SCRATCH),y            ; third character...
 1866 A:d2ee  20 60 d6                           jsr puta                ; print it
 1867 A:d2f1  a9 20                              lda #$20             ; print a space
 1868 A:d2f3  20 60 d6                           jsr puta
 1869 A:d2f6  7a                                 ply 
 1870 A:d2f7  4c a5 d4                           jmp endline

 1872 A:d2fa                                    ;;; these are the single-byte instructions at 8A, 9A, etc.
 1873 A:d2fa                                    ;;; again, code borrowed from above (branch) -- TODO -- refactor.
 1874 A:d2fa                           singlexa  
 1875 A:d2fa  b1 1a                              lda (BASE),y
 1876 A:d2fc  29 70                              and #%01110000
 1877 A:d2fe  4a                                 lsr 
 1878 A:d2ff  4a                                 lsr 
 1879 A:d300  4a                                 lsr 
 1880 A:d301  aa                                 tax 

 1882 A:d302                                    ;; now index into table
 1883 A:d302                                    ;; so now singlexatable,x is the pointer to the right string
 1884 A:d302  bd 54 d5                           lda singlexatable,x
 1885 A:d305  85 10                              sta SCRATCH
 1886 A:d307  bd 55 d5                           lda singlexatable+1,x
 1887 A:d30a  85 11                              sta SCRATCH+1
 1888 A:d30c  5a                                 phy 
 1889 A:d30d                                    ; print the three characters pointed to there
 1890 A:d30d  a0 00                              ldy #0
 1891 A:d30f  b1 10                              lda (SCRATCH),y            ; first character...
 1892 A:d311  20 60 d6                           jsr puta                ; print it
 1893 A:d314  c8                                 iny 
 1894 A:d315  b1 10                              lda (SCRATCH),y            ; second character...
 1895 A:d317  20 60 d6                           jsr puta                ; print it
 1896 A:d31a  c8                                 iny 
 1897 A:d31b  b1 10                              lda (SCRATCH),y            ; third character...
 1898 A:d31d  20 60 d6                           jsr puta                ; print it
 1899 A:d320  a9 20                              lda #$20             ; print a space
 1900 A:d322  20 60 d6                           jsr puta
 1901 A:d325  7a                                 ply 
 1902 A:d326  4c a5 d4                           jmp endline

 1904 A:d329                                    ;;; this is where we end up if we haven't figured anything else out
 1905 A:d329                                    ;;;
 1906 A:d329                           others    
 1907 A:d329  a9 3f                              lda #'?'
 1908 A:d32b  20 60 d6                           jsr puta
 1909 A:d32e  20 60 d6                           jsr puta
 1910 A:d331  20 60 d6                           jsr puta
 1911 A:d334  4c a5 d4                           jmp endline

 1913 A:d337                                    ;; special cases go here
 1914 A:d337                                    ;;
 1915 A:d337                           dobrk     
 1916 A:d337  a9 42                              lda #'B'
 1917 A:d339  20 60 d6                           jsr puta
 1918 A:d33c  a9 52                              lda #'R'
 1919 A:d33e  20 60 d6                           jsr puta
 1920 A:d341  a9 4b                              lda #'K'
 1921 A:d343  20 60 d6                           jsr puta
 1922 A:d346  4c a5 d4                           jmp endline

 1924 A:d349                           dojsr     
 1925 A:d349  a9 4a                              lda #'J'
 1926 A:d34b  20 60 d6                           jsr puta
 1927 A:d34e  a9 53                              lda #'S'
 1928 A:d350  20 60 d6                           jsr puta
 1929 A:d353  a9 52                              lda #'R'
 1930 A:d355  20 60 d6                           jsr puta
 1931 A:d358  a9 20                              lda #$20
 1932 A:d35a  20 60 d6                           jsr puta
 1933 A:d35d  4c cd d0                           jmp abs

 1935 A:d360                           dorti     
 1936 A:d360  a9 52                              lda #'R'
 1937 A:d362  20 60 d6                           jsr puta
 1938 A:d365  a9 54                              lda #'T'
 1939 A:d367  20 60 d6                           jsr puta
 1940 A:d36a  a9 49                              lda #'I'
 1941 A:d36c  20 60 d6                           jsr puta
 1942 A:d36f  4c a5 d4                           jmp endline

 1944 A:d372                           dorts     
 1945 A:d372  a9 52                              lda #'R'
 1946 A:d374  20 60 d6                           jsr puta
 1947 A:d377  a9 54                              lda #'T'
 1948 A:d379  20 60 d6                           jsr puta
 1949 A:d37c  a9 53                              lda #'S'
 1950 A:d37e  20 60 d6                           jsr puta
 1951 A:d381  4c a5 d4                           jmp endline

 1953 A:d384                           dobra     
 1954 A:d384  a9 42                              lda #'B'
 1955 A:d386  20 60 d6                           jsr puta
 1956 A:d389  a9 52                              lda #'R'
 1957 A:d38b  20 60 d6                           jsr puta
 1958 A:d38e  a9 41                              lda #'A'
 1959 A:d390  20 60 d6                           jsr puta
 1960 A:d393  a9 20                              lda #$20
 1961 A:d395  20 60 d6                           jsr puta
 1962 A:d398  4c bf d0                           jmp immb

 1964 A:d39b                           dotrbzp   
 1965 A:d39b  a9 54                              lda #'T'
 1966 A:d39d  20 60 d6                           jsr puta
 1967 A:d3a0  a9 52                              lda #'R'
 1968 A:d3a2  20 60 d6                           jsr puta
 1969 A:d3a5  a9 42                              lda #'B'
 1970 A:d3a7  20 60 d6                           jsr puta
 1971 A:d3aa  a9 20                              lda #$20
 1972 A:d3ac  20 60 d6                           jsr puta
 1973 A:d3af  4c 76 d0                           jmp zp

 1975 A:d3b2                           dotrbabs  
 1976 A:d3b2  a9 54                              lda #'T'
 1977 A:d3b4  20 60 d6                           jsr puta
 1978 A:d3b7  a9 52                              lda #'R'
 1979 A:d3b9  20 60 d6                           jsr puta
 1980 A:d3bc  a9 42                              lda #'B'
 1981 A:d3be  20 60 d6                           jsr puta
 1982 A:d3c1  a9 20                              lda #$20
 1983 A:d3c3  20 60 d6                           jsr puta
 1984 A:d3c6  4c cd d0                           jmp abs

 1986 A:d3c9                           dostzzp   
 1987 A:d3c9  a9 53                              lda #'S'
 1988 A:d3cb  20 60 d6                           jsr puta
 1989 A:d3ce  a9 54                              lda #'T'
 1990 A:d3d0  20 60 d6                           jsr puta
 1991 A:d3d3  a9 5a                              lda #'Z'
 1992 A:d3d5  20 60 d6                           jsr puta
 1993 A:d3d8  a9 20                              lda #$20
 1994 A:d3da  20 60 d6                           jsr puta
 1995 A:d3dd  4c 76 d0                           jmp zp

 1997 A:d3e0                           dostzabs  
 1998 A:d3e0  a9 53                              lda #'S'
 1999 A:d3e2  20 60 d6                           jsr puta
 2000 A:d3e5  a9 54                              lda #'T'
 2001 A:d3e7  20 60 d6                           jsr puta
 2002 A:d3ea  a9 5a                              lda #'Z'
 2003 A:d3ec  20 60 d6                           jsr puta
 2004 A:d3ef  a9 20                              lda #$20
 2005 A:d3f1  20 60 d6                           jsr puta
 2006 A:d3f4  4c cd d0                           jmp abs

 2008 A:d3f7                           dostzzpx  
 2009 A:d3f7  a9 53                              lda #'S'
 2010 A:d3f9  20 60 d6                           jsr puta
 2011 A:d3fc  a9 54                              lda #'T'
 2012 A:d3fe  20 60 d6                           jsr puta
 2013 A:d401  a9 5a                              lda #'Z'
 2014 A:d403  20 60 d6                           jsr puta
 2015 A:d406  a9 20                              lda #$20
 2016 A:d408  20 60 d6                           jsr puta
 2017 A:d40b  4c 57 d1                           jmp zpx

 2019 A:d40e                           dostzabsx 
 2020 A:d40e  a9 53                              lda #'S'
 2021 A:d410  20 60 d6                           jsr puta
 2022 A:d413  a9 54                              lda #'T'
 2023 A:d415  20 60 d6                           jsr puta
 2024 A:d418  a9 5a                              lda #'Z'
 2025 A:d41a  20 60 d6                           jsr puta
 2026 A:d41d  a9 20                              lda #$20
 2027 A:d41f  20 60 d6                           jsr puta
 2028 A:d422  4c 2c d0                           jmp absx

 2030 A:d425                           doplx     
 2031 A:d425  a9 50                              lda #'P'
 2032 A:d427  20 60 d6                           jsr puta
 2033 A:d42a  a9 4c                              lda #'L'
 2034 A:d42c  20 60 d6                           jsr puta
 2035 A:d42f  a9 58                              lda #'X'
 2036 A:d431  20 60 d6                           jsr puta
 2037 A:d434  4c a5 d4                           jmp endline

 2039 A:d437                           dophx     
 2040 A:d437  a9 50                              lda #'P'
 2041 A:d439  20 60 d6                           jsr puta
 2042 A:d43c  a9 48                              lda #'H'
 2043 A:d43e  20 60 d6                           jsr puta
 2044 A:d441  a9 58                              lda #'X'
 2045 A:d443  20 60 d6                           jsr puta
 2046 A:d446  4c a5 d4                           jmp endline

 2048 A:d449                           doply     
 2049 A:d449  a9 50                              lda #'P'
 2050 A:d44b  20 60 d6                           jsr puta
 2051 A:d44e  a9 4c                              lda #'L'
 2052 A:d450  20 60 d6                           jsr puta
 2053 A:d453  a9 59                              lda #'Y'
 2054 A:d455  20 60 d6                           jsr puta
 2055 A:d458  4c a5 d4                           jmp endline

 2057 A:d45b                           dophy     
 2058 A:d45b  a9 50                              lda #'P'
 2059 A:d45d  20 60 d6                           jsr puta
 2060 A:d460  a9 48                              lda #'H'
 2061 A:d462  20 60 d6                           jsr puta
 2062 A:d465  a9 59                              lda #'Y'
 2063 A:d467  20 60 d6                           jsr puta
 2064 A:d46a  4c a5 d4                           jmp endline

 2066 A:d46d                           doinca    
 2067 A:d46d  a9 49                              lda #'I'
 2068 A:d46f  20 60 d6                           jsr puta
 2069 A:d472  a9 4e                              lda #'N'
 2070 A:d474  20 60 d6                           jsr puta
 2071 A:d477  a9 43                              lda #'C'
 2072 A:d479  20 60 d6                           jsr puta
 2073 A:d47c  a9 20                              lda #$20
 2074 A:d47e  20 60 d6                           jsr puta
 2075 A:d481  a9 41                              lda #'A'
 2076 A:d483  20 60 d6                           jsr puta
 2077 A:d486  4c a5 d4                           jmp endline

 2079 A:d489                           dodeca    
 2080 A:d489  a9 49                              lda #'I'
 2081 A:d48b  20 60 d6                           jsr puta
 2082 A:d48e  a9 4e                              lda #'N'
 2083 A:d490  20 60 d6                           jsr puta
 2084 A:d493  a9 43                              lda #'C'
 2085 A:d495  20 60 d6                           jsr puta
 2086 A:d498  a9 20                              lda #$20
 2087 A:d49a  20 60 d6                           jsr puta
 2088 A:d49d  a9 41                              lda #'A'
 2089 A:d49f  20 60 d6                           jsr puta
 2090 A:d4a2  4c a5 d4                           jmp endline

 2093 A:d4a5                           endline   
 2094 A:d4a5  20 45 d6                           jsr crlf

 2096 A:d4a8                                    ;; at this point, Y points to the last processed byte. Increment
 2097 A:d4a8                                    ;; to move on, and add it to base.
 2098 A:d4a8  c8                                 iny 
 2099 A:d4a9  18                                 clc 
 2100 A:d4aa  98                                 tya                    ; move Y to ACC and add to BASE address
 2101 A:d4ab  65 1a                              adc BASE
 2102 A:d4ad  85 1a                              sta BASE                ; low byte
 2103 A:d4af  a5 1b                              lda BASE+1
 2104 A:d4b1  69 00                              adc #0
 2105 A:d4b3  85 1b                              sta BASE+1          ; high byte
 2106 A:d4b5  a0 00                              ldy #0             ; reset Y

 2108 A:d4b7                                    ;; test if we should terminate... goes here...
 2109 A:d4b7  c6 1c                              dec COUNT
 2110 A:d4b9  f0 03                              beq finishdis

 2112 A:d4bb  4c 71 cf                           jmp nextinst

 2114 A:d4be                           finishdis 
 2115 A:d4be  fa                                 plx                    ; restore the stack pointer
 2116 A:d4bf                           exitdis   
 2117 A:d4bf  e8                                 inx                    ; pop one item off stack (one param)
 2118 A:d4c0  e8                                 inx 
 2119 A:d4c1  e8                                 inx                    ; pop second item off stack (other param)
 2120 A:d4c2  e8                                 inx 
 2121 A:d4c3  60                                 rts 

 2124 A:d4c4                           cc01optable 
 2125 A:d4c4  9a d5 9d d5 a0 d5 a3 ...           .word ORAstr,ANDstr,EORstr,ADCstr,STAstr,LDAstr,CMPstr,SBCstr
 2126 A:d4d4                           cc01adtable 
 2127 A:d4d4  4c d0 76 d0 ac d0 cd ...           .word izpx,zp,imm,abs,izpy,zpx,absy,absx

 2129 A:d4e4                           cc10optable 
 2130 A:d4e4  b2 d5 b5 d5 b8 d5 bb ...           .word ASLstr,ROLstr,LSRstr,RORstr,STXstr,LDXstr,DECstr,INCstr
 2131 A:d4f4                           cc10adtable 
 2132 A:d4f4  ac d0 76 d0 24 d0 cd ...           .word imm,zp,acc,abs,izp,zpx,err,absx

 2134 A:d504                           cc00optable 
 2135 A:d504                                    ;; yes, JMP appears here twice... it's not a mistake...
 2136 A:d504  3f d6 cd d5 d0 d5 d0 ...           .word TSBstr,BITstr,JMPstr,JMPstr,STYstr,LDYstr,CPYstr,CPXstr
 2137 A:d514                           cc00adtable 
 2138 A:d514  ac d0 76 d0 b7 d1 cd ...           .word imm,zp,err,abs,err,zpx,err,absx

 2140 A:d524                           branchoptable 
 2141 A:d524  df d5 e2 d5 e5 d5 e8 ...           .word BPLstr,BMIstr,BVCstr,BVSstr,BCCstr,BCSstr,BNEstr,BEQstr

 2143 A:d534                           single08table 
 2144 A:d534  f7 d5 fa d5 fd d5 00 ...           .word PHPstr,CLCstr,PLPstr,SECstr,PHAstr,CLIstr,PLAstr,SEIstr
 2145 A:d544  0f d6 12 d6 15 d6 18 ...           .word DEYstr,TYAstr,TAYstr,CLVstr,INYstr,CLDstr,INXstr,SEDstr

 2147 A:d554                           singlexatable 
 2148 A:d554  27 d6 2a d6 2d d6 30 ...           .word TXAstr,TXSstr,TAXstr,TSXstr,DEXstr,PHXstr,NOPstr,PLXstr

 2150 A:d564                           specialcasetable 
 2151 A:d564  00                                 .byt $00
 2152 A:d565  37 d3                              .word dobrk
 2153 A:d567  20                                 .byt $20
 2154 A:d568  49 d3                              .word dojsr
 2155 A:d56a  40                                 .byt $40
 2156 A:d56b  60 d3                              .word dorti
 2157 A:d56d  60                                 .byt $60
 2158 A:d56e  72 d3                              .word dorts
 2159 A:d570  80                                 .byt $80
 2160 A:d571  84 d3                              .word dobra
 2161 A:d573  14                                 .byt $14
 2162 A:d574  9b d3                              .word dotrbzp
 2163 A:d576  1c                                 .byt $1c
 2164 A:d577  b2 d3                              .word dotrbabs
 2165 A:d579  64                                 .byt $64
 2166 A:d57a  c9 d3                              .word dostzzp
 2167 A:d57c  9c                                 .byt $9c
 2168 A:d57d  e0 d3                              .word dostzabs
 2169 A:d57f  74                                 .byt $74
 2170 A:d580  f7 d3                              .word dostzzpx
 2171 A:d582  9e                                 .byt $9e
 2172 A:d583  0e d4                              .word dostzabsx
 2173 A:d585  1a                                 .byt $1a
 2174 A:d586  6d d4                              .word doinca
 2175 A:d588  3a                                 .byt $3a
 2176 A:d589  89 d4                              .word dodeca
 2177 A:d58b  5a                                 .byt $5a
 2178 A:d58c  5b d4                              .word dophy
 2179 A:d58e  7a                                 .byt $7a
 2180 A:d58f  49 d4                              .word doply
 2181 A:d591  da                                 .byt $da
 2182 A:d592  37 d4                              .word dophx
 2183 A:d594  fa                                 .byt $fa
 2184 A:d595  25 d4                              .word doplx
 2185 A:d597  ff                                 .byt $ff
 2186 A:d598  ff ff                              .word $ffff

 2189 A:d59a  4f 52 41                 ORAstr    .byt "ORA"
 2190 A:d59d  41 4e 44                 ANDstr    .byt "AND"
 2191 A:d5a0  45 4f 52                 EORstr    .byt "EOR"
 2192 A:d5a3  41 44 43                 ADCstr    .byt "ADC"
 2193 A:d5a6  53 54 41                 STAstr    .byt "STA"
 2194 A:d5a9  4c 44 41                 LDAstr    .byt "LDA"
 2195 A:d5ac  43 4d 50                 CMPstr    .byt "CMP"
 2196 A:d5af  53 42 43                 SBCstr    .byt "SBC"
 2197 A:d5b2  41 53 4c                 ASLstr    .byt "ASL"
 2198 A:d5b5  52 4f 4c                 ROLstr    .byt "ROL"
 2199 A:d5b8  4c 53 52                 LSRstr    .byt "LSR"
 2200 A:d5bb  52 4f 52                 RORstr    .byt "ROR"
 2201 A:d5be  53 54 58                 STXstr    .byt "STX"
 2202 A:d5c1  4c 44 58                 LDXstr    .byt "LDX"
 2203 A:d5c4  44 45 43                 DECstr    .byt "DEC"
 2204 A:d5c7  49 4e 43                 INCstr    .byt "INC"
 2205 A:d5ca  3f 3f 3f                 NONstr    .byt "???"
 2206 A:d5cd  42 49 54                 BITstr    .byt "BIT"
 2207 A:d5d0  4a 4d 50                 JMPstr    .byt "JMP"
 2208 A:d5d3  53 54 59                 STYstr    .byt "STY"
 2209 A:d5d6  4c 44 59                 LDYstr    .byt "LDY"
 2210 A:d5d9  43 50 59                 CPYstr    .byt "CPY"
 2211 A:d5dc  43 50 58                 CPXstr    .byt "CPX"
 2212 A:d5df  42 50 4c                 BPLstr    .byt "BPL"
 2213 A:d5e2  42 4d 49                 BMIstr    .byt "BMI"
 2214 A:d5e5  42 56 43                 BVCstr    .byt "BVC"
 2215 A:d5e8  42 56 53                 BVSstr    .byt "BVS"
 2216 A:d5eb  42 43 43                 BCCstr    .byt "BCC"
 2217 A:d5ee  42 43 53                 BCSstr    .byt "BCS"
 2218 A:d5f1  42 4e 45                 BNEstr    .byt "BNE"
 2219 A:d5f4  42 45 51                 BEQstr    .byt "BEQ"

 2221 A:d5f7  50 48 50                 PHPstr    .byt "PHP"
 2222 A:d5fa  43 4c 43                 CLCstr    .byt "CLC"
 2223 A:d5fd  50 4c 50                 PLPstr    .byt "PLP"
 2224 A:d600  53 45 43                 SECstr    .byt "SEC"
 2225 A:d603  50 48 41                 PHAstr    .byt "PHA"
 2226 A:d606  43 4c 49                 CLIstr    .byt "CLI"
 2227 A:d609  50 4c 41                 PLAstr    .byt "PLA"
 2228 A:d60c  53 45 49                 SEIstr    .byt "SEI"
 2229 A:d60f  44 45 59                 DEYstr    .byt "DEY"
 2230 A:d612  54 59 41                 TYAstr    .byt "TYA"
 2231 A:d615  54 41 59                 TAYstr    .byt "TAY"
 2232 A:d618  43 4c 56                 CLVstr    .byt "CLV"
 2233 A:d61b  49 4e 59                 INYstr    .byt "INY"
 2234 A:d61e  43 4c 44                 CLDstr    .byt "CLD"
 2235 A:d621  49 4e 58                 INXstr    .byt "INX"
 2236 A:d624  53 45 44                 SEDstr    .byt "SED"

 2238 A:d627  54 58 41                 TXAstr    .byt "TXA"
 2239 A:d62a  54 58 53                 TXSstr    .byt "TXS"
 2240 A:d62d  54 41 58                 TAXstr    .byt "TAX"
 2241 A:d630  54 53 58                 TSXstr    .byt "TSX"
 2242 A:d633  44 45 58                 DEXstr    .byt "DEX"
 2243 A:d636  4e 4f 50                 NOPstr    .byt "NOP"

 2245 A:d639  50 4c 41                 PLXstr    .byt "PLA"
 2246 A:d63c  50 48 58                 PHXstr    .byt "PHX"
 2247 A:d63f  54 53 42                 TSBstr    .byt "TSB"

 2249 A:d642  3f 3f 3f                 errstr    .byt "???"

 2251 A:d645                                     .) 

 2253 A:d645                                    ;;;;;;;;;;;;;
 2254 A:d645                                    ;;;
 2255 A:d645                                    ;;; END OF DISASSEMBLER
 2256 A:d645                                    ;;;
 2257 A:d645                                    ;;;;;;;;;;;;;

 2260 A:d645                                    ;;;;;;;;;;;;;
 2261 A:d645                                    ;;;
 2262 A:d645                                    ;;; Various utility routines
 2263 A:d645                                    ;;;
 2264 A:d645                                    ;;;;;;;;;;;;;

 2266 A:d645                                    ;;;
 2267 A:d645                                    ;;; Ouptut carriage return and line feed
 2268 A:d645                                    ;;;
 2269 A:d645                           crlf      
 2270 A:d645  48                                 pha 
 2271 A:d646                                     .( 
 2272 A:d646                           wait_txd_empty 
 2273 A:d646  ad 01 80                           lda ACIA_STATUS
 2274 A:d649  29 10                              and #$10
 2275 A:d64b  f0 f9                              beq wait_txd_empty
 2276 A:d64d                                     .) 
 2277 A:d64d  a9 0d                              lda #$0d
 2278 A:d64f  8d 00 80                           sta ACIA_DATA
 2279 A:d652                                     .( 
 2280 A:d652                           wait_txd_empty 
 2281 A:d652  ad 01 80                           lda ACIA_STATUS
 2282 A:d655  29 10                              and #$10
 2283 A:d657  f0 f9                              beq wait_txd_empty
 2284 A:d659                                     .) 
 2285 A:d659  a9 0a                              lda #$0a
 2286 A:d65b  8d 00 80                           sta ACIA_DATA
 2287 A:d65e  68                                 pla 
 2288 A:d65f  60                                 rts 

 2291 A:d660                                    ;;;
 2292 A:d660                                    ;;; output the character code in the accumulator
 2293 A:d660                                    ;;;
 2294 A:d660                           puta      
 2295 A:d660                                     .( 
 2296 A:d660  48                                 pha 
 2297 A:d661                           wait_txd_empty 
 2298 A:d661  ad 01 80                           lda ACIA_STATUS
 2299 A:d664  29 10                              and #$10
 2300 A:d666  f0 f9                              beq wait_txd_empty
 2301 A:d668  68                                 pla 
 2302 A:d669  8d 00 80                           sta ACIA_DATA
 2303 A:d66c                                     .) 
 2304 A:d66c  60                                 rts 

 2306 A:d66d                                    ;;;
 2307 A:d66d                                    ;;; output the value in the accumulator as a hex pattern
 2308 A:d66d                                    ;;; NB x cannot be guaranteed to be stack ptr during this... check...
 2309 A:d66d                                    ;;;
 2310 A:d66d                           putax     
 2311 A:d66d                                     .( 
 2312 A:d66d  5a                                 phy 

 2314 A:d66e  48                                 pha 
 2315 A:d66f                           wait_txd_empty 
 2316 A:d66f  ad 01 80                           lda ACIA_STATUS
 2317 A:d672  29 10                              and #$10
 2318 A:d674  f0 f9                              beq wait_txd_empty
 2319 A:d676  68                                 pla 
 2320 A:d677  48                                 pha                    ; put a copy back
 2321 A:d678  18                                 clc 
 2322 A:d679  29 f0                              and #$f0
 2323 A:d67b  6a                                 ror 
 2324 A:d67c  6a                                 ror 
 2325 A:d67d  6a                                 ror 
 2326 A:d67e  6a                                 ror 
 2327 A:d67f  a8                                 tay 
 2328 A:d680  b9 f3 e9                           lda hextable,y
 2329 A:d683  8d 00 80                           sta ACIA_DATA
 2330 A:d686                           wait_txd_empty2 
 2331 A:d686  ad 01 80                           lda ACIA_STATUS
 2332 A:d689  29 10                              and #$10
 2333 A:d68b  f0 f9                              beq wait_txd_empty2
 2334 A:d68d  68                                 pla 
 2335 A:d68e  18                                 clc 
 2336 A:d68f  29 0f                              and #$0f
 2337 A:d691  a8                                 tay 
 2338 A:d692  b9 f3 e9                           lda hextable,y
 2339 A:d695  8d 00 80                           sta ACIA_DATA
 2340 A:d698                                     .) 
 2341 A:d698  7a                                 ply 
 2342 A:d699  60                                 rts 

 2345 A:d69a                                    ;;; read a line of input from the serial interface
 2346 A:d69a                                    ;;; leaves data in the buffer at INPUT
 2347 A:d69a                                    ;;; y is the number of characters in the line, so it will fail if
 2348 A:d69a                                    ;;; more then 255 characters are entered
 2349 A:d69a                                    ;;; line terminated by carriage return. backspaces processed internally.
 2350 A:d69a                                    ;;;
 2351 A:d69a                           readline  
 2352 A:d69a  a0 00                              ldy #0
 2353 A:d69c                           readchar  
 2354 A:d69c                                     .( 
 2355 A:d69c                           wait_rxd_full 
 2356 A:d69c  ad 01 80                           lda ACIA_STATUS
 2357 A:d69f  29 08                              and #$08
 2358 A:d6a1  f0 f9                              beq wait_rxd_full
 2359 A:d6a3                                     .) 
 2360 A:d6a3  ad 00 80                           lda ACIA_DATA
 2361 A:d6a6  c9 08                              cmp #$08             ; check for backspace
 2362 A:d6a8  f0 0e                              beq backspace
 2363 A:d6aa  c9 0d                              cmp #$0d             ; check for newline
 2364 A:d6ac  f0 15                              beq done
 2365 A:d6ae  99 00 02                           sta INPUT,y              ; track the input
 2366 A:d6b1  c8                                 iny 
 2367 A:d6b2  20 60 d6                           jsr puta                ; echo the typed character
 2368 A:d6b5  4c 9c d6                           jmp readchar                ; loop to repeat
 2369 A:d6b8                           backspace 
 2370 A:d6b8  c0 00                              cpy #0             ; beginning of line?
 2371 A:d6ba  f0 e0                              beq readchar
 2372 A:d6bc  88                                 dey                    ; if not, go back one character
 2373 A:d6bd  20 60 d6                           jsr puta                ; move cursor back
 2374 A:d6c0  4c 9c d6                           jmp readchar

 2376 A:d6c3                                    ;; this is where we land if the line input has finished
 2377 A:d6c3                                    ;;
 2378 A:d6c3                           done      
 2379 A:d6c3  60                                 rts 

 2381 A:d6c4                                    ;; data receive
 2382 A:d6c4                                    ;; receives data from serial
 2383 A:d6c4                                    ;;
 2384 A:d6c4                                    ;; !! DISABLED !!

 2386 A:d6c4                                    ;receivecmd
 2387 A:d6c4                                    ;  pha
 2388 A:d6c4                                    ;  phx  ; save registers
 2389 A:d6c4                                    ;  phy
 2390 A:d6c4                                    ;  lda XYLODSAV2
 2391 A:d6c4                                    ;  pha
 2392 A:d6c4                                    ;  lda XYLODSAV2+1
 2393 A:d6c4                                    ;  pha
 2394 A:d6c4                                    ;;  ldx #<transferstring
 2395 A:d6c4                                    ;;  ldy #>transferstring
 2396 A:d6c4                                    ;;  jsr w_acia_full
 2397 A:d6c4                                    ;END_LOAD_MSG
 2398 A:d6c4                                    ;SERIAL_LOAD
 2399 A:d6c4                                    ;  ldx #0
 2400 A:d6c4                                    ;WRMSG
 2401 A:d6c4                                    ;  ldx #<serialstring
 2402 A:d6c4                                    ;  ldy #>serialstring ; Start serial load. <CRLF>
 2403 A:d6c4                                    ;  jsr w_acia_full
 2404 A:d6c4                                    ;receive_serial
 2405 A:d6c4                                    ;  lda #$55
 2406 A:d6c4                                    ;  sta serialvar
 2407 A:d6c4                                    ;  lda $0208  ; if "receive h"
 2408 A:d6c4                                    ;  cmp #'h'
 2409 A:d6c4                                    ;  bne rcloopstart ; then header mode
 2410 A:d6c4                                    ;  lda #0  ; otherwize, receive <addr>
 2411 A:d6c4                                    ;  sta serialvar  ; let rsl know
 2412 A:d6c4                                    ;  jmp serialheader
 2413 A:d6c4                                    ;rcloopstart
 2414 A:d6c4                                    ;  ldx #$04  ; 4 bytes
 2415 A:d6c4                                    ;rcloopadd
 2416 A:d6c4                                    ;  lda $0207,x  ; operand addr -1 (because of the loop)
 2417 A:d6c4                                    ;  pha   ; preserve a
 2418 A:d6c4                                    ;  cmp #$41  ; alphabet? (operand >= $41)
 2419 A:d6c4                                    ;  bcc rcloopadd1 ; no
 2420 A:d6c4                                    ;  pla   ; yes, restore a
 2421 A:d6c4                                    ;  sec   ; $57 cuz $A = #10
 2422 A:d6c4                                    ;  sbc #$57  ; $61 - $A = $57
 2423 A:d6c4                                    ;  jmp rcloopadd2 ; continue
 2424 A:d6c4                                    ;rcloopadd1  ; it is a number
 2425 A:d6c4                                    ;  pla   ; restore a so we can compare it
 2426 A:d6c4                                    ;  sec   ; (operand - $30)
 2427 A:d6c4                                    ;  sbc #$30
 2428 A:d6c4                                    ;rcloopadd2
 2429 A:d6c4                                    ;  sta $0207,x  ; store the created nibble, one per byte...
 2430 A:d6c4                                    ;  dex
 2431 A:d6c4                                    ;  bne rcloopadd
 2432 A:d6c4                                    ;
 2433 A:d6c4                                    ;  lda $0208  ; load the 4 nibbles into 2 bytes
 2434 A:d6c4                                    ;  asl   ; a nibble per byte to 2 nibbles per byte
 2435 A:d6c4                                    ;  asl   ; so it can be readable (little endian)
 2436 A:d6c4                                    ;  asl
 2437 A:d6c4                                    ;  asl
 2438 A:d6c4                                    ;  ora $0209
 2439 A:d6c4                                    ;  sta XYLODSAV2+1
 2440 A:d6c4                                    ;  lda $020a
 2441 A:d6c4                                    ;  asl
 2442 A:d6c4                                    ;  asl
 2443 A:d6c4                                    ;  asl
 2444 A:d6c4                                    ;  asl
 2445 A:d6c4                                    ;  ora $020b
 2446 A:d6c4                                    ;  sta XYLODSAV2
 2447 A:d6c4                                    ;
 2448 A:d6c4                                    ;  ldy #0
 2449 A:d6c4                                    ;  jmp rsl
 2450 A:d6c4                                    ;
 2451 A:d6c4                                    ;wop
 2451 A:d6c4                                    
 2452 A:d6c4                                    ;  jsr MONRDKEY  ; read a byte
 2453 A:d6c4                                    ;  bcc wop
 2454 A:d6c4                                    ;  lda ACIA_DATA
 2455 A:d6c4                                    ;  rts
 2456 A:d6c4                                    ;serialheader
 2456 A:d6c4                                    
 2457 A:d6c4                                    ;  jsr wop  ; load addr
 2458 A:d6c4                                    ;  sta XYLODSAV2  ; (where the load to)
 2459 A:d6c4                                    ;  jsr wop
 2460 A:d6c4                                    ;  sta XYLODSAV2+1
 2461 A:d6c4                                    ;  jsr wop  ; start addr
 2462 A:d6c4                                    ;  sta STARTADDR  ; (where to jump to)
 2463 A:d6c4                                    ;  jsr wop
 2464 A:d6c4                                    ;  sta STARTADDR+1
 2465 A:d6c4                                    ;  jsr wop  ; end addr
 2466 A:d6c4                                    ;  sta ENDADDR  ; (when the program ends)
 2467 A:d6c4                                    ;  jsr wop
 2468 A:d6c4                                    ;  sta ENDADDR+1
 2469 A:d6c4                                    ;  stz serialvar  ; a zero here means header mode
 2470 A:d6c4                                    ;  ldy #0
 2471 A:d6c4                                    ;rsl
 2472 A:d6c4                                    ;  jsr MONRDKEY  ; byte received?
 2473 A:d6c4                                    ;  bcc rsl
 2474 A:d6c4                                    ;  ldy #0
 2475 A:d6c4                                    ;  lda ACIA_DATA  ; then load it,
 2476 A:d6c4                                    ;  sta (XYLODSAV2),y ; and store it at the address (indexed because "sta (XYLODSAV2)" is illegal)
 2477 A:d6c4                                    ;  lda #$2e  ; print a period
 2478 A:d6c4                                    ;  jsr MONCOUT  ; to show it is working
 2479 A:d6c4                                    ;  inc XYLODSAV2
 2480 A:d6c4                                    ;  lda XYLODSAV2  ; increment 16-bit address
 2481 A:d6c4                                    ;  bne checkit
 2482 A:d6c4                                    ;  inc XYLODSAV2+1
 2483 A:d6c4                                    ;checkit
 2483 A:d6c4                                    
 2484 A:d6c4                                    ;  lda serialvar  ; header mode?
 2485 A:d6c4                                    ;  bne rsl
 2486 A:d6c4                                    ;   ; if so,
 2487 A:d6c4                                    ;  lda XYLODSAV2  ; check if we are done.
 2488 A:d6c4                                    ;  cmp ENDADDR
 2489 A:d6c4                                    ;  bne rsl
 2490 A:d6c4                                    ;  lda XYLODSAV2+1
 2491 A:d6c4                                    ;  cmp ENDADDR+1
 2492 A:d6c4                                    ;  bne rsl
 2493 A:d6c4                                    ;
 2494 A:d6c4                                    ;  ; done
 2495 A:d6c4                                    ;  jmp (STARTADDR) ; jump to the start address.
 2496 A:d6c4                                    ;
 2497 A:d6c4                                    ;serialdone
 2497 A:d6c4                                    
 2498 A:d6c4                                    ;  ldx #0
 2499 A:d6c4                                    ;sdone
 2500 A:d6c4                                    ;  lda loaddonestring,x
 2501 A:d6c4                                    ;  beq esl2  ; idk
 2502 A:d6c4                                    ;  jsr MONCOUT  ; not used
 2503 A:d6c4                                    ;  inx
 2504 A:d6c4                                    ;  jmp sdone
 2505 A:d6c4                                    ;esl2
 2506 A:d6c4                                    ;  pla
 2507 A:d6c4                                    ;  sta XYLODSAV2+1
 2508 A:d6c4                                    ;  pla
 2509 A:d6c4                                    ;  sta XYLODSAV2
 2510 A:d6c4                                    ;  ply
 2511 A:d6c4                                    ;  plx
 2512 A:d6c4                                    ;  pla
 2513 A:d6c4                                    ;  rts

 2515 A:d6c4                           MONCOUT   
 2516 A:d6c4  48                                 pha 
 2517 A:d6c5                           SerialOutWait 
 2518 A:d6c5  ad 01 80                           lda ACIA_STATUS
 2519 A:d6c8  29 10                              and #$10
 2520 A:d6ca  c9 10                              cmp #$10
 2521 A:d6cc  d0 f7                              bne SerialOutWait
 2522 A:d6ce  68                                 pla 
 2523 A:d6cf  8d 00 80                           sta ACIA_DATA
 2524 A:d6d2  60                                 rts 

 2526 A:d6d3                           MONRDKEY  
 2527 A:d6d3  ad 01 80                           lda ACIA_STATUS
 2528 A:d6d6  29 08                              and #$08
 2529 A:d6d8  c9 08                              cmp #$08
 2530 A:d6da  d0 05                              bne NoDataIn
 2531 A:d6dc  ad 00 80                           lda ACIA_DATA
 2532 A:d6df  38                                 sec 
 2533 A:d6e0  60                                 rts 
 2534 A:d6e1                           NoDataIn  
 2535 A:d6e1  18                                 clc 
 2536 A:d6e2  60                                 rts 

 2538 A:d6e3                           MONISCNTC 
 2539 A:d6e3  20 d3 d6                           jsr MONRDKEY
 2540 A:d6e6  90 06                              bcc NotCTRLC                ; If no key pressed then exit
 2541 A:d6e8  c9 03                              cmp #3
 2542 A:d6ea  d0 02                              bne NotCTRLC                ; if CTRL-C not pressed then exit
 2543 A:d6ec  38                                 sec                    ; Carry set if control C pressed
 2544 A:d6ed  60                                 rts 
 2545 A:d6ee                           NotCTRLC  
 2546 A:d6ee  18                                 clc                    ; Carry clear if control C not pressed
 2547 A:d6ef  60                                 rts 

 2549 A:d6f0                           via_init  
 2549 A:d6f0                                    
 2550 A:d6f0  a9 ff                              lda #%11111111             ; Set all pins on port B to output
 2551 A:d6f2  8d 02 b0                           sta VIA_DDRB
 2552 A:d6f5  a9 1c                              lda #PORTA_OUTPUTPINS               ; Set various pins on port A to output
 2553 A:d6f7  8d 03 b0                           sta VIA_DDRA
 2554 A:d6fa  60                                 rts 

 2556 A:d6fb                                    ; sd

libsd.a65

    1 A:d6fb                                    ; SD card interface module
    2 A:d6fb                                    ;
    3 A:d6fb                                    ; Requires zero-page variable storage
    3 A:d6fb                                    
    4 A:d6fb                                    ;   zp_sd_address - 2 bytes
    5 A:d6fb                                    ;   zp_sd_currentsector - 4 bytes

    7 A:d6fb                           cmsg      
    8 A:d6fb  43 6f 6d 6d 61 6e 64 ...           .byt "Command: ",$00

   10 A:d705                           sd_init   
   11 A:d705                                    ; Let the SD card boot up, by pumping the clock with SD CS disabled

   13 A:d705                                    ; We need to apply around 80 clock pulses with CS and MOSI high.
   14 A:d705                                    ; Normally MOSI doesn't matter when CS is high, but the card is
   15 A:d705                                    ; not yet is SPI mode, and in this non-SPI state it does care.

   17 A:d705  a9 14                              lda #SD_CS|SD_MOSI
   18 A:d707  a2 a0                              ldx #160             ; toggle the clock 160 times, so 80 low-high transitions
   19 A:d709                           preinitloop 
   20 A:d709  49 08                              eor #SD_SCK
   21 A:d70b  8d 01 b0                           sta VIA_PORTA
   22 A:d70e  ca                                 dex 
   23 A:d70f  d0 f8                              bne preinitloop

   26 A:d711                           cmd0                       ; GO_IDLE_STATE - resets card to idle state, and SPI mode
   27 A:d711  a9 6a                              lda #<sd_cmd0_bytes
   28 A:d713  85 48                              sta zp_sd_address
   29 A:d715  a9 d7                              lda #>sd_cmd0_bytes
   30 A:d717  85 49                              sta zp_sd_address+1

   32 A:d719  20 bc d7                           jsr sd_sendcommand

   34 A:d71c                                    ; Expect status response $01 (not initialized)
   35 A:d71c                                    ; cmp #$01
   36 A:d71c                                    ; bne initfailed

   38 A:d71c                           cmd8                       ; SEND_IF_COND - tell the card how we want it to operate (3.3V, etc)
   39 A:d71c  a9 70                              lda #<sd_cmd8_bytes
   40 A:d71e  85 48                              sta zp_sd_address
   41 A:d720  a9 d7                              lda #>sd_cmd8_bytes
   42 A:d722  85 49                              sta zp_sd_address+1

   44 A:d724  20 bc d7                           jsr sd_sendcommand

   46 A:d727                                    ; Expect status response $01 (not initialized)
   47 A:d727  c9 01                              cmp #$01
   48 A:d729  d0 3d                              bne initfailed

   50 A:d72b                                    ; Read 32-bit return value, but ignore it
   51 A:d72b  20 82 d7                           jsr sd_readbyte
   52 A:d72e  20 82 d7                           jsr sd_readbyte
   53 A:d731  20 82 d7                           jsr sd_readbyte
   54 A:d734  20 82 d7                           jsr sd_readbyte

   56 A:d737                           cmd55                      ; APP_CMD - required prefix for ACMD commands
   57 A:d737  a9 76                              lda #<sd_cmd55_bytes
   58 A:d739  85 48                              sta zp_sd_address
   59 A:d73b  a9 d7                              lda #>sd_cmd55_bytes
   60 A:d73d  85 49                              sta zp_sd_address+1

   62 A:d73f  20 bc d7                           jsr sd_sendcommand

   64 A:d742                                    ; Expect status response $01 (not initialized)
   65 A:d742  c9 01                              cmp #$01
   66 A:d744  d0 22                              bne initfailed

   68 A:d746                           cmd41                      ; APP_SEND_OP_COND - send operating conditions, initialize card
   69 A:d746  a9 7c                              lda #<sd_cmd41_bytes
   70 A:d748  85 48                              sta zp_sd_address
   71 A:d74a  a9 d7                              lda #>sd_cmd41_bytes
   72 A:d74c  85 49                              sta zp_sd_address+1

   74 A:d74e  20 bc d7                           jsr sd_sendcommand

   76 A:d751                                    ; Status response $00 means initialised
   77 A:d751  c9 00                              cmp #$00
   78 A:d753  f0 11                              beq initialized

   80 A:d755                                    ; Otherwise expect status response $01 (not initialized)
   81 A:d755  c9 01                              cmp #$01
   82 A:d757  d0 0f                              bne initfailed

   84 A:d759                                    ; Not initialized yet, so wait a while then try again.
   85 A:d759                                    ; This retry is important, to give the card time to initialize.

   87 A:d759  a2 00                              ldx #0
   88 A:d75b  a0 00                              ldy #0
   89 A:d75d                           delayloop 
   90 A:d75d  88                                 dey 
   91 A:d75e  d0 fd                              bne delayloop
   92 A:d760  ca                                 dex 
   93 A:d761  d0 fa                              bne delayloop

   95 A:d763  4c 37 d7                           jmp cmd55

   98 A:d766                           initialized 
   99 A:d766                                    ;  ldy #>initmsg
  100 A:d766                                    ;  ldx #<initmsg
  101 A:d766                                    ;  jsr w_acia_full
  102 A:d766  18                                 clc 
  103 A:d767  60                                 rts 

  105 A:d768                           initfailed 
  106 A:d768                                    ;ldy #>initfailedmsg
  107 A:d768                                    ;ldx #<initfailedmsg
  108 A:d768                                    ;jsr w_acia_full
  109 A:d768  38                                 sec 
  110 A:d769  60                                 rts 

  112 A:d76a                           sd_cmd0_bytes 
  113 A:d76a  40 00 00 00 00 95                  .byt $40,$00,$00,$00,$00,$95
  114 A:d770                           sd_cmd8_bytes 
  115 A:d770  48 00 00 01 aa 87                  .byt $48,$00,$00,$01,$aa,$87
  116 A:d776                           sd_cmd55_bytes 
  117 A:d776  77 00 00 00 00 01                  .byt $77,$00,$00,$00,$00,$01
  118 A:d77c                           sd_cmd41_bytes 
  119 A:d77c  69 40 00 00 00 01                  .byt $69,$40,$00,$00,$00,$01

  123 A:d782                           sd_readbyte 
  124 A:d782                                    ; Enable the card and tick the clock 8 times with MOSI high, 
  125 A:d782                                    ; capturing bits from MISO and returning them

  127 A:d782  a2 fe                              ldx #$fe             ; Preloaded with seven ones and a zero, so we stop after eight bits

  129 A:d784                           looop     

  131 A:d784  a9 04                              lda #SD_MOSI               ; enable card (CS low), set MOSI (resting state), SCK low
  132 A:d786  8d 01 b0                           sta VIA_PORTA

  134 A:d789  a9 0c                              lda #SD_MOSI|SD_SCK           ; toggle the clock high
  135 A:d78b  8d 01 b0                           sta VIA_PORTA

  137 A:d78e  ad 01 b0                           lda VIA_PORTA                ; read next bit
  138 A:d791  29 02                              and #SD_MISO

  140 A:d793  18                                 clc                    ; default to clearing the bottom bit
  141 A:d794  f0 01                              beq bitnotset                ; unless MISO was set
  142 A:d796  38                                 sec                    ; in which case get ready to set the bottom bit
  143 A:d797                           bitnotset 

  145 A:d797  8a                                 txa                    ; transfer partial result from X
  146 A:d798  2a                                 rol                    ; rotate carry bit into read result, and loop bit into carry
  147 A:d799  aa                                 tax                    ; save partial result back to X

  149 A:d79a  b0 e8                              bcs looop                ; loop if we need to read more bits

  151 A:d79c  60                                 rts 

  154 A:d79d                           sd_writebyte 
  155 A:d79d                                    ; Tick the clock 8 times with descending bits on MOSI
  156 A:d79d                                    ; SD communication is mostly half-duplex so we ignore anything it sends back here

  158 A:d79d  a2 08                              ldx #8             ; send 8 bits

  160 A:d79f                           loopp     
  161 A:d79f  0a                                 asl                    ; shift next bit into carry
  162 A:d7a0  a8                                 tay                    ; save remaining bits for later

  164 A:d7a1  a9 00                              lda #0
  165 A:d7a3  90 02                              bcc sendbit                ; if carry clear, don't set MOSI for this bit
  166 A:d7a5  09 04                              ora #SD_MOSI

  168 A:d7a7                           sendbit   
  169 A:d7a7  8d 01 b0                           sta VIA_PORTA                ; set MOSI (or not) first with SCK low
  170 A:d7aa  49 08                              eor #SD_SCK
  171 A:d7ac  8d 01 b0                           sta VIA_PORTA                ; raise SCK keeping MOSI the same, to send the bit

  173 A:d7af  98                                 tya                    ; restore remaining bits to send

  175 A:d7b0  ca                                 dex 
  176 A:d7b1  d0 ec                              bne loopp                ; loop if there are more bits to send

  178 A:d7b3  60                                 rts 

  181 A:d7b4                           sd_waitresult 
  182 A:d7b4                                    ; Wait for the SD card to return something other than $ff
  183 A:d7b4  20 82 d7                           jsr sd_readbyte
  184 A:d7b7  c9 ff                              cmp #$ff
  185 A:d7b9  f0 f9                              beq sd_waitresult
  186 A:d7bb  60                                 rts 

  188 A:d7bc                           sd_sendcommand 

  190 A:d7bc  a9 04                              lda #SD_MOSI               ; pull CS low to begin command
  191 A:d7be  8d 01 b0                           sta VIA_PORTA

  193 A:d7c1  a0 00                              ldy #0
  194 A:d7c3  b1 48                              lda (zp_sd_address),y            ; command byte
  195 A:d7c5  20 9d d7                           jsr sd_writebyte
  196 A:d7c8  a0 01                              ldy #1
  197 A:d7ca  b1 48                              lda (zp_sd_address),y            ; data 1
  198 A:d7cc  20 9d d7                           jsr sd_writebyte
  199 A:d7cf  a0 02                              ldy #2
  200 A:d7d1  b1 48                              lda (zp_sd_address),y            ; data 2
  201 A:d7d3  20 9d d7                           jsr sd_writebyte
  202 A:d7d6  a0 03                              ldy #3
  203 A:d7d8  b1 48                              lda (zp_sd_address),y            ; data 3
  204 A:d7da  20 9d d7                           jsr sd_writebyte
  205 A:d7dd  a0 04                              ldy #4
  206 A:d7df  b1 48                              lda (zp_sd_address),y            ; data 4
  207 A:d7e1  20 9d d7                           jsr sd_writebyte
  208 A:d7e4  a0 05                              ldy #5
  209 A:d7e6  b1 48                              lda (zp_sd_address),y            ; crc
  210 A:d7e8  20 9d d7                           jsr sd_writebyte

  212 A:d7eb  20 b4 d7                           jsr sd_waitresult
  213 A:d7ee  48                                 pha 

  215 A:d7ef                                    ; End command
  216 A:d7ef  a9 14                              lda #SD_CS|SD_MOSI           ; set CS high again
  217 A:d7f1  8d 01 b0                           sta VIA_PORTA

  219 A:d7f4  68                                 pla                    ; restore result code
  220 A:d7f5  60                                 rts 

  223 A:d7f6                           sd_readsector 
  224 A:d7f6                                    ; Read a sector from the SD card.  A sector is 512 bytes.
  225 A:d7f6                                    ;
  226 A:d7f6                                    ; Parameters
  226 A:d7f6                                    
  227 A:d7f6                                    ;    zp_sd_currentsector   32-bit sector number
  228 A:d7f6                                    ;    zp_sd_address     address of buffer to receive data

  230 A:d7f6  a9 04                              lda #SD_MOSI
  231 A:d7f8  8d 01 b0                           sta VIA_PORTA

  233 A:d7fb                                    ; Command 17, arg is sector number, crc not checked
  234 A:d7fb  a9 51                              lda #$51             ; CMD17 - READ_SINGLE_BLOCK
  235 A:d7fd  20 9d d7                           jsr sd_writebyte
  236 A:d800  a5 4d                              lda zp_sd_currentsector+3
  237 A:d802  20 9d d7                           jsr sd_writebyte
  238 A:d805  a5 4c                              lda zp_sd_currentsector+2
  239 A:d807  20 9d d7                           jsr sd_writebyte
  240 A:d80a  a5 4b                              lda zp_sd_currentsector+1
  241 A:d80c  20 9d d7                           jsr sd_writebyte
  242 A:d80f  a5 4a                              lda zp_sd_currentsector
  243 A:d811  20 9d d7                           jsr sd_writebyte
  244 A:d814  a9 01                              lda #$01             ; crc (not checked)
  245 A:d816  20 9d d7                           jsr sd_writebyte

  247 A:d819  20 b4 d7                           jsr sd_waitresult
  248 A:d81c  c9 00                              cmp #$00
  249 A:d81e  d0 17                              bne sd_fail

  251 A:d820                                    ; wait for data
  252 A:d820  20 b4 d7                           jsr sd_waitresult
  253 A:d823  c9 fe                              cmp #$fe
  254 A:d825  d0 10                              bne sd_fail

  256 A:d827                                    ; Need to read 512 bytes - two pages of 256 bytes each
  257 A:d827  20 41 d8                           jsr readpage
  258 A:d82a  e6 49                              inc zp_sd_address+1
  259 A:d82c  20 41 d8                           jsr readpage
  260 A:d82f  c6 49                              dec zp_sd_address+1

  262 A:d831                                    ; End command
  263 A:d831  a9 14                              lda #SD_CS|SD_MOSI
  264 A:d833  8d 01 b0                           sta VIA_PORTA

  266 A:d836  60                                 rts 

  269 A:d837                           sd_fail   
  269 A:d837                                    
  270 A:d837                                    ;  ldx #<statusmsg
  271 A:d837                                    ;  ldy #>statusmsg  ; Status
  271 A:d837                                    
  272 A:d837                                    ;  jsr w_acia_full

  274 A:d837  a2 b6                              ldx #<failedmsg
  275 A:d839  a0 d8                              ldy #>failedmsg              ; Failed!
  276 A:d83b  20 f0 df                           jsr w_acia_full
  277 A:d83e                           failloop  
  278 A:d83e  6c fc ff                           jmp ($fffc)

  280 A:d841                           readpage  
  281 A:d841                                    ; Read 256 bytes to the address at zp_sd_address
  282 A:d841  a0 00                              ldy #0
  283 A:d843                           readloop  
  284 A:d843  20 82 d7                           jsr sd_readbyte
  285 A:d846  91 48                              sta (zp_sd_address),y
  286 A:d848  c8                                 iny 
  287 A:d849  d0 f8                              bne readloop
  288 A:d84b  60                                 rts 

  290 A:d84c                           sd_writesector 
  290 A:d84c                                    
  291 A:d84c                                     .( 
  292 A:d84c                                    ; Write a sector to the SD card.  A sector is 512 bytes.
  293 A:d84c                                    ;
  294 A:d84c                                    ; Parameters
  294 A:d84c                                    
  295 A:d84c                                    ;    zp_sd_currentsector   32-bit sector number
  296 A:d84c                                    ;    zp_sd_address     address of buffer to take data from

  298 A:d84c  a9 04                              lda #SD_MOSI
  299 A:d84e  8d 01 b0                           sta PORTA

  301 A:d851                                    ; Command 24, arg is sector number, crc not checked
  302 A:d851  a9 58                              lda #$58             ; CMD24 - WRITE_BLOCK
  303 A:d853  20 9d d7                           jsr sd_writebyte
  304 A:d856  a5 4d                              lda zp_sd_currentsector+3          ; sector 24 to 31
  305 A:d858  20 9d d7                           jsr sd_writebyte
  306 A:d85b  a5 4c                              lda zp_sd_currentsector+2          ; sector 16 to 23
  307 A:d85d  20 9d d7                           jsr sd_writebyte
  308 A:d860  a5 4b                              lda zp_sd_currentsector+1          ; sector 8 to15
  309 A:d862  20 9d d7                           jsr sd_writebyte
  310 A:d865  a5 4a                              lda zp_sd_currentsector                ; sector 0 to 7
  311 A:d867  20 9d d7                           jsr sd_writebyte
  312 A:d86a  a9 01                              lda #$01             ; crc (not checked)
  313 A:d86c  20 9d d7                           jsr sd_writebyte

  315 A:d86f  20 b4 d7                           jsr sd_waitresult
  316 A:d872  c9 00                              cmp #$00
  317 A:d874  d0 c1                              bne sd_fail

  319 A:d876                                    ; Send start token
  320 A:d876  a9 fe                              lda #$fe
  321 A:d878  20 9d d7                           jsr sd_writebyte

  323 A:d87b                                    ; Need to write 512 bytes - two pages of 256 bytes each
  324 A:d87b  20 9b d8                           jsr writepage
  325 A:d87e  e6 49                              inc zp_sd_address+1
  326 A:d880  20 9b d8                           jsr writepage
  327 A:d883  c6 49                              dec zp_sd_address+1

  329 A:d885                                    ; wait for data response
  330 A:d885  20 b4 d7                           jsr sd_waitresult
  331 A:d888  29 1f                              and #$1f
  332 A:d88a  c9 05                              cmp #$05
  333 A:d88c  d0 a9                              bne sd_fail

  335 A:d88e                           waitidle  
  336 A:d88e  20 82 d7                           jsr sd_readbyte
  337 A:d891  c9 ff                              cmp #$ff
  338 A:d893  d0 f9                              bne waitidle

  340 A:d895                                    ; End command
  341 A:d895  a9 14                              lda #SD_CS|SD_MOSI           ; set cs and mosi high (disconnected)
  342 A:d897  8d 01 b0                           sta PORTA

  344 A:d89a  60                                 rts 

  346 A:d89b                           writepage 
  346 A:d89b                                    
  347 A:d89b                                    ; Write 256 bytes fom zp_sd_address
  348 A:d89b  a0 00                              ldy #0
  349 A:d89d                           writeloop 
  349 A:d89d                                    
  350 A:d89d  b1 48                              lda (zp_sd_address),y
  351 A:d89f  5a                                 phy 
  352 A:d8a0  20 9d d7                           jsr sd_writebyte
  353 A:d8a3  7a                                 ply 
  354 A:d8a4  c8                                 iny 
  355 A:d8a5  d0 f6                              bne writeloop
  356 A:d8a7  60                                 rts 
  357 A:d8a8                                     .) 

  359 A:d8a8                           statusmsg 
  360 A:d8a8  53 74 61 74 75 73 3a ...           .byt "Status: ",$00
  361 A:d8b1                           initfailedmsg 
  362 A:d8b1  49 6e 69 74 20                     .byt "Init "
  363 A:d8b6                           failedmsg 
  364 A:d8b6  46 61 69 6c 65 64 21 ...           .byt "Failed!",$0d,$0a,$00
  365 A:d8c0                           respmsg   
  366 A:d8c0  52 65 73 70 6f 6e 73 ...           .byt "Response: ",$00
  367 A:d8cb                           initmsg   
  368 A:d8cb  49 6e 69 74 69 61 6c ...           .byt "Initialized!",$0d,$0a,$00

main.a65


 2559 A:d8da                                    ; fat32

libfat32.a65

    1 A:d8da                                    ; FAT32/SD interface library
    2 A:d8da                                    ;
    3 A:d8da                                    ; This module requires some RAM workspace to be defined elsewhere
    3 A:d8da                                    
    4 A:d8da                                    ; 
    5 A:d8da                                    ; fat32_workspace    - a large page-aligned 512-byte workspace
    6 A:d8da                                    ; zp_fat32_variables - 49 bytes of zero-page storage for variables etc

    8 A:d8da                                    fat32_readbuffer=fat32_workspace

   10 A:d8da                                    fat32_fatstart=zp_fat32_variables+$00       ; 4 bytes
   11 A:d8da                                    fat32_datastart=zp_fat32_variables+$04       ; 4 bytes
   12 A:d8da                                    fat32_rootcluster=zp_fat32_variables+$08       ; 4 bytes
   13 A:d8da                                    fat32_sectorspercluster=zp_fat32_variables+$0c       ; 1 byte
   14 A:d8da                                    fat32_pendingsectors=zp_fat32_variables+$0d       ; 1 byte
   15 A:d8da                                    fat32_address=zp_fat32_variables+$0e       ; 2 bytes
   16 A:d8da                                    fat32_nextcluster=zp_fat32_variables+$10       ; 4 bytes
   17 A:d8da                                    fat32_bytesremaining=zp_fat32_variables+$14       ; 4 bytes    
   18 A:d8da                                    fat32_lastfoundfreecluster=zp_fat32_variables+$18       ; 4 bytes
   19 A:d8da                                    fat32_lastcluster=zp_fat32_variables+$1c       ; 4 bytes
   20 A:d8da                                    fat32_lastsector=zp_fat32_variables+$21       ; 4 bytes
   21 A:d8da                                    fat32_filenamepointer=zp_fat32_variables+$26       ; 2 bytes
   22 A:d8da                                    fat32_numfats=zp_fat32_variables+$28       ; 1 byte
   23 A:d8da                                    fat32_filecluster=zp_fat32_variables+$29       ; 4 bytes
   24 A:d8da                                    fat32_sectorsperfat=zp_fat32_variables+$2d       ; 4 bytes
   25 A:d8da                                    fat32_cdcluster=zp_fat32_variables+$31       ; 4 bytes

   27 A:d8da                                    fat32_errorstage=fat32_bytesremaining             ; only used during initialization

   29 A:d8da                           fat32_init 
   29 A:d8da                                    
   30 A:d8da                                     .( 
   31 A:d8da                                    ; Initialize the module - read the MBR etc, find the partition,
   32 A:d8da                                    ; and set up the variables ready for navigating the filesystem

   34 A:d8da                                    ; Read the MBR and extract pertinent information

   36 A:d8da  a9 00                              lda #0
   37 A:d8dc  85 62                              sta fat32_errorstage

   39 A:d8de                                    ; Sector 0
   40 A:d8de  a9 00                              lda #0
   41 A:d8e0  85 4a                              sta zp_sd_currentsector
   42 A:d8e2  85 4b                              sta zp_sd_currentsector+1
   43 A:d8e4  85 4c                              sta zp_sd_currentsector+2
   44 A:d8e6  85 4d                              sta zp_sd_currentsector+3

   46 A:d8e8                                    ; Target buffer
   47 A:d8e8  a9 00                              lda #<fat32_readbuffer
   48 A:d8ea  85 5c                              sta fat32_address
   49 A:d8ec  85 48                              sta zp_sd_address
   50 A:d8ee  a9 05                              lda #>fat32_readbuffer
   51 A:d8f0  85 5d                              sta fat32_address+1
   52 A:d8f2  85 49                              sta zp_sd_address+1

   54 A:d8f4                                    ; Do the read
   55 A:d8f4  20 f6 d7                           jsr sd_readsector

   58 A:d8f7  e6 62                              inc fat32_errorstage                ; stage 1 = boot sector signature check

   60 A:d8f9                                    ; Check some things
   61 A:d8f9  ad fe 06                           lda fat32_readbuffer+510          ; Boot sector signature 55
   62 A:d8fc  c9 55                              cmp #$55
   63 A:d8fe  d0 2d                              bne fail
   64 A:d900  ad ff 06                           lda fat32_readbuffer+511          ; Boot sector signature aa
   65 A:d903  c9 aa                              cmp #$aa
   66 A:d905  d0 26                              bne fail

   69 A:d907  e6 62                              inc fat32_errorstage                ; stage 2 = finding partition

   71 A:d909                                    ; Find a FAT32 partition
   72 A:d909                                    FSTYPE_FAT32=12
   73 A:d909  a2 00                              ldx #0
   74 A:d90b  bd c2 06                           lda fat32_readbuffer+$01c2,x
   75 A:d90e  c9 0c                              cmp #FSTYPE_FAT32
   76 A:d910  f0 1e                              beq foundpart
   77 A:d912  a2 10                              ldx #16
   78 A:d914  bd c2 06                           lda fat32_readbuffer+$01c2,x
   79 A:d917  c9 0c                              cmp #FSTYPE_FAT32
   80 A:d919  f0 15                              beq foundpart
   81 A:d91b  a2 20                              ldx #32
   82 A:d91d  bd c2 06                           lda fat32_readbuffer+$01c2,x
   83 A:d920  c9 0c                              cmp #FSTYPE_FAT32
   84 A:d922  f0 0c                              beq foundpart
   85 A:d924  a2 30                              ldx #48
   86 A:d926  bd c2 06                           lda fat32_readbuffer+$01c2,x
   87 A:d929  c9 0c                              cmp #FSTYPE_FAT32
   88 A:d92b  f0 03                              beq foundpart

   90 A:d92d                           fail      
   90 A:d92d                                    
   91 A:d92d  4c 0a da                           jmp error

   93 A:d930                           foundpart 
   93 A:d930                                    

   95 A:d930                                    ; Read the FAT32 BPB
   96 A:d930  bd c6 06                           lda fat32_readbuffer+$01c6,x
   97 A:d933  85 4a                              sta zp_sd_currentsector
   98 A:d935  bd c7 06                           lda fat32_readbuffer+$01c7,x
   99 A:d938  85 4b                              sta zp_sd_currentsector+1
  100 A:d93a  bd c8 06                           lda fat32_readbuffer+$01c8,x
  101 A:d93d  85 4c                              sta zp_sd_currentsector+2
  102 A:d93f  bd c9 06                           lda fat32_readbuffer+$01c9,x
  103 A:d942  85 4d                              sta zp_sd_currentsector+3

  105 A:d944  20 f6 d7                           jsr sd_readsector

  108 A:d947  e6 62                              inc fat32_errorstage                ; stage 3 = BPB signature check

  110 A:d949                                    ; Check some things
  111 A:d949  ad fe 06                           lda fat32_readbuffer+510          ; BPB sector signature 55
  112 A:d94c  c9 55                              cmp #$55
  113 A:d94e  d0 dd                              bne fail
  114 A:d950  ad ff 06                           lda fat32_readbuffer+511          ; BPB sector signature aa
  115 A:d953  c9 aa                              cmp #$aa
  116 A:d955  d0 d6                              bne fail

  118 A:d957  e6 62                              inc fat32_errorstage                ; stage 4 = RootEntCnt check

  120 A:d959  ad 11 05                           lda fat32_readbuffer+17          ; RootEntCnt should be 0 for FAT32
  121 A:d95c  0d 12 05                           ora fat32_readbuffer+18
  122 A:d95f  d0 cc                              bne fail

  124 A:d961  e6 62                              inc fat32_errorstage                ; stage 5 = TotSec16 check

  126 A:d963  ad 13 05                           lda fat32_readbuffer+19          ; TotSec16 should be 0 for FAT32
  127 A:d966  0d 14 05                           ora fat32_readbuffer+20
  128 A:d969  d0 c2                              bne fail

  130 A:d96b  e6 62                              inc fat32_errorstage                ; stage 6 = SectorsPerCluster check

  132 A:d96d                                    ; Check bytes per filesystem sector, it should be 512 for any SD card that supports FAT32
  133 A:d96d  ad 0b 05                           lda fat32_readbuffer+11          ; low byte should be zero
  134 A:d970  d0 bb                              bne fail
  135 A:d972  ad 0c 05                           lda fat32_readbuffer+12          ; high byte is 2 (512), 4, 8, or 16
  136 A:d975  c9 02                              cmp #2
  137 A:d977  d0 b4                              bne fail

  139 A:d979                                    ; Calculate the starting sector of the FAT
  140 A:d979  18                                 clc 
  141 A:d97a  a5 4a                              lda zp_sd_currentsector
  142 A:d97c  6d 0e 05                           adc fat32_readbuffer+14          ; reserved sectors lo
  143 A:d97f  85 4e                              sta fat32_fatstart
  144 A:d981  85 52                              sta fat32_datastart
  145 A:d983  a5 4b                              lda zp_sd_currentsector+1
  146 A:d985  6d 0f 05                           adc fat32_readbuffer+15          ; reserved sectors hi
  147 A:d988  85 4f                              sta fat32_fatstart+1
  148 A:d98a  85 53                              sta fat32_datastart+1
  149 A:d98c  a5 4c                              lda zp_sd_currentsector+2
  150 A:d98e  69 00                              adc #0
  151 A:d990  85 50                              sta fat32_fatstart+2
  152 A:d992  85 54                              sta fat32_datastart+2
  153 A:d994  a5 4d                              lda zp_sd_currentsector+3
  154 A:d996  69 00                              adc #0
  155 A:d998  85 51                              sta fat32_fatstart+3
  156 A:d99a  85 55                              sta fat32_datastart+3

  158 A:d99c                                    ; Calculate the starting sector of the data area
  159 A:d99c  ae 10 05                           ldx fat32_readbuffer+16          ; number of FATs
  160 A:d99f  86 76                              stx fat32_numfats                ; (stash for later as well)
  161 A:d9a1                           skipfatsloop 
  161 A:d9a1                                    
  162 A:d9a1  18                                 clc 
  163 A:d9a2  a5 52                              lda fat32_datastart
  164 A:d9a4  6d 24 05                           adc fat32_readbuffer+36          ; fatsize 0
  165 A:d9a7  85 52                              sta fat32_datastart
  166 A:d9a9  a5 53                              lda fat32_datastart+1
  167 A:d9ab  6d 25 05                           adc fat32_readbuffer+37          ; fatsize 1
  168 A:d9ae  85 53                              sta fat32_datastart+1
  169 A:d9b0  a5 54                              lda fat32_datastart+2
  170 A:d9b2  6d 26 05                           adc fat32_readbuffer+38          ; fatsize 2
  171 A:d9b5  85 54                              sta fat32_datastart+2
  172 A:d9b7  a5 55                              lda fat32_datastart+3
  173 A:d9b9  6d 27 05                           adc fat32_readbuffer+39          ; fatsize 3
  174 A:d9bc  85 55                              sta fat32_datastart+3
  175 A:d9be  ca                                 dex 
  176 A:d9bf  d0 e0                              bne skipfatsloop

  178 A:d9c1                                    ; Sectors-per-cluster is a power of two from 1 to 128
  179 A:d9c1  ad 0d 05                           lda fat32_readbuffer+13
  180 A:d9c4  85 5a                              sta fat32_sectorspercluster

  182 A:d9c6                                    ; Remember the root cluster
  183 A:d9c6  ad 2c 05                           lda fat32_readbuffer+44
  184 A:d9c9  85 56                              sta fat32_rootcluster
  185 A:d9cb  ad 2d 05                           lda fat32_readbuffer+45
  186 A:d9ce  85 57                              sta fat32_rootcluster+1
  187 A:d9d0  ad 2e 05                           lda fat32_readbuffer+46
  188 A:d9d3  85 58                              sta fat32_rootcluster+2
  189 A:d9d5  ad 2f 05                           lda fat32_readbuffer+47
  190 A:d9d8  85 59                              sta fat32_rootcluster+3

  192 A:d9da                                    ; Save Sectors Per FAT
  193 A:d9da  ad 24 05                           lda fat32_readbuffer+36
  194 A:d9dd  85 7b                              sta fat32_sectorsperfat
  195 A:d9df  ad 25 05                           lda fat32_readbuffer+37
  196 A:d9e2  85 7c                              sta fat32_sectorsperfat+1
  197 A:d9e4  ad 26 05                           lda fat32_readbuffer+38
  198 A:d9e7  85 7d                              sta fat32_sectorsperfat+2
  199 A:d9e9  ad 27 05                           lda fat32_readbuffer+39
  200 A:d9ec  85 7e                              sta fat32_sectorsperfat+3

  202 A:d9ee                                    ; Set the last found free cluster to 0.
  203 A:d9ee  a9 00                              lda #0
  204 A:d9f0  85 66                              sta fat32_lastfoundfreecluster
  205 A:d9f2  85 67                              sta fat32_lastfoundfreecluster+1
  206 A:d9f4  85 68                              sta fat32_lastfoundfreecluster+2
  207 A:d9f6  85 69                              sta fat32_lastfoundfreecluster+3

  209 A:d9f8                                    ; As well as the last read clusters and sectors
  210 A:d9f8  85 6a                              sta fat32_lastcluster
  211 A:d9fa  85 6b                              sta fat32_lastcluster+1
  212 A:d9fc  85 6c                              sta fat32_lastcluster+2
  213 A:d9fe  85 6d                              sta fat32_lastcluster+3
  214 A:da00  85 6f                              sta fat32_lastsector
  215 A:da02  85 70                              sta fat32_lastsector+1
  216 A:da04  85 71                              sta fat32_lastsector+2
  217 A:da06  85 72                              sta fat32_lastsector+3

  219 A:da08  18                                 clc 
  220 A:da09  60                                 rts 

  222 A:da0a                           error     
  222 A:da0a                                    
  223 A:da0a  38                                 sec 
  224 A:da0b  60                                 rts 
  225 A:da0c                                     .) 

  227 A:da0c                           fat32_seekcluster 
  227 A:da0c                                    
  228 A:da0c                                     .( 
  229 A:da0c                                    ; Calculates the FAT sector given fat32_nextcluster and stores in zp_sd_currentsector
  230 A:da0c                                    ; Optionally will load the 512 byte FAT sector into memory at fat32_readbuffer
  231 A:da0c                                    ; If carry is set, subroutine is optimized to skip the loading if the expected
  232 A:da0c                                    ; sector is already loaded. Clearing carry before calling will skip optimization
  233 A:da0c                                    ; and force reload of the FAT sector. Once the FAT sector is loaded,
  234 A:da0c                                    ; the next cluster in the chain is loaded into fat32_nextcluster and
  235 A:da0c                                    ; zp_sd_currentsector is updated to point to the referenced data sector

  237 A:da0c                                    ; This routine also leaves Y pointing to the LSB for the 32 bit next cluster.

  239 A:da0c                                    ; Gets ready to read fat32_nextcluster, and advances it according to the FAT                            
  240 A:da0c                                    ; Before calling, set carry to compare the current FAT sector with lastsector.
  241 A:da0c                                    ; Otherwize, clear carry to force reading the FAT.            

  243 A:da0c  08                                 php 

  245 A:da0d                                    ; Target buffer
  246 A:da0d  a9 00                              lda #<fat32_readbuffer
  247 A:da0f  85 48                              sta zp_sd_address
  248 A:da11  a9 05                              lda #>fat32_readbuffer
  249 A:da13  85 49                              sta zp_sd_address+1

  251 A:da15                                    ; FAT sector = (cluster*4) / 512 = (cluster*2) / 256
  252 A:da15  a5 5e                              lda fat32_nextcluster
  253 A:da17  0a                                 asl 
  254 A:da18  a5 5f                              lda fat32_nextcluster+1
  255 A:da1a  2a                                 rol 
  256 A:da1b  85 4a                              sta zp_sd_currentsector
  257 A:da1d  a5 60                              lda fat32_nextcluster+2
  258 A:da1f  2a                                 rol 
  259 A:da20  85 4b                              sta zp_sd_currentsector+1
  260 A:da22  a5 61                              lda fat32_nextcluster+3
  261 A:da24  2a                                 rol 
  262 A:da25  85 4c                              sta zp_sd_currentsector+2
  263 A:da27                                    ; note - cluster numbers never have the top bit set, so no carry can occur

  265 A:da27                                    ; Add FAT starting sector
  266 A:da27  a5 4a                              lda zp_sd_currentsector
  267 A:da29  65 4e                              adc fat32_fatstart
  268 A:da2b  85 4a                              sta zp_sd_currentsector
  269 A:da2d  a5 4b                              lda zp_sd_currentsector+1
  270 A:da2f  65 4f                              adc fat32_fatstart+1
  271 A:da31  85 4b                              sta zp_sd_currentsector+1
  272 A:da33  a5 4c                              lda zp_sd_currentsector+2
  273 A:da35  65 50                              adc fat32_fatstart+2
  274 A:da37  85 4c                              sta zp_sd_currentsector+2
  275 A:da39  a9 00                              lda #0
  276 A:da3b  65 51                              adc fat32_fatstart+3
  277 A:da3d  85 4d                              sta zp_sd_currentsector+3

  279 A:da3f                                    ; Branch if we don't need to check
  280 A:da3f  28                                 plp 
  281 A:da40  90 18                              bcc newsector

  283 A:da42                                    ; Check if this sector is the same as the last one
  284 A:da42  a5 6f                              lda fat32_lastsector
  285 A:da44  c5 4a                              cmp zp_sd_currentsector
  286 A:da46  d0 12                              bne newsector
  287 A:da48  a5 70                              lda fat32_lastsector+1
  288 A:da4a  c5 4b                              cmp zp_sd_currentsector+1
  289 A:da4c  d0 0c                              bne newsector
  290 A:da4e  a5 71                              lda fat32_lastsector+2
  291 A:da50  c5 4c                              cmp zp_sd_currentsector+2
  292 A:da52  d0 06                              bne newsector
  293 A:da54  a5 72                              lda fat32_lastsector+3
  294 A:da56  c5 4d                              cmp zp_sd_currentsector+3
  295 A:da58  f0 13                              beq notnew

  297 A:da5a                           newsector 

  299 A:da5a                                    ; Read the sector from the FAT
  300 A:da5a  20 f6 d7                           jsr sd_readsector

  302 A:da5d                                    ; Update fat32_lastsector

  304 A:da5d  a5 4a                              lda zp_sd_currentsector
  305 A:da5f  85 6f                              sta fat32_lastsector
  306 A:da61  a5 4b                              lda zp_sd_currentsector+1
  307 A:da63  85 70                              sta fat32_lastsector+1
  308 A:da65  a5 4c                              lda zp_sd_currentsector+2
  309 A:da67  85 71                              sta fat32_lastsector+2
  310 A:da69  a5 4d                              lda zp_sd_currentsector+3
  311 A:da6b  85 72                              sta fat32_lastsector+3

  313 A:da6d                           notnew    

  315 A:da6d                                    ; Before using this FAT data, set currentsector ready to read the cluster itself
  316 A:da6d                                    ; We need to multiply the cluster number minus two by the number of sectors per 
  317 A:da6d                                    ; cluster, then add the data region start sector

  319 A:da6d                                    ; Subtract two from cluster number
  320 A:da6d  38                                 sec 
  321 A:da6e  a5 5e                              lda fat32_nextcluster
  322 A:da70  e9 02                              sbc #2
  323 A:da72  85 4a                              sta zp_sd_currentsector
  324 A:da74  a5 5f                              lda fat32_nextcluster+1
  325 A:da76  e9 00                              sbc #0
  326 A:da78  85 4b                              sta zp_sd_currentsector+1
  327 A:da7a  a5 60                              lda fat32_nextcluster+2
  328 A:da7c  e9 00                              sbc #0
  329 A:da7e  85 4c                              sta zp_sd_currentsector+2
  330 A:da80  a5 61                              lda fat32_nextcluster+3
  331 A:da82  e9 00                              sbc #0
  332 A:da84  85 4d                              sta zp_sd_currentsector+3

  334 A:da86                                    ; Multiply by sectors-per-cluster which is a power of two between 1 and 128
  335 A:da86  a5 5a                              lda fat32_sectorspercluster
  336 A:da88                           spcshiftloop 
  336 A:da88                                    
  337 A:da88  4a                                 lsr 
  338 A:da89  b0 0b                              bcs spcshiftloopdone
  339 A:da8b  06 4a                              asl zp_sd_currentsector
  340 A:da8d  26 4b                              rol zp_sd_currentsector+1
  341 A:da8f  26 4c                              rol zp_sd_currentsector+2
  342 A:da91  26 4d                              rol zp_sd_currentsector+3
  343 A:da93  4c 88 da                           jmp spcshiftloop
  344 A:da96                           spcshiftloopdone 
  344 A:da96                                    

  346 A:da96                                    ; Add the data region start sector
  347 A:da96  18                                 clc 
  348 A:da97  a5 4a                              lda zp_sd_currentsector
  349 A:da99  65 52                              adc fat32_datastart
  350 A:da9b  85 4a                              sta zp_sd_currentsector
  351 A:da9d  a5 4b                              lda zp_sd_currentsector+1
  352 A:da9f  65 53                              adc fat32_datastart+1
  353 A:daa1  85 4b                              sta zp_sd_currentsector+1
  354 A:daa3  a5 4c                              lda zp_sd_currentsector+2
  355 A:daa5  65 54                              adc fat32_datastart+2
  356 A:daa7  85 4c                              sta zp_sd_currentsector+2
  357 A:daa9  a5 4d                              lda zp_sd_currentsector+3
  358 A:daab  65 55                              adc fat32_datastart+3
  359 A:daad  85 4d                              sta zp_sd_currentsector+3

  361 A:daaf                                    ; That's now ready for later code to read this sector in - tell it how many consecutive
  362 A:daaf                                    ; sectors it can now read
  363 A:daaf  a5 5a                              lda fat32_sectorspercluster
  364 A:dab1  85 5b                              sta fat32_pendingsectors

  366 A:dab3                                    ; Now go back to looking up the next cluster in the chain
  367 A:dab3                                    ; Find the offset to this cluster's entry in the FAT sector we loaded earlier

  369 A:dab3                                    ; Offset = (cluster*4) & 511 = (cluster & 127) * 4
  370 A:dab3  a5 5e                              lda fat32_nextcluster
  371 A:dab5  29 7f                              and #$7f
  372 A:dab7  0a                                 asl 
  373 A:dab8  0a                                 asl 
  374 A:dab9  a8                                 tay                    ; Y = low byte of offset

  376 A:daba                                    ; Add the potentially carried bit to the high byte of the address
  377 A:daba  a5 49                              lda zp_sd_address+1
  378 A:dabc  69 00                              adc #0
  379 A:dabe  85 49                              sta zp_sd_address+1

  381 A:dac0  5a                                 phy                    ; stash the index to next value for the cluster

  383 A:dac1                                    ; Store the previous cluster
  384 A:dac1                                    ;lda fat32_nextcluster
  385 A:dac1                                    ;sta fat32_prevcluster
  386 A:dac1                                    ;lda fat32_nextcluster+1
  387 A:dac1                                    ;sta fat32_prevcluster+1
  388 A:dac1                                    ;lda fat32_nextcluster+2
  389 A:dac1                                    ;sta fat32_prevcluster+2
  390 A:dac1                                    ;lda fat32_nextcluster+3
  391 A:dac1                                    ;sta fat32_prevcluster+3

  393 A:dac1                                    ; Copy out the next cluster in the chain for later use
  394 A:dac1  b1 48                              lda (zp_sd_address),y
  395 A:dac3  85 5e                              sta fat32_nextcluster
  396 A:dac5  c8                                 iny 
  397 A:dac6  b1 48                              lda (zp_sd_address),y
  398 A:dac8  85 5f                              sta fat32_nextcluster+1
  399 A:daca  c8                                 iny 
  400 A:dacb  b1 48                              lda (zp_sd_address),y
  401 A:dacd  85 60                              sta fat32_nextcluster+2
  402 A:dacf  c8                                 iny 
  403 A:dad0  b1 48                              lda (zp_sd_address),y
  404 A:dad2  29 0f                              and #$0f
  405 A:dad4  85 61                              sta fat32_nextcluster+3

  407 A:dad6  7a                                 ply                    ; restore index to the table entry for the cluster

  409 A:dad7                                    ; See if it's the end of the chain
  410 A:dad7  09 f0                              ora #$f0
  411 A:dad9  25 60                              and fat32_nextcluster+2
  412 A:dadb  25 5f                              and fat32_nextcluster+1
  413 A:dadd  c9 ff                              cmp #$ff
  414 A:dadf  d0 08                              bne notendofchain
  415 A:dae1  a5 5e                              lda fat32_nextcluster
  416 A:dae3  c9 f8                              cmp #$f8
  417 A:dae5  90 02                              bcc notendofchain

  419 A:dae7                                    ; It's the end of the chain, set the top bits so that we can tell this later on
  420 A:dae7  85 61                              sta fat32_nextcluster+3
  421 A:dae9                           notendofchain 
  421 A:dae9                                    
  422 A:dae9  60                                 rts 
  423 A:daea                                     .) 

  425 A:daea                           fat32_readnextsector 
  425 A:daea                                    
  426 A:daea                                     .( 
  427 A:daea                                    ; Reads the next sector from a cluster chain into the buffer at fat32_address.
  428 A:daea                                    ;
  429 A:daea                                    ; Advances the current sector ready for the next read and looks up the next cluster
  430 A:daea                                    ; in the chain when necessary.
  431 A:daea                                    ;
  432 A:daea                                    ; On return, carry is clear if data was read, or set if the cluster chain has ended.

  434 A:daea                                    ; Maybe there are pending sectors in the current cluster
  435 A:daea  a5 5b                              lda fat32_pendingsectors
  436 A:daec  d0 08                              bne readsector

  438 A:daee                                    ; No pending sectors, check for end of cluster chain
  439 A:daee  a5 61                              lda fat32_nextcluster+3
  440 A:daf0  30 21                              bmi endofchain

  442 A:daf2                                    ; Prepare to read the next cluster
  443 A:daf2  38                                 sec 
  444 A:daf3  20 0c da                           jsr fat32_seekcluster

  446 A:daf6                           readsector 
  446 A:daf6                                    
  447 A:daf6  c6 5b                              dec fat32_pendingsectors

  449 A:daf8                                    ; Set up target address  
  450 A:daf8  a5 5c                              lda fat32_address
  451 A:dafa  85 48                              sta zp_sd_address
  452 A:dafc  a5 5d                              lda fat32_address+1
  453 A:dafe  85 49                              sta zp_sd_address+1

  455 A:db00                                    ; Read the sector
  456 A:db00  20 f6 d7                           jsr sd_readsector

  458 A:db03                                    ; Advance to next sector
  459 A:db03  e6 4a                              inc zp_sd_currentsector
  460 A:db05  d0 0a                              bne sectorincrementdone
  461 A:db07  e6 4b                              inc zp_sd_currentsector+1
  462 A:db09  d0 06                              bne sectorincrementdone
  463 A:db0b  e6 4c                              inc zp_sd_currentsector+2
  464 A:db0d  d0 02                              bne sectorincrementdone
  465 A:db0f  e6 4d                              inc zp_sd_currentsector+3
  466 A:db11                           sectorincrementdone 
  466 A:db11                                    

  468 A:db11                                    ; Success - clear carry and return
  469 A:db11  18                                 clc 
  470 A:db12  60                                 rts 

  472 A:db13                           endofchain 
  472 A:db13                                    
  473 A:db13                                    ; End of chain - set carry and return
  474 A:db13  38                                 sec 
  475 A:db14  60                                 rts 
  476 A:db15                                     .) 

  478 A:db15                           fat32_writenextsector 
  478 A:db15                                    
  479 A:db15                                     .( 
  480 A:db15                                    ; Writes the next sector into the buffer at fat32_address.
  481 A:db15                                    ;
  482 A:db15                                    ; On return, carry is set if its the end of the chain. 

  484 A:db15                                    ; Maybe there are pending sectors in the current cluster
  485 A:db15  a5 5b                              lda fat32_pendingsectors
  486 A:db17  d0 08                              bne wr

  488 A:db19                                    ; No pending sectors, check for end of cluster chain
  489 A:db19  a5 61                              lda fat32_nextcluster+3
  490 A:db1b  30 09                              bmi endofchain

  492 A:db1d                                    ; Prepare to read the next cluster
  493 A:db1d  38                                 sec 
  494 A:db1e  20 0c da                           jsr fat32_seekcluster

  496 A:db21                           wr        
  496 A:db21                                    
  497 A:db21  20 2b db                           jsr writesector

  499 A:db24                                    ; Success - clear carry and return
  500 A:db24  18                                 clc 
  501 A:db25  60                                 rts 

  503 A:db26                           endofchain 
  503 A:db26                                    
  504 A:db26                                    ; End of chain - set carry and return
  505 A:db26  20 2b db                           jsr writesector
  506 A:db29  38                                 sec 
  507 A:db2a  60                                 rts 

  509 A:db2b                           writesector 
  509 A:db2b                                    
  510 A:db2b  c6 5b                              dec fat32_pendingsectors

  512 A:db2d                                    ; Set up target address
  513 A:db2d  a5 5c                              lda fat32_address
  514 A:db2f  85 48                              sta zp_sd_address
  515 A:db31  a5 5d                              lda fat32_address+1
  516 A:db33  85 49                              sta zp_sd_address+1

  518 A:db35                                    ; Write the sector
  519 A:db35  20 4c d8                           jsr sd_writesector

  521 A:db38                                    ; Advance to next sector
  522 A:db38  e6 4a                              inc zp_sd_currentsector
  523 A:db3a  d0 0a                              bne nextsectorincrementdone
  524 A:db3c  e6 4b                              inc zp_sd_currentsector+1
  525 A:db3e  d0 06                              bne nextsectorincrementdone
  526 A:db40  e6 4c                              inc zp_sd_currentsector+2
  527 A:db42  d0 02                              bne nextsectorincrementdone
  528 A:db44  e6 4d                              inc zp_sd_currentsector+3
  529 A:db46                           nextsectorincrementdone 
  529 A:db46                                    
  530 A:db46  60                                 rts 

  532 A:db47                                     .) 

  534 A:db47                           fat32_updatefat 
  534 A:db47                                    
  535 A:db47                                     .( 
  536 A:db47                                    ; Preserve the current sector
  537 A:db47  a5 4a                              lda zp_sd_currentsector
  538 A:db49  48                                 pha 
  539 A:db4a  a5 4b                              lda zp_sd_currentsector+1
  540 A:db4c  48                                 pha 
  541 A:db4d  a5 4c                              lda zp_sd_currentsector+2
  542 A:db4f  48                                 pha 
  543 A:db50  a5 4d                              lda zp_sd_currentsector+3
  544 A:db52  48                                 pha 

  546 A:db53                                    ; Write FAT sector
  547 A:db53  a5 6f                              lda fat32_lastsector
  548 A:db55  85 4a                              sta zp_sd_currentsector
  549 A:db57  a5 70                              lda fat32_lastsector+1
  550 A:db59  85 4b                              sta zp_sd_currentsector+1
  551 A:db5b  a5 71                              lda fat32_lastsector+2
  552 A:db5d  85 4c                              sta zp_sd_currentsector+2
  553 A:db5f  a5 72                              lda fat32_lastsector+3
  554 A:db61  85 4d                              sta zp_sd_currentsector+3

  556 A:db63                                    ; Target buffer
  557 A:db63  a9 00                              lda #<fat32_readbuffer
  558 A:db65  85 48                              sta zp_sd_address
  559 A:db67  a9 05                              lda #>fat32_readbuffer
  560 A:db69  85 49                              sta zp_sd_address+1

  562 A:db6b                                    ; Write the FAT sector
  563 A:db6b  20 4c d8                           jsr sd_writesector

  565 A:db6e                                    ; Check if FAT mirroring is enabled
  566 A:db6e  a5 76                              lda fat32_numfats
  567 A:db70  c9 02                              cmp #2
  568 A:db72  d0 1b                              bne onefat

  570 A:db74                                    ; Add the last sector to the amount of sectors per FAT
  571 A:db74                                    ; (to get the second fat location)
  572 A:db74  a5 6f                              lda fat32_lastsector
  573 A:db76  65 7b                              adc fat32_sectorsperfat
  574 A:db78  85 4a                              sta zp_sd_currentsector
  575 A:db7a  a5 70                              lda fat32_lastsector+1
  576 A:db7c  65 7c                              adc fat32_sectorsperfat+1
  577 A:db7e  85 4b                              sta zp_sd_currentsector+1
  578 A:db80  a5 71                              lda fat32_lastsector+2
  579 A:db82  65 7d                              adc fat32_sectorsperfat+2
  580 A:db84  85 4c                              sta zp_sd_currentsector+2
  581 A:db86  a5 72                              lda fat32_lastsector+3
  582 A:db88  65 7e                              adc fat32_sectorsperfat+3
  583 A:db8a  85 4d                              sta zp_sd_currentsector+3

  585 A:db8c                                    ; Write the FAT sector
  586 A:db8c  20 4c d8                           jsr sd_writesector

  588 A:db8f                           onefat    
  588 A:db8f                                    
  589 A:db8f                                    ; Pull back the current sector
  590 A:db8f  68                                 pla 
  591 A:db90  85 4d                              sta zp_sd_currentsector+3
  592 A:db92  68                                 pla 
  593 A:db93  85 4c                              sta zp_sd_currentsector+2
  594 A:db95  68                                 pla 
  595 A:db96  85 4b                              sta zp_sd_currentsector+1
  596 A:db98  68                                 pla 
  597 A:db99  85 4a                              sta zp_sd_currentsector

  599 A:db9b  60                                 rts 
  600 A:db9c                                     .) 

  603 A:db9c                           fat32_openroot 
  603 A:db9c                                    
  604 A:db9c                                     .( 
  605 A:db9c                                    ; Prepare to read the root directory

  607 A:db9c  a5 56                              lda fat32_rootcluster
  608 A:db9e  85 5e                              sta fat32_nextcluster
  609 A:dba0  85 7f                              sta fat32_cdcluster
  610 A:dba2  a5 57                              lda fat32_rootcluster+1
  611 A:dba4  85 5f                              sta fat32_nextcluster+1
  612 A:dba6  85 80                              sta fat32_cdcluster+1
  613 A:dba8  a5 58                              lda fat32_rootcluster+2
  614 A:dbaa  85 60                              sta fat32_nextcluster+2
  615 A:dbac  85 81                              sta fat32_cdcluster+2
  616 A:dbae  a5 59                              lda fat32_rootcluster+3
  617 A:dbb0  85 61                              sta fat32_nextcluster+3
  618 A:dbb2  85 82                              sta fat32_cdcluster+3

  620 A:dbb4  18                                 clc 
  621 A:dbb5  20 0c da                           jsr fat32_seekcluster

  623 A:dbb8                                    ; Set the pointer to a large value so we always read a sector the first time through
  624 A:dbb8  a9 ff                              lda #$ff
  625 A:dbba  85 49                              sta zp_sd_address+1

  627 A:dbbc  60                                 rts 
  628 A:dbbd                                     .) 

  630 A:dbbd                           fat32_allocatecluster 
  630 A:dbbd                                    
  631 A:dbbd                                     .( 
  632 A:dbbd                                    ; Allocate the first cluster to store a file at.

  634 A:dbbd                                    ; Find a free cluster
  635 A:dbbd  20 92 dc                           jsr fat32_findnextfreecluster

  637 A:dbc0                                    ; Cache the value so we can add the address of the next one later, if any
  638 A:dbc0  a5 66                              lda fat32_lastfoundfreecluster
  639 A:dbc2  85 6a                              sta fat32_lastcluster
  640 A:dbc4  85 77                              sta fat32_filecluster
  641 A:dbc6  a5 67                              lda fat32_lastfoundfreecluster+1
  642 A:dbc8  85 6b                              sta fat32_lastcluster+1
  643 A:dbca  85 78                              sta fat32_filecluster+1
  644 A:dbcc  a5 68                              lda fat32_lastfoundfreecluster+2
  645 A:dbce  85 6c                              sta fat32_lastcluster+2
  646 A:dbd0  85 79                              sta fat32_filecluster+2
  647 A:dbd2  a5 69                              lda fat32_lastfoundfreecluster+3
  648 A:dbd4  85 6d                              sta fat32_lastcluster+3
  649 A:dbd6  85 7a                              sta fat32_filecluster+3

  651 A:dbd8                                    ; Add marker for the following routines, so we don't think this is free.
  652 A:dbd8  a9 0f                              lda #$0f
  653 A:dbda  91 48                              sta (zp_sd_address),y

  655 A:dbdc  60                                 rts 
  656 A:dbdd                                     .) 

  658 A:dbdd                           fat32_allocatefile 
  658 A:dbdd                                    
  659 A:dbdd                                     .( 
  660 A:dbdd                                    ; Allocate an entire file in the FAT, with the
  661 A:dbdd                                    ; file's size in fat32_bytesremaining

  663 A:dbdd                                    ; We will read a new sector the first time around
  664 A:dbdd  64 6f                              stz fat32_lastsector
  665 A:dbdf  64 70                              stz fat32_lastsector+1
  666 A:dbe1  64 71                              stz fat32_lastsector+2
  667 A:dbe3  64 72                              stz fat32_lastsector+3

  669 A:dbe5                                    ; BUG if we have a FAT enty at the end of a sector, it may be ignored! 

  671 A:dbe5                                    ; Allocate the first cluster.
  672 A:dbe5  20 bd db                           jsr fat32_allocatecluster

  674 A:dbe8                                    ; We don't properly support 64k+ files, as it's unnecessary complication given
  675 A:dbe8                                    ; the 6502's small address space. So we'll just empty out the top two bytes.
  676 A:dbe8  a9 00                              lda #0
  677 A:dbea  85 64                              sta fat32_bytesremaining+2
  678 A:dbec  85 65                              sta fat32_bytesremaining+3

  680 A:dbee                                    ; Stash filesize, as we will be clobbering it here
  681 A:dbee  a5 62                              lda fat32_bytesremaining
  682 A:dbf0  48                                 pha 
  683 A:dbf1  a5 63                              lda fat32_bytesremaining+1
  684 A:dbf3  48                                 pha 

  686 A:dbf4                                    ; Round the size up to the next whole sector
  687 A:dbf4  a5 62                              lda fat32_bytesremaining
  688 A:dbf6  c9 01                              cmp #1             ; set carry if bottom 8 bits not zero
  689 A:dbf8  a5 63                              lda fat32_bytesremaining+1
  690 A:dbfa  69 00                              adc #0             ; add carry, if any
  691 A:dbfc  4a                                 lsr                    ; divide by 2
  692 A:dbfd  69 00                              adc #0             ; round up

  694 A:dbff                                    ; No data?
  695 A:dbff  d0 03                              bne nofail
  696 A:dc01  4c 8b dc                           jmp fail

  698 A:dc04                           nofail    
  698 A:dc04                                    
  699 A:dc04                                    ; This will be clustersremaining now.
  700 A:dc04  85 62                              sta fat32_bytesremaining

  702 A:dc06                                    ; Divide by sectors per cluster (power of 2)
  703 A:dc06  a5 5a                              lda fat32_sectorspercluster
  704 A:dc08                           cloop     
  705 A:dc08  c9 01                              cmp #1
  706 A:dc0a  f0 08                              beq one
  707 A:dc0c  4a                                 lsr 
  708 A:dc0d  46 63                              lsr fat32_bytesremaining+1          ; high byte
  709 A:dc0f  66 62                              ror fat32_bytesremaining                ; low byte, with carry from high

  711 A:dc11  4c 08 dc                           jmp cloop

  713 A:dc14                           one       

  715 A:dc14                                    ; We will be making a new cluster every time
  716 A:dc14  64 5b                              stz fat32_pendingsectors

  718 A:dc16                                    ; Find free clusters and allocate them for use for this file.
  719 A:dc16                           allocatelp 
  720 A:dc16                                    ; Check if it's the last cluster in the chain 
  721 A:dc16  a5 62                              lda fat32_bytesremaining
  722 A:dc18  f0 04                              beq lastcluster
  723 A:dc1a  c9 01                              cmp #1             ; CHECK! is 1 the right amound for this?
  724 A:dc1c  90 29                              bcc notlastcluster                ; clustersremaining <=1?

  726 A:dc1e                                    ; It is the last one.

  728 A:dc1e                           lastcluster 

  730 A:dc1e                                    ; go back the previous one
  731 A:dc1e  a5 6a                              lda fat32_lastcluster
  732 A:dc20  85 5e                              sta fat32_nextcluster
  733 A:dc22  a5 6b                              lda fat32_lastcluster+1
  734 A:dc24  85 5f                              sta fat32_nextcluster+1
  735 A:dc26  a5 6c                              lda fat32_lastcluster+2
  736 A:dc28  85 60                              sta fat32_nextcluster+2
  737 A:dc2a  a5 6d                              lda fat32_lastcluster+3
  738 A:dc2c  85 61                              sta fat32_nextcluster+3

  740 A:dc2e  38                                 sec 
  741 A:dc2f  20 0c da                           jsr fat32_seekcluster

  743 A:dc32                                    ; Write 0x0FFFFFFF (EOC)
  744 A:dc32  a9 0f                              lda #$0f
  745 A:dc34  91 48                              sta (zp_sd_address),y
  746 A:dc36  88                                 dey 
  747 A:dc37  a9 ff                              lda #$ff
  748 A:dc39  91 48                              sta (zp_sd_address),y
  749 A:dc3b  88                                 dey 
  750 A:dc3c  91 48                              sta (zp_sd_address),y
  751 A:dc3e  88                                 dey 
  752 A:dc3f  91 48                              sta (zp_sd_address),y

  754 A:dc41                                    ; Update the FAT
  755 A:dc41  20 47 db                           jsr fat32_updatefat

  757 A:dc44                                    ; End of chain - exit
  758 A:dc44  4c 8b dc                           jmp fail

  760 A:dc47                           notlastcluster 
  761 A:dc47                                    ; Wait! Is there exactly 1 cluster left?
  762 A:dc47  f0 d5                              beq lastcluster

  764 A:dc49                                    ; Find the next cluster
  765 A:dc49  20 92 dc                           jsr fat32_findnextfreecluster

  767 A:dc4c                                    ; Add marker so we don't think this is free.
  768 A:dc4c  a9 0f                              lda #$0f
  769 A:dc4e  91 48                              sta (zp_sd_address),y

  771 A:dc50                                    ; Seek to the previous cluster
  772 A:dc50  a5 6a                              lda fat32_lastcluster
  773 A:dc52  85 5e                              sta fat32_nextcluster
  774 A:dc54  a5 6b                              lda fat32_lastcluster+1
  775 A:dc56  85 5f                              sta fat32_nextcluster+1
  776 A:dc58  a5 6c                              lda fat32_lastcluster+2
  777 A:dc5a  85 60                              sta fat32_nextcluster+2
  778 A:dc5c  a5 6d                              lda fat32_lastcluster+3
  779 A:dc5e  85 61                              sta fat32_nextcluster+3

  781 A:dc60  38                                 sec 
  782 A:dc61  20 0c da                           jsr fat32_seekcluster

  784 A:dc64  5a                                 phy 
  785 A:dc65                                    ; Enter the address of the next one into the FAT
  786 A:dc65  a5 69                              lda fat32_lastfoundfreecluster+3
  787 A:dc67  85 6d                              sta fat32_lastcluster+3
  788 A:dc69  91 48                              sta (zp_sd_address),y
  789 A:dc6b  88                                 dey 
  790 A:dc6c  a5 68                              lda fat32_lastfoundfreecluster+2
  791 A:dc6e  85 6c                              sta fat32_lastcluster+2
  792 A:dc70  91 48                              sta (zp_sd_address),y
  793 A:dc72  88                                 dey 
  794 A:dc73  a5 67                              lda fat32_lastfoundfreecluster+1
  795 A:dc75  85 6b                              sta fat32_lastcluster+1
  796 A:dc77  91 48                              sta (zp_sd_address),y
  797 A:dc79  88                                 dey 
  798 A:dc7a  a5 66                              lda fat32_lastfoundfreecluster
  799 A:dc7c  85 6a                              sta fat32_lastcluster
  800 A:dc7e  91 48                              sta (zp_sd_address),y
  801 A:dc80  7a                                 ply 

  803 A:dc81                                    ; Update the FAT
  804 A:dc81  20 47 db                           jsr fat32_updatefat

  806 A:dc84  a6 62                              ldx fat32_bytesremaining                ; note - actually loads clusters remaining
  807 A:dc86  ca                                 dex 
  808 A:dc87  86 62                              stx fat32_bytesremaining                ; note - actually stores clusters remaining

  810 A:dc89  d0 8b                              bne allocatelp

  812 A:dc8b                                    ; Done!
  813 A:dc8b                           fail      
  814 A:dc8b                                    ; Pull the filesize back from the stack
  815 A:dc8b  68                                 pla 
  816 A:dc8c  85 63                              sta fat32_bytesremaining+1
  817 A:dc8e  68                                 pla 
  818 A:dc8f  85 62                              sta fat32_bytesremaining
  819 A:dc91  60                                 rts 

  821 A:dc92                                     .) 

  823 A:dc92                           fat32_findnextfreecluster 
  823 A:dc92                                    
  824 A:dc92                                     .( 
  825 A:dc92                                    ; Find next free cluster
  826 A:dc92                                    ; 
  827 A:dc92                                    ; This program will search the FAT for an empty entry, and
  828 A:dc92                                    ; save the 32-bit cluster number at fat32_lastfoundfreecluster.
  829 A:dc92                                    ;
  830 A:dc92                                    ; Also sets the carry bit if the SD card is full.
  831 A:dc92                                    ;

  833 A:dc92                                    ; Find a free cluster and store it's location in fat32_lastfoundfreecluster
  834 A:dc92                                    ; skip reserved clusters
  835 A:dc92  a9 02                              lda #2
  836 A:dc94  85 5e                              sta fat32_nextcluster
  837 A:dc96  85 66                              sta fat32_lastfoundfreecluster
  838 A:dc98  a9 00                              lda #0
  839 A:dc9a  85 5f                              sta fat32_nextcluster+1
  840 A:dc9c  85 67                              sta fat32_lastfoundfreecluster+1
  841 A:dc9e  85 60                              sta fat32_nextcluster+2
  842 A:dca0  85 68                              sta fat32_lastfoundfreecluster+2
  843 A:dca2  85 61                              sta fat32_nextcluster+3
  844 A:dca4  85 69                              sta fat32_lastfoundfreecluster+3

  846 A:dca6                           searchclusters 

  848 A:dca6                                    ; Seek cluster
  849 A:dca6  38                                 sec 
  850 A:dca7  20 0c da                           jsr fat32_seekcluster

  852 A:dcaa                                    ; Is the cluster free?
  853 A:dcaa  a5 5e                              lda fat32_nextcluster
  854 A:dcac  05 5f                              ora fat32_nextcluster+1
  855 A:dcae  05 60                              ora fat32_nextcluster+2
  856 A:dcb0  05 61                              ora fat32_nextcluster+3
  857 A:dcb2  f0 29                              beq foundcluster

  859 A:dcb4                                    ; No, increment the cluster count
  860 A:dcb4  e6 66                              inc fat32_lastfoundfreecluster
  861 A:dcb6  d0 10                              bne copycluster
  862 A:dcb8  e6 67                              inc fat32_lastfoundfreecluster+1
  863 A:dcba  d0 0c                              bne copycluster
  864 A:dcbc  e6 68                              inc fat32_lastfoundfreecluster+2
  865 A:dcbe  d0 08                              bne copycluster
  866 A:dcc0  e6 69                              inc fat32_lastfoundfreecluster+3

  868 A:dcc2  a5 66                              lda fat32_lastfoundfreecluster
  869 A:dcc4  c9 10                              cmp #$10
  870 A:dcc6  b0 17                              bcs sd_full

  872 A:dcc8                           copycluster 

  874 A:dcc8                                    ; Copy the cluster count to the next cluster
  875 A:dcc8  a5 66                              lda fat32_lastfoundfreecluster
  876 A:dcca  85 5e                              sta fat32_nextcluster
  877 A:dccc  a5 67                              lda fat32_lastfoundfreecluster+1
  878 A:dcce  85 5f                              sta fat32_nextcluster+1
  879 A:dcd0  a5 68                              lda fat32_lastfoundfreecluster+2
  880 A:dcd2  85 60                              sta fat32_nextcluster+2
  881 A:dcd4  a5 69                              lda fat32_lastfoundfreecluster+3
  882 A:dcd6  29 0f                              and #$0f
  883 A:dcd8  85 61                              sta fat32_nextcluster+3

  885 A:dcda                                    ; Go again for another pass
  886 A:dcda  4c a6 dc                           jmp searchclusters

  888 A:dcdd                           foundcluster 
  889 A:dcdd                                    ; done.
  890 A:dcdd  18                                 clc 
  891 A:dcde  60                                 rts 

  893 A:dcdf                           sd_full   
  894 A:dcdf  38                                 sec 
  895 A:dce0  60                                 rts 
  896 A:dce1                                     .) 

  898 A:dce1                           fat32_opendirent 
  898 A:dce1                                    
  899 A:dce1                                     .( 
  900 A:dce1                                    ; Prepare to read/write a file or directory based on a dirent
  901 A:dce1                                    ;
  902 A:dce1                                    ; Point zp_sd_address at the dirent

  904 A:dce1                                    ; Remember file size in bytes remaining
  905 A:dce1  a0 1c                              ldy #28
  906 A:dce3  b1 48                              lda (zp_sd_address),y
  907 A:dce5  85 62                              sta fat32_bytesremaining
  908 A:dce7  c8                                 iny 
  909 A:dce8  b1 48                              lda (zp_sd_address),y
  910 A:dcea  85 63                              sta fat32_bytesremaining+1
  911 A:dcec  c8                                 iny 
  912 A:dced  b1 48                              lda (zp_sd_address),y
  913 A:dcef  85 64                              sta fat32_bytesremaining+2
  914 A:dcf1  c8                                 iny 
  915 A:dcf2  b1 48                              lda (zp_sd_address),y
  916 A:dcf4  85 65                              sta fat32_bytesremaining+3

  918 A:dcf6                                    ; Seek to first cluster
  919 A:dcf6  a0 1a                              ldy #26
  920 A:dcf8  b1 48                              lda (zp_sd_address),y
  921 A:dcfa  85 5e                              sta fat32_nextcluster
  922 A:dcfc  c8                                 iny 
  923 A:dcfd  b1 48                              lda (zp_sd_address),y
  924 A:dcff  85 5f                              sta fat32_nextcluster+1
  925 A:dd01  a0 14                              ldy #20
  926 A:dd03  b1 48                              lda (zp_sd_address),y
  927 A:dd05  85 60                              sta fat32_nextcluster+2
  928 A:dd07  c8                                 iny 
  929 A:dd08  b1 48                              lda (zp_sd_address),y
  930 A:dd0a  85 61                              sta fat32_nextcluster+3

  932 A:dd0c  18                                 clc 
  933 A:dd0d  a0 0b                              ldy #$0b
  934 A:dd0f  b1 48                              lda (zp_sd_address),Y
  935 A:dd11  29 10                              and #$10             ; is it a directory?
  936 A:dd13  f0 10                              beq fatskip_cd_cache

  938 A:dd15                                    ; If it's a directory, cache the cluster
  939 A:dd15  a5 5e                              lda fat32_nextcluster
  940 A:dd17  85 7f                              sta fat32_cdcluster
  941 A:dd19  a5 5f                              lda fat32_nextcluster+1
  942 A:dd1b  85 80                              sta fat32_cdcluster+1
  943 A:dd1d  a5 60                              lda fat32_nextcluster+2
  944 A:dd1f  85 81                              sta fat32_cdcluster+2
  945 A:dd21  a5 61                              lda fat32_nextcluster+3
  946 A:dd23  85 82                              sta fat32_cdcluster+3

  948 A:dd25                           fatskip_cd_cache 
  948 A:dd25                                    

  950 A:dd25                                    ; if we're opening a directory entry with 0 cluster, use the root cluster
  951 A:dd25  a5 61                              lda fat32_nextcluster+3
  952 A:dd27  d0 12                              bne fseek
  953 A:dd29  a5 60                              lda fat32_nextcluster+2
  954 A:dd2b  d0 0e                              bne fseek
  955 A:dd2d  a5 5f                              lda fat32_nextcluster+1
  956 A:dd2f  d0 0a                              bne fseek
  957 A:dd31  a5 5e                              lda fat32_nextcluster
  958 A:dd33  d0 06                              bne fseek
  959 A:dd35  a5 56                              lda fat32_rootcluster
  960 A:dd37  85 5e                              sta fat32_nextcluster
  961 A:dd39  85 7f                              sta fat32_cdcluster

  963 A:dd3b                           fseek     
  963 A:dd3b                                    
  964 A:dd3b  18                                 clc 
  965 A:dd3c  20 0c da                           jsr fat32_seekcluster

  967 A:dd3f                                    ; Set the pointer to a large value so we always read a sector the first time through
  968 A:dd3f  a9 ff                              lda #$ff
  969 A:dd41  85 49                              sta zp_sd_address+1

  971 A:dd43  60                                 rts 
  972 A:dd44                                     .) 

  974 A:dd44                           fat32_writedirent 
  974 A:dd44                                    
  975 A:dd44                                     .( 
  976 A:dd44                                    ; Write a directory entry from the open directory
  977 A:dd44                                    ; requires
  977 A:dd44                                    
  978 A:dd44                                    ;   fat32bytesremaining (2 bytes) = file size in bytes (little endian)

  980 A:dd44                                    ; Increment pointer by 32 to point to next entry
  981 A:dd44  18                                 clc 
  982 A:dd45  a5 48                              lda zp_sd_address
  983 A:dd47  69 20                              adc #32
  984 A:dd49  85 48                              sta zp_sd_address
  985 A:dd4b  a5 49                              lda zp_sd_address+1
  986 A:dd4d  69 00                              adc #0
  987 A:dd4f  85 49                              sta zp_sd_address+1

  989 A:dd51                                    ; If it's not at the end of the buffer, we have data already
  990 A:dd51  c9 07                              cmp #>(fat32_readbuffer+$0200)
  991 A:dd53  90 0f                              bcc gotdirrent

  993 A:dd55                                    ; Read another sector
  994 A:dd55  a9 00                              lda #<fat32_readbuffer
  995 A:dd57  85 5c                              sta fat32_address
  996 A:dd59  a9 05                              lda #>fat32_readbuffer
  997 A:dd5b  85 5d                              sta fat32_address+1

  999 A:dd5d  20 ea da                           jsr fat32_readnextsector
 1000 A:dd60  90 02                              bcc gotdirrent

 1002 A:dd62                           endofdirectorywrite 
 1002 A:dd62                                    
 1003 A:dd62  38                                 sec 
 1004 A:dd63  60                                 rts 

 1006 A:dd64                           gotdirrent 
 1006 A:dd64                                    
 1007 A:dd64                                    ; Check first character
 1008 A:dd64  18                                 clc 
 1009 A:dd65  a0 00                              ldy #0
 1010 A:dd67  b1 48                              lda (zp_sd_address),y
 1011 A:dd69  d0 d9                              bne fat32_writedirent                ; go again
 1012 A:dd6b                                    ; End of directory. Now make a new entry.
 1013 A:dd6b                           dloop     
 1013 A:dd6b                                    
 1014 A:dd6b  b1 74                              lda (fat32_filenamepointer),y            ; copy filename
 1015 A:dd6d  91 48                              sta (zp_sd_address),y
 1016 A:dd6f  c8                                 iny 
 1017 A:dd70  c0 0b                              cpy #$0b
 1018 A:dd72  d0 f7                              bne dloop
 1019 A:dd74                                    ; The full Short filename is #11 bytes long so,
 1020 A:dd74                                    ; this start at 0x0b - File type
 1021 A:dd74                                    ; BUG assumes that we are making a file, not a folder...
 1022 A:dd74  a9 20                              lda #$20             ; File Type
 1022 A:dd76                           ARCHIVE   
 1023 A:dd76  91 48                              sta (zp_sd_address),y
 1024 A:dd78  c8                                 iny                    ; 0x0c - Checksum/File accsess password
 1025 A:dd79  a9 10                              lda #$10             ; No checksum or password
 1026 A:dd7b  91 48                              sta (zp_sd_address),y
 1027 A:dd7d  c8                                 iny                    ; 0x0d - first char of deleted file - 0x7d for nothing
 1028 A:dd7e  a9 7d                              lda #$7d
 1029 A:dd80  91 48                              sta (zp_sd_address),y
 1030 A:dd82  c8                                 iny                    ; 0x0e-0x11 - File creation time/date
 1031 A:dd83  a9 00                              lda #0
 1032 A:dd85                           empty     
 1033 A:dd85  91 48                              sta (zp_sd_address),y            ; No time/date because I don't have an RTC
 1034 A:dd87  c8                                 iny 
 1035 A:dd88  c0 14                              cpy #$14             ; also empty the user ID (0x12-0x13)
 1036 A:dd8a  d0 f9                              bne empty
 1037 A:dd8c                                    ;sta (zp_sd_address),y
 1038 A:dd8c                                    ;iny
 1039 A:dd8c                                    ;sta (zp_sd_address),y
 1040 A:dd8c                                    ;iny
 1041 A:dd8c                                    ;sta (zp_sd_address),y
 1042 A:dd8c                                    ; if you have an RTC, refer to https
 1042 A:dd8c                                    
 1043 A:dd8c                                    ; show the "Directory entry" table and look at at 0x0E onward.
 1044 A:dd8c                                    ;iny   ; 0x12-0x13 - User ID
 1045 A:dd8c                                    ;lda #0
 1046 A:dd8c                                    ;sta (zp_sd_address),y ; No ID
 1047 A:dd8c                                    ;iny
 1048 A:dd8c                                    ;sta (zp_sd_address),y
 1049 A:dd8c                                    ;iny 
 1050 A:dd8c                                    ; 0x14-0x15 - File start cluster (high word)
 1051 A:dd8c  a5 79                              lda fat32_filecluster+2
 1052 A:dd8e  91 48                              sta (zp_sd_address),y
 1053 A:dd90  c8                                 iny 
 1054 A:dd91  a5 7a                              lda fat32_filecluster+3
 1055 A:dd93  91 48                              sta (zp_sd_address),y
 1056 A:dd95  c8                                 iny                    ; 0x16-0x19 - File modifiaction date
 1057 A:dd96  a9 00                              lda #0
 1058 A:dd98  91 48                              sta (zp_sd_address),y
 1059 A:dd9a  c8                                 iny 
 1060 A:dd9b  91 48                              sta (zp_sd_address),y            ; no rtc
 1061 A:dd9d  c8                                 iny 
 1062 A:dd9e  91 48                              sta (zp_sd_address),y
 1063 A:dda0  c8                                 iny 
 1064 A:dda1  91 48                              sta (zp_sd_address),y
 1065 A:dda3  c8                                 iny                    ; 0x1a-0x1b - File start cluster (low word)
 1066 A:dda4  a5 77                              lda fat32_filecluster
 1067 A:dda6  91 48                              sta (zp_sd_address),y
 1068 A:dda8  c8                                 iny 
 1069 A:dda9  a5 78                              lda fat32_filecluster+1
 1070 A:ddab  91 48                              sta (zp_sd_address),y
 1071 A:ddad  c8                                 iny                    ; 0x1c-0x1f File size in bytes
 1072 A:ddae  a5 62                              lda fat32_bytesremaining
 1073 A:ddb0  91 48                              sta (zp_sd_address),y
 1074 A:ddb2  c8                                 iny 
 1075 A:ddb3  a5 63                              lda fat32_bytesremaining+1
 1076 A:ddb5  91 48                              sta (zp_sd_address),y
 1077 A:ddb7  c8                                 iny 
 1078 A:ddb8  a9 00                              lda #0
 1079 A:ddba  91 48                              sta (zp_sd_address),y            ; No bigger that 64k
 1080 A:ddbc  c8                                 iny 
 1081 A:ddbd  91 48                              sta (zp_sd_address),y
 1082 A:ddbf  c8                                 iny 
 1083 A:ddc0                                    ; are we over the buffer?
 1084 A:ddc0  a5 49                              lda zp_sd_address+1
 1085 A:ddc2  c9 07                              cmp #>(fat32_readbuffer+$0200)
 1086 A:ddc4  90 12                              bcc notoverbuffer
 1087 A:ddc6  20 fb dd                           jsr fat32_wrcurrent                ; if so, write the current sector
 1088 A:ddc9  20 ea da                           jsr fat32_readnextsector                ; then read the next one.
 1089 A:ddcc  b0 2b                              bcs dfail
 1090 A:ddce  a0 00                              ldy #0
 1091 A:ddd0  a9 00                              lda #<fat32_readbuffer
 1092 A:ddd2  85 48                              sta zp_sd_address
 1093 A:ddd4  a9 05                              lda #>fat32_readbuffer
 1094 A:ddd6  85 49                              sta zp_sd_address+1
 1095 A:ddd8                           notoverbuffer 
 1096 A:ddd8                                    ; next entry is 0 (end of dir)
 1097 A:ddd8  a9 00                              lda #0
 1098 A:ddda  91 48                              sta (zp_sd_address),y
 1099 A:dddc                                    ; write all the data...
 1100 A:dddc  20 fb dd                           jsr fat32_wrcurrent

 1102 A:dddf                                    ; Great, lets get this ready for other code to use.

 1104 A:dddf                                    ; Seek to first cluster
 1105 A:dddf  a5 77                              lda fat32_filecluster
 1106 A:dde1  85 5e                              sta fat32_nextcluster
 1107 A:dde3  a5 78                              lda fat32_filecluster+1
 1108 A:dde5  85 5f                              sta fat32_nextcluster+1
 1109 A:dde7  a5 79                              lda fat32_filecluster+2
 1110 A:dde9  85 60                              sta fat32_nextcluster+2
 1111 A:ddeb  a5 7a                              lda fat32_filecluster+3
 1112 A:dded  85 61                              sta fat32_nextcluster+3

 1114 A:ddef  18                                 clc 
 1115 A:ddf0  20 0c da                           jsr fat32_seekcluster

 1117 A:ddf3                                    ; Set the pointer to a large value so we always read a sector the first time through
 1118 A:ddf3  a9 ff                              lda #$ff
 1119 A:ddf5  85 49                              sta zp_sd_address+1

 1121 A:ddf7  18                                 clc 
 1122 A:ddf8  60                                 rts 

 1124 A:ddf9                           dfail     
 1124 A:ddf9                                    
 1125 A:ddf9                                    ; Card Full
 1126 A:ddf9  38                                 sec 
 1127 A:ddfa  60                                 rts 
 1128 A:ddfb                                     .) 

 1130 A:ddfb                           fat32_wrcurrent 
 1130 A:ddfb                                    
 1131 A:ddfb                                     .( 
 1132 A:ddfb                                    ; decrement the sector so we write the current one (not the next one)
 1133 A:ddfb  a5 4a                              lda zp_sd_currentsector
 1134 A:ddfd  d0 0a                              bne skip
 1135 A:ddff  c6 4b                              dec zp_sd_currentsector+1
 1136 A:de01  d0 06                              bne skip
 1137 A:de03  c6 4c                              dec zp_sd_currentsector+2
 1138 A:de05  d0 02                              bne skip
 1139 A:de07  c6 4d                              dec zp_sd_currentsector+3

 1141 A:de09                           skip      
 1142 A:de09  c6 4a                              dec zp_sd_currentsector

 1144 A:de0b                           nodec     

 1146 A:de0b  a5 5c                              lda fat32_address
 1147 A:de0d  85 48                              sta zp_sd_address
 1148 A:de0f  a5 5d                              lda fat32_address+1
 1149 A:de11  85 49                              sta zp_sd_address+1

 1151 A:de13                                    ; Read the sector
 1152 A:de13  20 4c d8                           jsr sd_writesector

 1154 A:de16                                    ; Advance to next sector
 1155 A:de16  e6 4a                              inc zp_sd_currentsector
 1156 A:de18  d0 0a                              bne sectorincrementdone
 1157 A:de1a  e6 4b                              inc zp_sd_currentsector+1
 1158 A:de1c  d0 06                              bne sectorincrementdone
 1159 A:de1e  e6 4c                              inc zp_sd_currentsector+2
 1160 A:de20  d0 02                              bne sectorincrementdone
 1161 A:de22  e6 4d                              inc zp_sd_currentsector+3

 1163 A:de24                           sectorincrementdone 
 1164 A:de24  60                                 rts 
 1165 A:de25                                     .) 

 1167 A:de25                           fat32_readdirent 
 1167 A:de25                                    
 1168 A:de25                                     .( 
 1169 A:de25                                    ; Read a directory entry from the open directory
 1170 A:de25                                    ;
 1171 A:de25                                    ; On exit the carry is set if there were no more directory entries.
 1172 A:de25                                    ;
 1173 A:de25                                    ; Otherwise, A is set to the file's attribute byte and
 1174 A:de25                                    ; zp_sd_address points at the returned directory entry.
 1175 A:de25                                    ; LFNs and empty entries are ignored automatically.

 1177 A:de25                                    ; Increment pointer by 32 to point to next entry
 1178 A:de25  18                                 clc 
 1179 A:de26  a5 48                              lda zp_sd_address
 1180 A:de28  69 20                              adc #32
 1181 A:de2a  85 48                              sta zp_sd_address
 1182 A:de2c  a5 49                              lda zp_sd_address+1
 1183 A:de2e  69 00                              adc #0
 1184 A:de30  85 49                              sta zp_sd_address+1

 1186 A:de32                                    ; If it's not at the end of the buffer, we have data already
 1187 A:de32  c9 07                              cmp #>(fat32_readbuffer+$0200)
 1188 A:de34  90 0f                              bcc gotdata

 1190 A:de36                                    ; Read another sector
 1191 A:de36  a9 00                              lda #<fat32_readbuffer
 1192 A:de38  85 5c                              sta fat32_address
 1193 A:de3a  a9 05                              lda #>fat32_readbuffer
 1194 A:de3c  85 5d                              sta fat32_address+1

 1196 A:de3e  20 ea da                           jsr fat32_readnextsector
 1197 A:de41  90 02                              bcc gotdata

 1199 A:de43                           endofdirectory 
 1199 A:de43                                    
 1200 A:de43  38                                 sec 
 1201 A:de44  60                                 rts 

 1203 A:de45                           gotdata   
 1203 A:de45                                    
 1204 A:de45                                    ; Check first character
 1205 A:de45  a0 00                              ldy #0
 1206 A:de47  b1 48                              lda (zp_sd_address),y

 1208 A:de49                                    ; End of directory => abort
 1209 A:de49  f0 f8                              beq endofdirectory

 1211 A:de4b                                    ; Empty entry => start again
 1212 A:de4b  c9 e5                              cmp #$e5
 1213 A:de4d  f0 d6                              beq fat32_readdirent

 1215 A:de4f                                    ; Check attributes
 1216 A:de4f  a0 0b                              ldy #11
 1217 A:de51  b1 48                              lda (zp_sd_address),y
 1218 A:de53  29 3f                              and #$3f
 1219 A:de55  c9 0f                              cmp #$0f             ; LFN => start again
 1220 A:de57  f0 cc                              beq fat32_readdirent

 1222 A:de59                                    ; Yield this result
 1223 A:de59  18                                 clc 
 1224 A:de5a  60                                 rts 
 1225 A:de5b                                     .) 

 1227 A:de5b                           fat32_finddirent 
 1227 A:de5b                                    
 1228 A:de5b                                     .( 
 1229 A:de5b                                    ; Finds a particular directory entry. X,Y point to the 11-character filename to seek.
 1230 A:de5b                                    ; The directory should already be open for iteration.

 1232 A:de5b                                    ; Form ZP pointer to user's filename
 1233 A:de5b  86 74                              stx fat32_filenamepointer
 1234 A:de5d  84 75                              sty fat32_filenamepointer+1

 1236 A:de5f                                    ; Iterate until name is found or end of directory
 1237 A:de5f                           direntloop 
 1237 A:de5f                                    
 1238 A:de5f  20 25 de                           jsr fat32_readdirent
 1239 A:de62  a0 0a                              ldy #10
 1240 A:de64  90 01                              bcc comparenameloop
 1241 A:de66  60                                 rts                    ; with carry set

 1243 A:de67                           comparenameloop 
 1243 A:de67                                    
 1244 A:de67  b1 48                              lda (zp_sd_address),y
 1245 A:de69  d1 74                              cmp (fat32_filenamepointer),y
 1246 A:de6b  d0 f2                              bne direntloop                ; no match
 1247 A:de6d  88                                 dey 
 1248 A:de6e  10 f7                              bpl comparenameloop

 1250 A:de70                                    ; Found it
 1251 A:de70  18                                 clc 
 1252 A:de71  60                                 rts 
 1253 A:de72                                     .) 

 1255 A:de72                           fat32_markdeleted 
 1255 A:de72                                    
 1256 A:de72                                    ; Mark the file as deleted
 1257 A:de72                                    ; We need to stash the first character at index 0x0D
 1258 A:de72  a0 00                              ldy #$00
 1259 A:de74  b1 48                              lda (zp_sd_address),y
 1260 A:de76  a0 0d                              ldy #$0d
 1261 A:de78  91 48                              sta (zp_sd_address),y

 1263 A:de7a                                    ; Now put 0xE5 at the first byte
 1264 A:de7a  a0 00                              ldy #$00
 1265 A:de7c  a9 e5                              lda #$e5
 1266 A:de7e  91 48                              sta (zp_sd_address),y

 1268 A:de80                                    ; Get start cluster high word
 1269 A:de80  a0 14                              ldy #$14
 1270 A:de82  b1 48                              lda (zp_sd_address),y
 1271 A:de84  85 60                              sta fat32_nextcluster+2
 1272 A:de86  c8                                 iny 
 1273 A:de87  b1 48                              lda (zp_sd_address),y
 1274 A:de89  85 61                              sta fat32_nextcluster+3

 1276 A:de8b                                    ; And low word
 1277 A:de8b  a0 1a                              ldy #$1a
 1278 A:de8d  b1 48                              lda (zp_sd_address),y
 1279 A:de8f  85 5e                              sta fat32_nextcluster
 1280 A:de91  c8                                 iny 
 1281 A:de92  b1 48                              lda (zp_sd_address),y
 1282 A:de94  85 5f                              sta fat32_nextcluster+1

 1284 A:de96                                    ; Write the dirent
 1285 A:de96  20 fb dd                           jsr fat32_wrcurrent

 1287 A:de99                                    ; Done
 1288 A:de99  18                                 clc 
 1289 A:de9a  60                                 rts 

 1291 A:de9b                           fat32_deletefile 
 1291 A:de9b                                    
 1292 A:de9b                                     .( 
 1293 A:de9b                                    ; Removes the open file from the SD card.
 1294 A:de9b                                    ; The directory needs to be open and
 1295 A:de9b                                    ; zp_sd_address pointed to the first byte of the file entry.

 1297 A:de9b                                    ; Mark the file as "Removed"
 1298 A:de9b  20 72 de                           jsr fat32_markdeleted

 1300 A:de9e                                    ; We will read a new sector the first time around
 1301 A:de9e  64 6f                              stz fat32_lastsector
 1302 A:dea0  64 70                              stz fat32_lastsector+1
 1303 A:dea2  64 71                              stz fat32_lastsector+2
 1304 A:dea4  64 72                              stz fat32_lastsector+3

 1306 A:dea6                                    ; Now we need to iterate through this file's cluster chain, and remove it from the FAT.
 1307 A:dea6  a0 00                              ldy #0
 1308 A:dea8                           chainloop 
 1309 A:dea8                                    ; Seek to cluster
 1310 A:dea8  38                                 sec 
 1311 A:dea9  20 0c da                           jsr fat32_seekcluster

 1313 A:deac                                    ; Is this the end of the chain?
 1314 A:deac  a5 61                              lda fat32_nextcluster+3
 1315 A:deae  30 13                              bmi endofchain

 1317 A:deb0                                    ; Zero it out
 1318 A:deb0  a9 00                              lda #0
 1319 A:deb2  91 48                              sta (zp_sd_address),y
 1320 A:deb4  88                                 dey 
 1321 A:deb5  91 48                              sta (zp_sd_address),y
 1322 A:deb7  88                                 dey 
 1323 A:deb8  91 48                              sta (zp_sd_address),y
 1324 A:deba  88                                 dey 
 1325 A:debb  91 48                              sta (zp_sd_address),y

 1327 A:debd                                    ; Write the FAT
 1328 A:debd  20 47 db                           jsr fat32_updatefat

 1330 A:dec0                                    ; And go again for another pass.
 1331 A:dec0  4c a8 de                           jmp chainloop

 1333 A:dec3                           endofchain 
 1334 A:dec3                                    ; This is the last cluster in the chain.

 1336 A:dec3                                    ; Just zero it out,
 1337 A:dec3  a9 00                              lda #0
 1338 A:dec5  91 48                              sta (zp_sd_address),y
 1339 A:dec7  88                                 dey 
 1340 A:dec8  91 48                              sta (zp_sd_address),y
 1341 A:deca  88                                 dey 
 1342 A:decb  91 48                              sta (zp_sd_address),y
 1343 A:decd  88                                 dey 
 1344 A:dece  91 48                              sta (zp_sd_address),y

 1346 A:ded0                                    ; Write the FAT
 1347 A:ded0  20 47 db                           jsr fat32_updatefat

 1349 A:ded3                                    ; And we're done!
 1350 A:ded3  18                                 clc 
 1351 A:ded4  60                                 rts 
 1352 A:ded5                                     .) 

 1354 A:ded5                           fat32_file_readbyte 
 1354 A:ded5                                    
 1355 A:ded5                                     .( 
 1356 A:ded5                                    ; Read a byte from an open file
 1357 A:ded5                                    ;
 1358 A:ded5                                    ; The byte is returned in A with C clear; or if end-of-file was reached, C is set instead

 1360 A:ded5  38                                 sec 

 1362 A:ded6                                    ; Is there any data to read at all?
 1363 A:ded6  a5 62                              lda fat32_bytesremaining
 1364 A:ded8  05 63                              ora fat32_bytesremaining+1
 1365 A:deda  05 64                              ora fat32_bytesremaining+2
 1366 A:dedc  05 65                              ora fat32_bytesremaining+3
 1367 A:dede  f0 3d                              beq rtss

 1369 A:dee0                                    ; Decrement the remaining byte count
 1370 A:dee0  a5 62                              lda fat32_bytesremaining
 1371 A:dee2  e9 01                              sbc #1
 1372 A:dee4  85 62                              sta fat32_bytesremaining
 1373 A:dee6  a5 63                              lda fat32_bytesremaining+1
 1374 A:dee8  e9 00                              sbc #0
 1375 A:deea  85 63                              sta fat32_bytesremaining+1
 1376 A:deec  a5 64                              lda fat32_bytesremaining+2
 1377 A:deee  e9 00                              sbc #0
 1378 A:def0  85 64                              sta fat32_bytesremaining+2
 1379 A:def2  a5 65                              lda fat32_bytesremaining+3
 1380 A:def4  e9 00                              sbc #0
 1381 A:def6  85 65                              sta fat32_bytesremaining+3

 1383 A:def8                                    ; Need to read a new sector?
 1384 A:def8  a5 49                              lda zp_sd_address+1
 1385 A:defa  c9 07                              cmp #>(fat32_readbuffer+$0200)
 1386 A:defc  90 0d                              bcc gotdata

 1388 A:defe                                    ; Read another sector
 1389 A:defe  a9 00                              lda #<fat32_readbuffer
 1390 A:df00  85 5c                              sta fat32_address
 1391 A:df02  a9 05                              lda #>fat32_readbuffer
 1392 A:df04  85 5d                              sta fat32_address+1

 1394 A:df06  20 ea da                           jsr fat32_readnextsector
 1395 A:df09  b0 12                              bcs rtss

 1397 A:df0b                           gotdata   
 1397 A:df0b                                    
 1398 A:df0b  a0 00                              ldy #0
 1399 A:df0d  b1 48                              lda (zp_sd_address),y

 1401 A:df0f  e6 48                              inc zp_sd_address
 1402 A:df11  d0 0a                              bne rtss
 1403 A:df13  e6 49                              inc zp_sd_address+1
 1404 A:df15  d0 06                              bne rtss
 1405 A:df17  e6 4a                              inc zp_sd_address+2
 1406 A:df19  d0 02                              bne rtss
 1407 A:df1b  e6 4b                              inc zp_sd_address+3

 1409 A:df1d                           rtss      
 1409 A:df1d                                    
 1410 A:df1d  60                                 rts 
 1411 A:df1e                                     .) 

 1413 A:df1e                           fat32_file_read 
 1413 A:df1e                                    
 1414 A:df1e                                     .( 
 1415 A:df1e                                    ; Read a whole file into memory.  It's assumed the file has just been opened 
 1416 A:df1e                                    ; and no data has been read yet.
 1417 A:df1e                                    ;
 1418 A:df1e                                    ; Also we read whole sectors, so data in the target region beyond the end of the 
 1419 A:df1e                                    ; file may get overwritten, up to the next 512-byte boundary.
 1420 A:df1e                                    ;
 1421 A:df1e                                    ; And we don't properly support 64k+ files, as it's unnecessary complication given
 1422 A:df1e                                    ; the 6502's small address space

 1424 A:df1e                                    ; Round the size up to the next whole sector
 1425 A:df1e  a5 62                              lda fat32_bytesremaining
 1426 A:df20  c9 01                              cmp #1             ; set carry if bottom 8 bits not zero
 1427 A:df22  a5 63                              lda fat32_bytesremaining+1
 1428 A:df24  69 00                              adc #0             ; add carry, if any
 1429 A:df26  4a                                 lsr                    ; divide by 2
 1430 A:df27  69 00                              adc #0             ; round up

 1432 A:df29                                    ; No data?
 1433 A:df29  f0 12                              beq donee

 1435 A:df2b                                    ; Store sector count - not a byte count any more
 1436 A:df2b  85 62                              sta fat32_bytesremaining

 1438 A:df2d                                    ; Read entire sectors to the user-supplied buffer
 1439 A:df2d                           wholesectorreadloop 
 1439 A:df2d                                    
 1440 A:df2d                                    ; Read a sector to fat32_address
 1441 A:df2d  20 ea da                           jsr fat32_readnextsector

 1443 A:df30                                    ; Advance fat32_address by 512 bytes
 1444 A:df30  a5 5d                              lda fat32_address+1
 1445 A:df32  69 02                              adc #2             ; carry already clear
 1446 A:df34  85 5d                              sta fat32_address+1

 1448 A:df36  a6 62                              ldx fat32_bytesremaining                ; note - actually loads sectors remaining
 1449 A:df38  ca                                 dex 
 1450 A:df39  86 62                              stx fat32_bytesremaining                ; note - actually stores sectors remaining

 1452 A:df3b  d0 f0                              bne wholesectorreadloop

 1454 A:df3d                           donee     
 1454 A:df3d                                    
 1455 A:df3d  60                                 rts 
 1456 A:df3e                                     .) 

 1458 A:df3e                           fat32_file_write 
 1458 A:df3e                                    
 1459 A:df3e                                     .( 
 1460 A:df3e                                    ; Write a whole file from memory.  It's assumed the file has just been opened 
 1461 A:df3e                                    ; and no data has been written yet.

 1463 A:df3e                                    ; Start at the first cluster for this file
 1464 A:df3e  a5 77                              lda fat32_filecluster
 1465 A:df40  85 6a                              sta fat32_lastcluster
 1466 A:df42  a5 78                              lda fat32_filecluster+1
 1467 A:df44  85 6b                              sta fat32_lastcluster+1
 1468 A:df46  a5 79                              lda fat32_filecluster+2
 1469 A:df48  85 6c                              sta fat32_lastcluster+2
 1470 A:df4a  a5 7a                              lda fat32_filecluster+3
 1471 A:df4c  85 6d                              sta fat32_lastcluster+3

 1473 A:df4e  a5 77                              lda fat32_filecluster
 1474 A:df50  85 5e                              sta fat32_nextcluster
 1475 A:df52  a5 78                              lda fat32_filecluster+1
 1476 A:df54  85 5f                              sta fat32_nextcluster+1
 1477 A:df56  a5 79                              lda fat32_filecluster+2
 1478 A:df58  85 60                              sta fat32_nextcluster+2
 1479 A:df5a  a5 7a                              lda fat32_filecluster+3
 1480 A:df5c  85 61                              sta fat32_nextcluster+3

 1482 A:df5e                                    ; Round the size up to the next whole sector
 1483 A:df5e  a5 62                              lda fat32_bytesremaining
 1484 A:df60  c9 01                              cmp #1             ; set carry if bottom 8 bits not zero
 1485 A:df62  a5 63                              lda fat32_bytesremaining+1
 1486 A:df64  69 00                              adc #0             ; add carry, if any
 1487 A:df66  4a                                 lsr                    ; divide by 2
 1488 A:df67  69 00                              adc #0             ; round up

 1490 A:df69                                    ; No data?
 1491 A:df69  f0 15                              beq fail

 1493 A:df6b                                    ; Store sector count - not a byte count anymore.
 1494 A:df6b  85 62                              sta fat32_bytesremaining

 1496 A:df6d                                    ; We will be making a new cluster the first time around
 1497 A:df6d  64 5b                              stz fat32_pendingsectors

 1499 A:df6f                                    ; Write entire sectors from the user-supplied buffer
 1500 A:df6f                           wholesectorwriteloop 
 1500 A:df6f                                    
 1501 A:df6f                                    ; Write a sector from fat32_address
 1502 A:df6f  20 15 db                           jsr fat32_writenextsector
 1503 A:df72                                    ;bcs fail ; this shouldn't happen

 1505 A:df72  18                                 clc 
 1506 A:df73                                    ; Advance fat32_address by 512 bytes
 1507 A:df73  a5 5d                              lda fat32_address+1
 1508 A:df75  69 02                              adc #2             ; carry already clear
 1509 A:df77  85 5d                              sta fat32_address+1

 1511 A:df79  a6 62                              ldx fat32_bytesremaining                ; note - actually loads sectors remaining
 1512 A:df7b  ca                                 dex 
 1513 A:df7c  86 62                              stx fat32_bytesremaining                ; note - actually stores sectors remaining

 1515 A:df7e  d0 ef                              bne wholesectorwriteloop

 1517 A:df80                                    ; Done!
 1518 A:df80                           fail      
 1519 A:df80  60                                 rts 
 1520 A:df81                                     .) 

 1522 A:df81                           fat32_open_cd 
 1522 A:df81                                    
 1523 A:df81                                    ; Prepare to read from a file or directory based on a dirent
 1524 A:df81                                    ;

 1526 A:df81  48                                 pha 
 1527 A:df82  da                                 phx 
 1528 A:df83  5a                                 phy 

 1530 A:df84                                    ; Seek to first cluster of current directory
 1531 A:df84  a5 7f                              lda fat32_cdcluster
 1532 A:df86  85 5e                              sta fat32_nextcluster
 1533 A:df88  a5 80                              lda fat32_cdcluster+1
 1534 A:df8a  85 5f                              sta fat32_nextcluster+1
 1535 A:df8c  a5 81                              lda fat32_cdcluster+2
 1536 A:df8e  85 60                              sta fat32_nextcluster+2
 1537 A:df90  a5 82                              lda fat32_cdcluster+3
 1538 A:df92  85 61                              sta fat32_nextcluster+3

 1540 A:df94  a9 00                              lda #<fat32_readbuffer
 1541 A:df96  85 5c                              sta fat32_address
 1542 A:df98  a9 05                              lda #>fat32_readbuffer
 1543 A:df9a  85 5d                              sta fat32_address+1

 1545 A:df9c  18                                 clc 
 1546 A:df9d  20 0c da                           jsr fat32_seekcluster

 1548 A:dfa0                                    ; Set the pointer to a large value so we always read a sector the first time through
 1549 A:dfa0  a9 ff                              lda #$ff
 1550 A:dfa2  85 49                              sta zp_sd_address+1

 1552 A:dfa4  7a                                 ply 
 1553 A:dfa5  fa                                 plx 
 1554 A:dfa6  68                                 pla 
 1555 A:dfa7  60                                 rts 

main.a65


 2562 A:dfa8                                    ; include ACIA library

acia.a65

    1 A:dfa8                                    ;;;       ------------------ 6551 ACIA Subroutine Library -------------------
    2 A:dfa8                                    ;;; Includes
    2 A:dfa8                                    
    3 A:dfa8                                    ;;; acia_init       - Initializes the ACIA
    4 A:dfa8                                    ;;; print_hex_acia  - Prints a hex value in A
    5 A:dfa8                                    ;;; clear_display   - Sends a <CLS> command
    6 A:dfa8                                    ;;; txpoll          - Polls the TX bit to see if the ACIA is ready
    7 A:dfa8                                    ;;; print_chara     - Prints a Character that is stored in A
    8 A:dfa8                                    ;;; print_char_acia - Same as print_chara
    9 A:dfa8                                    ;;; ascii_home      - Home the cursor
   10 A:dfa8                                    ;;; w_acia_full     - Print a NULL-Termintated String with >HIGH in Y and <LOW in X

   12 A:dfa8                           acia_init 
   13 A:dfa8  48                                 pha 
   14 A:dfa9  a9 0b                              lda #%00001011             ; No parity, no echo, no interrupt
   15 A:dfab  8d 02 80                           sta $8002
   16 A:dfae  a9 1f                              lda #%00011111             ; 1 stop bit, 8 data bits, 19200 baud
   17 A:dfb0  8d 03 80                           sta $8003
   18 A:dfb3  68                                 pla 
   19 A:dfb4  60                                 rts 

   21 A:dfb5                           print_hex_acia 
   22 A:dfb5  48                                 pha 
   23 A:dfb6  6a                                 ror 
   24 A:dfb7  6a                                 ror 
   25 A:dfb8  6a                                 ror 
   26 A:dfb9  6a                                 ror 
   27 A:dfba  20 be df                           jsr print_nybble                ; This is just som usful hex cod
   28 A:dfbd  68                                 pla 
   29 A:dfbe                           print_nybble 
   30 A:dfbe  29 0f                              and #15
   31 A:dfc0  c9 0a                              cmp #10
   32 A:dfc2  30 02                              bmi skipletter
   33 A:dfc4  69 06                              adc #6
   34 A:dfc6                           skipletter 
   35 A:dfc6  69 30                              adc #48
   36 A:dfc8                                    ; jsr print_char
   37 A:dfc8  20 df df                           jsr print_chara
   38 A:dfcb  60                                 rts 

   40 A:dfcc                           cleardisplay 
   41 A:dfcc  48                                 pha 
   42 A:dfcd  20 d7 df                           jsr txpoll                ; Poll the TX bit
   43 A:dfd0  a9 0c                              lda #12             ; Print decimal 12 (CLS)
   44 A:dfd2  8d 00 80                           sta $8000
   45 A:dfd5  68                                 pla 
   46 A:dfd6  60                                 rts 

   48 A:dfd7                           txpoll    
   49 A:dfd7  ad 01 80                           lda $8001
   50 A:dfda  29 10                              and #$10             ; Poll the TX bit
   51 A:dfdc  f0 f9                              beq txpoll
   52 A:dfde  60                                 rts 

   54 A:dfdf                           print_char_acia                  ; same command
   55 A:dfdf                           print_chara 
   56 A:dfdf  48                                 pha 
   57 A:dfe0  20 d7 df                           jsr txpoll                ; Poll the TX bit
   58 A:dfe3  68                                 pla 
   59 A:dfe4  8d 00 80                           sta $8000              ; Print character from A
   60 A:dfe7  60                                 rts 

   62 A:dfe8                           ascii_home 
   63 A:dfe8  48                                 pha 
   64 A:dfe9  a9 01                              lda #1
   65 A:dfeb  20 df df                           jsr print_chara                ; Print 1 (HOME)
   66 A:dfee  68                                 pla 
   67 A:dfef  60                                 rts 

   69 A:dff0                                    ; TODO FIX VARIABLES

   71 A:dff0                           w_acia_full 
   72 A:dff0  48                                 pha 
   73 A:dff1  a5 ff                              lda $ff
   74 A:dff3  48                                 pha                    ; Push Previous States onto the stack
   75 A:dff4  a5 fe                              lda $fe
   76 A:dff6  48                                 pha 
   77 A:dff7  84 ff                              sty $ff              ; Set Y as the Upper Address (8-15)
   78 A:dff9  86 fe                              stx $fe              ; Set X as the Lower Adderss (0-7)
   79 A:dffb  a0 00                              ldy #0
   80 A:dffd                           acia_man  
   81 A:dffd  20 d7 df                           jsr txpoll                ; Poll TX
   82 A:e000  b1 fe                              lda ($fe),y          ; Load the Address
   83 A:e002  8d 00 80                           sta $8000              ; Print what is at the address
   84 A:e005  f0 04                              beq endwacia                ; If Done, End
   85 A:e007  c8                                 iny                    ; Next Character
   86 A:e008  4c fd df                           jmp acia_man                ; Back to the top
   87 A:e00b                           endwacia  
   88 A:e00b  68                                 pla 
   89 A:e00c  85 fe                              sta $fe
   90 A:e00e  68                                 pla                    ; Restore Variables
   91 A:e00f  85 ff                              sta $ff
   92 A:e011  68                                 pla 
   93 A:e012  60                                 rts 

main.a65


 2565 A:e013                                    ; error sound
 2566 A:e013                           error_sound 
 2566 A:e013                                    
 2567 A:e013  20 5b e0                           jsr clear_sid
 2568 A:e016  a9 06                              lda #$06
 2569 A:e018  85 0c                              sta mem_copy
 2570 A:e01a  a9 10                              lda #$10
 2571 A:e01c  85 0d                              sta mem_copy+1
 2572 A:e01e  a9 09                              lda #<sounddata
 2573 A:e020  85 0a                              sta mem_source
 2574 A:e022  a9 c4                              lda #>sounddata
 2575 A:e024  85 0b                              sta mem_source+1
 2576 A:e026  a9 0a                              lda #$0a
 2577 A:e028  85 0e                              sta mem_end
 2578 A:e02a  a9 11                              lda #$11
 2579 A:e02c  85 0f                              sta mem_end+1
 2580 A:e02e  20 4b e9                           jsr memcopy
 2581 A:e031  a9 0a                              lda #$0a
 2582 A:e033  85 0c                              sta mem_copy
 2583 A:e035  a9 11                              lda #$11
 2584 A:e037  85 0d                              sta mem_copy+1
 2585 A:e039  a9 64                              lda #<errordat
 2586 A:e03b  85 0a                              sta mem_source
 2587 A:e03d  a9 e0                              lda #>errordat
 2588 A:e03f  85 0b                              sta mem_source+1
 2589 A:e041  a9 2e                              lda #$2e
 2590 A:e043  85 0e                              sta mem_end
 2591 A:e045  a9 12                              lda #$12
 2592 A:e047  85 0f                              sta mem_end+1
 2593 A:e049  20 4b e9                           jsr memcopy
 2594 A:e04c  a9 55                              lda #$55
 2595 A:e04e  85 00                              sta donefact
 2596 A:e050  64 01                              stz irqcount
 2597 A:e052  a9 0f                              lda #$0f
 2598 A:e054  8d 18 b8                           sta $b818
 2599 A:e057  20 c0 c3                           jsr runthesound
 2600 A:e05a  60                                 rts 

 2602 A:e05b                           clear_sid 
 2603 A:e05b  a2 17                              ldx #$17
 2604 A:e05d                           csid      
 2605 A:e05d  9e 00 b8                           stz $b800,x
 2606 A:e060  ca                                 dex 
 2607 A:e061  d0 fa                              bne csid
 2608 A:e063  60                                 rts 

 2610 A:e064                                    ; error sound
 2611 A:e064                           errordat  
 2611 A:e064                                    
 2612 A:e064  f0 0f 77 11 01 00                  .byt $f0,$0f,$77,$11,$01,$00
 2613 A:e06a  12 0d 04 05 0b 14 08 ...           .byt $12,$0d,$04,$05,$0b,$14,$08,$09,$07,$06,$0c,$03,$0e,$0f,$10,$11
 2614 A:e07a  17 13 0a 15 16 18 02 ...           .byt $17,$13,$0a,$15,$16,$18,$02,$00,$b6,$00,$6e,$b6,$01,$16,$ff,$3e
 2615 A:e08a  03 20 f0 41 08 20 ff ...           .byt $03,$20,$f0,$41,$08,$20,$ff,$f0,$00,$fd,$00,$00,$00,$07,$ff,$00
 2616 A:e09a  00 fd 07 00 00 07 1e ...           .byt $00,$fd,$07,$00,$00,$07,$1e,$00,$00,$0f,$fd,$06,$16,$6e,$06,$3e
 2617 A:e0aa  03 ff 16 6e 08 00 08 ...           .byt $03,$ff,$16,$6e,$08,$00,$08,$00,$08,$63,$00,$00,$00,$40,$00,$ff
 2618 A:e0ba  3e 03 20 f0 41 08 20 ...           .byt $3e,$03,$20,$f0,$41,$08,$20,$9f,$f0,$00,$fd,$00,$07,$bf,$00,$00
 2619 A:e0ca  fd 07 00 07 0e 00 00 ...           .byt $fd,$07,$00,$07,$0e,$00,$00,$0f,$11,$2d,$00,$fd,$11,$4a,$a0,$11
 2620 A:e0da  4a a0 11 4a a0 11 4a ...           .byt $4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a
 2621 A:e0ea  a0 11 4a a0 11 4a a0 ...           .byt $a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0
 2622 A:e0fa  11 4a a0 11 4a a0 11 ...           .byt $11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11
 2623 A:e10a  4a a0 11 4a a0 11 4a ...           .byt $4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a
 2624 A:e11a  a0 11 4a a0 11 4a a0 ...           .byt $a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0
 2625 A:e12a  11 4a a0 11 4a a0 11 ...           .byt $11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11
 2626 A:e13a  4a a0 11 4a a0 11 4a ...           .byt $4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a
 2627 A:e14a  a0 11 4a a0 11 4a a0 ...           .byt $a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0
 2628 A:e15a  11 4a a0 11 4a a0 11 ...           .byt $11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11
 2629 A:e16a  4a a0 11 4a a0 11 4a ...           .byt $4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a
 2630 A:e17a  a0 11 4a a0 11 4a a0 ...           .byt $a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a2,$00,$fe

 2632 A:e189                           subdirname 
 2633 A:e189  52 4f 4f 54 20 20 20 ...           .byt "ROOT       "
 2634 A:e194                           filename  
 2635 A:e194  43 4f 44 45 20 20 20 ...           .byt "CODE    XPL"
 2636 A:e19f                           loadname  
 2637 A:e19f  4c 4f 41 44 41 44 44 ...           .byt "LOADADDRSAR"
 2638 A:e1aa                           fat_error 
 2639 A:e1aa  46 41 54 33 32 20 45 ...           .byt "FAT32 Error At Stage ",$00

 2641 A:e1c0                                    ; include xplDOS system

xpldos.a65

    1 A:e1c0                                    ;; xplDOS
    2 A:e1c0                                    ;; *NIX-esque SD Card Navigation system.
    3 A:e1c0                                    ;;
    4 A:e1c0                                    ;; the first byte of path is 0 if there was an init error.
    5 A:e1c0                                    ;; otherwise it is a index to PATH for the empty space after the last foldername
    6 A:e1c0                                    ;; to calculate what value 0 is when v is PATH+0 and f is the amount of folders, use
    6 A:e1c0                                    
    7 A:e1c0                                    ;; v = 11f+1
    8 A:e1c0                                    ;; for example
    8 A:e1c0                                    
    9 A:e1c0                                    ;; 23,"FOLDER     ", "TEST       ", $00 <--path points here (11+11+1=23)
   10 A:e1c0                                    ;; BUG root usage is not possible, thus, it is required that we are in a folder (ls does not seem to like reading the SD root.)
   11 A:e1c0                                    ;; TODO add path support to a typed command
   12 A:e1c0                                    ;; TODO need to add /path support to file-based commands  
   13 A:e1c0                                    ;; Commands
   13 A:e1c0                                    
   14 A:e1c0                                    ;; CD
   15 A:e1c0                                    ;; LS
   16 A:e1c0                                    ;; LOAD
   17 A:e1c0                                    ;; CAT
   18 A:e1c0                                    ;; SAVE
   19 A:e1c0                                    ;; RM
   20 A:e1c0                                    ;; MV
   21 A:e1c0                                    ;; upcoming commands (TODO)
   21 A:e1c0                                    
   22 A:e1c0                                    ;; MKDIR
   23 A:e1c0                                    ;; CP
   24 A:e1c0                                    ;; TAR?
   25 A:e1c0                                    ;; MAN?

   27 A:e1c0                                    ; Jump to / dir
   28 A:e1c0                                    ; jumps to a dir with a /
   29 A:e1c0                                    ; temp addr at "tmp"
   30 A:e1c0                                    ;
   31 A:e1c0                                    ; NOTE
   31 A:e1c0                           NOT FUNCTIONAL YET 

   33 A:e1c0                                    ;jmpdir
   33 A:e1c0                                    
   34 A:e1c0                                    ;.(
   35 A:e1c0                                    ;  ; stash folderpointer
   36 A:e1c0                                    ;  lda folderpointer
   37 A:e1c0                                    ;  sta pathindex
   38 A:e1c0                                    ;  lda folderpointer+1
   39 A:e1c0                                    ;  sta pathindex+1
   40 A:e1c0                                    ;  lda #<tmp
   41 A:e1c0                                    ;  sta folderpointer
   42 A:e1c0                                    ;  lda #>tmp
   43 A:e1c0                                    ;  sta folderpointer+1
   44 A:e1c0                                    ;  ; check if there is a slash at all
   45 A:e1c0                                    ;  ldy #0
   46 A:e1c0                                    ;chklp
   46 A:e1c0                                    
   47 A:e1c0                                    ;  lda (pathindex),y
   48 A:e1c0                                    ;  beq no
   49 A:e1c0                                    ;  cmp '/'
   50 A:e1c0                                    ;  beq css
   51 A:e1c0                                    ;  iny
   52 A:e1c0                                    ;  jmp chklp
   53 A:e1c0                                    ;css
   53 A:e1c0                                    
   54 A:e1c0                                    ;  cpy #0 ; was the / at the start? ex. "ls /folder"
   55 A:e1c0                                    ;  beq root ;      ^   
   56 A:e1c0                                    ;  ; ok. the path is relative. (ls test/hi) NOT root (ls /test/hi)  
   57 A:e1c0                                    ;  ; now incrementally cd
   58 A:e1c0                                    ;  ldy #0
   59 A:e1c0                                    ;  jmp cse
   60 A:e1c0                                    ;cslp
   60 A:e1c0                                    
   61 A:e1c0                                    ;  lda (pathindex),y
   62 A:e1c0                                    ;  beq csdone
   63 A:e1c0                                    ;  cmp '/' ; / ?
   64 A:e1c0                                    ;  beq csdn
   65 A:e1c0                                    ;  iny
   66 A:e1c0                                    ;  jmp cslp
   67 A:e1c0                                    ;csdn
   67 A:e1c0                                    
   68 A:e1c0                                    ;  iny
   69 A:e1c0                                    ;cse
   69 A:e1c0                                    
   70 A:e1c0                                    ;  ; a dot?
   71 A:e1c0                                    ;;  lda (pathindex),y
   72 A:e1c0                                    ;;  cmp #$2e
   73 A:e1c0                                    ;;  bne csnd
   74 A:e1c0                                    ;;  iny
   75 A:e1c0                                    ;;  lda (pathindex),y 
   76 A:e1c0                                    ;;  cmp #$2e
   77 A:e1c0                                    ;;  bne csndd
   78 A:e1c0                                    ;;  ; if .. then go back
   79 A:e1c0                                    ;;  jsr backpath
   80 A:e1c0                                    ;;  lda dircnt
   81 A:e1c0                                    ;;  bne csnd
   82 A:e1c0                                    ;;  ; auugh
   83 A:e1c0                                    ;;  jmp csnd
   84 A:e1c0                                    ;;csndd
   84 A:e1c0                                    
   85 A:e1c0                                    ;;  ; if . then do nothing
   86 A:e1c0                                    ;;  dey
   87 A:e1c0                                    ;;csnd
   87 A:e1c0                                    
   88 A:e1c0                                    ;  inc dircnt
   89 A:e1c0                                    ;  ; convert to uppercase
   90 A:e1c0                                    ;  ; first copy to temp addr
   91 A:e1c0                                    ;  phy
   92 A:e1c0                                    ;  ldx #0
   93 A:e1c0                                    ;csclp
   93 A:e1c0                                    
   94 A:e1c0                                    ;  lda (pathindex),y
   95 A:e1c0                                    ;  beq scn
   96 A:e1c0                                    ;  cmp #'/'
   97 A:e1c0                                    ;  beq scn
   98 A:e1c0                                    ;  sta tmp,x
   99 A:e1c0                                    ;  iny
  100 A:e1c0                                    ;  inx
  101 A:e1c0                                    ;  jmp csclp
  102 A:e1c0                                    ;scn
  102 A:e1c0                                    
  103 A:e1c0                                    ;  lda #$2e
  104 A:e1c0                                    ;  sta tmp,x
  105 A:e1c0                                    ;  inx
  106 A:e1c0                                    ;  lda #$20
  107 A:e1c0                                    ;  ldy #0
  108 A:e1c0                                    ;scnl
  108 A:e1c0                                    
  109 A:e1c0                                    ;  sta tmp,x
  110 A:e1c0                                    ;  inx
  111 A:e1c0                                    ;  iny
  112 A:e1c0                                    ;  cpy #3
  113 A:e1c0                                    ;  bne scnl
  114 A:e1c0                                    ;  ply
  115 A:e1c0                                    ;  ; then convert
  116 A:e1c0                                    ;  jsr shortconvert
  117 A:e1c0                                    ;  jsr addpath ; add it
  118 A:e1c0                                    ;  ; next folder
  119 A:e1c0                                    ;  clc
  120 A:e1c0                                    ;  tya
  121 A:e1c0                                    ;  adc folderpointer
  122 A:e1c0                                    ;  sta folderpointer
  123 A:e1c0                                    ;  jmp cslp
  124 A:e1c0                                    ;csdone
  124 A:e1c0                                    
  125 A:e1c0                                    ;  lda pathindex
  126 A:e1c0                                    ;  sta folderpointer
  127 A:e1c0                                    ;  lda pathindex+1
  128 A:e1c0                                    ;  sta folderpointer+1
  129 A:e1c0                                    ;  jsr fat32_open_cd ; load it
  130 A:e1c0                                    ;  ; all done
  131 A:e1c0                                    ;  clc
  132 A:e1c0                                    ;  rts
  133 A:e1c0                                    ;root
  133 A:e1c0                                    
  134 A:e1c0                                    ;  ; root !!
  135 A:e1c0                                    ;  ldx #<rootmsg
  136 A:e1c0                                    ;  ldy #>rootmsg
  137 A:e1c0                                    ;  jsr w_acia_full
  138 A:e1c0                                    ;no
  138 A:e1c0                                    
  139 A:e1c0                                    ;  ; no / dir
  140 A:e1c0                                    ;  ; proceed normally
  141 A:e1c0                                    ;  stz dircnt
  142 A:e1c0                                    ;  lda pathindex
  143 A:e1c0                                    ;  sta folderpointer
  144 A:e1c0                                    ;  lda pathindex+1
  145 A:e1c0                                    ;  sta folderpointer+1
  146 A:e1c0                                    ;  sec
  147 A:e1c0                                    ;  rts
  148 A:e1c0                                    ;.)
  149 A:e1c0                                    ;
  150 A:e1c0                                    ;rootmsg
  150 A:e1c0                                    
  151 A:e1c0                                    ;  .byte "Root Not Yet Supported! Use ", $22, "folder", $22, " instead", $0d, $0a, $00

  153 A:e1c0                                    ; PATH refresh
  154 A:e1c0                                    ; goes to the ROOT directory, and CDs to the directory at PATH.
  155 A:e1c0                                    ;
  156 A:e1c0                                    ; this is probably equivilent to "Refresh" in Microsoft Windows.
  157 A:e1c0                           refreshpath 
  157 A:e1c0                                    
  158 A:e1c0                                     .( 
  159 A:e1c0                                    ; No memory card?
  160 A:e1c0  ad 00 04                           lda path
  161 A:e1c3  f0 26                              beq patherr
  162 A:e1c5  a9 01                              lda #1             ; path+1 because path+0 is the path size variable
  163 A:e1c7  85 16                              sta pathindex
  164 A:e1c9                                    ; If memory card, then goto dir
  165 A:e1c9  20 9c db                           jsr fat32_openroot
  166 A:e1cc                           rloop     
  166 A:e1cc                                    
  167 A:e1cc                                    ; Open the directory
  168 A:e1cc  a6 16                              ldx pathindex
  169 A:e1ce  a0 04                              ldy #>path
  170 A:e1d0  20 5b de                           jsr fat32_finddirent
  171 A:e1d3  90 03                              bcc fine
  172 A:e1d5  4c f4 e1                           jmp rlerror
  173 A:e1d8                           fine      
  173 A:e1d8                                    
  174 A:e1d8  20 e1 dc                           jsr fat32_opendirent
  175 A:e1db                                    ; advance to the next directory
  176 A:e1db  18                                 clc 
  177 A:e1dc  a5 16                              lda pathindex
  178 A:e1de  69 0b                              adc #11
  179 A:e1e0  85 16                              sta pathindex
  180 A:e1e2                                    ;lda (pathindex) ; end of path?
  181 A:e1e2  ad 00 04                           lda path
  182 A:e1e5  c5 16                              cmp pathindex
  183 A:e1e7  d0 e3                              bne rloop                ; if not, cd to the next directory
  184 A:e1e9  18                                 clc 
  185 A:e1ea  60                                 rts 
  186 A:e1eb                                     .) 
  187 A:e1eb                           patherr   
  187 A:e1eb                                    
  188 A:e1eb  a2 34                              ldx #<patherror
  189 A:e1ed  a0 e2                              ldy #>patherror
  190 A:e1ef  20 f0 df                           jsr w_acia_full
  191 A:e1f2  38                                 sec 
  192 A:e1f3  60                                 rts 
  193 A:e1f4                           rlerror   
  193 A:e1f4                                    
  194 A:e1f4  a2 f4                              ldx #<foldermsg
  195 A:e1f6  a0 e7                              ldy #>foldermsg
  196 A:e1f8  20 f0 df                           jsr w_acia_full
  197 A:e1fb  20 13 e0                           jsr error_sound
  198 A:e1fe  38                                 sec 
  199 A:e1ff  60                                 rts 

  201 A:e200                                    ; add PATH
  202 A:e200                                    ; adds a SHORT formatted folder at (folderpointer) to the PATH variable.
  203 A:e200                           addpath   
  203 A:e200                                    
  204 A:e200                                     .( 
  205 A:e200  48                                 pha 
  206 A:e201  da                                 phx 
  207 A:e202  5a                                 phy 
  208 A:e203  a0 00                              ldy #0
  209 A:e205  ae 00 04                           ldx path
  210 A:e208                           aplp      
  210 A:e208                                    
  211 A:e208  b1 11                              lda (folderpointer),y
  212 A:e20a  9d 00 04                           sta path,x
  213 A:e20d  c8                                 iny 
  214 A:e20e  e8                                 inx 
  215 A:e20f  c0 0b                              cpy #11
  216 A:e211  d0 f5                              bne aplp
  217 A:e213  9e 00 04                           stz path,x
  218 A:e216  8e 00 04                           stx path
  219 A:e219  7a                                 ply 
  220 A:e21a  fa                                 plx 
  221 A:e21b  68                                 pla 
  222 A:e21c  60                                 rts 
  223 A:e21d                                     .) 

  225 A:e21d                                    ; delete PATH
  226 A:e21d                                    ; goes back a directory, used in cd ..
  227 A:e21d                           backpath  
  227 A:e21d                                    
  228 A:e21d                                     .( 
  229 A:e21d  da                                 phx 
  230 A:e21e  48                                 pha 
  231 A:e21f  38                                 sec 
  232 A:e220  ad 00 04                           lda path
  233 A:e223  e9 0b                              sbc #11             ; remove dir
  234 A:e225  8d 00 04                           sta path
  235 A:e228  ae 00 04                           ldx path
  236 A:e22b  9e 00 04                           stz path,x
  237 A:e22e  20 c0 e1                           jsr refreshpath
  238 A:e231  68                                 pla 
  239 A:e232  fa                                 plx 
  240 A:e233  60                                 rts 
  241 A:e234                                     .) 

  243 A:e234                           patherror 
  243 A:e234                                    
  244 A:e234  4e 6f 20 4d 65 6d 6f ...           .byt "No Memory Card.",$0d,$0a,$00

  246 A:e246                                    ;; print PATH
  247 A:e246                                    ;; prints the current directory, like *NIX
  248 A:e246                                    ;; for example
  248 A:e246                                    
  249 A:e246                                    ;; ~/test/ >_
  250 A:e246                                    ;; or
  250 A:e246                                    
  251 A:e246                                    ;; ~/ >_
  252 A:e246                                    ;;
  253 A:e246                           printpath 
  253 A:e246                                    
  254 A:e246                                     .( 
  255 A:e246                                    ; No memory card?
  256 A:e246  ad 00 04                           lda path
  257 A:e249  d0 02                              bne ppb
  258 A:e24b  38                                 sec 
  259 A:e24c  60                                 rts 
  260 A:e24d                                    ;jmp rlerror
  261 A:e24d                           ppb       
  262 A:e24d                                    ; sould this be $fb? (square root symbol)
  263 A:e24d                                    ; for now it's ~
  264 A:e24d  a9 7e                              lda #$7e             ; root
  265 A:e24f  20 df df                           jsr print_chara
  266 A:e252                           ppc       
  266 A:e252                                    
  267 A:e252  a9 2f                              lda #'/'
  268 A:e254  20 df df                           jsr print_chara
  269 A:e257  a9 0c                              lda #12             ; path+12 because we already showed the root
  270 A:e259  85 16                              sta pathindex
  271 A:e25b  a9 04                              lda #>path
  272 A:e25d  85 17                              sta pathindex+1
  273 A:e25f  a0 00                              ldy #0
  274 A:e261                           pplp      
  274 A:e261                                    
  275 A:e261                                    ; loop through path and print the folder, in lowercase
  276 A:e261  b1 16                              lda (pathindex),y
  277 A:e263  f0 23                              beq ppdone                ; exit if only root
  278 A:e265  c9 20                              cmp #$20             ; space?
  279 A:e267  f0 09                              beq ppd
  280 A:e269  09 20                              ora #$20             ; if not, print (in lowercase)
  281 A:e26b  20 df df                           jsr print_chara
  282 A:e26e  c8                                 iny 
  283 A:e26f  4c 61 e2                           jmp pplp
  284 A:e272                           ppd       
  284 A:e272                                    
  285 A:e272  a9 2f                              lda #'/'             ; if space, dir done.
  286 A:e274  20 df df                           jsr print_chara
  287 A:e277                           ppdl      
  287 A:e277                                    
  288 A:e277  b1 16                              lda (pathindex),y            ; look for the next entry.
  289 A:e279  c9 20                              cmp #$20
  290 A:e27b  d0 04                              bne notspace
  291 A:e27d  c8                                 iny 
  292 A:e27e  4c 77 e2                           jmp ppdl
  293 A:e281                           notspace  
  293 A:e281                                    
  294 A:e281  b1 16                              lda (pathindex),y            ; end of path?
  295 A:e283  f0 03                              beq ppdone
  296 A:e285  4c 61 e2                           jmp pplp                ; no, print another folder name.
  297 A:e288                           ppdone    
  297 A:e288                                    
  298 A:e288                                    ; Print a space for good spacing
  299 A:e288  a9 20                              lda #$20
  300 A:e28a  20 df df                           jsr print_chara
  301 A:e28d  18                                 clc 
  302 A:e28e  60                                 rts                    ; done!
  303 A:e28f                                     .) 

  305 A:e28f                                    ;; CD
  306 A:e28f                                    ;; Change the directory
  307 A:e28f                                    ;; if you use cdsub, folderpointer holds the address of the folder name

  309 A:e28f                           cdcmd     
  309 A:e28f                                    
  310 A:e28f                                     .( 
  311 A:e28f  da                                 phx 
  312 A:e290  ad 00 04                           lda path
  313 A:e293  d0 03                              bne cdf
  314 A:e295  4c eb e1                           jmp patherr
  315 A:e298                           cdf       
  315 A:e298                                    
  316 A:e298                                    ;; check arguments
  317 A:e298  a5 20                              lda ARGINDEX
  318 A:e29a  c9 02                              cmp #2             ; if there's two arguments, change to the specified directory
  319 A:e29c  f0 03                              beq processparam
  320 A:e29e  4c dc e2                           jmp error
  321 A:e2a1                           processparam                  ; process the filename parameter
  322 A:e2a1  18                                 clc 
  323 A:e2a2  a9 00                              lda #<INPUT
  324 A:e2a4  65 22                              adc ARGINDEX+2
  325 A:e2a6  85 11                              sta folderpointer
  326 A:e2a8  a9 02                              lda #>INPUT
  327 A:e2aa  85 12                              sta folderpointer+1
  328 A:e2ac                                     .) 
  329 A:e2ac                           cdd       
  329 A:e2ac                                    
  330 A:e2ac                                     .( 
  331 A:e2ac                                    ; handle dir
  332 A:e2ac                                    ;jsr jmpdir 
  333 A:e2ac                                    ;bcc cdbb
  334 A:e2ac                                    ; check for . or ..
  335 A:e2ac  20 41 e3                           jsr shortconvert
  336 A:e2af  a5 18                              lda backdir
  337 A:e2b1  f0 1c                              beq notcd
  338 A:e2b3  c9 55                              cmp #$55
  339 A:e2b5  f0 16                              beq cdbb
  340 A:e2b7                                    ; ok, that should do it.
  341 A:e2b7                                    ; Open root directory
  342 A:e2b7                                    ;jsr fat32_openroot 
  343 A:e2b7                                    ; Find the subdirectory by name
  344 A:e2b7                                    ;ldx #<subdirname
  345 A:e2b7                                    ;ldy #>subdirname
  346 A:e2b7                                    ;jsr fat32_finddirent
  347 A:e2b7                                    ;bcs error
  348 A:e2b7                                    ; Open subdirectory
  349 A:e2b7                                    ;jsr fat32_opendirent ; open folder
  350 A:e2b7  20 81 df                           jsr fat32_open_cd
  351 A:e2ba                                     .) 
  352 A:e2ba                           cdsub     
  352 A:e2ba                                    
  353 A:e2ba                                    ; check if the folder exists + get info
  354 A:e2ba  a6 11                              ldx folderpointer
  355 A:e2bc  a4 12                              ldy folderpointer+1
  356 A:e2be  20 5b de                           jsr fat32_finddirent
  357 A:e2c1  b0 11                              bcs fileerror
  358 A:e2c3                                    ; ok, it exists, now cd
  359 A:e2c3  20 e1 dc                           jsr fat32_opendirent
  360 A:e2c6                                    ; all done.
  361 A:e2c6                                    ; now add this to the current directory, only if no cd ..
  362 A:e2c6  a5 18                              lda backdir
  363 A:e2c8  f0 03                              beq cdbb
  364 A:e2ca  20 00 e2                           jsr addpath
  365 A:e2cd                           cdbb      
  365 A:e2cd                                    
  366 A:e2cd  fa                                 plx 
  367 A:e2ce  60                                 rts 
  368 A:e2cf                           notcd     
  368 A:e2cf                                    
  369 A:e2cf  20 81 df                           jsr fat32_open_cd
  370 A:e2d2  fa                                 plx 
  371 A:e2d3  60                                 rts 

  373 A:e2d4                           fileerror 
  374 A:e2d4                                    ; no such folder
  375 A:e2d4  a2 f4                              ldx #<foldermsg
  376 A:e2d6  a0 e7                              ldy #>foldermsg
  377 A:e2d8  20 f0 df                           jsr w_acia_full
  378 A:e2db  60                                 rts 

  380 A:e2dc                           error     
  381 A:e2dc  a2 b9                              ldx #<errormsg
  382 A:e2de  a0 f3                              ldy #>errormsg
  383 A:e2e0  20 f0 df                           jsr w_acia_full
  384 A:e2e3  60                                 rts 

  386 A:e2e4                                    ;; CAT
  387 A:e2e4                                    ;; prints out a file

  389 A:e2e4                           catcmd    
  389 A:e2e4                                    
  390 A:e2e4                                     .( 
  391 A:e2e4  ad 00 04                           lda path
  392 A:e2e7  d0 03                              bne cdf
  393 A:e2e9  4c eb e1                           jmp patherr
  394 A:e2ec                           cdf       
  394 A:e2ec                                    
  395 A:e2ec                                    ;; check arguments
  396 A:e2ec  a5 20                              lda ARGINDEX
  397 A:e2ee  c9 02                              cmp #2
  398 A:e2f0  d0 ea                              bne error
  399 A:e2f2  18                                 clc 
  400 A:e2f3  a9 00                              lda #<INPUT
  401 A:e2f5  65 22                              adc ARGINDEX+2
  402 A:e2f7  85 11                              sta folderpointer
  403 A:e2f9  a9 02                              lda #>INPUT
  404 A:e2fb  85 12                              sta folderpointer+1
  405 A:e2fd                                    ; Convert to SHORT
  406 A:e2fd  20 41 e3                           jsr shortconvert
  407 A:e300                                    ; Refresh Path
  408 A:e300  20 81 df                           jsr fat32_open_cd
  409 A:e303                                    ; Find the file
  410 A:e303  a6 11                              ldx folderpointer
  411 A:e305  a4 12                              ldy folderpointer+1
  412 A:e307  20 5b de                           jsr fat32_finddirent
  413 A:e30a  b0 d0                              bcs error
  414 A:e30c                                    ; Open the file
  415 A:e30c  20 e1 dc                           jsr fat32_opendirent
  416 A:e30f                                    ; Read file contents into buffer
  417 A:e30f  a9 00                              lda #<buffer
  418 A:e311  85 5c                              sta fat32_address
  419 A:e313  a9 07                              lda #>buffer
  420 A:e315  85 5d                              sta fat32_address+1
  421 A:e317                           redlp     
  421 A:e317                                    
  422 A:e317  20 d5 de                           jsr fat32_file_readbyte
  423 A:e31a  f0 21                              beq catd
  424 A:e31c  c9 0d                              cmp #$0d
  425 A:e31e  f0 17                              beq notunix
  426 A:e320  4c 28 e3                           jmp unixloop
  427 A:e323                           unix      
  427 A:e323                                    
  428 A:e323  20 d5 de                           jsr fat32_file_readbyte
  429 A:e326  f0 15                              beq catd
  430 A:e328                           unixloop  
  430 A:e328                                    
  431 A:e328  c9 0a                              cmp #$0a
  432 A:e32a  d0 05                              bne notcr
  433 A:e32c  20 df df                           jsr print_chara
  434 A:e32f  a9 0d                              lda #$0d
  435 A:e331                           notcr     
  435 A:e331                                    
  436 A:e331  20 df df                           jsr print_chara
  437 A:e334  4c 23 e3                           jmp unix
  438 A:e337                           notunix   
  438 A:e337                                    
  439 A:e337  20 df df                           jsr print_chara
  440 A:e33a  4c 17 e3                           jmp redlp
  441 A:e33d                           catd      
  441 A:e33d                                    
  442 A:e33d                                    ; CR+LF
  443 A:e33d  20 45 d6                           jsr crlf
  444 A:e340  60                                 rts 
  445 A:e341                                     .) 

  447 A:e341                           shortconvert 
  447 A:e341                                    
  448 A:e341                                     .( 
  449 A:e341                                    ; loop through the null-terminated string at (folderpointer)
  450 A:e341                                    ; and convert it to SHORT format.
  451 A:e341                                    ; ex. "file.xpl",0 --> "FILE    XPL"
  452 A:e341                                    ; check for . or ..
  453 A:e341  a0 00                              ldy #0
  454 A:e343  b1 11                              lda (folderpointer),y
  455 A:e345  c9 2e                              cmp #$2e
  456 A:e347  f0 07                              beq dotf
  457 A:e349  a9 ff                              lda #$ff
  458 A:e34b  85 18                              sta backdir
  459 A:e34d  4c 62 e3                           jmp nopd
  460 A:e350                           dotf      
  460 A:e350                                    
  461 A:e350  c8                                 iny 
  462 A:e351  b1 11                              lda (folderpointer),y
  463 A:e353  c9 2e                              cmp #$2e
  464 A:e355  f0 05                              beq backdire
  465 A:e357  a9 55                              lda #$55
  466 A:e359  85 18                              sta backdir
  467 A:e35b  60                                 rts                    ; do nothing if "."
  468 A:e35c                           backdire  
  468 A:e35c                                    
  469 A:e35c                                    ; ".." means go back
  470 A:e35c  20 1d e2                           jsr backpath
  471 A:e35f  64 18                              stz backdir
  472 A:e361                                    ;jsr refreshpath
  473 A:e361  60                                 rts 
  474 A:e362                           nopd      
  474 A:e362                                    
  475 A:e362  a0 18                              ldy #24
  476 A:e364  a9 00                              lda #0
  477 A:e366  91 11                              sta (folderpointer),y
  478 A:e368  a9 15                              lda #21
  479 A:e36a  85 14                              sta fileext
  480 A:e36c  a0 00                              ldy #0
  481 A:e36e                           shortlp   
  481 A:e36e                                    
  482 A:e36e  b1 11                              lda (folderpointer),y
  483 A:e370  f0 08                              beq nodot
  484 A:e372  c9 2e                              cmp #$2e             ; find the dot 
  485 A:e374  f0 20                              beq extst
  486 A:e376  c8                                 iny 
  487 A:e377  4c 6e e3                           jmp shortlp
  488 A:e37a                           nodot     
  489 A:e37a                                    ; no dot, this is a folder
  490 A:e37a                                    ; empty out the extension
  491 A:e37a  84 19                              sty sc
  492 A:e37c  18                                 clc 
  493 A:e37d  a5 19                              lda sc
  494 A:e37f  69 0d                              adc #13
  495 A:e381  85 19                              sta sc
  496 A:e383  a9 0d                              lda #13
  497 A:e385  85 14                              sta fileext
  498 A:e387  a9 20                              lda #$20
  499 A:e389  a0 15                              ldy #21
  500 A:e38b  91 11                              sta (folderpointer),y
  501 A:e38d  c8                                 iny 
  502 A:e38e  91 11                              sta (folderpointer),y
  503 A:e390  c8                                 iny 
  504 A:e391  91 11                              sta (folderpointer),y
  505 A:e393  4c b7 e3                           jmp mvname                ; ok, go ahead and copy the name
  506 A:e396                           extst     
  506 A:e396                                    
  507 A:e396  84 19                              sty sc                ; now move the file extension
  508 A:e398                           ext       
  508 A:e398                                    
  509 A:e398  c8                                 iny 
  510 A:e399  b1 11                              lda (folderpointer),y
  511 A:e39b  5a                                 phy 
  512 A:e39c  a4 14                              ldy fileext
  513 A:e39e  91 11                              sta (folderpointer),y
  514 A:e3a0  c8                                 iny 
  515 A:e3a1  84 14                              sty fileext
  516 A:e3a3  c0 18                              cpy #24
  517 A:e3a5  f0 04                              beq extd
  518 A:e3a7  7a                                 ply 
  519 A:e3a8  4c 98 e3                           jmp ext
  520 A:e3ab                           extd      
  520 A:e3ab                                    
  521 A:e3ab  7a                                 ply 
  522 A:e3ac  18                                 clc 
  523 A:e3ad  a5 19                              lda sc                ; add to sc
  524 A:e3af  69 0d                              adc #13
  525 A:e3b1  85 19                              sta sc
  526 A:e3b3  a9 0d                              lda #13
  527 A:e3b5  85 14                              sta fileext
  528 A:e3b7                           mvname    
  528 A:e3b7                                    
  529 A:e3b7                                    ; move name
  530 A:e3b7  a0 00                              ldy #0
  531 A:e3b9                           mvlp      
  531 A:e3b9                                    
  532 A:e3b9  b1 11                              lda (folderpointer),y
  533 A:e3bb  5a                                 phy 
  534 A:e3bc  a4 14                              ldy fileext
  535 A:e3be  c4 19                              cpy sc
  536 A:e3c0  f0 0a                              beq ad2sc
  537 A:e3c2  91 11                              sta (folderpointer),y
  538 A:e3c4  c8                                 iny 
  539 A:e3c5  84 14                              sty fileext
  540 A:e3c7  7a                                 ply 
  541 A:e3c8  c8                                 iny 
  542 A:e3c9  4c b9 e3                           jmp mvlp
  543 A:e3cc                           ad2sc     
  543 A:e3cc                                    
  544 A:e3cc  7a                                 ply 
  545 A:e3cd  a4 19                              ldy sc
  546 A:e3cf                                    ; the file extention is moved, now pad spaces from the end of the name
  547 A:e3cf                                    ; to the start of the extension.
  548 A:e3cf                           fill      
  548 A:e3cf                                    
  549 A:e3cf  a9 20                              lda #$20
  550 A:e3d1  c0 15                              cpy #21
  551 A:e3d3  f0 07                              beq notfill
  552 A:e3d5                           filllp    
  552 A:e3d5                                    
  553 A:e3d5  91 11                              sta (folderpointer),y
  554 A:e3d7  c8                                 iny 
  555 A:e3d8  c0 15                              cpy #21             ; stop if index is 20, we don't want to overwrite the file extension
  556 A:e3da  d0 f9                              bne filllp
  557 A:e3dc                           notfill   
  558 A:e3dc                                    ; add 11 to folderpointer
  559 A:e3dc  18                                 clc 
  560 A:e3dd  a5 11                              lda folderpointer
  561 A:e3df  69 0d                              adc #13
  562 A:e3e1  85 11                              sta folderpointer
  563 A:e3e3                                    ; now we need to convert lowercase to uppercase
  564 A:e3e3  a0 00                              ldy #0
  565 A:e3e5                           ldlp      
  565 A:e3e5                                    
  566 A:e3e5  b1 11                              lda (folderpointer),y
  567 A:e3e7  f0 10                              beq ldd                ; if null, stop.
  568 A:e3e9  c9 40                              cmp #$40             ; if numbers/symbols/space, skip.
  569 A:e3eb  90 08                              bcc dontl
  570 A:e3ed  c9 5f                              cmp #$5f             ; if _ skip
  571 A:e3ef  f0 04                              beq dontl
  572 A:e3f1  29 df                              and #$df             ; otherwise convert to uppercase
  573 A:e3f3  91 11                              sta (folderpointer),y
  574 A:e3f5                           dontl     
  574 A:e3f5                                    
  575 A:e3f5  c8                                 iny 
  576 A:e3f6  4c e5 e3                           jmp ldlp
  577 A:e3f9                           ldd       
  577 A:e3f9                                    
  578 A:e3f9                                    ; ok! now we have a SHORT formatted filename at (folderpointer).
  579 A:e3f9  60                                 rts 
  580 A:e3fa                                     .) 

  582 A:e3fa                           other     
  582 A:e3fa                                    
  583 A:e3fa                                    ; Write a letter of the filename currently being read
  584 A:e3fa  b1 48                              lda (zp_sd_address),y
  585 A:e3fc  09 20                              ora #$20             ; convert uppercase to lowercase
  586 A:e3fe  20 df df                           jsr print_chara
  587 A:e401  c8                                 iny 
  588 A:e402  60                                 rts 

  590 A:e403                                    ;; LS
  591 A:e403                                    ;; print a directory listing

  593 A:e403                           lscmd     
  593 A:e403                                    
  594 A:e403                                     .( 
  595 A:e403  ad 00 04                           lda path
  596 A:e406  d0 03                              bne cdf
  597 A:e408  4c eb e1                           jmp patherr
  598 A:e40b                           cdf       
  598 A:e40b                                    
  599 A:e40b                                    ;; check arguments
  600 A:e40b  a5 20                              lda ARGINDEX
  601 A:e40d  c9 02                              cmp #2             ; if there's two arguments, list the specified directory
  602 A:e40f  f0 13                              beq processparam
  603 A:e411  a5 20                              lda ARGINDEX
  604 A:e413  c9 01                              cmp #1             ; if there's only one argument (ls) then list current directory 
  605 A:e415  d0 0a                              bne jmperror
  606 A:e417  20 81 df                           jsr fat32_open_cd
  607 A:e41a  a9 ff                              lda #$ff
  608 A:e41c  85 18                              sta backdir
  609 A:e41e  4c 36 e4                           jmp list
  610 A:e421                           jmperror  
  610 A:e421                                    
  611 A:e421  4c dc e2                           jmp error
  612 A:e424                           processparam                  ; process the filename parameter
  613 A:e424  64 18                              stz backdir
  614 A:e426  18                                 clc 
  615 A:e427  a9 00                              lda #<INPUT
  616 A:e429  65 22                              adc ARGINDEX+2
  617 A:e42b  85 11                              sta folderpointer
  618 A:e42d  a9 02                              lda #>INPUT
  619 A:e42f  85 12                              sta folderpointer+1
  620 A:e431                                    ; get /
  621 A:e431                                    ;jsr jmpdir
  622 A:e431                                    ;bcc dontcd
  623 A:e431                                    ; now cd
  624 A:e431  20 ac e2                           jsr cdd
  625 A:e434                                    ;dontcd
  625 A:e434                                    
  626 A:e434  64 18                              stz backdir
  627 A:e436                                     .) 

  629 A:e436                           list      
  629 A:e436                                    ; list file dir
  630 A:e436                                     .( 
  631 A:e436  20 25 de                           jsr fat32_readdirent                ; files?
  632 A:e439  b0 47                              bcs nofiles
  633 A:e43b                                    ;and #$40
  634 A:e43b                                    ;beq arc
  635 A:e43b                           ebut      
  635 A:e43b                                    
  636 A:e43b  a2 00                              ldx #0
  637 A:e43d  a0 08                              ldy #8
  638 A:e43f                           chklp     
  638 A:e43f                                    
  639 A:e43f  c0 0b                              cpy #11
  640 A:e441  f0 0b                              beq no
  641 A:e443  b1 48                              lda (zp_sd_address),y
  642 A:e445  c9 20                              cmp #$20
  643 A:e447  d0 01                              bne chky
  644 A:e449  e8                                 inx 
  645 A:e44a                           chky      
  645 A:e44a                                    
  646 A:e44a  c8                                 iny 
  647 A:e44b  4c 3f e4                           jmp chklp
  648 A:e44e                           no        
  648 A:e44e                                    
  649 A:e44e  e0 03                              cpx #3
  650 A:e450  d0 07                              bne arc
  651 A:e452                           dir       
  651 A:e452                                    
  652 A:e452  a9 ff                              lda #$ff
  653 A:e454  85 15                              sta filetype                ; directorys show up as 
  654 A:e456  4c 5b e4                           jmp name                ; yourfilename     test      folder  ...Etc
  655 A:e459                           arc       
  655 A:e459                                    
  656 A:e459  64 15                              stz filetype                ; files show up as
  657 A:e45b                           name      
  657 A:e45b                                    ; test.xpl         music.xpl        file.bin  ...Etc
  658 A:e45b                                    ; At this point, we know that there are no files, files, or a suddir
  659 A:e45b                                    ; Now for the name
  660 A:e45b  a0 00                              ldy #0
  661 A:e45d                           nameloop  
  661 A:e45d                                    
  662 A:e45d  c0 08                              cpy #8
  663 A:e45f  f0 06                              beq dot
  664 A:e461  20 fa e3                           jsr other
  665 A:e464  4c 5d e4                           jmp nameloop
  666 A:e467                           dot       
  666 A:e467                                    
  667 A:e467  a5 15                              lda filetype
  668 A:e469  d0 0f                              bne endthat                ; if it's a file,
  669 A:e46b  a9 2e                              lda #$2e             ; shows its file extention
  670 A:e46d  20 df df                           jsr print_chara
  671 A:e470                           lopii     
  671 A:e470                                    
  672 A:e470  c0 0b                              cpy #11
  673 A:e472  f0 06                              beq endthat                ; print 3-letter file extention
  674 A:e474  20 fa e3                           jsr other
  675 A:e477  4c 70 e4                           jmp lopii
  676 A:e47a                           endthat   
  676 A:e47a                                    
  677 A:e47a  a9 09                              lda #$09             ; Tab
  678 A:e47c  20 df df                           jsr print_chara                ; tab
  679 A:e47f  4c 36 e4                           jmp list                ; go again ; next file if there are any left
  680 A:e482                           nofiles   
  680 A:e482                                    ; if not,
  681 A:e482                           endlist   
  681 A:e482                                    ; exit listing code
  682 A:e482  20 45 d6                           jsr crlf
  683 A:e485  a5 18                              lda backdir
  684 A:e487  d0 04                              bne dontb
  685 A:e489                                    ;  lda dircnt
  686 A:e489                                    ;  beq nono
  687 A:e489                                    ;  ldx #0
  688 A:e489                                    ;dddl
  688 A:e489                                    
  689 A:e489                                    ;  jsr backpath
  690 A:e489                                    ;  inx
  691 A:e489                                    ;  cpx dircnt
  692 A:e489                                    ;  bne dddl
  693 A:e489                                    ;  jmp dontb
  694 A:e489                                    ;nono
  694 A:e489                                    
  695 A:e489  20 1d e2                           jsr backpath                ; cd .. if ls <folderpath>
  696 A:e48c  60                                 rts 
  697 A:e48d                           dontb     
  697 A:e48d                                    
  698 A:e48d  20 81 df                           jsr fat32_open_cd                ; refresh the directory
  699 A:e490  60                                 rts 
  700 A:e491                           jumptolist 
  700 A:e491                                    
  701 A:e491  20 45 d6                           jsr crlf
  702 A:e494  4c 36 e4                           jmp list
  703 A:e497                                     .) 

  705 A:e497                                    ;; load
  706 A:e497                                    ;; Here we load a file from the SD card.
  707 A:e497                                    ;; .SAR stands for Start AddRess.

  709 A:e497                           loadcmd   
  710 A:e497                                     .( 
  711 A:e497  ad 00 04                           lda path
  712 A:e49a  d0 03                              bne cdf
  713 A:e49c  4c eb e1                           jmp patherr
  714 A:e49f                           cdf       
  714 A:e49f                                    
  715 A:e49f                                    ;; check arguments
  716 A:e49f  a5 20                              lda ARGINDEX
  717 A:e4a1  c9 02                              cmp #2             ; if there's two arguments, load the specified file
  718 A:e4a3  f0 0e                              beq lprocessparam
  719 A:e4a5  a5 20                              lda ARGINDEX
  720 A:e4a7  c9 01                              cmp #1             ; if there's only one argument, do a handeler load.
  721 A:e4a9  f0 5b                              beq loadone
  722 A:e4ab                                     .) 
  723 A:e4ab                           lderror   
  723 A:e4ab                                    
  724 A:e4ab  a2 f4                              ldx #<foldermsg              ; if it was not found, error and return.
  725 A:e4ad  a0 e7                              ldy #>foldermsg
  726 A:e4af  20 f0 df                           jsr w_acia_full
  727 A:e4b2  60                                 rts 
  728 A:e4b3                           lprocessparam                  ; the user specified a file, process the filename parameter.
  729 A:e4b3  18                                 clc 
  730 A:e4b4  a9 00                              lda #<INPUT
  731 A:e4b6  65 22                              adc ARGINDEX+2
  732 A:e4b8  85 11                              sta folderpointer
  733 A:e4ba  a9 02                              lda #>INPUT              ; argument buffer under 256 bytes, so no adc #0.
  734 A:e4bc  85 12                              sta folderpointer+1
  735 A:e4be                           loadlc    
  735 A:e4be                                    
  736 A:e4be                                     .( 
  737 A:e4be                                    ; convert string
  738 A:e4be  20 41 e3                           jsr shortconvert
  739 A:e4c1                                    ; is this a .XPL file?
  740 A:e4c1  a0 08                              ldy #$08
  741 A:e4c3  b1 11                              lda (folderpointer),y
  742 A:e4c5  c9 58                              cmp #'X'
  743 A:e4c7  d0 14                              bne ldp
  744 A:e4c9  c8                                 iny 
  745 A:e4ca  b1 11                              lda (folderpointer),y
  746 A:e4cc  c9 50                              cmp #'P'
  747 A:e4ce  d0 0d                              bne ldp
  748 A:e4d0  c8                                 iny 
  749 A:e4d1  b1 11                              lda (folderpointer),y
  750 A:e4d3  c9 4c                              cmp #'L'
  751 A:e4d5  d0 06                              bne ldp
  752 A:e4d7  9c 04 07                           stz buffer+4
  753 A:e4da  4c e2 e4                           jmp ldp2
  754 A:e4dd                           ldp       
  754 A:e4dd                                    
  755 A:e4dd  a9 ff                              lda #$ff
  756 A:e4df  8d 04 07                           sta buffer+4
  757 A:e4e2                           ldp2      
  757 A:e4e2                                    
  758 A:e4e2                                     .) 
  759 A:e4e2                           loadpath  
  759 A:e4e2                                    
  760 A:e4e2                                     .( 
  761 A:e4e2                                    ; Refresh
  762 A:e4e2  20 81 df                           jsr fat32_open_cd
  763 A:e4e5                                    ; Loading..
  764 A:e4e5  a2 86                              ldx #<loading_msg
  765 A:e4e7  a0 cb                              ldy #>loading_msg
  766 A:e4e9  20 f0 df                           jsr w_acia_full
  767 A:e4ec                                    ; BUG i need to add a start address header to the .XPL file format...
  768 A:e4ec                                    ; at the moment it is assumed that the file will load and run at $0F00
  769 A:e4ec  9c 00 07                           stz buffer
  770 A:e4ef  9c 02 07                           stz buffer+2
  771 A:e4f2  a9 0f                              lda #$0f             ; $0F00
  772 A:e4f4  8d 01 07                           sta buffer+1
  773 A:e4f7  8d 03 07                           sta buffer+3
  774 A:e4fa  a6 11                              ldx folderpointer
  775 A:e4fc  a4 12                              ldy folderpointer+1          ; find the file
  776 A:e4fe  20 5b de                           jsr fat32_finddirent
  777 A:e501  90 47                              bcc loadfoundcode
  778 A:e503  4c ab e4                           jmp lderror
  779 A:e506                                     .) 
  780 A:e506                           loadone   
  780 A:e506                                    
  781 A:e506                                     .( 
  782 A:e506                                    ; the user has not specified a filename, so load the SD card handeler program.

  784 A:e506  20 98 e5                           jsr loadf

  786 A:e509                                    ; Find file by name
  787 A:e509  a2 9f                              ldx #<loadname
  788 A:e50b  a0 e1                              ldy #>loadname              ; this is LOADADDR.SAR, which is what I plan 
  789 A:e50d  20 5b de                           jsr fat32_finddirent                ; to merge into a header of .XPL files.
  790 A:e510  90 0a                              bcc foundfile                ; it holds the load address and jump address
  791 A:e512                                    ; of CODE.XPL.
  792 A:e512                                    ; File not found
  793 A:e512  a0 e7                              ldy #>filmsg
  794 A:e514  a2 78                              ldx #<filmsg
  795 A:e516  20 f0 df                           jsr w_acia_full
  796 A:e519  4c 13 e0                           jmp error_sound

  798 A:e51c                           foundfile 

  800 A:e51c                                    ; Open file
  801 A:e51c  20 e1 dc                           jsr fat32_opendirent

  803 A:e51f                                    ; Read file contents into buffer
  804 A:e51f  a9 00                              lda #<buffer
  805 A:e521  85 5c                              sta fat32_address
  806 A:e523  a9 07                              lda #>buffer
  807 A:e525  85 5d                              sta fat32_address+1

  809 A:e527  20 1e df                           jsr fat32_file_read

  811 A:e52a  9c 04 07                           stz buffer+4

  813 A:e52d  20 98 e5                           jsr loadf                ; BUG really?

  815 A:e530  a0 e7                              ldy #>lds
  816 A:e532  a2 ac                              ldx #<lds
  817 A:e534  20 f0 df                           jsr w_acia_full

  819 A:e537  a2 94                              ldx #<filename              ; CODE.XPL is the sd card's loader
  820 A:e539  a0 e1                              ldy #>filename
  821 A:e53b  20 5b de                           jsr fat32_finddirent
  822 A:e53e  90 0a                              bcc loadfoundcode

  824 A:e540  a0 e7                              ldy #>filmsg2
  825 A:e542  a2 94                              ldx #<filmsg2
  826 A:e544  20 f0 df                           jsr w_acia_full
  827 A:e547  4c 13 e0                           jmp error_sound
  828 A:e54a                                     .) 
  829 A:e54a                           loadfoundcode 
  830 A:e54a                                     .( 
  831 A:e54a                                    ; backup file size 
  832 A:e54a  a0 1c                              ldy #28
  833 A:e54c  b1 48                              lda (zp_sd_address),y
  834 A:e54e  18                                 clc 
  835 A:e54f  6d 00 07                           adc buffer
  836 A:e552  48                                 pha 
  837 A:e553  c8                                 iny 
  838 A:e554  b1 48                              lda (zp_sd_address),y
  839 A:e556  6d 01 07                           adc buffer+1
  840 A:e559  48                                 pha 

  842 A:e55a  20 e1 dc                           jsr fat32_opendirent                ; open the file

  844 A:e55d  ad 00 07                           lda buffer                ; and load it to the address
  845 A:e560  85 5c                              sta fat32_address                ; from LOADADDR.SAR
  846 A:e562  ad 01 07                           lda buffer+1
  847 A:e565  85 5d                              sta fat32_address+1

  849 A:e567  20 1e df                           jsr fat32_file_read

  851 A:e56a                                    ; All done.

  853 A:e56a                                    ;ldy #>ends
  854 A:e56a                                    ;ldx #<ends
  855 A:e56a                                    ;jsr w_acia_full
  856 A:e56a  a2 a5                              ldx #<loadedmsg
  857 A:e56c  a0 cb                              ldy #>loadedmsg
  858 A:e56e  20 f0 df                           jsr w_acia_full
  859 A:e571  ad 01 07                           lda buffer+1
  860 A:e574  20 b5 df                           jsr print_hex_acia
  861 A:e577  ad 00 07                           lda buffer
  862 A:e57a  20 b5 df                           jsr print_hex_acia
  863 A:e57d  a2 b2                              ldx #<tomsg
  864 A:e57f  a0 cb                              ldy #>tomsg
  865 A:e581  20 f0 df                           jsr w_acia_full
  866 A:e584  68                                 pla 
  867 A:e585  20 b5 df                           jsr print_hex_acia
  868 A:e588  68                                 pla 
  869 A:e589  20 b5 df                           jsr print_hex_acia
  870 A:e58c  20 45 d6                           jsr crlf

  872 A:e58f                                    ; Is this a XPL file?
  873 A:e58f  ad 04 07                           lda buffer+4
  874 A:e592  d0 03                              bne lo

  876 A:e594  6c 02 07                           jmp (buffer+2)        ; jump to start address from LOADADDR

  878 A:e597                           lo        
  878 A:e597                                    
  879 A:e597  60                                 rts 
  880 A:e598                                     .) 

  882 A:e598                           loadf     
  882 A:e598                                    
  883 A:e598                                    ; Open root directory
  884 A:e598  20 9c db                           jsr fat32_openroot

  886 A:e59b                                    ; Find subdirectory by name
  887 A:e59b  a2 89                              ldx #<subdirname
  888 A:e59d  a0 e1                              ldy #>subdirname
  889 A:e59f  20 5b de                           jsr fat32_finddirent
  890 A:e5a2  90 0a                              bcc foundsubdir

  892 A:e5a4                                    ; Subdirectory not found
  893 A:e5a4  a0 e7                              ldy #>submsg
  894 A:e5a6  a2 66                              ldx #<submsg
  895 A:e5a8  20 f0 df                           jsr w_acia_full
  896 A:e5ab  4c 13 e0                           jmp error_sound

  898 A:e5ae                           foundsubdir 

  900 A:e5ae                                    ; Open subdirectory
  901 A:e5ae  4c e1 dc                           jmp fat32_opendirent

  903 A:e5b1                           savecmd   
  903 A:e5b1                                    
  904 A:e5b1                                     .( 
  905 A:e5b1                                    ; Save a file.
  906 A:e5b1  da                                 phx 
  907 A:e5b2  ad 00 04                           lda path
  908 A:e5b5  d0 03                              bne sv
  909 A:e5b7  4c eb e1                           jmp patherr
  910 A:e5ba                           sv        
  910 A:e5ba                                    
  911 A:e5ba  a5 20                              lda ARGINDEX
  912 A:e5bc  c9 04                              cmp #4
  913 A:e5be  f0 03                              beq proc
  914 A:e5c0  4c dc e2                           jmp error
  915 A:e5c3                           proc      
  915 A:e5c3                                    
  916 A:e5c3                                    ; filename
  917 A:e5c3  18                                 clc 
  918 A:e5c4  a9 00                              lda #<INPUT
  919 A:e5c6  65 24                              adc ARGINDEX+4
  920 A:e5c8  85 11                              sta folderpointer
  921 A:e5ca  a9 02                              lda #>INPUT
  922 A:e5cc  85 12                              sta folderpointer+1
  923 A:e5ce                                    ; convert it to SHORT
  924 A:e5ce  20 41 e3                           jsr shortconvert
  925 A:e5d1  a5 11                              lda folderpointer
  926 A:e5d3  85 1c                              sta savepoint
  927 A:e5d5  a5 12                              lda folderpointer+1
  928 A:e5d7  85 1d                              sta savepoint+1
  929 A:e5d9                                    ; second addr parameter
  930 A:e5d9  18                                 clc 
  931 A:e5da  a9 00                              lda #<INPUT
  932 A:e5dc  65 23                              adc ARGINDEX+3
  933 A:e5de  85 80                              sta stackaccess
  934 A:e5e0  a9 02                              lda #>INPUT
  935 A:e5e2  85 81                              sta stackaccess+1
  936 A:e5e4  20 db c0                           jsr push16
  937 A:e5e7  20 76 c2                           jsr read16hex
  938 A:e5ea                                    ; first address parameter
  939 A:e5ea  18                                 clc 
  940 A:e5eb  a9 00                              lda #<INPUT
  941 A:e5ed  65 22                              adc ARGINDEX+2
  942 A:e5ef  85 80                              sta stackaccess
  943 A:e5f1  a9 02                              lda #>INPUT
  944 A:e5f3  85 81                              sta stackaccess+1
  945 A:e5f5  20 db c0                           jsr push16
  946 A:e5f8  20 76 c2                           jsr read16hex
  947 A:e5fb                                    ; stash them
  948 A:e5fb  20 e6 c0                           jsr pop16
  949 A:e5fe  a5 80                              lda stackaccess
  950 A:e600  85 1a                              sta savestart
  951 A:e602  a5 81                              lda stackaccess+1
  952 A:e604  85 1b                              sta savestart+1
  953 A:e606  20 e6 c0                           jsr pop16
  954 A:e609  a5 80                              lda stackaccess
  955 A:e60b  85 10                              sta saveend
  956 A:e60d  a5 81                              lda stackaccess+1
  957 A:e60f  85 11                              sta saveend+1
  958 A:e611  4c 15 e6                           jmp sg
  959 A:e614                                     .) 
  960 A:e614                           savekernal 
  960 A:e614                                    
  961 A:e614  da                                 phx 
  962 A:e615                           sg        
  962 A:e615                                    
  963 A:e615                                     .( 
  964 A:e615                                    ; now lets begin 
  965 A:e615                                    ; Refresh PATH
  966 A:e615  20 c0 e1                           jsr refreshpath
  967 A:e618                                    ; Open the filename
  968 A:e618  a6 1c                              ldx savepoint
  969 A:e61a  a4 1d                              ldy savepoint+1
  970 A:e61c                                    ; Check if the file exists
  971 A:e61c  20 5b de                           jsr fat32_finddirent
  972 A:e61f  90 03                              bcc fileexists
  973 A:e621  4c 40 e6                           jmp nf
  974 A:e624                           fileexists 
  974 A:e624                                    
  975 A:e624                                    ; If so, ask the user if they would like to overwrite the file.
  976 A:e624  a2 d4                              ldx #<femsg
  977 A:e626  a0 e7                              ldy #>femsg
  978 A:e628  20 f0 df                           jsr w_acia_full
  979 A:e62b  20 c2 f3                           jsr rxpoll
  980 A:e62e  ad 00 80                           lda $8000
  981 A:e631  c9 79                              cmp #'y'             ; response = 'y'?
  982 A:e633  f0 05                              beq yes
  983 A:e635  20 45 d6                           jsr crlf                ; no, cancel save
  984 A:e638  fa                                 plx 
  985 A:e639  60                                 rts 
  986 A:e63a                           yes       
  987 A:e63a                                    ; we would like to overwrite the file.
  988 A:e63a  20 45 d6                           jsr crlf
  989 A:e63d                                    ; delete it to clean the FAT
  990 A:e63d  20 9b de                           jsr fat32_deletefile
  991 A:e640                           nf        
  991 A:e640                                    
  992 A:e640                                    ;jsr fat32_open_cd
  993 A:e640  a2 c2                              ldx #<savemsg
  994 A:e642  a0 e7                              ldy #>savemsg
  995 A:e644  20 f0 df                           jsr w_acia_full
  996 A:e647                                    ; Calculate file size (end - start)
  997 A:e647  38                                 sec 
  998 A:e648  a5 10                              lda saveend
  999 A:e64a  e5 1a                              sbc savestart
 1000 A:e64c  85 62                              sta fat32_bytesremaining
 1001 A:e64e  48                                 pha 
 1002 A:e64f  a5 11                              lda saveend+1
 1003 A:e651  e5 1b                              sbc savestart+1
 1004 A:e653  85 63                              sta fat32_bytesremaining+1
 1005 A:e655  48                                 pha 
 1006 A:e656                                    ; Allocate all the clusters for this file
 1007 A:e656  20 dd db                           jsr fat32_allocatefile
 1008 A:e659                                    ; Refresh
 1009 A:e659  20 c0 e1                           jsr refreshpath
 1010 A:e65c                                    ; Put the filename at fat32_filenamepointer
 1011 A:e65c  a5 1c                              lda savepoint
 1012 A:e65e  85 74                              sta fat32_filenamepointer
 1013 A:e660  a5 1d                              lda savepoint+1
 1014 A:e662  85 75                              sta fat32_filenamepointer+1
 1015 A:e664  68                                 pla 
 1016 A:e665  85 63                              sta fat32_bytesremaining+1
 1017 A:e667  68                                 pla 
 1018 A:e668  85 62                              sta fat32_bytesremaining
 1019 A:e66a                                    ; Write a directory entry for this file
 1020 A:e66a  20 44 dd                           jsr fat32_writedirent
 1021 A:e66d                                    ; Now, to actually write the file...
 1022 A:e66d  a5 1a                              lda savestart
 1023 A:e66f  85 5c                              sta fat32_address
 1024 A:e671  a5 1b                              lda savestart+1
 1025 A:e673  85 5d                              sta fat32_address+1
 1026 A:e675  20 3e df                           jsr fat32_file_write
 1027 A:e678                                    ; All Done!
 1028 A:e678  a2 cc                              ldx #<ends
 1029 A:e67a  a0 e7                              ldy #>ends
 1030 A:e67c  20 f0 df                           jsr w_acia_full
 1031 A:e67f                           saveexit  
 1031 A:e67f                                    
 1032 A:e67f  fa                                 plx 
 1033 A:e680  60                                 rts 
 1034 A:e681                                     .) 

 1036 A:e681                           rmcmd     
 1036 A:e681                                    
 1037 A:e681                                     .( 
 1038 A:e681                                    ; Remove a file
 1039 A:e681  da                                 phx 
 1040 A:e682  ad 00 04                           lda path
 1041 A:e685  d0 03                              bne rm
 1042 A:e687  4c eb e1                           jmp patherr
 1043 A:e68a                           rm        
 1043 A:e68a                                    
 1044 A:e68a                                    ;; check arguments
 1045 A:e68a  a5 20                              lda ARGINDEX
 1046 A:e68c  c9 02                              cmp #2             ; if there's two arguments, load the specified file
 1047 A:e68e  f0 03                              beq proc
 1048 A:e690  4c dc e2                           jmp error
 1049 A:e693                           proc      
 1049 A:e693                                    
 1050 A:e693                                    ; filename
 1051 A:e693  18                                 clc 
 1052 A:e694  a9 00                              lda #<INPUT
 1053 A:e696  65 22                              adc ARGINDEX+2
 1054 A:e698  85 11                              sta folderpointer
 1055 A:e69a  a9 02                              lda #>INPUT
 1056 A:e69c  85 12                              sta folderpointer+1
 1057 A:e69e                                    ; convert it to SHORT
 1058 A:e69e  20 41 e3                           jsr shortconvert
 1059 A:e6a1  a5 11                              lda folderpointer
 1060 A:e6a3  85 1c                              sta savepoint
 1061 A:e6a5  a5 12                              lda folderpointer+1
 1062 A:e6a7  85 1d                              sta savepoint+1
 1063 A:e6a9                                    ; path refresh
 1064 A:e6a9  20 81 df                           jsr fat32_open_cd
 1065 A:e6ac                                    ; load
 1066 A:e6ac  a6 1c                              ldx savepoint
 1067 A:e6ae  a4 1d                              ldy savepoint+1
 1068 A:e6b0                                    ; find it
 1069 A:e6b0  20 5b de                           jsr fat32_finddirent
 1070 A:e6b3  90 05                              bcc foundfile
 1071 A:e6b5  20 f4 e1                           jsr rlerror
 1072 A:e6b8  fa                                 plx 
 1073 A:e6b9  60                                 rts 
 1074 A:e6ba                           foundfile 
 1074 A:e6ba                                    
 1075 A:e6ba  20 9b de                           jsr fat32_deletefile
 1076 A:e6bd                                    ; done
 1077 A:e6bd  fa                                 plx 
 1078 A:e6be  60                                 rts 
 1079 A:e6bf                                     .) 

 1081 A:e6bf                           mvcmd     
 1081 A:e6bf                                    
 1082 A:e6bf                                     .( 
 1083 A:e6bf                                    ; Move a file.
 1084 A:e6bf  da                                 phx 
 1085 A:e6c0  ad 00 04                           lda path
 1086 A:e6c3  d0 03                              bne mv
 1087 A:e6c5  4c eb e1                           jmp patherr
 1088 A:e6c8                           mv        
 1088 A:e6c8                                    
 1089 A:e6c8                                    ;; check arguments
 1090 A:e6c8  a5 20                              lda ARGINDEX
 1091 A:e6ca  c9 03                              cmp #3
 1092 A:e6cc  f0 03                              beq proc
 1093 A:e6ce  4c dc e2                           jmp error
 1094 A:e6d1                           proc      
 1094 A:e6d1                                    
 1095 A:e6d1                                    ; fetch first filename
 1096 A:e6d1  18                                 clc 
 1097 A:e6d2  a9 00                              lda #<INPUT
 1098 A:e6d4  65 22                              adc ARGINDEX+2
 1099 A:e6d6  85 11                              sta folderpointer
 1100 A:e6d8  a9 02                              lda #>INPUT
 1101 A:e6da  85 12                              sta folderpointer+1
 1102 A:e6dc  20 51 e7                           jsr overf
 1103 A:e6df                                    ; convert it to SHORT
 1104 A:e6df  20 41 e3                           jsr shortconvert
 1105 A:e6e2  a5 11                              lda folderpointer
 1106 A:e6e4  85 1c                              sta savepoint
 1107 A:e6e6  a5 12                              lda folderpointer+1
 1108 A:e6e8  85 1d                              sta savepoint+1
 1109 A:e6ea                                    ; path refresh
 1110 A:e6ea  20 81 df                           jsr fat32_open_cd
 1111 A:e6ed                                    ; load
 1112 A:e6ed  a6 1c                              ldx savepoint
 1113 A:e6ef  a4 1d                              ldy savepoint+1
 1114 A:e6f1                                    ; find it
 1115 A:e6f1  20 5b de                           jsr fat32_finddirent
 1116 A:e6f4  90 03                              bcc gotit
 1117 A:e6f6  4c 2c e7                           jmp mvfail
 1118 A:e6f9                           gotit     
 1118 A:e6f9                                    
 1119 A:e6f9                                    ; carry already clear
 1120 A:e6f9                                    ; get the folder to move it to
 1121 A:e6f9  a9 00                              lda #<INPUT
 1122 A:e6fb  65 23                              adc ARGINDEX+3
 1123 A:e6fd  85 11                              sta folderpointer
 1124 A:e6ff  a9 02                              lda #>INPUT
 1125 A:e701  85 12                              sta folderpointer+1
 1126 A:e703  20 51 e7                           jsr overf
 1127 A:e706                                    ; convert it to SHORT
 1128 A:e706  20 41 e3                           jsr shortconvert
 1129 A:e709  a5 11                              lda folderpointer
 1130 A:e70b  85 1c                              sta savepoint
 1131 A:e70d  a5 12                              lda folderpointer+1
 1132 A:e70f  85 1d                              sta savepoint+1
 1133 A:e711                                    ; Now, for the copy
 1134 A:e711                                    ; Store the dirent temporaraly
 1135 A:e711  a0 00                              ldy #0
 1136 A:e713                           stlp      
 1137 A:e713  b1 48                              lda (zp_sd_address),y
 1138 A:e715  99 00 02                           sta INPUT,y
 1139 A:e718  c8                                 iny 
 1140 A:e719  c0 20                              cpy #$20
 1141 A:e71b  d0 f6                              bne stlp
 1142 A:e71d                                    ; Now, mark it as a deleted file
 1143 A:e71d  20 72 de                           jsr fat32_markdeleted
 1144 A:e720  20 81 df                           jsr fat32_open_cd
 1145 A:e723                                    ; Find the directory
 1146 A:e723                                    ;lda backdir
 1147 A:e723                                    ;beq nono ;TODO CHECK
 1148 A:e723                           nono      
 1148 A:e723                                    
 1149 A:e723  a6 1c                              ldx savepoint
 1150 A:e725  a4 1d                              ldy savepoint+1
 1151 A:e727  20 5b de                           jsr fat32_finddirent
 1152 A:e72a  90 05                              bcc mvgotdirent
 1153 A:e72c                           mvfail    
 1154 A:e72c                                    ; The directory was not found
 1155 A:e72c  20 f4 e1                           jsr rlerror
 1156 A:e72f  fa                                 plx 
 1157 A:e730  60                                 rts 
 1158 A:e731                           mvgotdirent 
 1159 A:e731                                    ; It was, open it.
 1160 A:e731  20 e1 dc                           jsr fat32_opendirent
 1161 A:e734                                    ; Ok. now we need to find a free entry
 1162 A:e734                           mvlp      
 1163 A:e734  20 25 de                           jsr fat32_readdirent
 1164 A:e737  90 fb                              bcc mvlp
 1165 A:e739                                    ; Got it. now paste the file here
 1166 A:e739  a0 00                              ldy #0
 1167 A:e73b                           mvpaste   
 1168 A:e73b  b9 00 02                           lda INPUT,y
 1169 A:e73e  91 48                              sta (zp_sd_address),y
 1170 A:e740  c8                                 iny 
 1171 A:e741  c0 20                              cpy #$20
 1172 A:e743  d0 f6                              bne mvpaste
 1173 A:e745                                    ; Just to be sure, zero out the next entry.
 1174 A:e745  a9 00                              lda #0
 1175 A:e747  91 48                              sta (zp_sd_address),y
 1176 A:e749                                    ; Now write the sector
 1177 A:e749  20 fb dd                           jsr fat32_wrcurrent
 1178 A:e74c                                    ; Done!
 1179 A:e74c  20 c0 e1                           jsr refreshpath
 1180 A:e74f  fa                                 plx 
 1181 A:e750  60                                 rts 
 1182 A:e751                           overf     
 1182 A:e751                                    
 1183 A:e751                                    ; copy it to the buffer so we don't overwrite the foldername
 1184 A:e751  a0 00                              ldy #0
 1185 A:e753                           mvff      
 1186 A:e753  b1 11                              lda (folderpointer),y
 1187 A:e755  99 20 07                           sta buffer+32,y
 1188 A:e758  c8                                 iny 
 1189 A:e759  c0 0d                              cpy #13
 1190 A:e75b  d0 f6                              bne mvff
 1191 A:e75d                           mvdn      
 1191 A:e75d                                    
 1192 A:e75d                                    ; store location
 1193 A:e75d  a9 20                              lda #<buffer+32
 1194 A:e75f  85 11                              sta folderpointer
 1195 A:e761  a9 07                              lda #>buffer+32
 1196 A:e763  85 12                              sta folderpointer+1
 1197 A:e765  60                                 rts 
 1198 A:e766                                     .) 

 1200 A:e766                           submsg    
 1201 A:e766  52 6f 6f 74 20 4e 6f ...           .byt "Root Not Found!",$0d,$0a,$00
 1202 A:e778                           filmsg    
 1203 A:e778  27 6c 6f 61 64 61 64 ...           .byt "'loadaddr.sar' Not Found!",$0d,$0a,$00
 1204 A:e794                           filmsg2   
 1205 A:e794  27 63 6f 64 65 2e 78 ...           .byt "'code.xpl' Not Found!",$0d,$0a,$00
 1206 A:e7ac                           lds       
 1207 A:e7ac  4c 6f 61 64 69 6e 67 ...           .byt "Loading SD Handler...",$00
 1208 A:e7c2                           savemsg   
 1208 A:e7c2                                    
 1209 A:e7c2  53 61 76 69 6e 67 2e ...           .byt "Saving...",$00
 1210 A:e7cc                           ends      
 1211 A:e7cc  44 6f 6e 65 2e 0d 0a 00            .byt "Done.",$0d,$0a,$00
 1212 A:e7d4                           femsg     
 1212 A:e7d4                                    
 1213 A:e7d4  46 69 6c 65 20 65 78 ...           .byt "File exists. Overwrite? (y/n): ",$00
 1214 A:e7f4                           foldermsg 
 1214 A:e7f4                                    
 1215 A:e7f4  4e 6f 20 73 75 63 68 ...           .byt "No such file or directory.",$0d,$0a,$00

 1217 A:e811                                    ; THE FOLLOWING MESSAGES ARE ALREADY IN TAPE.A65!
 1218 A:e811                                    ;loadedmsg
 1218 A:e811                                    
 1219 A:e811                                    ;  .byte "Loaded from ", $00
 1220 A:e811                                    ;tomsg
 1220 A:e811                                    
 1221 A:e811                                    ;  .byte " to ", $00

main.a65


 2645 A:e811                                    ; goofy ahh fake vi

vi65s.a65

    1 A:e811                                    ; VI
    2 A:e811                                    ; requires xplDOS
    3 A:e811                                    ;

    5 A:e811                           vicmd     
    5 A:e811                                    
    6 A:e811                                     .( 
    7 A:e811  da                                 phx 
    8 A:e812  20 cc df                           jsr cleardisplay
    9 A:e815  a9 0f                              lda #$0f
   10 A:e817  20 df df                           jsr print_chara
   11 A:e81a  a9 18                              lda #24
   12 A:e81c  20 df df                           jsr print_chara
   13 A:e81f  a9 02                              lda #$02
   14 A:e821  20 df df                           jsr print_chara
   15 A:e824  a9 00                              lda #0
   16 A:e826  20 df df                           jsr print_chara
   17 A:e829                                    ;; check arguments
   18 A:e829  a5 20                              lda ARGINDEX
   19 A:e82b  c9 02                              cmp #2             ; if there's two arguments, edit the typed file
   20 A:e82d  f0 0c                              beq processparam
   21 A:e82f  a5 20                              lda ARGINDEX
   22 A:e831  c9 01                              cmp #1             ; if there's only one argument, edit an unnamed file
   23 A:e833  d0 03                              bne jer
   24 A:e835  4c a8 e8                           jmp vnf
   25 A:e838                           jer       
   25 A:e838                                    
   26 A:e838  4c dc e2                           jmp error
   27 A:e83b                           processparam                  ; process the filename parameter
   28 A:e83b  18                                 clc 
   29 A:e83c  a9 00                              lda #<INPUT
   30 A:e83e  65 22                              adc ARGINDEX+2
   31 A:e840  85 11                              sta folderpointer
   32 A:e842  aa                                 tax 
   33 A:e843  a0 02                              ldy #>INPUT
   34 A:e845  84 12                              sty folderpointer+1
   35 A:e847  da                                 phx 
   36 A:e848  5a                                 phy 
   37 A:e849                                    ; print filename
   38 A:e849  a9 22                              lda #$22
   39 A:e84b  20 df df                           jsr print_chara
   40 A:e84e  7a                                 ply 
   41 A:e84f  fa                                 plx 
   42 A:e850  20 f0 df                           jsr w_acia_full
   43 A:e853  a9 22                              lda #$22
   44 A:e855  20 df df                           jsr print_chara
   45 A:e858  a9 20                              lda #$20
   46 A:e85a  20 df df                           jsr print_chara
   47 A:e85d                                    ; convert to SHORT
   48 A:e85d  20 41 e3                           jsr shortconvert
   49 A:e860                                    ; refresh
   50 A:e860  20 c0 e1                           jsr refreshpath
   51 A:e863                                    ; chech if the file exists
   52 A:e863  a6 11                              ldx folderpointer
   53 A:e865  a4 12                              ldy folderpointer+1
   54 A:e867  20 5b de                           jsr fat32_finddirent
   55 A:e86a  b0 3c                              bcs vnf
   56 A:e86c                                    ; if it exists, load it to $0900
   57 A:e86c                                    ; WARNING this will overwrite RAM! 
   58 A:e86c  20 e1 dc                           jsr fat32_opendirent
   59 A:e86f  a9 09                              lda #$09
   60 A:e871  85 5d                              sta fat32_address+1
   61 A:e873  64 5c                              stz fat32_address
   62 A:e875  20 1e df                           jsr fat32_file_read
   63 A:e878                                    ; now print first part to screen
   64 A:e878                                    ; BUG files can go past the screen limit, and glitch the viewer.
   65 A:e878  20 e8 df                           jsr ascii_home
   66 A:e87b  a2 00                              ldx #0
   67 A:e87d  a0 00                              ldy #0
   68 A:e87f  64 1a                              stz viaddr
   69 A:e881  a9 09                              lda #$09
   70 A:e883  85 1b                              sta viaddr+1
   71 A:e885                           vcplp     
   71 A:e885                                    
   72 A:e885  b2 1a                              lda (viaddr)
   73 A:e887  f0 28                              beq veof
   74 A:e889  c9 0d                              cmp #$0d
   75 A:e88b  f0 15                              beq cr
   76 A:e88d  c8                                 iny 
   77 A:e88e  c0 50                              cpy #80
   78 A:e890  f0 10                              beq cr
   79 A:e892                           otherv    
   79 A:e892                                    
   80 A:e892  20 df df                           jsr print_chara
   81 A:e895  f0 3a                              beq startcsr                ; file displayed, no eof yet
   82 A:e897  e6 1a                              inc viaddr
   83 A:e899  a5 1a                              lda viaddr
   84 A:e89b  d0 02                              bne nnon
   85 A:e89d  e6 1b                              inc viaddr+1
   86 A:e89f                           nnon      
   86 A:e89f                                    
   87 A:e89f  4c 85 e8                           jmp vcplp
   88 A:e8a2                           cr        
   88 A:e8a2                                    
   89 A:e8a2  e8                                 inx 
   90 A:e8a3  a0 00                              ldy #0
   91 A:e8a5  4c 92 e8                           jmp otherv
   92 A:e8a8                           vnf       
   92 A:e8a8                                    
   93 A:e8a8  a2 40                              ldx #<nfm
   94 A:e8aa  a0 e9                              ldy #>nfm
   95 A:e8ac  20 f0 df                           jsr w_acia_full
   96 A:e8af  a2 00                              ldx #0
   97 A:e8b1                           veof      
   97 A:e8b1                                    
   98 A:e8b1                                    ; eof reached. fill the screen with ~
   99 A:e8b1  e8                                 inx 
  100 A:e8b2  86 1e                              stx vif_end
  101 A:e8b4                           vinlp     
  101 A:e8b4                                    
  102 A:e8b4  a9 0f                              lda #$0f
  103 A:e8b6  20 df df                           jsr print_chara
  104 A:e8b9  8a                                 txa 
  105 A:e8ba  20 df df                           jsr print_chara
  106 A:e8bd  a9 0e                              lda #$0e
  107 A:e8bf  20 df df                           jsr print_chara
  108 A:e8c2  a9 00                              lda #0
  109 A:e8c4  20 df df                           jsr print_chara
  110 A:e8c7  a9 7e                              lda #'~'
  111 A:e8c9  20 df df                           jsr print_chara
  112 A:e8cc  e8                                 inx 
  113 A:e8cd  e0 18                              cpx #24
  114 A:e8cf  d0 e3                              bne vinlp
  115 A:e8d1                           startcsr  
  115 A:e8d1                                    
  116 A:e8d1  a9 0e                              lda #$0e
  117 A:e8d3  20 df df                           jsr print_chara
  118 A:e8d6  a9 46                              lda #70
  119 A:e8d8  20 df df                           jsr print_chara
  120 A:e8db  a9 0f                              lda #$0f
  121 A:e8dd  20 df df                           jsr print_chara
  122 A:e8e0  a9 18                              lda #24
  123 A:e8e2  20 df df                           jsr print_chara
  124 A:e8e5  a9 30                              lda #'0'
  125 A:e8e7  20 df df                           jsr print_chara
  126 A:e8ea  a9 2c                              lda #','
  127 A:e8ec  20 df df                           jsr print_chara
  128 A:e8ef  a9 30                              lda #'0'
  129 A:e8f1  20 df df                           jsr print_chara
  130 A:e8f4  20 e8 df                           jsr ascii_home
  131 A:e8f7  a9 02                              lda #$02
  132 A:e8f9  20 df df                           jsr print_chara
  133 A:e8fc  a9 db                              lda #$db
  134 A:e8fe  20 df df                           jsr print_chara
  135 A:e901  64 1c                              stz cursor_x
  136 A:e903  64 1d                              stz cursor_y
  137 A:e905                           vlp       
  137 A:e905                                    
  138 A:e905                                    ; wait until key pressed
  139 A:e905  20 c2 f3                           jsr rxpoll
  140 A:e908  ad 00 80                           lda $8000
  141 A:e90b                                    ; parse arrow keys
  142 A:e90b  c9 18                              cmp #$18
  143 A:e90d  f0 11                              beq vi_down
  144 A:e90f  c9 05                              cmp #$05
  145 A:e911  f0 15                              beq vi_up
  146 A:e913  c9 10                              cmp #$10
  147 A:e915  f0 19                              beq vi_left
  148 A:e917  c9 04                              cmp #$04
  149 A:e919  f0 1d                              beq vi_right
  150 A:e91b  4c 05 e9                           jmp vlp
  151 A:e91e  fa                                 plx 
  152 A:e91f  60                                 rts 
  153 A:e920                           vi_down   
  153 A:e920                                    
  154 A:e920  a9 1f                              lda #$1f
  155 A:e922  20 df df                           jsr print_chara
  156 A:e925  4c 05 e9                           jmp vlp
  157 A:e928                           vi_up     
  157 A:e928                                    
  158 A:e928  a9 1e                              lda #$1e
  159 A:e92a  20 df df                           jsr print_chara
  160 A:e92d  4c 05 e9                           jmp vlp
  161 A:e930                           vi_left   
  161 A:e930                                    
  162 A:e930  a9 1d                              lda #$1d
  163 A:e932  20 df df                           jsr print_chara
  164 A:e935  4c 05 e9                           jmp vlp
  165 A:e938                           vi_right  
  165 A:e938                                    
  166 A:e938  a9 1c                              lda #$1c
  167 A:e93a  20 df df                           jsr print_chara
  168 A:e93d  4c 05 e9                           jmp vlp
  169 A:e940                                     .) 

  171 A:e940                           nfm       
  171 A:e940  5b 4e 65 77 20 46 69 ...           .byt "[New File]",0

main.a65


 2649 A:e94b                                    ;; memory copy
 2650 A:e94b                                    ;; copies from (mem_source) to (mem_copy), all the way to (mem_end).
 2651 A:e94b                           memcopy   
 2651 A:e94b                                    
 2652 A:e94b                                     .( 
 2653 A:e94b  a0 00                              ldy #0
 2654 A:e94d                           loopbring 
 2655 A:e94d  b1 0a                              lda (mem_source),y  
 2656 A:e94f  91 0c                              sta (mem_copy),y
 2657 A:e951  e6 0a                              inc mem_source
 2658 A:e953  d0 02                              bne dontinc
 2659 A:e955  e6 0b                              inc mem_source+1
 2660 A:e957                           dontinc   
 2661 A:e957  e6 0c                              inc mem_copy
 2662 A:e959  d0 02                              bne calc
 2663 A:e95b  e6 0d                              inc mem_copy+1
 2664 A:e95d                           calc      
 2665 A:e95d  a5 0d                              lda mem_copy+1
 2666 A:e95f  c5 0f                              cmp mem_end+1
 2667 A:e961  d0 ea                              bne loopbring
 2668 A:e963  a5 0c                              lda mem_copy
 2669 A:e965  c5 0e                              cmp mem_end
 2670 A:e967  d0 e4                              bne loopbring
 2671 A:e969  60                                 rts 
 2672 A:e96a                                     .) 

 2674 A:e96a                                    ;; memory test
 2675 A:e96a                                    ;; the process is, for each page of memory (and MEMTESTBASE points
 2676 A:e96a                                    ;; to the starting point), we write the number of that page into
 2677 A:e96a                                    ;; each byte of that page (ie, each byte on page $1200 gets written
 2678 A:e96a                                    ;; with $12, each byte on page $4600 gets written with $46).
 2679 A:e96a                                    ;; then we read back and report errors. Leave the memory as it
 2680 A:e96a                                    ;; is at the end of the test so that I can poke around with the
 2681 A:e96a                                    ;; monitor later
 2682 A:e96a                                    ;;
 2683 A:e96a                           memtestcmd 
 2684 A:e96a  da                                 phx                    ; preserve the stack, we're going to need x...
 2685 A:e96b                                    ;; stage one is the write
 2686 A:e96b                           writetest 
 2687 A:e96b  64 46                              stz MEMTESTBASE
 2688 A:e96d  a9 05                              lda #$05             ;; we start at page $05
 2689 A:e96f  85 47                              sta MEMTESTBASE+1

 2691 A:e971                                    ;; for page x, write x into each byte
 2692 A:e971                                     .( 
 2693 A:e971                           fillpage  
 2694 A:e971  a0 00                              ldy #$00
 2695 A:e973  a5 47                              lda MEMTESTBASE+1          ; load bit pattern
 2696 A:e975                           loop      
 2697 A:e975  91 46                              sta (MEMTESTBASE),y
 2698 A:e977  c8                                 iny 
 2699 A:e978  d0 fb                              bne loop

 2701 A:e97a                                    ;; move onto the next page, as long as we're still in the RAM
 2702 A:e97a                           nextpage  
 2703 A:e97a                                    ;lda BASE+1
 2704 A:e97a  1a                                 inc                    ; accumulator still holds page numner
 2705 A:e97b  c9 80                              cmp #$80             ; stop when we hit the upper half of memory
 2706 A:e97d  f0 04                              beq readtest
 2707 A:e97f  85 47                              sta MEMTESTBASE+1
 2708 A:e981  80 ee                              bra fillpage
 2709 A:e983                                     .) 

 2711 A:e983                                    ;; stage two. read it back and check.
 2712 A:e983                           readtest  
 2713 A:e983                                    ;; start at the beginning again
 2714 A:e983  64 46                              stz MEMTESTBASE
 2715 A:e985  a9 05                              lda #$05
 2716 A:e987  85 47                              sta MEMTESTBASE+1

 2718 A:e989                                     .( 
 2719 A:e989                                    ;; each byte should be the same as the page
 2720 A:e989                           nextpage  
 2721 A:e989  a0 00                              ldy #$00
 2722 A:e98b                           loop      
 2723 A:e98b  b1 46                              lda (MEMTESTBASE),y
 2724 A:e98d  c5 47                              cmp MEMTESTBASE+1
 2725 A:e98f  d0 0e                              bne testerr
 2726 A:e991  c8                                 iny 
 2727 A:e992  d0 f7                              bne loop

 2729 A:e994  a5 47                              lda MEMTESTBASE+1
 2730 A:e996  1a                                 inc 
 2731 A:e997  c9 80                              cmp #$80
 2732 A:e999  f0 10                              beq exit
 2733 A:e99b  85 47                              sta MEMTESTBASE+1
 2734 A:e99d  80 ea                              bra nextpage
 2735 A:e99f                           testerr   
 2736 A:e99f  a5 47                              lda MEMTESTBASE+1
 2737 A:e9a1  20 6d d6                           jsr putax
 2738 A:e9a4  98                                 tya 
 2739 A:e9a5  20 6d d6                           jsr putax
 2740 A:e9a8  20 ad e9                           jsr memtesterr
 2741 A:e9ab                           exit      
 2742 A:e9ab  fa                                 plx 
 2743 A:e9ac  60                                 rts 
 2744 A:e9ad                                     .) 

 2747 A:e9ad                           memtesterr 
 2748 A:e9ad  a0 00                              ldy #0
 2749 A:e9af                                     .( 
 2750 A:e9af                           next_char 
 2751 A:e9af                           wait_txd_empty 
 2752 A:e9af  ad 01 80                           lda ACIA_STATUS
 2753 A:e9b2  29 10                              and #$10
 2754 A:e9b4  f0 f9                              beq wait_txd_empty
 2755 A:e9b6  b9 14 f3                           lda memerrstr,y
 2756 A:e9b9  f0 06                              beq endstr
 2757 A:e9bb  8d 00 80                           sta ACIA_DATA
 2758 A:e9be  c8                                 iny 
 2759 A:e9bf  80 ee                              bra next_char
 2760 A:e9c1                           endstr    
 2761 A:e9c1  20 45 d6                           jsr crlf
 2762 A:e9c4                                     .) 
 2763 A:e9c4  60                                 rts 

 2766 A:e9c5                                    ;;; print the string pointed to at PRINTVEC
 2767 A:e9c5                                    ;;;
 2768 A:e9c5                           printvecstr 
 2769 A:e9c5  a0 00                              ldy #0
 2770 A:e9c7                                     .( 
 2771 A:e9c7                           next_char 
 2772 A:e9c7                           wait_txd_empty 
 2773 A:e9c7  ad 01 80                           lda ACIA_STATUS
 2774 A:e9ca  29 10                              and #$10             ;; if you have a wdc 65c51 installed, replace this 
 2775 A:e9cc  f0 f9                              beq wait_txd_empty                ;; with a loop.
 2776 A:e9ce  b1 42                              lda (PRINTVEC),y            ;;
 2777 A:e9d0  f0 06                              beq endstr                ;; be sure to also change the code in acia.a65!
 2778 A:e9d2  8d 00 80                           sta ACIA_DATA
 2779 A:e9d5  c8                                 iny 
 2780 A:e9d6  80 ef                              bra next_char
 2781 A:e9d8                           endstr    
 2782 A:e9d8                                     .) 
 2783 A:e9d8  60                                 rts 

 2785 A:e9d9                                    ;;; print a string bigger than 256 bytes. 
 2786 A:e9d9                                    ;;; start at PRINTVEC and end at ENDVEC
 2787 A:e9d9                                    ;;;
 2788 A:e9d9                           printveclong 
 2788 A:e9d9                                    
 2789 A:e9d9                                     .( 
 2790 A:e9d9  da                                 phx 
 2791 A:e9da                           lp        
 2791 A:e9da                                    
 2792 A:e9da  b2 42                              lda (PRINTVEC)
 2793 A:e9dc  20 df df                           jsr print_chara
 2794 A:e9df  e6 42                              inc PRINTVEC
 2795 A:e9e1  d0 02                              bne pvl
 2796 A:e9e3  e6 43                              inc PRINTVEC+1
 2797 A:e9e5                           pvl       
 2797 A:e9e5                                    
 2798 A:e9e5  a5 42                              lda PRINTVEC
 2799 A:e9e7  c5 0e                              cmp ENDVEC
 2800 A:e9e9  d0 ef                              bne lp
 2801 A:e9eb  a5 43                              lda PRINTVEC+1
 2802 A:e9ed  c5 0f                              cmp ENDVEC+1
 2803 A:e9ef  d0 e9                              bne lp
 2804 A:e9f1  fa                                 plx 
 2805 A:e9f2  60                                 rts 
 2806 A:e9f3                                     .) 

 2809 A:e9f3                                    ;;;
 2810 A:e9f3                                    ;;; Various string constants
 2811 A:e9f3                                    ;;;

 2813 A:e9f3                           hextable  
 2813 A:e9f3  30 31 32 33 34 35 36 ...           .byt "0123456789ABCDEF"
 2814 A:ea03                           greeting  
 2814 A:ea03  58 50 4c 2d 33 32 20 ...           .byt "XPL-32 monitor",$0d,$0a,$00
 2815 A:ea14                           prompt    
 2815 A:ea14  3e                                 .byt ">"
 2816 A:ea15                           aboutstring 
 2816 A:ea15  58 50 4c 2d 33 32 20 ...           .byt "XPL-32 monitor - a command prompt for the XPL-32.",$0d,$0a
 2817 A:ea48  54 68 69 73 20 70 72 ...           .byt "This program was original developed by Paul Dourish, and it was called Mitemon.",$0d,$0a
 2818 A:ea99  49 6e 20 74 68 69 73 ...           .byt "In this version, I have added XPL-32 support, and a couple new commands.",$0d,$0a,$0d,$0a
 2819 A:eae5  43 6f 70 79 72 69 67 ...           .byt "Copyright (C) 2023  Waverider & Paul Dourish",$0d,$0a,$0d,$0a
 2820 A:eb15  54 68 69 73 20 70 72 ...           .byt "This program is free software: you can redistribute it and/or modify",$0d,$0a
 2821 A:eb5b  69 74 20 75 6e 64 65 ...           .byt "it under the terms of the GNU General Public License as published by",$0d,$0a
 2822 A:eba1  74 68 65 20 46 72 65 ...           .byt "the Free Software Foundation, either version 3 of the License, or",$0d,$0a
 2823 A:ebe4  28 61 74 20 79 6f 75 ...           .byt "(at your option) any later version.",$0d,$0a,$0d,$0a
 2824 A:ec0b  54 68 69 73 20 70 72 ...           .byt "This program is distributed in the hope that it will be useful,",$0d,$0a
 2825 A:ec4c  62 75 74 20 57 49 54 ...           .byt "but WITHOUT ANY WARRANTY",$3b," without even the implied warranty of",$0d,$0a
 2826 A:ec8c  4d 45 52 43 48 41 4e ...           .byt "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the",$0d,$0a
 2827 A:eccb  47 4e 55 20 47 65 6e ...           .byt "GNU General Public License for more details.",$0d,$0a,$0d,$0a
 2828 A:ecfb  59 6f 75 20 73 68 6f ...           .byt "You should have received a copy of the GNU General Public License",$0d,$0a
 2829 A:ed3e  61 6c 6f 6e 67 20 77 ...           .byt "along with this program.  If not, see <https://www.gnu.org/licenses/>.",$0d,$0a
 2830 A:ed86                           aboutstringend 
 2830 A:ed86  00                                 .byt $00
 2831 A:ed87                           helpstring 
 2831 A:ed87  43 6f 6d 6d 61 6e 64 ...           .byt "Commands available:",$0d,$0a,$0d,$0a
 2832 A:ed9e  65 63 68 6f 09 20 2d ...           .byt "echo",$09," - Echos a string to the screen.",$0d,$0a
 2833 A:edc5  68 65 6c 70 09 20 2d ...           .byt "help",$09," - displays this screen",$0d,$0a
 2834 A:ede3  61 62 6f 75 74 09 20 ...           .byt "about",$09," - displays information about this software",$0d,$0a
 2835 A:ee16  64 75 6d 70 09 20 2d ...           .byt "dump",$09," - dumps memory contents at a specific address",$0d,$0a
 2836 A:ee4b  70 6f 6b 65 09 20 2d ...           .byt "poke",$09," - puts a value at an address",$0d,$0a,$00
 2837 A:ee70  7a 65 72 6f 09 20 2d ...           .byt "zero",$09," - fills a memory range with zeros",$0d,$0a
 2838 A:ee99  67 6f 09 20 2d 20 6a ...           .byt "go",$09," - jumps to an address",$0d,$0a
 2839 A:eeb4  78 72 65 63 65 69 76 ...           .byt "xreceive - receive from the serial port with xmodem to a specified address",$0d,$0a
 2840 A:ef00  64 69 73 09 20 2d 20 ...           .byt "dis",$09," - disassembles machine code a memory range into assembly, and prints that onto the screen",$0d,$0a,$00
 2841 A:ef61  69 6e 70 75 74 09 20 ...           .byt "input",$09," - inputs hexadecimal bytes from the keyboard to an address. terminated by a double return.",$0d,$0a
 2842 A:efc4  6d 65 6d 74 65 73 74 ...           .byt "memtest  - tests memory integrity",$0d,$0a
 2843 A:efe7                                    ;.byte "receive  - like xreceive, but no protocol is used", $0d, $0a
 2844 A:efe7  76 69 09 20 2d 20 65 ...           .byt "vi",$09," - edits a file on the sd card (NOT DONE)",$0d,$0a
 2845 A:f015  6c 6f 61 64 09 20 2d ...           .byt "load",$09," - load a memory card's automatic loading system - also can load the specified file",$0d,$0a
 2846 A:f06f  73 61 76 65 09 20 2d ...           .byt "save",$09," - saves a file to the memory card",$0d,$0a
 2847 A:f098  6c 73 09 20 2d 20 6c ...           .byt "ls",$09," - list the current directory",$0d,$0a
 2848 A:f0ba  63 64 09 20 2d 20 63 ...           .byt "cd",$09," - change to the specified directory",$0d,$0a
 2849 A:f0e3  63 61 74 09 20 2d 20 ...           .byt "cat",$09," - dumps a file directly to the screen",$0d,$0a
 2850 A:f10f  72 6d 09 20 2d 20 72 ...           .byt "rm",$09," - removes a file",$0d,$0a
 2851 A:f125  6d 76 09 20 2d 20 6d ...           .byt "mv",$09," - moves a file",$0d,$0a
 2852 A:f139  63 6c 65 61 72 09 20 ...           .byt "clear",$09," - clears the screen",$0d,$0a
 2853 A:f155  74 6c 6f 61 64 09 20 ...           .byt "tload",$09," - loads a file from the tape system",$0d,$0a
 2854 A:f181  74 73 61 76 65 09 20 ...           .byt "tsave",$09," - saves a file to the tape system",$0d,$0a
 2855 A:f1ab  72 74 69 09 20 2d 20 ...           .byt "rti",$09," - return from any pending interuppts. warning-might crash",$0d,$0a
 2856 A:f1eb                           helpstringend 
 2856 A:f1eb  00                                 .byt $00
 2857 A:f1ec                           nocmderrstr 
 2857 A:f1ec  43 6f 6d 6d 61 6e 64 ...           .byt "Command not recognized",$0d,$0a,$00
 2858 A:f205                           implementstring 
 2858 A:f205  4e 6f 74 20 79 65 74 ...           .byt "Not yet implemented",$0d,$0a,$00
 2859 A:f21b                           dumperrstring 
 2859 A:f21b  55 73 61 67 65 3a 20 ...           .byt "Usage: dump hexaddress [count:10]",$00
 2860 A:f23d                           pokeerrstring 
 2860 A:f23d  55 73 61 67 65 3a 20 ...           .byt "Usage: poke hexaddress hexvalue",$00
 2861 A:f25d                           goerrstring 
 2861 A:f25d  55 73 61 67 65 3a 20 ...           .byt "Usage: go hexaddress",$00
 2862 A:f272                           zeroerrstring 
 2862 A:f272  55 73 61 67 65 3a 20 ...           .byt "Usage: zero hexaddress [count:10]",$00
 2863 A:f294                           xrecverrstring 
 2863 A:f294  55 73 61 67 65 3a 20 ...           .byt "Usage: xreceive hexaddress",$00
 2864 A:f2af                           tsaveerrstring 
 2864 A:f2af  55 73 61 67 65 3a 20 ...           .byt "Usage: tsave startaddr endaddr",$00
 2865 A:f2ce                           inputhelpstring 
 2865 A:f2ce  45 6e 74 65 72 20 74 ...           .byt "Enter two-digit hex bytes. Blank line to end.",$00
 2866 A:f2fc                           inputerrstring 
 2866 A:f2fc  55 73 61 67 65 3a 20 ...           .byt "Usage: input hexaddress",$00
 2867 A:f314                           memerrstr 
 2867 A:f314  4d 65 6d 6f 72 79 20 ...           .byt "Memory test failed",$00
 2868 A:f327                           diserrorstring 
 2868 A:f327  55 73 61 67 65 3a 20 ...           .byt "Usage: dis hexaddress [count: 10]",$00
 2869 A:f349                                    ; transferstring
 2869 A:f349  53 65 72 69 61 6c 20 ...           .byt "Serial [S] or Memory Card [M] Transfer?",$0d,$0a,$00
 2870 A:f373                           serialstring 
 2870 A:f373  53 74 61 72 74 20 53 ...           .byt "Start Serial Load.",$0d,$0a,$00
 2871 A:f388                           loaddonestring 
 2871 A:f388  4c 6f 61 64 20 43 6f ...           .byt "Load Complete.",$0d,$0a,$00
 2872 A:f399                           char      
 2872 A:f399  2e                                 .byt "."
 2873 A:f39a                           sd_error  
 2873 A:f39a  53 44 20 43 61 72 64 ...           .byt "SD Card failed to initialize",$0d,$0a,$00
 2874 A:f3b9                           errormsg  
 2874 A:f3b9  45 72 72 6f 72 21 0d ...           .byt "Error!",$0d,$0a,$00

 2876 A:f3c2                           rxpoll    
 2876 A:f3c2                                    
 2877 A:f3c2  ad 01 80                           lda ACIA_STATUS
 2878 A:f3c5  29 08                              and #$08
 2879 A:f3c7  f0 f9                              beq rxpoll
 2880 A:f3c9  60                                 rts 

 2882 A:f3ca                           interrupt 
 2883 A:f3ca  6c fe 7f                           jmp ($7ffe)
 2884 A:f3cd  40                                 rti 

 2886 A:f3ce  00 ff c0 0b 00 64 2c ...           .dsb 3008,$00

 2888 A:ff8e                                    ; ----KERNAL----

 2890 A:ff8e                                     *= $ff8e

 2892 A:ff8e                                    ; New SD/fat32 commands
 2893 A:ff8e                           KERNAL_sd_writesector 
 2894 A:ff8e  4c 4c d8                           jmp sd_writesector
 2895 A:ff91                                    ;fat
 2896 A:ff91                           KERNAL_fat32_writenextsector 
 2896 A:ff91                                    
 2897 A:ff91  20 15 db                           jsr fat32_writenextsector
 2898 A:ff94                           KERNAL_fat32_allocatecluster 
 2898 A:ff94                                    
 2899 A:ff94  20 bd db                           jsr fat32_allocatecluster
 2900 A:ff97                           KERNAL_fat32_findnextfreecluster 
 2900 A:ff97                                    
 2901 A:ff97  20 92 dc                           jsr fat32_findnextfreecluster
 2902 A:ff9a                           KERNAL_fat32_writedirent 
 2902 A:ff9a                                    
 2903 A:ff9a  20 44 dd                           jsr fat32_writedirent
 2904 A:ff9d                           KERNAL_fat32_deletefile 
 2904 A:ff9d                                    
 2905 A:ff9d  20 9b de                           jsr fat32_deletefile
 2906 A:ffa0                           KERNAL_fat32_file_write 
 2906 A:ffa0                                    
 2907 A:ffa0  20 3e df                           jsr fat32_file_write

 2909 A:ffa3                                    ; DOS commands
 2910 A:ffa3                           KERNAL_save 
 2910 A:ffa3                                    
 2911 A:ffa3  4c 14 e6                           jmp savekernal
 2912 A:ffa6                           KERNAL_cd 
 2912 A:ffa6                                    
 2913 A:ffa6  4c ba e2                           jmp cdsub
 2914 A:ffa9                           KERNAL_ls 
 2914 A:ffa9                                    
 2915 A:ffa9  4c 36 e4                           jmp list

 2917 A:ffac                                    ; inits

 2919 A:ffac                           KERNAL_acia_init 
 2919 A:ffac                                    
 2920 A:ffac  4c a8 df                           jmp acia_init
 2921 A:ffaf                           KERNAL_via_init 
 2921 A:ffaf                                    
 2922 A:ffaf  4c f0 d6                           jmp via_init
 2923 A:ffb2                           KERNAL_sd_init 
 2923 A:ffb2                                    
 2924 A:ffb2  4c 05 d7                           jmp sd_init
 2925 A:ffb5                           KERNAL_fat32_init 
 2925 A:ffb5                                    
 2926 A:ffb5  4c da d8                           jmp fat32_init

 2928 A:ffb8                                    ; acia

 2930 A:ffb8                           KERNAL_print_hex_acia 
 2930 A:ffb8                                    
 2931 A:ffb8  4c b5 df                           jmp print_hex_acia
 2932 A:ffbb                           KERNAL_crlf 
 2932 A:ffbb                                    
 2933 A:ffbb  4c 45 d6                           jmp crlf
 2934 A:ffbe                           KERNAL_cleardisplay 
 2934 A:ffbe                                    
 2935 A:ffbe  4c cc df                           jmp cleardisplay
 2936 A:ffc1                           KERNAL_rxpoll 
 2936 A:ffc1                                    
 2937 A:ffc1  4c c2 f3                           jmp rxpoll
 2938 A:ffc4                           KERNAL_txpoll 
 2938 A:ffc4                                    
 2939 A:ffc4  4c d7 df                           jmp txpoll
 2940 A:ffc7                           KERNAL_print_chara 
 2940 A:ffc7                                    
 2941 A:ffc7                           KERNAL_print_char_acia 
 2941 A:ffc7                                    
 2942 A:ffc7  4c df df                           jmp print_chara
 2943 A:ffca                           KERNAL_ascii_home 
 2943 A:ffca                                    
 2944 A:ffca  4c e8 df                           jmp ascii_home
 2945 A:ffcd                           KERNAL_w_acia_full 
 2946 A:ffcd  4c f0 df                           jmp w_acia_full

 2948 A:ffd0                                    ; fat32

 2950 A:ffd0                           KERNAL_fat32_seekcluster 
 2950 A:ffd0                                    
 2951 A:ffd0  4c 0c da                           jmp fat32_seekcluster
 2952 A:ffd3                           KERNAL_fat32_readnextsector 
 2953 A:ffd3  4c ea da                           jmp fat32_readnextsector
 2954 A:ffd6                           KERNAL_fat32_openroot 
 2954 A:ffd6                                    
 2955 A:ffd6  4c 9c db                           jmp fat32_openroot
 2956 A:ffd9                           KERNAL_fat32_opendirent 
 2956 A:ffd9                                    
 2957 A:ffd9  4c e1 dc                           jmp fat32_opendirent
 2958 A:ffdc                           KERNAL_fat32_readdirent 
 2959 A:ffdc  4c 25 de                           jmp fat32_readdirent
 2960 A:ffdf                           KERNAL_fat32_finddirent 
 2960 A:ffdf                                    
 2961 A:ffdf  4c 5b de                           jmp fat32_finddirent
 2962 A:ffe2                           KERNAL_fat32_file_readbyte 
 2962 A:ffe2                                    
 2963 A:ffe2  4c d5 de                           jmp fat32_file_readbyte
 2964 A:ffe5                           KERNAL_fat32_file_read 
 2964 A:ffe5                                    
 2965 A:ffe5  4c 1e df                           jmp fat32_file_read

 2967 A:ffe8                                    ; sd

 2969 A:ffe8                           KERNAL_sd_readbyte 
 2969 A:ffe8                                    
 2970 A:ffe8  4c 82 d7                           jmp sd_readbyte
 2971 A:ffeb                           KERNAL_sd_sendcommand 
 2971 A:ffeb                                    
 2972 A:ffeb  4c bc d7                           jmp sd_sendcommand
 2973 A:ffee                           KERNAL_sd_readsector 
 2973 A:ffee                                    
 2974 A:ffee  4c f6 d7                           jmp sd_readsector

 2976 A:fff1                                    ; other

 2978 A:fff1                           KERNAL_loadcmd 
 2978 A:fff1                                    
 2979 A:fff1  4c 06 e5                           jmp loadone
 2980 A:fff4                           KERNAL_tsave 
 2980 A:fff4                                    
 2981 A:fff4  4c 04 ca                           jmp tsavecmd+94
 2982 A:fff7                           KERNAL_tload 
 2982 A:fff7                                    
 2983 A:fff7  4c d3 cb                           jmp tload_kernal

 2985 A:fffa                                     *= $fffa
 2986 A:fffa  ca f3                              .word interrupt
 2987 A:fffc  00 c0                              .word reset
 2988 A:fffe  ca f3                              .word interrupt
