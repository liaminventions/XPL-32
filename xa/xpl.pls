
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
   86 A:c000                                    zp_fat32_variables=$4e           ; 55 bytes
   87 A:c000                                    fat32_variables=$0300
   88 A:c000                                    fnstash=$0318           ; 32 bytes
   89 A:c000                                    last_slash_pos=$0338
   90 A:c000                                    ; only used during fat32 processing
   91 A:c000                                    path=$0400           ; page
   92 A:c000                                    fat32_workspace=$0500           ; two pages
   93 A:c000                                    buffer=$0700           ; 24 bytes
   94 A:c000                                    ; now, addresses $0725-$7ffc are free.

   96 A:c000                                    ;; $0080-00FF is my operand stack
   97 A:c000                                    ;; $0100-01FF is 6502 stack
   98 A:c000                                    INPUT=$0200           ; block out this page for monitor command input
   99 A:c000                                    ;; $0300-03FF is blocked for xmodem buffer
  100 A:c000                                    ;; $0400-04FF is blocked for xmodem testing (temporary)
  101 A:c000                                    ;;
  102 A:c000                                    ;; names of variables used in the scratchpad
  103 A:c000                                    ;;XYLODSAV2 = $10  ; temporary address for save command
  104 A:c000                                    STARTADDR=$12           ; for start addr for receive
  105 A:c000                                    ENDADDR=$14
  106 A:c000                                    serialvar=$16
  107 A:c000                                    ; only used in tape
  107 A:c000                                    
  108 A:c000                                    thing=$10           ; 1byt
  109 A:c000                                    tapest=$11           ; 1byt
  110 A:c000                                    cnt=$12           ; 2byt
  111 A:c000                                    len=$14           ; 2byt
  112 A:c000                                    cnt2=$15           ; 2byt
  113 A:c000                                    tapespeed=$17           ; 1byt
  114 A:c000                                    ;; xplDOS
  115 A:c000                                    fileext=$14           ; 1byt
  116 A:c000                                    filetype=$15           ; 1byt
  117 A:c000                                    folderpointer=$11           ; 2byt
  118 A:c000                                    pathindex=$16           ; 2byt
  119 A:c000                                    backdir=$18           ; 1byt
  120 A:c000                                    sc=$19           ; 1byt
  121 A:c000                                    ;dircnt  = $1a ; 1byt
  122 A:c000                                    savestart=$1a           ; 2byt
  123 A:c000                                    saveend=$10           ; 2byt
  124 A:c000                                    savepoint=$1c           ; 2byt
  125 A:c000                                    ;; vi..?
  126 A:c000                                    viaddr=$1a           ; 2byt
  127 A:c000                                    cursor_x=$1c           ; 1byt
  128 A:c000                                    cursor_y=$1d           ; 1byt
  129 A:c000                                    vif_end=$1e           ; 2byt

  131 A:c000                                    ;; startup enable
  132 A:c000                                    SEN=$7ffd
  133 A:c000                                    ;; after startup enable, there is a irq address.
  134 A:c000                                    ;; BUG THERE IS NO NMI! this is due to there being no NMI on the XPL-32 PCB. (not yet implemented)
  135 A:c000                                    ; 

  137 A:c000                                    ;;;;;;;;;;;;;;;;;
  138 A:c000                                    ;;;
  139 A:c000                                    ;;; Include standard startup code
  140 A:c000                                    ;;;
  141 A:c000                                    ;;;;;;;;;;;;;;;;;

  143 A:c000                           reset     

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

  147 A:c003                                    ;;; Dispatch table
  148 A:c003                                    ;;;
  149 A:c003                                    ;;; each entry has a two-byte pointer to the next entry (or $0000 on end)
  150 A:c003                                    ;;; then a null-terminated string that names the command
  151 A:c003                                    ;;; then a two-type pointer for the code to execute the command
  152 A:c003                                    ;;;
  153 A:c003                           table     
  154 A:c003  0d c0                              .word table1
  155 A:c005  61 62 6f 75 74 00                  .byt "about",$00
  156 A:c00b  9b c7                              .word aboutcmd
  157 A:c00d                           table1    
  158 A:c00d  16 c0                              .word table2
  159 A:c00f  68 65 6c 70 00                     .byt "help",$00
  160 A:c014  ae c7                              .word helpcmd
  161 A:c016                           table2    
  162 A:c016  1f c0                              .word table3
  163 A:c018  64 75 6d 70 00                     .byt "dump",$00
  164 A:c01d  3c c8                              .word dumpcmd
  165 A:c01f                           table3    
  166 A:c01f  28 c0                              .word table4
  167 A:c021  65 63 68 6f 00                     .byt "echo",$00
  168 A:c026  cd c7                              .word echocmd
  169 A:c028                           table4    
  170 A:c028  31 c0                              .word table5
  171 A:c02a  70 6f 6b 65 00                     .byt "poke",$00
  172 A:c02f  f6 c7                              .word pokecmd
  173 A:c031                           table5    
  174 A:c031  38 c0                              .word table6
  175 A:c033  67 6f 00                           .byt "go",$00
  176 A:c036  71 c9                              .word gocmd
  177 A:c038                           table6    
  178 A:c038  41 c0                              .word table7
  179 A:c03a  74 65 73 74 00                     .byt "test",$00
  180 A:c03f  bb cc                              .word testcmd
  181 A:c041                           table7    
  182 A:c041  4d c0                              .word table8
  183 A:c043  6d 65 6d 74 65 73 74 00            .byt "memtest",$00
  184 A:c04b  4c eb                              .word memtestcmd
  185 A:c04d                           table8    
  186 A:c04d  55 c0                              .word table9
  187 A:c04f  64 69 73 00                        .byt "dis",$00
  188 A:c053  17 cf                              .word discmd
  189 A:c055                           table9    
  190 A:c055  62 c0                              .word table10
  191 A:c057  78 72 65 63 65 69 76 ...           .byt "xreceive",$00
  192 A:c060  bc cc                              .word xreceivecmd
  193 A:c062                           table10   
  194 A:c062  6b c0                              .word table11
  195 A:c064  7a 65 72 6f 00                     .byt "zero",$00
  196 A:c069  0a c9                              .word zerocmd
  197 A:c06b                           table11   
  198 A:c06b  75 c0                              .word table12
  199 A:c06d  69 6e 70 75 74 00                  .byt "input",$00
  200 A:c073  7f ce                              .word inputcmd
  201 A:c075                           table12   
  202 A:c075                                    ;.word table13
  203 A:c075                                    ;.byte "receive", $00
  204 A:c075                                    ;.word receivecmd
  205 A:c075                                    ;table13
  206 A:c075  7c c0                              .word table13
  207 A:c077  76 69 00                           .byt "vi",$00
  208 A:c07a  f3 e9                              .word vicmd
  209 A:c07c                           table13   
  210 A:c07c  85 c0                              .word table14
  211 A:c07e  6c 6f 61 64 00                     .byt "load",$00
  212 A:c083  82 e6                              .word loadcmd
  213 A:c085                           table14   
  214 A:c085  8f c0                              .word table15
  215 A:c087  74 73 61 76 65 00                  .byt "tsave",$00
  216 A:c08d  a6 c9                              .word tsavecmd
  217 A:c08f                           table15   
  218 A:c08f  99 c0                              .word table16
  219 A:c091  74 6c 6f 61 64 00                  .byt "tload",$00
  220 A:c097  b7 cb                              .word tloadcmd
  221 A:c099                           table16   
  222 A:c099  a0 c0                              .word table17
  223 A:c09b  6c 73 00                           .byt "ls",$00
  224 A:c09e  ea e5                              .word lscmd
  225 A:c0a0                           table17   
  226 A:c0a0  a7 c0                              .word table18
  227 A:c0a2  63 64 00                           .byt "cd",$00
  228 A:c0a5  d7 e3                              .word cdcmd
  229 A:c0a7                           table18   
  230 A:c0a7  af c0                              .word table19
  231 A:c0a9  63 61 74 00                        .byt "cat",$00
  232 A:c0ad  7a e4                              .word catcmd
  233 A:c0af                           table19   
  234 A:c0af  b9 c0                              .word table20
  235 A:c0b1  63 6c 65 61 72 00                  .byt "clear",$00
  236 A:c0b7  a0 c9                              .word clearcmd
  237 A:c0b9                           table20   
  238 A:c0b9  c2 c0                              .word table21
  239 A:c0bb  73 61 76 65 00                     .byt "save",$00
  240 A:c0c0  9c e7                              .word savecmd
  241 A:c0c2                           table21   
  242 A:c0c2  c9 c0                              .word table22
  243 A:c0c4  72 6d 00                           .byt "rm",$00
  244 A:c0c7  6c e8                              .word rmcmd
  245 A:c0c9                           table22   
  246 A:c0c9  d0 c0                              .word table23
  247 A:c0cb  6d 76 00                           .byt "mv",$00
  248 A:c0ce  aa e8                              .word mvcmd
  249 A:c0d0                           table23   
  250 A:c0d0  00 00                              .word $00              ; this signals it's the last entry in the table
  251 A:c0d2  72 74 69 00                        .byt "rti",$00
  252 A:c0d6  7c ce                              .word rticmd

  254 A:c0d8                                    ;; More utility routines
  255 A:c0d8                                    ;;

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


  259 A:c380                                    ;; Finally -- we actually start executing code
  260 A:c380                                    ;;
  261 A:c380                           startup   

  263 A:c380                                    ;; the very first thing we do is to clear the memory
  264 A:c380                                    ;; used to do this in a subrouting, but of course it trashes
  265 A:c380                                    ;; the stack!
  266 A:c380                                    ;clearmem
  267 A:c380                                    ;.(
  268 A:c380                                    ;  stz $00  
  269 A:c380                                    ;  stz $01
  270 A:c380                                    ;nextpage
  271 A:c380                                    ;  ldy #0
  272 A:c380                                    ;  lda #0
  273 A:c380                                    ;clearloop
  274 A:c380                                    ;  sta ($00),y
  275 A:c380                                    ;  iny
  276 A:c380                                    ;  bne clearloop
  277 A:c380                                    ;  inx
  278 A:c380                                    ;  stx $01
  279 A:c380                                    ;  cpx #$80
  280 A:c380                                    ;  bne nextpage
  281 A:c380                                    ;.)

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


  285 A:c38a  20 90 c3                           jsr dostartupsound
  286 A:c38d  4c 66 c6                           jmp init_acia

  288 A:c390                                    ;; Include Startup sound and sound effect engine
  289 A:c390                                    ;;

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

   39 A:c3bd  20 2d eb                           jsr memcopy

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
  137 A:c65d  20 f0 e0                           jsr clear_sid
  138 A:c660  a9 43                              lda #$43
  139 A:c662  8d fd 7f                           sta SEN
  140 A:c665                           ender     
  140 A:c665                                    
  141 A:c665  60                                 rts 

main.a65


  293 A:c666                                    ;; Initialize the ACIA
  294 A:c666                                    ;;

  296 A:c666                           init_acia 
  297 A:c666  a9 0b                              lda #%00001011             ; No parity, no echo, no interrupt
  298 A:c668  8d 02 80                           sta ACIA_COMMAND
  299 A:c66b  a9 1f                              lda #%00011111             ; 1 stop bit, 8 data bits, 19200 baud
  300 A:c66d  8d 03 80                           sta ACIA_CONTROL

  302 A:c670  a9 02                              lda #$02
  303 A:c672  20 74 e0                           jsr print_chara                ; set cursor to _
  304 A:c675  a9 5f                              lda #$5f
  305 A:c677  20 74 e0                           jsr print_chara

  307 A:c67a  20 f0 d6                           jsr via_init
  308 A:c67d  20 05 d7                           jsr sd_init
  309 A:c680  90 06                              bcc load1
  310 A:c682  9c 00 04                           stz path
  311 A:c685  4c db c6                           jmp initf
  312 A:c688                           load1     
  313 A:c688  20 da d8                           jsr fat32_init
  314 A:c68b  b0 1f                              bcs initerror

  316 A:c68d                                    ; Open root directory
  317 A:c68d  20 f7 db                           jsr fat32_openroot

  319 A:c690                                    ; Find subdirectory by name
  320 A:c690  a2 1e                              ldx #<subdirname
  321 A:c692  a0 e2                              ldy #>subdirname
  322 A:c694  20 e4 de                           jsr fat32_finddirent
  323 A:c697  90 0d                              bcc foundsubdirr

  325 A:c699                                    ; Subdirectory not found
  326 A:c699  a0 e9                              ldy #>submsg
  327 A:c69b  a2 48                              ldx #<submsg
  328 A:c69d  20 85 e0                           jsr w_acia_full
  329 A:c6a0  9c 00 04                           stz path
  330 A:c6a3  4c db c6                           jmp initf

  332 A:c6a6                           foundsubdirr 

  334 A:c6a6                                    ; Open subdirectory
  335 A:c6a6  20 5d dd                           jsr fat32_opendirent                ; open folder

  337 A:c6a9  4c c7 c6                           jmp initdone

  339 A:c6ac                           initerror 
  340 A:c6ac                                    ; Error during FAT32 initialization

  342 A:c6ac  a0 e2                              ldy #>fat_error
  343 A:c6ae  a2 3f                              ldx #<fat_error
  344 A:c6b0  20 85 e0                           jsr w_acia_full
  345 A:c6b3  ad 62 00                           lda fat32_errorstage
  346 A:c6b6  20 4a e0                           jsr print_hex_acia
  347 A:c6b9  a9 21                              lda #'!'
  348 A:c6bb  20 74 e0                           jsr print_chara
  349 A:c6be  9c 00 04                           stz path
  350 A:c6c1  20 a8 e0                           jsr error_sound
  351 A:c6c4  4c db c6                           jmp initf

  353 A:c6c7                           initdone  
  354 A:c6c7  a2 00                              ldx #0
  355 A:c6c9                           inlp      
  355 A:c6c9                                    
  356 A:c6c9  bd 1e e2                           lda subdirname,x
  357 A:c6cc  9d 01 04                           sta path+1,x
  358 A:c6cf  e8                                 inx 
  359 A:c6d0  e0 0b                              cpx #11
  360 A:c6d2  d0 f5                              bne inlp
  361 A:c6d4  e8                                 inx 
  362 A:c6d5  9e 00 04                           stz path,x
  363 A:c6d8  8e 00 04                           stx path

  365 A:c6db                           initf     
  365 A:c6db                                    

  367 A:c6db                                    ; if the init failed, just continue on with no SD card.

  369 A:c6db  a2 ff                              ldx #$ff

  371 A:c6dd                                    ;; done with initialization. start actually being a monitor
  372 A:c6dd                                    ;;

  374 A:c6dd                           main      
  375 A:c6dd                                    ;;;
  376 A:c6dd                                    ;;; first, display a greeting. through out a couple of newlines
  377 A:c6dd                                    ;;; first just in case there's other gunk on the screen.
  378 A:c6dd                                    ;;;
  379 A:c6dd                           sayhello  
  380 A:c6dd  a9 e5                              lda #<greeting
  381 A:c6df  85 42                              sta PRINTVEC
  382 A:c6e1  a9 eb                              lda #>greeting
  383 A:c6e3  85 43                              sta PRINTVEC+1
  384 A:c6e5  a0 00                              ldy #0
  385 A:c6e7  20 a7 eb                           jsr printvecstr

  387 A:c6ea                                    ;  ldy #0
  388 A:c6ea                                    ;.(
  389 A:c6ea                                    ;next_char
  390 A:c6ea                                    ;wait_txd_empty  
  391 A:c6ea                                    ;  lda ACIA_STATUS
  392 A:c6ea                                    ;  and #$10
  393 A:c6ea                                    ;  beq wait_txd_empty
  394 A:c6ea                                    ;  lda greeting,y
  395 A:c6ea                                    ;  beq reploop
  396 A:c6ea                                    ;  sta ACIA_DATA
  397 A:c6ea                                    ;  iny
  398 A:c6ea                                    ;  jmp next_char
  399 A:c6ea                                    ;.)
  400 A:c6ea                                    ;; greeting has CRLF included, so we don't need to print those.

  403 A:c6ea                                    ;;;
  404 A:c6ea                                    ;;; now down to business. this is the main entrypoint for the
  405 A:c6ea                                    ;;; read/execution loop. print a prompt, read a line, parse, dispatch,
  406 A:c6ea                                    ;;; repeat.
  407 A:c6ea                                    ;;;
  408 A:c6ea                           reploop   
  409 A:c6ea                                     .( 
  410 A:c6ea                                    ;; is the sd card availible?
  411 A:c6ea  ad 00 04                           lda path
  412 A:c6ed  f0 03                              beq wait_txd_empty
  413 A:c6ef                                    ;; if so, print the current directory.
  414 A:c6ef  20 93 e3                           jsr printpath
  415 A:c6f2                                    ;; print the prompt
  416 A:c6f2                           wait_txd_empty 
  417 A:c6f2  ad 01 80                           lda ACIA_STATUS
  418 A:c6f5  29 10                              and #$10
  419 A:c6f7  f0 f9                              beq wait_txd_empty
  420 A:c6f9  ad f6 eb                           lda prompt
  421 A:c6fc  8d 00 80                           sta ACIA_DATA
  422 A:c6ff                                     .) 

  424 A:c6ff  20 9a d6                           jsr readline                ; read a line into INPUT
  425 A:c702  20 45 d6                           jsr crlf                ; echo line feed/carriage return

  427 A:c705                                    ;; nothing entered? loop again
  428 A:c705  c0 00                              cpy #0
  429 A:c707  f0 e1                              beq reploop

  431 A:c709                                    ;; parse and process the command line
  432 A:c709                                    ;;
  433 A:c709  a9 00                              lda #0
  434 A:c70b  99 00 02                           sta INPUT,y              ; null-terminate the string
  435 A:c70e  20 17 c7                           jsr parseinput                ; parse into individual arguments, indexed at ARGINDEX
  436 A:c711                                    ; jsr testparse     ; debugging output for test purposes
  437 A:c711  20 44 c7                           jsr matchcommand                ; match input command and execute
  438 A:c714  4c ea c6                           jmp reploop                ; loop around

  441 A:c717                           parseinput 
  442 A:c717  da                                 phx                    ; preserve x, since it's our private stack pointer
  443 A:c718  a2 00                              ldx #0
  444 A:c71a  a0 00                              ldy #0

  446 A:c71c                                     .( 
  447 A:c71c                                    ;; look for non-space
  448 A:c71c                           nextchar  
  449 A:c71c  bd 00 02                           lda INPUT,x
  450 A:c71f  c9 20                              cmp #32
  451 A:c721  d0 04                              bne nonspace
  452 A:c723  e8                                 inx 
  453 A:c724  4c 1c c7                           jmp nextchar

  455 A:c727                                    ;; mark the start of the word
  456 A:c727                           nonspace  
  457 A:c727  c8                                 iny                    ; maintain a count of words in y
  458 A:c728  96 20                              stx ARGINDEX,y
  459 A:c72a                                    ;; look for space
  460 A:c72a                           lookforspace 
  461 A:c72a  e8                                 inx 
  462 A:c72b  bd 00 02                           lda INPUT,x
  463 A:c72e  f0 10                              beq endofline                ; check for null termination
  464 A:c730  c9 20                              cmp #32             ; only looking for spaces. Tab?
  465 A:c732  f0 03                              beq endofword
  466 A:c734  4c 2a c7                           jmp lookforspace
  467 A:c737                                    ;; didn't hit a terminator, so there must be more.
  468 A:c737                                    ;; terminate this word with a zero and then continue
  469 A:c737                           endofword 
  470 A:c737  a9 00                              lda #0
  471 A:c739  9d 00 02                           sta INPUT,x              ; null-terminate
  472 A:c73c  e8                                 inx 
  473 A:c73d  4c 1c c7                           jmp nextchar                ; repeat
  474 A:c740                           endofline 
  475 A:c740                                    ;; we're done
  476 A:c740                                    ;; cache the arg count
  477 A:c740  84 20                              sty ARGINDEX

  479 A:c742                                    ;; restore x and return
  480 A:c742  fa                                 plx 
  481 A:c743  60                                 rts 
  482 A:c744                                     .) 

  485 A:c744                                    ;;;
  486 A:c744                                    ;;; just for testing. echo arguments, backwards.
  487 A:c744                                    ;;;

  489 A:c744                                    ; NOTE - we dont need this right now.

  491 A:c744                                    ;testparse
  492 A:c744                                    ;  phx               ; preserve x
  493 A:c744                                    ;  cpy #0            ; test for no arguments
  494 A:c744                                    ;  beq donetestparse
  495 A:c744                                    ;  iny               ; add one to get a guard value
  496 A:c744                                    ;  sty SCRATCH       ; store in SCRATCH. when we get to this value, we stop
  497 A:c744                                    ;  ldy #1            ; start at 1
  498 A:c744                                    ;nextarg
  499 A:c744                                    ;  clc
  500 A:c744                                    ;  tya               ; grab the argument number
  501 A:c744                                    ;  adc #$30          ; add 48 to make it an ascii value
  502 A:c744                                    ;  jsr puta
  503 A:c744                                    ;  lda #$3A          ; ascii for ":"
  504 A:c744                                    ;  jsr puta
  505 A:c744                                    ;  ldx ARGINDEX,y    ; load the index of the next argument into x
  506 A:c744                                    ;nextletter
  507 A:c744                                    ;  ;; print null-terminated string from INPUT+x
  508 A:c744                                    ;  lda INPUT,x
  509 A:c744                                    ;  beq donearg
  510 A:c744                                    ;  jsr puta
  511 A:c744                                    ;  inx
  512 A:c744                                    ;  bne nextletter    ; use this as "branch always," will never be 0
  513 A:c744                                    ;donearg
  514 A:c744                                    ;  ;; output carriage return/line feed and see if there are more arguments
  515 A:c744                                    ;  jsr crlf
  516 A:c744                                    ;  iny
  517 A:c744                                    ;  cpy SCRATCH
  518 A:c744                                    ;  bne nextarg       ; not hit guard yet, so repeat
  519 A:c744                                    ;donetestparse
  520 A:c744                                    ;  plx
  521 A:c744                                    ;  rts

  524 A:c744                                    ;;;;;;;;;;;;;
  525 A:c744                                    ;;;
  526 A:c744                                    ;;; Command lookup/dispatch
  527 A:c744                                    ;;;
  528 A:c744                                    ;;;;;;;;;;;;;

  531 A:c744                           matchcommand 
  532 A:c744  a9 03                              lda #<table              ; low byte of table address
  533 A:c746  85 44                              sta ENTRY
  534 A:c748  a9 c0                              lda #>table              ; high byte of table address
  535 A:c74a  85 45                              sta ENTRY+1

  537 A:c74c  da                                 phx                    ; preserve x, since it's our private stack pointer

  539 A:c74d                           testentry 
  540 A:c74d                           cacheptr  
  541 A:c74d                                    ;; grab the pointer to the next entry and cache it in scratchpad
  542 A:c74d  a0 00                              ldy #0
  543 A:c74f  b1 44                              lda (ENTRY),Y            ; first byte
  544 A:c751  85 10                              sta SCRATCH
  545 A:c753  c8                                 iny 
  546 A:c754  b1 44                              lda (ENTRY),Y            ; second byte
  547 A:c756  85 11                              sta SCRATCH+1
  548 A:c758  c8                                 iny 
  549 A:c759  a2 00                              ldx #0             ;; will use X and Yas index for string
  550 A:c75b                                     .( 
  551 A:c75b                           nextchar  
  552 A:c75b  bd 00 02                           lda INPUT,x
  553 A:c75e  f0 09                              beq endofword
  554 A:c760  d1 44                              cmp (ENTRY),y
  555 A:c762  d0 1b                              bne nextentry
  556 A:c764  e8                                 inx 
  557 A:c765  c8                                 iny 
  558 A:c766  4c 5b c7                           jmp nextchar
  559 A:c769                                     .) 

  561 A:c769                           endofword 
  562 A:c769                                    ;; we got here because we hit the end of the word in the buffer
  563 A:c769                                    ;; if it's also the end of the entry label, then we've found the right place
  564 A:c769  b1 44                              lda (ENTRY),y
  565 A:c76b  f0 03                              beq successful
  566 A:c76d                                    ;; but if it's not, then we haven't.
  567 A:c76d                                    ;; continue to the next entry
  568 A:c76d  4c 7f c7                           jmp nextentry

  570 A:c770                           successful 
  571 A:c770                                    ;; we got a match! copy out the destination address, jump to it
  572 A:c770  c8                                 iny 
  573 A:c771  b1 44                              lda (ENTRY),Y
  574 A:c773  85 12                              sta SCRATCH+2
  575 A:c775  c8                                 iny 
  576 A:c776  b1 44                              lda (ENTRY),Y
  577 A:c778  85 13                              sta SCRATCH+3
  578 A:c77a  fa                                 plx                    ; restore stack pointer
  579 A:c77b  6c 12 00                           jmp (SCRATCH+2)
  580 A:c77e  60                                 rts                    ;; never get here -- we rts from the command code

  582 A:c77f                           nextentry 
  582 A:c77f                                    
  583 A:c77f  a5 10                              lda SCRATCH                ;; copy the address of next entry from scratchpad
  584 A:c781  85 44                              sta ENTRY
  585 A:c783  a5 11                              lda SCRATCH+1
  586 A:c785  85 45                              sta ENTRY+1
  587 A:c787                                    ;; test for null here
  588 A:c787  05 10                              ora SCRATCH                ;; check if the entry was $0000
  589 A:c789  f0 03                              beq endoftable                ;; if so, we're at the end of table
  590 A:c78b  4c 4d c7                           jmp testentry

  592 A:c78e                           endoftable 
  593 A:c78e                                    ;; got to the end of the table with no match
  594 A:c78e                                    ;; print an error message, and return to line input
  595 A:c78e                                    ;; ...

  597 A:c78e                           printerror 
  598 A:c78e  a9 ce                              lda #<nocmderrstr
  599 A:c790  85 42                              sta PRINTVEC
  600 A:c792  a9 f3                              lda #>nocmderrstr
  601 A:c794  85 43                              sta PRINTVEC+1
  602 A:c796  20 a7 eb                           jsr printvecstr
  603 A:c799                                    ; no need for crlf
  604 A:c799                                    ;  ldy #0
  605 A:c799                                    ;.(
  606 A:c799                                    ;next_char
  607 A:c799                                    ;wait_txd_empty  
  608 A:c799                                    ;  lda ACIA_STATUS
  609 A:c799                                    ;  and #$10
  610 A:c799                                    ;  beq wait_txd_empty
  611 A:c799                                    ;  lda errorstring,y
  612 A:c799                                    ;  beq end
  613 A:c799                                    ;  sta ACIA_DATA
  614 A:c799                                    ;  iny
  615 A:c799                                    ;  jmp next_char
  616 A:c799                                    ;end
  617 A:c799                                    ;.)
  618 A:c799  fa                                 plx                    ; restore the stack pointer
  619 A:c79a  60                                 rts 

  623 A:c79b                                    ;;;;;;;;;;;;;
  624 A:c79b                                    ;;;
  625 A:c79b                                    ;;; Monitor commands
  626 A:c79b                                    ;;;
  627 A:c79b                                    ;;;;;;;;;;;;;

  629 A:c79b                           aboutcmd  
  630 A:c79b  a9 f7                              lda #<aboutstring
  631 A:c79d  85 42                              sta PRINTVEC
  632 A:c79f  a9 eb                              lda #>aboutstring
  633 A:c7a1  85 43                              sta PRINTVEC+1
  634 A:c7a3  a9 68                              lda #<aboutstringend
  635 A:c7a5  85 0e                              sta ENDVEC
  636 A:c7a7  a9 ef                              lda #>aboutstringend
  637 A:c7a9  85 0f                              sta ENDVEC+1
  638 A:c7ab  4c bb eb                           jmp printveclong

  640 A:c7ae                           helpcmd   
  641 A:c7ae  a9 69                              lda #<helpstring
  642 A:c7b0  85 42                              sta PRINTVEC
  643 A:c7b2  a9 ef                              lda #>helpstring
  644 A:c7b4  85 43                              sta PRINTVEC+1
  645 A:c7b6  a9 cd                              lda #<helpstringend
  646 A:c7b8  85 0e                              sta ENDVEC
  647 A:c7ba  a9 f3                              lda #>helpstringend
  648 A:c7bc  85 0f                              sta ENDVEC+1
  649 A:c7be  4c bb eb                           jmp printveclong

  651 A:c7c1                           notimplcmd 
  652 A:c7c1  a9 e7                              lda #<implementstring
  653 A:c7c3  85 42                              sta PRINTVEC
  654 A:c7c5  a9 f3                              lda #>implementstring
  655 A:c7c7  85 43                              sta PRINTVEC+1
  656 A:c7c9  20 a7 eb                           jsr printvecstr
  657 A:c7cc  60                                 rts 

  659 A:c7cd                           echocmd   
  660 A:c7cd                                     .( 
  661 A:c7cd  da                                 phx                    ; preserve x, since it's our private stack pointer
  662 A:c7ce  a0 01                              ldy #1             ; start at 1 because we ignore the command itself
  663 A:c7d0                           echonext  
  664 A:c7d0  c4 20                              cpy ARGINDEX                ; have we just done the last?
  665 A:c7d2  d0 03                              bne nottend                ; yes, so end
  666 A:c7d4  4c f1 c7                           jmp end
  667 A:c7d7                           nottend   
  668 A:c7d7  c8                                 iny                    ; no, so move on to the next
  669 A:c7d8  b6 20                              ldx ARGINDEX,y
  670 A:c7da                                    ;; not using printvecstr for this because we're printing
  671 A:c7da                                    ;; directly out of the input buffer  
  672 A:c7da                           next_char 
  673 A:c7da  20 6c e0                           jsr txpoll
  674 A:c7dd  bd 00 02                           lda INPUT,x
  675 A:c7e0  f0 07                              beq endofarg
  676 A:c7e2  8d 00 80                           sta ACIA_DATA
  677 A:c7e5  e8                                 inx 
  678 A:c7e6  4c da c7                           jmp next_char
  679 A:c7e9                           endofarg  
  680 A:c7e9  a9 20                              lda #32             ; put a space at the end
  681 A:c7eb  20 60 d6                           jsr puta
  682 A:c7ee  4c d0 c7                           jmp echonext
  683 A:c7f1                           end       
  684 A:c7f1  20 45 d6                           jsr crlf                ; carriage return/line feed
  685 A:c7f4  fa                                 plx                    ; restore the stack pointer
  686 A:c7f5  60                                 rts 
  687 A:c7f6                                     .) 

  691 A:c7f6                           pokecmd   
  692 A:c7f6                                     .( 
  693 A:c7f6                                    ;; check arguments
  694 A:c7f6  a5 20                              lda ARGINDEX
  695 A:c7f8  c9 03                              cmp #3
  696 A:c7fa  d0 31                              bne error                ; not three, so there's an error of some sort
  697 A:c7fc  18                                 clc 
  698 A:c7fd  a9 00                              lda #<INPUT
  699 A:c7ff  65 23                              adc ARGINDEX+3
  700 A:c801  85 80                              sta stackaccess
  701 A:c803  a9 02                              lda #>INPUT
  702 A:c805  85 81                              sta stackaccess+1
  703 A:c807  20 db c0                           jsr push16
  704 A:c80a  20 2e c2                           jsr read8hex
  705 A:c80d  18                                 clc 
  706 A:c80e  a9 00                              lda #<INPUT
  707 A:c810  65 22                              adc ARGINDEX+2
  708 A:c812  85 80                              sta stackaccess
  709 A:c814  a9 02                              lda #>INPUT
  710 A:c816  85 81                              sta stackaccess+1
  711 A:c818  20 db c0                           jsr push16
  712 A:c81b  20 76 c2                           jsr read16hex

  714 A:c81e  20 e6 c0                           jsr pop16
  715 A:c821  b5 01                              lda stackbase+1,x
  716 A:c823  92 80                              sta (stackaccess)
  717 A:c825  20 6d d6                           jsr putax
  718 A:c828  20 e6 c0                           jsr pop16
  719 A:c82b  80 0b                              bra ende

  721 A:c82d                           error     
  722 A:c82d  a9 1f                              lda #<pokeerrstring
  723 A:c82f  85 42                              sta PRINTVEC
  724 A:c831  a9 f4                              lda #>pokeerrstring
  725 A:c833  85 43                              sta PRINTVEC+1
  726 A:c835  20 a7 eb                           jsr printvecstr
  727 A:c838                           ende      
  728 A:c838                                     .) 
  729 A:c838  20 45 d6                           jsr crlf
  730 A:c83b  60                                 rts 

  732 A:c83c                           dumpcmd   
  733 A:c83c                                     .( 
  734 A:c83c                                    ;; check arguments
  735 A:c83c  a5 20                              lda ARGINDEX
  736 A:c83e  c9 02                              cmp #2
  737 A:c840  f0 07                              beq twoparam                ; two parameters (ie instruction plus address)
  738 A:c842  c9 03                              cmp #3
  739 A:c844  f0 0e                              beq threeparam                ; three parameters (instruction, address, count)
  740 A:c846  4c fb c8                           jmp error                ; neither 2 nor 3, so there's an error
  741 A:c849                           twoparam                   ; only two parameters specified, so fill in third
  742 A:c849  a9 10                              lda #$10             ; default number of bytes to dump
  743 A:c84b  85 80                              sta stackaccess
  744 A:c84d  64 81                              stz stackaccess+1
  745 A:c84f  20 db c0                           jsr push16
  746 A:c852  80 11                              bra finishparam
  747 A:c854                           threeparam                  ; grab both parameters and push them
  748 A:c854  18                                 clc 
  749 A:c855  a9 00                              lda #<INPUT
  750 A:c857  65 23                              adc ARGINDEX+3
  751 A:c859  85 80                              sta stackaccess
  752 A:c85b  a9 02                              lda #>INPUT
  753 A:c85d  85 81                              sta stackaccess+1
  754 A:c85f  20 db c0                           jsr push16
  755 A:c862  20 2e c2                           jsr read8hex
  756 A:c865                           finishparam                  ; process the (first) address parameter
  757 A:c865  18                                 clc 
  758 A:c866  a9 00                              lda #<INPUT
  759 A:c868  65 22                              adc ARGINDEX+2
  760 A:c86a  85 80                              sta stackaccess
  761 A:c86c  a9 02                              lda #>INPUT
  762 A:c86e  85 81                              sta stackaccess+1
  763 A:c870  20 db c0                           jsr push16
  764 A:c873  20 76 c2                           jsr read16hex

  766 A:c876                                    ;; now we actually do the work
  767 A:c876                                    ;; stash base address at SCRATCH
  768 A:c876  b5 01                              lda stackbase+1,x
  769 A:c878  85 10                              sta SCRATCH
  770 A:c87a  b5 02                              lda stackbase+2,x
  771 A:c87c  85 11                              sta SCRATCH+1

  773 A:c87e                           nextline  

  775 A:c87e  da                                 phx                    ; push x. X is only protected for PART of this code.

  777 A:c87f  a0 00                              ldy #0

  779 A:c881                                    ;; print one line

  781 A:c881                                    ;; print the address
  782 A:c881  a5 11                              lda SCRATCH+1
  783 A:c883  20 6d d6                           jsr putax
  784 A:c886  a5 10                              lda SCRATCH
  785 A:c888  20 6d d6                           jsr putax

  787 A:c88b                                    ;; print separator
  788 A:c88b  a9 3a                              lda #$3a             ; colon
  789 A:c88d  20 60 d6                           jsr puta
  790 A:c890  a9 20                              lda #$20             ; space
  791 A:c892  20 60 d6                           jsr puta

  793 A:c895                                    ;; print first eight bytes
  794 A:c895                           printbyte 
  795 A:c895  b1 10                              lda (SCRATCH),y
  796 A:c897  20 6d d6                           jsr putax
  797 A:c89a  a9 20                              lda #$20
  798 A:c89c  20 60 d6                           jsr puta
  799 A:c89f  c0 07                              cpy #$07             ; if at the eighth, print extra separator
  800 A:c8a1  d0 03                              bne nextbyte
  801 A:c8a3  20 60 d6                           jsr puta
  802 A:c8a6                           nextbyte                   ; inc and move on to next byte
  803 A:c8a6  c8                                 iny 
  804 A:c8a7  c0 10                              cpy #$10             ; stop when we get to 16
  805 A:c8a9  d0 ea                              bne printbyte

  807 A:c8ab                                    ;; print separator
  808 A:c8ab  a9 20                              lda #$20
  809 A:c8ad  20 60 d6                           jsr puta
  810 A:c8b0  20 60 d6                           jsr puta
  811 A:c8b3  a9 7c                              lda #$7c             ; vertical bar
  812 A:c8b5  20 60 d6                           jsr puta                ; faster to have that as a little character string!

  814 A:c8b8                                    ;; print ascii values for 16 bytes
  815 A:c8b8  a0 00                              ldy #0
  816 A:c8ba                           nextascii 
  817 A:c8ba  c0 10                              cpy #$10
  818 A:c8bc  f0 12                              beq endascii
  819 A:c8be  b1 10                              lda (SCRATCH),y
  820 A:c8c0                                    ;; it's printable if it's over 32 and under 127
  821 A:c8c0  c9 20                              cmp #32
  822 A:c8c2  30 04                              bmi unprintable
  823 A:c8c4  c9 7f                              cmp #127
  824 A:c8c6  30 02                              bmi printascii
  825 A:c8c8                           unprintable 
  826 A:c8c8  a9 2e                              lda #$2e             ; dot
  827 A:c8ca                           printascii 
  828 A:c8ca  20 60 d6                           jsr puta
  829 A:c8cd  c8                                 iny 
  830 A:c8ce  80 ea                              bra nextascii
  831 A:c8d0                           endascii  
  832 A:c8d0  a9 7c                              lda #$7c             ; vertical bar
  833 A:c8d2  20 60 d6                           jsr puta                ; faster to have that as a little character string!
  834 A:c8d5  20 45 d6                           jsr crlf

  836 A:c8d8                                    ;; now bump the address and check if we should go around again
  837 A:c8d8                                    ;;
  838 A:c8d8  fa                                 plx                    ; restore x so we can work with the stack again
  839 A:c8d9  18                                 clc 

  841 A:c8da                                    ;; subtract 16 from the count
  842 A:c8da  b5 03                              lda stackbase+3,x
  843 A:c8dc  e9 10                              sbc #$10
  844 A:c8de                                    ;; don't bother with the second byte, since it's always a single byte
  845 A:c8de  95 03                              sta stackbase+3,x
  846 A:c8e0  90 12                              bcc donedump
  847 A:c8e2  f0 10                              beq donedump

  849 A:c8e4                                    ;; going round again, so add 16 to the base address
  850 A:c8e4  18                                 clc 
  851 A:c8e5  a5 10                              lda SCRATCH
  852 A:c8e7  69 10                              adc #$10
  853 A:c8e9  85 10                              sta SCRATCH
  854 A:c8eb  a5 11                              lda SCRATCH+1
  855 A:c8ed  69 00                              adc #0
  856 A:c8ef  85 11                              sta SCRATCH+1
  857 A:c8f1  4c 7e c8                           jmp nextline

  859 A:c8f4                           donedump  
  860 A:c8f4                                    ;; throw away last two items on the stack
  861 A:c8f4  e8                                 inx 
  862 A:c8f5  e8                                 inx 
  863 A:c8f6  e8                                 inx 
  864 A:c8f7  e8                                 inx 
  865 A:c8f8  4c 09 c9                           jmp enddumpcmd

  867 A:c8fb                           error     
  868 A:c8fb  a9 fd                              lda #<dumperrstring
  869 A:c8fd  85 42                              sta PRINTVEC
  870 A:c8ff  a9 f3                              lda #>dumperrstring
  871 A:c901  85 43                              sta PRINTVEC+1
  872 A:c903  20 a7 eb                           jsr printvecstr
  873 A:c906                                    ;  ldy #0
  874 A:c906                                    ;  ;; do error
  875 A:c906                                    ;next_char
  876 A:c906                                    ;wait_txd_empty  
  877 A:c906                                    ;  lda ACIA_STATUS
  878 A:c906                                    ;  and #$10
  879 A:c906                                    ;  beq wait_txd_empty
  880 A:c906                                    ;  lda dumperrstring,y
  881 A:c906                                    ;  beq enderr
  882 A:c906                                    ;  sta ACIA_DATA
  883 A:c906                                    ;  iny
  884 A:c906                                    ;  jmp next_char
  885 A:c906                                    ;enderr
  886 A:c906  20 45 d6                           jsr crlf

  888 A:c909                           enddumpcmd 
  889 A:c909  60                                 rts 
  890 A:c90a                                     .) 

  892 A:c90a                                    ;;; zero command -- zero out a block of memory. Two parameters just
  893 A:c90a                                    ;;; like dump.
  894 A:c90a                                    ;;;
  895 A:c90a                           zerocmd   
  896 A:c90a                                     .( 
  897 A:c90a                                    ;; check arguments
  898 A:c90a  a5 20                              lda ARGINDEX
  899 A:c90c  c9 02                              cmp #2
  900 A:c90e  f0 07                              beq twoparam                ; two parameters (ie instruction plus address)
  901 A:c910  c9 03                              cmp #3
  902 A:c912  f0 0e                              beq threeparam                ; three parameters (instruction, address, count)
  903 A:c914  4c 60 c9                           jmp error                ; neither 2 nor 3, so there's an error
  904 A:c917                           twoparam                   ; only two parameters specified, so fill in third
  905 A:c917  a9 10                              lda #$10             ; default number of bytes to dump
  906 A:c919  85 80                              sta stackaccess
  907 A:c91b  64 81                              stz stackaccess+1
  908 A:c91d  20 db c0                           jsr push16
  909 A:c920  80 11                              bra finishparam
  910 A:c922                           threeparam                  ; grab both parameters and push them
  911 A:c922  18                                 clc 
  912 A:c923  a9 00                              lda #<INPUT
  913 A:c925  65 23                              adc ARGINDEX+3
  914 A:c927  85 80                              sta stackaccess
  915 A:c929  a9 02                              lda #>INPUT
  916 A:c92b  85 81                              sta stackaccess+1
  917 A:c92d  20 db c0                           jsr push16
  918 A:c930  20 2e c2                           jsr read8hex
  919 A:c933                           finishparam                  ; process the (first) address parameter
  920 A:c933  18                                 clc 
  921 A:c934  a9 00                              lda #<INPUT
  922 A:c936  65 22                              adc ARGINDEX+2
  923 A:c938  85 80                              sta stackaccess
  924 A:c93a  a9 02                              lda #>INPUT
  925 A:c93c  85 81                              sta stackaccess+1
  926 A:c93e  20 db c0                           jsr push16
  927 A:c941  20 76 c2                           jsr read16hex

  929 A:c944                                    ;; now we actually do the work
  930 A:c944                                    ;; stash base address at SCRATCH
  931 A:c944  b5 01                              lda stackbase+1,x
  932 A:c946  85 10                              sta SCRATCH
  933 A:c948  b5 02                              lda stackbase+2,x
  934 A:c94a  85 11                              sta SCRATCH+1

  937 A:c94c                           loop      
  938 A:c94c  b4 03                              ldy stackbase+3,x        ; the byte count is at stackbase+3,x
  939 A:c94e  f0 09                              beq donezero                ; if we're done, stop
  940 A:c950  88                                 dey                    ; otherwise, decrement the count in y
  941 A:c951  94 03                              sty stackbase+3,x        ; put it back
  942 A:c953  a9 00                              lda #0             ; and store a zero...
  943 A:c955  91 10                              sta (SCRATCH),y            ; in the base address plus y
  944 A:c957  80 f3                              bra loop

  946 A:c959                           donezero  
  947 A:c959                                    ;; finished, so pop two 16-bit values off the stack
  948 A:c959  e8                                 inx 
  949 A:c95a  e8                                 inx 
  950 A:c95b  e8                                 inx 
  951 A:c95c  e8                                 inx 
  952 A:c95d  4c 70 c9                           jmp endzerocmd

  954 A:c960                           error     
  955 A:c960  a0 00                              ldy #0
  956 A:c962  a9 54                              lda #<zeroerrstring
  957 A:c964  85 42                              sta PRINTVEC
  958 A:c966  a9 f4                              lda #>zeroerrstring
  959 A:c968  85 43                              sta PRINTVEC+1
  960 A:c96a  20 a7 eb                           jsr printvecstr
  961 A:c96d                                    ;  ;; do error
  962 A:c96d                                    ;next_char
  963 A:c96d                                    ;wait_txd_empty  
  964 A:c96d                                    ;  lda ACIA_STATUS
  965 A:c96d                                    ;  and #$10
  966 A:c96d                                    ;  beq wait_txd_empty
  967 A:c96d                                    ;  lda zeroerrstring,y
  968 A:c96d                                    ;  beq enderr
  969 A:c96d                                    ;  sta ACIA_DATA
  970 A:c96d                                    ;  iny
  971 A:c96d                                    ;  jmp next_char
  972 A:c96d                                    ;enderr
  973 A:c96d  20 45 d6                           jsr crlf

  975 A:c970                           endzerocmd 
  976 A:c970  60                                 rts 
  977 A:c971                                     .) 

  981 A:c971                                    ;;; NEW go command, using stack-based parameter processing
  982 A:c971                                    ;;;
  983 A:c971                           gocmd     
  984 A:c971                                     .( 
  985 A:c971                                    ;; check arguments
  986 A:c971  a5 20                              lda ARGINDEX
  987 A:c973  c9 02                              cmp #2
  988 A:c975  f0 03                              beq processparam
  989 A:c977  4c 91 c9                           jmp error

  991 A:c97a                           processparam                  ; process the (first) address parameter
  992 A:c97a  18                                 clc 
  993 A:c97b  a9 00                              lda #<INPUT
  994 A:c97d  65 22                              adc ARGINDEX+2
  995 A:c97f  85 80                              sta stackaccess
  996 A:c981  a9 02                              lda #>INPUT
  997 A:c983  85 81                              sta stackaccess+1
  998 A:c985  20 db c0                           jsr push16
  999 A:c988  20 76 c2                           jsr read16hex

 1001 A:c98b  20 e6 c0                           jsr pop16                ; put the address into stackaccess
 1002 A:c98e  6c 80 00                           jmp (stackaccess)              ; jump directly
 1003 A:c991                                    ;; no rts here because we'll rts from the subroutine

 1005 A:c991                           error     
 1006 A:c991  a9 3f                              lda #<goerrstring
 1007 A:c993  85 42                              sta PRINTVEC
 1008 A:c995  a9 f4                              lda #>goerrstring
 1009 A:c997  85 43                              sta PRINTVEC+1
 1010 A:c999  20 a7 eb                           jsr printvecstr

 1012 A:c99c  20 45 d6                           jsr crlf
 1013 A:c99f  60                                 rts 
 1014 A:c9a0                                     .) 

 1016 A:c9a0                                    ; Clear Screen
 1017 A:c9a0                           clearcmd  
 1017 A:c9a0                                    
 1018 A:c9a0  da                                 phx 
 1019 A:c9a1  20 61 e0                           jsr cleardisplay
 1020 A:c9a4  fa                                 plx 
 1021 A:c9a5  60                                 rts 

 1023 A:c9a6                                    ; include cassette tape system

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
   91 A:ca30  20 85 e0                           jsr w_acia_full

   93 A:ca33  a9 18                              lda #$18             ; 4 seconds
   94 A:ca35  20 3c cb                           jsr tape_delay                ; (ye fumble)

   96 A:ca38  a2 91                              ldx #<saving_msg              ; Saving...
   97 A:ca3a  a0 cb                              ldy #>saving_msg
   98 A:ca3c  20 85 e0                           jsr w_acia_full

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
  178 A:cad0  20 85 e0                           jsr w_acia_full

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
  240 A:cb1a  a9 91                              lda #<tsaveerrstring
  241 A:cb1c  85 42                              sta PRINTVEC
  242 A:cb1e  a9 f4                              lda #>tsaveerrstring
  243 A:cb20  85 43                              sta PRINTVEC+1
  244 A:cb22  20 a7 eb                           jsr printvecstr

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
  334 A:cbe7  20 85 e0                           jsr w_acia_full

  336 A:cbea  a9 18                              lda #$18             ; ye fumble
  337 A:cbec  20 3c cb                           jsr tape_delay                ; 4 second delay

  339 A:cbef  a2 86                              ldx #<loading_msg              ; Loading...
  340 A:cbf1  a0 cb                              ldy #>loading_msg
  341 A:cbf3  20 85 e0                           jsr w_acia_full

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
  418 A:cc73  20 85 e0                           jsr w_acia_full
  419 A:cc76  68                                 pla 
  420 A:cc77  20 4a e0                           jsr print_hex_acia
  421 A:cc7a  68                                 pla 
  422 A:cc7b  20 4a e0                           jsr print_hex_acia
  423 A:cc7e  a2 b2                              ldx #<tomsg
  424 A:cc80  a0 cb                              ldy #>tomsg
  425 A:cc82  20 85 e0                           jsr w_acia_full
  426 A:cc85  a5 15                              lda len+1
  427 A:cc87  20 4a e0                           jsr print_hex_acia
  428 A:cc8a  a5 14                              lda len
  429 A:cc8c  20 4a e0                           jsr print_hex_acia
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


 1026 A:ccbb                           testcmd   
 1027 A:ccbb                                    ;jsr xmodemtest
 1028 A:ccbb  60                                 rts 

 1030 A:ccbc                           xreceivecmd 
 1031 A:ccbc                                     .( 
 1032 A:ccbc                                    ;; check arguments
 1033 A:ccbc  a5 20                              lda ARGINDEX
 1034 A:ccbe  c9 02                              cmp #2
 1035 A:ccc0  f0 03                              beq processparam
 1036 A:ccc2  4c e9 cc                           jmp xerror

 1038 A:ccc5                           processparam                  ; process the address parameter
 1039 A:ccc5  18                                 clc 
 1040 A:ccc6  a9 00                              lda #<INPUT
 1041 A:ccc8  65 22                              adc ARGINDEX+2
 1042 A:ccca  85 80                              sta stackaccess
 1043 A:cccc  a9 02                              lda #>INPUT
 1044 A:ccce                                    ;; BUG?? shouldn't there be an ADC #0 in here?
 1045 A:ccce                                    ;; it works as long as INPUT starts low on a page and so the
 1046 A:ccce                                    ;; upper byte never changes.. but this is an error!
 1047 A:ccce  85 81                              sta stackaccess+1

 1049 A:ccd0  20 db c0                           jsr push16                ; put the string address on the stack
 1050 A:ccd3  20 76 c2                           jsr read16hex                ; convert string to a number value
 1051 A:ccd6  20 e6 c0                           jsr pop16                ; pop number, leave in stackaccess

 1053 A:ccd9  a5 80                              lda stackaccess                ; copy 16 bit address into XDESTADDR
 1054 A:ccdb  8d 34 00                           sta XDESTADDR
 1055 A:ccde  a5 81                              lda stackaccess+1
 1056 A:cce0  8d 35 00                           sta XDESTADDR+1

 1058 A:cce3  20 f8 cc                           jsr xmodemrecv                ; call the receive command
 1059 A:cce6  4c f7 cc                           jmp xmreturn

 1061 A:cce9                           xerror    
 1062 A:cce9  a9 76                              lda #<xrecverrstring
 1063 A:cceb  85 42                              sta PRINTVEC
 1064 A:cced  a9 f4                              lda #>xrecverrstring+1
 1065 A:ccef  85 43                              sta PRINTVEC+1
 1066 A:ccf1  20 a7 eb                           jsr printvecstr
 1067 A:ccf4  20 45 d6                           jsr crlf

 1069 A:ccf7                                     .) 
 1070 A:ccf7                           xmreturn  
 1071 A:ccf7  60                                 rts 

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


 1075 A:ce7c                           rticmd    
 1076 A:ce7c                                    ;; we got here via a JSR, so we need to drop the return
 1077 A:ce7c                                    ;; address from the stack
 1078 A:ce7c  68                                 pla 
 1079 A:ce7d  68                                 pla 
 1080 A:ce7e                                    ;; now return from interrupt
 1081 A:ce7e  40                                 rti 

 1083 A:ce7f                           inputcmd  
 1084 A:ce7f                                     .( 
 1085 A:ce7f                                    ;; check arguments
 1086 A:ce7f  a5 20                              lda ARGINDEX
 1087 A:ce81  c9 02                              cmp #2
 1088 A:ce83  f0 03                              beq printhelp
 1089 A:ce85  4c 08 cf                           jmp inputerror

 1091 A:ce88                           printhelp 
 1092 A:ce88                                    ;; print a help message
 1093 A:ce88  a9 b0                              lda #<inputhelpstring
 1094 A:ce8a  85 42                              sta PRINTVEC
 1095 A:ce8c  a9 f4                              lda #>inputhelpstring
 1096 A:ce8e  85 43                              sta PRINTVEC+1
 1097 A:ce90  20 a7 eb                           jsr printvecstr
 1098 A:ce93  20 45 d6                           jsr crlf

 1100 A:ce96                           processparam                  ; process the address parameter
 1101 A:ce96  18                                 clc 
 1102 A:ce97  a9 00                              lda #<INPUT
 1103 A:ce99  65 22                              adc ARGINDEX+2
 1104 A:ce9b  85 80                              sta stackaccess
 1105 A:ce9d  a9 02                              lda #>INPUT
 1106 A:ce9f                                    ;; BUG?? shouldn't there be an ADC #0 in here?
 1107 A:ce9f                                    ;; it works as long as INPUT starts low on a page and so the
 1108 A:ce9f                                    ;; upper byte never changes.. but this is an error!
 1109 A:ce9f  85 81                              sta stackaccess+1

 1111 A:cea1  20 db c0                           jsr push16                ; put the string address on the stack
 1112 A:cea4  20 76 c2                           jsr read16hex                ; convert string to a number value
 1113 A:cea7  20 e6 c0                           jsr pop16                ; pop number, leave in stackaccess

 1115 A:ceaa  a5 80                              lda stackaccess                ; copy 16 bit address into SCRATCH
 1116 A:ceac  85 10                              sta SCRATCH
 1117 A:ceae  a5 81                              lda stackaccess+1
 1118 A:ceb0  85 11                              sta SCRATCH+1

 1120 A:ceb2                           start     
 1121 A:ceb2  a5 10                              lda SCRATCH                ; first, print the current address as a prompt
 1122 A:ceb4  85 80                              sta stackaccess
 1123 A:ceb6  a5 11                              lda SCRATCH+1
 1124 A:ceb8  85 81                              sta stackaccess+1
 1125 A:ceba  20 db c0                           jsr push16                ; put it onto the stack
 1126 A:cebd  20 4d c3                           jsr print16hex                ; print it in hex
 1127 A:cec0  a9 20                              lda #$20             ; output a space
 1128 A:cec2  20 60 d6                           jsr puta

 1130 A:cec5  20 9a d6                           jsr readline                ; read a line of input into the buffer
 1131 A:cec8  20 45 d6                           jsr crlf                ; echo newline

 1133 A:cecb  c0 00                              cpy #0             ; is the line blank?
 1134 A:cecd  f0 36                              beq endinput                ; if so, then end the routine
 1135 A:cecf  20 17 c7                           jsr parseinput                ; otherwise, parse the input into byte strings

 1137 A:ced2                                    ;; write those bytes into memory starting at the address
 1138 A:ced2                                    ;; begin a new line with the next address
 1139 A:ced2  a0 01                              ldy #1
 1140 A:ced4  e6 20                              inc ARGINDEX                ; change from count to sentinel value

 1142 A:ced6                           nextbyte  
 1143 A:ced6  c4 20                              cpy ARGINDEX                ; have we done all the arguments?
 1144 A:ced8  f0 29                              beq donebytes                ; if so, jump to the end of this round

 1146 A:ceda  18                                 clc 
 1147 A:cedb  a9 00                              lda #<INPUT              ; load the base address for the input buffer
 1148 A:cedd  79 20 00                           adc ARGINDEX,y              ; and add the offset to the y'th argument
 1149 A:cee0  85 80                              sta stackaccess                ; store at stackaccess
 1150 A:cee2  a9 02                              lda #>INPUT              ; then the upper byte
 1151 A:cee4  69 00                              adc #0             ; in case we cross page boundary (but we shouldn't)
 1152 A:cee6  85 81                              sta stackaccess+1
 1153 A:cee8  20 db c0                           jsr push16                ; push the address for the byte string
 1154 A:ceeb  20 2e c2                           jsr read8hex                ; interpret as an eight-bit hex value
 1155 A:ceee  20 e6 c0                           jsr pop16                ; pull off the stack
 1156 A:cef1  a5 80                              lda stackaccess                ; this is the byte, in the lower 8 bits
 1157 A:cef3  da                                 phx 
 1158 A:cef4  a2 00                              ldx #0             ; needed  because there's no non-index indirect mode
 1159 A:cef6  81 10                              sta (SCRATCH,x)            ; store it at the address pointed to by SCRATCH
 1160 A:cef8  e6 10                              inc SCRATCH                ; increment SCRATCH (and possibly SCRATCH+1)
 1161 A:cefa  d0 02                              bne endloop
 1162 A:cefc  e6 11                              inc SCRATCH+1
 1163 A:cefe                           endloop   
 1164 A:cefe  fa                                 plx                    ; restore X before we use the stack routines again
 1165 A:ceff  c8                                 iny                    ; move on to next entered type
 1166 A:cf00  4c d6 ce                           jmp nextbyte

 1168 A:cf03                           donebytes 
 1169 A:cf03  80 ad                              bra start                ; again with the next line

 1171 A:cf05                           endinput  
 1172 A:cf05  4c 16 cf                           jmp inputreturn

 1174 A:cf08                           inputerror 
 1175 A:cf08  a9 de                              lda #<inputerrstring
 1176 A:cf0a  85 42                              sta PRINTVEC
 1177 A:cf0c  a9 f4                              lda #>inputerrstring+1
 1178 A:cf0e  85 43                              sta PRINTVEC+1
 1179 A:cf10  20 a7 eb                           jsr printvecstr
 1180 A:cf13  20 45 d6                           jsr crlf
 1181 A:cf16                           inputreturn 
 1182 A:cf16  60                                 rts                    ; return (x already restored)
 1183 A:cf17                                     .) 

 1186 A:cf17                                    ;;;;;;;;;;;;;
 1187 A:cf17                                    ;;;
 1188 A:cf17                                    ;;; Disassembler
 1189 A:cf17                                    ;;;
 1190 A:cf17                                    ;;; Handles all original 6502 opcodes and (almost) all of the 65C02
 1191 A:cf17                                    ;;; opcodes. It may occasionally interpret things overly generously,
 1192 A:cf17                                    ;;; ie take a nonsense byte and give it a meaning... but such a byte
 1193 A:cf17                                    ;;; shouldn't be in a program anyway, right?
 1194 A:cf17                                    ;;;
 1195 A:cf17                                    ;;; Paul Dourish, October 2017
 1196 A:cf17                                    ;;;
 1197 A:cf17                                    ;;;
 1198 A:cf17                                    ;;;;;;;;;;;;;

 1200 A:cf17                           discmd    
 1201 A:cf17                                     .( 
 1202 A:cf17                                    ;; check arguments
 1203 A:cf17  a5 20                              lda ARGINDEX
 1204 A:cf19  c9 02                              cmp #2
 1205 A:cf1b  f0 07                              beq twoparam                ; two parameters (ie instruction plus address)
 1206 A:cf1d  c9 03                              cmp #3
 1207 A:cf1f  f0 0e                              beq threeparam                ; three parameters (instruction, address, count)
 1208 A:cf21  4c 60 cf                           jmp diserror                ; neither 2 nor 3, so there's an error
 1209 A:cf24                           twoparam                   ; only two parameters specified, so fill in third
 1210 A:cf24  a9 10                              lda #$10             ; default number of instructions to decode
 1211 A:cf26  85 80                              sta stackaccess
 1212 A:cf28  64 81                              stz stackaccess+1
 1213 A:cf2a  20 db c0                           jsr push16
 1214 A:cf2d  80 11                              bra finishparam
 1215 A:cf2f                           threeparam                  ; grab both parameters and push them
 1216 A:cf2f  18                                 clc 
 1217 A:cf30  a9 00                              lda #<INPUT
 1218 A:cf32  65 23                              adc ARGINDEX+3
 1219 A:cf34  85 80                              sta stackaccess
 1220 A:cf36  a9 02                              lda #>INPUT
 1221 A:cf38  85 81                              sta stackaccess+1
 1222 A:cf3a  20 db c0                           jsr push16
 1223 A:cf3d  20 2e c2                           jsr read8hex
 1224 A:cf40                           finishparam                  ; process the (first) address parameter
 1225 A:cf40  18                                 clc 
 1226 A:cf41  a9 00                              lda #<INPUT
 1227 A:cf43  65 22                              adc ARGINDEX+2
 1228 A:cf45  85 80                              sta stackaccess
 1229 A:cf47  a9 02                              lda #>INPUT
 1230 A:cf49  85 81                              sta stackaccess+1
 1231 A:cf4b  20 db c0                           jsr push16
 1232 A:cf4e  20 76 c2                           jsr read16hex

 1234 A:cf51                                    ;; now we actually do the work
 1235 A:cf51                                    ;; stash base address at BASE (upper area of scratch memory)

 1237 A:cf51                                    BASE=SCRATCH+$0a
 1238 A:cf51  b5 01                              lda stackbase+1,x
 1239 A:cf53  85 1a                              sta BASE
 1240 A:cf55  b5 02                              lda stackbase+2,x
 1241 A:cf57  85 1b                              sta BASE+1

 1243 A:cf59                                    ;; and stash the count at COUNT (also upper area of scratch memory)
 1244 A:cf59                                    COUNT=SCRATCH+$0c
 1245 A:cf59  b5 03                              lda stackbase+3,x
 1246 A:cf5b  85 1c                              sta COUNT
 1247 A:cf5d  4c 6e cf                           jmp begindis

 1249 A:cf60                           diserror  
 1250 A:cf60  a9 09                              lda #<diserrorstring
 1251 A:cf62  85 42                              sta PRINTVEC
 1252 A:cf64  a9 f5                              lda #>diserrorstring
 1253 A:cf66  85 43                              sta PRINTVEC+1
 1254 A:cf68  20 a7 eb                           jsr printvecstr

 1256 A:cf6b                           enddis    
 1257 A:cf6b  4c bf d4                           jmp exitdis

 1261 A:cf6e                                    ;;; I'm following details and logic from
 1262 A:cf6e                                    ;;; http
 1262 A:cf6e                                    
 1263 A:cf6e                                    ;;;
 1264 A:cf6e                                    ;;; Most instructions are of the form aaabbbcc, where cc signals
 1265 A:cf6e                                    ;;; a block of instructons that operate in a similar way, with aaa
 1266 A:cf6e                                    ;;; indicating the instructoon and bbb indicating the addressing mode.
 1267 A:cf6e                                    ;;; Each of those blocks is handled by two tables, one of which
 1268 A:cf6e                                    ;;; indicates the opcode strings and one of which handles the
 1269 A:cf6e                                    ;;; addressing modes (by storing entry points into the processing
 1270 A:cf6e                                    ;;; routines).
 1271 A:cf6e                                    ;;;

 1273 A:cf6e                           begindis  
 1274 A:cf6e  da                                 phx                    ; preserve X (it's a stack pointer elsewhere)
 1275 A:cf6f  a0 00                              ldy #0             ; y will track bytes as we go

 1277 A:cf71                           start     
 1278 A:cf71                           nextinst  
 1279 A:cf71                                    ;; start the line by printing the address and a couple of spaces
 1280 A:cf71                                    ;;
 1281 A:cf71  a5 1b                              lda BASE+1
 1282 A:cf73  20 6d d6                           jsr putax
 1283 A:cf76  a5 1a                              lda BASE
 1284 A:cf78  20 6d d6                           jsr putax
 1285 A:cf7b  a9 20                              lda #$20
 1286 A:cf7d  20 60 d6                           jsr puta
 1287 A:cf80  20 60 d6                           jsr puta
 1288 A:cf83  20 60 d6                           jsr puta

 1290 A:cf86                                    ;; before we handle the regular cases, check the table
 1291 A:cf86                                    ;; of special cases which are harder to detect via regular
 1292 A:cf86                                    ;; patterns
 1293 A:cf86  a2 00                              ldx #0
 1294 A:cf88                           nextspecial 
 1295 A:cf88  bd 64 d5                           lda specialcasetable,x              ; load item from table
 1296 A:cf8b  c9 ff                              cmp #$ff             ; check if it's the end of the table
 1297 A:cf8d  f0 0d                              beq endspecial                ; if so, exit
 1298 A:cf8f  d1 1a                              cmp (BASE),y            ; compare table item to instruction
 1299 A:cf91  f0 05                              beq foundspecial                ; match?
 1300 A:cf93  e8                                 inx                    ; move on to next table -- three bytes
 1301 A:cf94  e8                                 inx 
 1302 A:cf95  e8                                 inx 
 1303 A:cf96  80 f0                              bra nextspecial                ; loop
 1304 A:cf98                           foundspecial 
 1305 A:cf98  e8                                 inx                    ; when we find a match, jump to address in table
 1306 A:cf99  7c 64 d5                           jmp (specialcasetable,x)
 1307 A:cf9c                           endspecial                  ; got to the end of the table without a match
 1308 A:cf9c  b1 1a                              lda (BASE),y            ; re-load instruction

 1310 A:cf9e  29 1f                              and #%00011111             ; checking if it's a branch
 1311 A:cfa0  c9 10                              cmp #%00010000
 1312 A:cfa2  f0 2d                              beq jbranch                ; jump to code for branches

 1314 A:cfa4                                    ;; block of single byte instructions where the lower nybble is 8
 1315 A:cfa4                                    ;;
 1316 A:cfa4                           testlow8  
 1317 A:cfa4  b1 1a                              lda (BASE),y            ; get the instruction again (last test was destructive)
 1318 A:cfa6  29 0f                              and #%00001111
 1319 A:cfa8  c9 08                              cmp #$08             ; single-byte instructions with 8 in lower nybble
 1320 A:cfaa  d0 03                              bne testxa
 1321 A:cfac  4c cb d2                           jmp single8

 1323 A:cfaf                                    ;; block of single byte instructions at 8A, 9A, etc
 1324 A:cfaf                           testxa    
 1325 A:cfaf  b1 1a                              lda (BASE),y            ; get the instruction again (last test was destructive)
 1326 A:cfb1  29 8f                              and #%10001111
 1327 A:cfb3  c9 8a                              cmp #$8a             ; 8A, 9A, etc
 1328 A:cfb5  d0 03                              bne testcc00
 1329 A:cfb7  4c fa d2                           jmp singlexa

 1331 A:cfba                                    ;; otherwise, process according to the regular scheme of aaabbbcc
 1332 A:cfba                                    ;;
 1333 A:cfba                           testcc00  
 1334 A:cfba  b1 1a                              lda (BASE),y            ; get the instruction again (last test was destructive)
 1335 A:cfbc  29 03                              and #%00000011             ; look at the "cc" bits -- what sort of opcode?
 1336 A:cfbe  d0 03                              bne testcc10
 1337 A:cfc0  4c 39 d2                           jmp branch00                ; go to branch for cc=00
 1338 A:cfc3                           testcc10  
 1339 A:cfc3  c9 02                              cmp #%00000010
 1340 A:cfc5  d0 03                              bne testcc01
 1341 A:cfc7  4c c5 d1                           jmp branch10                ; go to branch for cc=10
 1342 A:cfca                           testcc01  
 1343 A:cfca  c9 01                              cmp #%00000001
 1344 A:cfcc  d0 06                              bne jothers                ; go to branch for remaining opcodes
 1345 A:cfce  4c d7 cf                           jmp branch01

 1347 A:cfd1                           jbranch   
 1348 A:cfd1  4c 9b d2                           jmp branch
 1349 A:cfd4                           jothers   
 1350 A:cfd4  4c 29 d3                           jmp others

 1352 A:cfd7                                    ;;; interpret according to the pattern for cc=01
 1353 A:cfd7                                    ;;;
 1354 A:cfd7                           branch01  
 1355 A:cfd7  b1 1a                              lda (BASE),y            ; reload instruction
 1356 A:cfd9  29 e0                              and #%11100000             ; grab top three bits
 1357 A:cfdb  4a                                 lsr                    ; shift right for times
 1358 A:cfdc  4a                                 lsr 
 1359 A:cfdd  4a                                 lsr                    ; result is the aaa code * 2, ...
 1360 A:cfde  4a                                 lsr                    ; ... the better to use as index into opcode table
 1361 A:cfdf  aa                                 tax 
 1362 A:cfe0                                    ; so now cc01optable,x is the pointer to the right string
 1363 A:cfe0  bd c4 d4                           lda cc01optable,x
 1364 A:cfe3  85 10                              sta SCRATCH
 1365 A:cfe5  bd c5 d4                           lda cc01optable+1,x
 1366 A:cfe8  85 11                              sta SCRATCH+1
 1367 A:cfea  5a                                 phy 
 1368 A:cfeb                                    ; print the three characters pointed to there
 1369 A:cfeb  a0 00                              ldy #0
 1370 A:cfed  b1 10                              lda (SCRATCH),y            ; first character...
 1371 A:cfef  20 60 d6                           jsr puta                ; print it
 1372 A:cff2  c8                                 iny 
 1373 A:cff3  b1 10                              lda (SCRATCH),y            ; second character...
 1374 A:cff5  20 60 d6                           jsr puta                ; print it
 1375 A:cff8  c8                                 iny 
 1376 A:cff9  b1 10                              lda (SCRATCH),y            ; third character...
 1377 A:cffb  20 60 d6                           jsr puta                ; print it
 1378 A:cffe  a9 20                              lda #$20             ; print a space
 1379 A:d000  20 60 d6                           jsr puta
 1380 A:d003  7a                                 ply 

 1382 A:d004                                    ;; handle each addressing mode
 1383 A:d004                                    ;; the addressing mode is going to determine how many
 1384 A:d004                                    ;; bytes we need to consume overall
 1385 A:d004                                    ;; so we do something similar... grab the bits, shift them down
 1386 A:d004                                    ;; and use that to look up a table which will tell us where
 1387 A:d004                                    ;; to jump to to interpret it correctly.

 1389 A:d004  b1 1a                              lda (BASE),y            ; get the instruction again
 1390 A:d006  29 1c                              and #%00011100             ; extract the bbb bits -- addressing mode
 1391 A:d008  4a                                 lsr                    ; shift just once
 1392 A:d009                                    ;; acc now holds the offset of the right entry in the table
 1393 A:d009                                    ;; now add in the base address of the table, and store it in SCRATCH
 1394 A:d009  18                                 clc 
 1395 A:d00a  69 d4                              adc #<cc01adtable
 1396 A:d00c  85 10                              sta SCRATCH                ; less significant byte
 1397 A:d00e  a9 d4                              lda #>cc01adtable
 1398 A:d010  69 00                              adc #0
 1399 A:d012  85 11                              sta SCRATCH+1          ; most significant byte
 1400 A:d014                                    ;; one more level of indirection -- fetch the address listed there
 1401 A:d014  5a                                 phy 
 1402 A:d015  a0 00                              ldy #0
 1403 A:d017  b1 10                              lda (SCRATCH),y
 1404 A:d019  85 12                              sta SCRATCH+2
 1405 A:d01b  c8                                 iny 
 1406 A:d01c  b1 10                              lda (SCRATCH),y
 1407 A:d01e  85 13                              sta SCRATCH+3
 1408 A:d020  7a                                 ply 
 1409 A:d021  6c 12 00                           jmp (SCRATCH+2)        ; jump to address specified in table

 1412 A:d024                                    ;;;
 1413 A:d024                                    ;;; Routines to handle the output for different addressing modes.
 1414 A:d024                                    ;;; Each addressing mode has its own entry point; entries in the
 1415 A:d024                                    ;;; addressing tables for each instruction block point here directly.
 1416 A:d024                                    ;;; On entry and exit, Y indicates the last byte processed.
 1417 A:d024                                    ;;;

 1419 A:d024                           acc       
 1420 A:d024                                    ;; accumulator
 1421 A:d024  a9 41                              lda #'A'
 1422 A:d026  20 60 d6                           jsr puta
 1423 A:d029  4c a5 d4                           jmp endline

 1425 A:d02c                           absx                       ; absolute, X -- consumes two more bytes
 1426 A:d02c  a9 24                              lda #'$'
 1427 A:d02e  20 60 d6                           jsr puta
 1428 A:d031  c8                                 iny                    ; get the second (most-sig) byte first
 1429 A:d032  c8                                 iny 
 1430 A:d033  b1 1a                              lda (BASE),y
 1431 A:d035  20 6d d6                           jsr putax
 1432 A:d038  88                                 dey                    ; then the less-significant byte
 1433 A:d039  b1 1a                              lda (BASE),y
 1434 A:d03b  20 6d d6                           jsr putax
 1435 A:d03e  c8                                 iny                    ; leave Y pointing to last byte consumed
 1436 A:d03f  a9 2c                              lda #','
 1437 A:d041  20 60 d6                           jsr puta
 1438 A:d044  a9 58                              lda #'X'
 1439 A:d046  20 60 d6                           jsr puta
 1440 A:d049  4c a5 d4                           jmp endline

 1442 A:d04c                           izpx                       ; (zero page,X), consumes one more byte
 1443 A:d04c  c8                                 iny 
 1444 A:d04d  a9 28                              lda #'('
 1445 A:d04f  20 60 d6                           jsr puta
 1446 A:d052  a9 24                              lda #'$'
 1447 A:d054  20 60 d6                           jsr puta
 1448 A:d057  a9 30                              lda #'0'
 1449 A:d059  20 60 d6                           jsr puta
 1450 A:d05c  20 60 d6                           jsr puta
 1451 A:d05f  b1 1a                              lda (BASE),y
 1452 A:d061  20 6d d6                           jsr putax
 1453 A:d064  a9 2c                              lda #','
 1454 A:d066  20 60 d6                           jsr puta
 1455 A:d069  a9 58                              lda #'X'
 1456 A:d06b  20 60 d6                           jsr puta
 1457 A:d06e  a9 29                              lda #')'
 1458 A:d070  20 60 d6                           jsr puta
 1459 A:d073  4c a5 d4                           jmp endline

 1461 A:d076                           zp                         ; zero page, consumes one more byte
 1462 A:d076  c8                                 iny 
 1463 A:d077  a9 24                              lda #'$'
 1464 A:d079  20 60 d6                           jsr puta
 1465 A:d07c  a9 30                              lda #'0'
 1466 A:d07e  20 60 d6                           jsr puta
 1467 A:d081  20 60 d6                           jsr puta
 1468 A:d084  b1 1a                              lda (BASE),y
 1469 A:d086  20 6d d6                           jsr putax
 1470 A:d089  4c a5 d4                           jmp endline

 1472 A:d08c                           izp                        ; indirect zero page, only on 65C02, consumes 1 byte
 1473 A:d08c  c8                                 iny 
 1474 A:d08d  a9 28                              lda #'('
 1475 A:d08f  20 60 d6                           jsr puta
 1476 A:d092  a9 24                              lda #'$'
 1477 A:d094  20 60 d6                           jsr puta
 1478 A:d097  a9 30                              lda #'0'
 1479 A:d099  20 60 d6                           jsr puta
 1480 A:d09c  20 60 d6                           jsr puta
 1481 A:d09f  b1 1a                              lda (BASE),y
 1482 A:d0a1  20 6d d6                           jsr putax
 1483 A:d0a4  a9 29                              lda #')'
 1484 A:d0a6  20 60 d6                           jsr puta
 1485 A:d0a9  4c a5 d4                           jmp endline

 1487 A:d0ac                           imm                        ; immediate mode, consumes one byte
 1488 A:d0ac  c8                                 iny 
 1489 A:d0ad  a9 23                              lda #'#'
 1490 A:d0af  20 60 d6                           jsr puta
 1491 A:d0b2  a9 24                              lda #'$'
 1492 A:d0b4  20 60 d6                           jsr puta
 1493 A:d0b7  b1 1a                              lda (BASE),y
 1494 A:d0b9  20 6d d6                           jsr putax
 1495 A:d0bc  4c a5 d4                           jmp endline

 1497 A:d0bf                           immb                       ; like immediate, but for branches (so ditch the "#")
 1498 A:d0bf  c8                                 iny 
 1499 A:d0c0  a9 24                              lda #'$'
 1500 A:d0c2  20 60 d6                           jsr puta
 1501 A:d0c5  b1 1a                              lda (BASE),y
 1502 A:d0c7  20 6d d6                           jsr putax
 1503 A:d0ca  4c a5 d4                           jmp endline

 1505 A:d0cd                           abs       
 1506 A:d0cd                                    ;; absolute -- consumes two more bytes
 1507 A:d0cd  a9 24                              lda #'$'
 1508 A:d0cf  20 60 d6                           jsr puta
 1509 A:d0d2  c8                                 iny                    ; get the second (most-sig) byte first
 1510 A:d0d3  c8                                 iny 
 1511 A:d0d4  b1 1a                              lda (BASE),y
 1512 A:d0d6  20 6d d6                           jsr putax
 1513 A:d0d9  88                                 dey                    ; then the less-significant byte
 1514 A:d0da  b1 1a                              lda (BASE),y
 1515 A:d0dc  20 6d d6                           jsr putax
 1516 A:d0df  c8                                 iny 
 1517 A:d0e0  4c a5 d4                           jmp endline

 1519 A:d0e3                           izpy      
 1520 A:d0e3                                    ;; (zero page),Y -- consumes one more byte
 1521 A:d0e3  c8                                 iny 
 1522 A:d0e4  a9 28                              lda #'('
 1523 A:d0e6  20 60 d6                           jsr puta
 1524 A:d0e9  a9 24                              lda #'$'
 1525 A:d0eb  20 60 d6                           jsr puta
 1526 A:d0ee  a9 30                              lda #'0'
 1527 A:d0f0  20 60 d6                           jsr puta
 1528 A:d0f3  20 60 d6                           jsr puta
 1529 A:d0f6  b1 1a                              lda (BASE),y
 1530 A:d0f8  20 6d d6                           jsr putax
 1531 A:d0fb  a9 29                              lda #')'
 1532 A:d0fd  20 60 d6                           jsr puta
 1533 A:d100  a9 2c                              lda #','
 1534 A:d102  20 60 d6                           jsr puta
 1535 A:d105  a9 59                              lda #'Y'
 1536 A:d107  20 60 d6                           jsr puta
 1537 A:d10a  4c a5 d4                           jmp endline

 1539 A:d10d                           ind       
 1540 A:d10d                                    ;; (addr) -- consumes two more bytes
 1541 A:d10d  c8                                 iny 
 1542 A:d10e  c8                                 iny 
 1543 A:d10f  a9 28                              lda #'('
 1544 A:d111  20 60 d6                           jsr puta
 1545 A:d114  a9 24                              lda #'$'
 1546 A:d116  20 60 d6                           jsr puta
 1547 A:d119  b1 1a                              lda (BASE),y
 1548 A:d11b  20 6d d6                           jsr putax
 1549 A:d11e  88                                 dey 
 1550 A:d11f  b1 1a                              lda (BASE),y
 1551 A:d121  20 6d d6                           jsr putax
 1552 A:d124  a9 29                              lda #')'
 1553 A:d126  20 60 d6                           jsr puta
 1554 A:d129  c8                                 iny 
 1555 A:d12a  4c a5 d4                           jmp endline

 1557 A:d12d                           indx                       ; only the JMP on 65C02?
 1558 A:d12d  c8                                 iny 
 1559 A:d12e  c8                                 iny 
 1560 A:d12f  a9 28                              lda #'('
 1561 A:d131  20 60 d6                           jsr puta
 1562 A:d134  a9 24                              lda #'$'
 1563 A:d136  20 60 d6                           jsr puta
 1564 A:d139  b1 1a                              lda (BASE),y
 1565 A:d13b  20 6d d6                           jsr putax
 1566 A:d13e  88                                 dey 
 1567 A:d13f  b1 1a                              lda (BASE),y
 1568 A:d141  20 6d d6                           jsr putax
 1569 A:d144  a9 2c                              lda #','
 1570 A:d146  20 60 d6                           jsr puta
 1571 A:d149  a9 58                              lda #'X'
 1572 A:d14b  20 60 d6                           jsr puta
 1573 A:d14e  a9 29                              lda #')'
 1574 A:d150  20 60 d6                           jsr puta
 1575 A:d153  c8                                 iny 
 1576 A:d154  4c a5 d4                           jmp endline

 1578 A:d157                           zpx       
 1579 A:d157                                    ;; zero page,X -- consumes one more byte
 1580 A:d157  c8                                 iny 
 1581 A:d158  a9 24                              lda #'$'
 1582 A:d15a  20 60 d6                           jsr puta
 1583 A:d15d  a9 30                              lda #'0'
 1584 A:d15f  20 60 d6                           jsr puta
 1585 A:d162  20 60 d6                           jsr puta
 1586 A:d165  b1 1a                              lda (BASE),y
 1587 A:d167  20 6d d6                           jsr putax
 1588 A:d16a  a9 2c                              lda #','
 1589 A:d16c  20 60 d6                           jsr puta
 1590 A:d16f  a9 58                              lda #'X'
 1591 A:d171  20 60 d6                           jsr puta
 1592 A:d174  4c a5 d4                           jmp endline

 1594 A:d177                           zpy       
 1595 A:d177                                    ;; zero page,Y -- consumes one more byte
 1596 A:d177  c8                                 iny 
 1597 A:d178  a9 24                              lda #'$'
 1598 A:d17a  20 60 d6                           jsr puta
 1599 A:d17d  a9 30                              lda #'0'
 1600 A:d17f  20 60 d6                           jsr puta
 1601 A:d182  20 60 d6                           jsr puta
 1602 A:d185  b1 1a                              lda (BASE),y
 1603 A:d187  20 6d d6                           jsr putax
 1604 A:d18a  a9 2c                              lda #','
 1605 A:d18c  20 60 d6                           jsr puta
 1606 A:d18f  a9 59                              lda #'Y'
 1607 A:d191  20 60 d6                           jsr puta
 1608 A:d194  4c a5 d4                           jmp endline

 1610 A:d197                           absy      
 1611 A:d197                                    ;; absolute,Y -- consumes two more bytes
 1612 A:d197  a9 24                              lda #'$'
 1613 A:d199  20 60 d6                           jsr puta
 1614 A:d19c  c8                                 iny                    ; get the second (most-sig) byte first
 1615 A:d19d  c8                                 iny 
 1616 A:d19e  b1 1a                              lda (BASE),y
 1617 A:d1a0  20 6d d6                           jsr putax
 1618 A:d1a3  88                                 dey                    ; then the less-significant byte
 1619 A:d1a4  b1 1a                              lda (BASE),y
 1620 A:d1a6  20 6d d6                           jsr putax
 1621 A:d1a9  c8                                 iny                    ; leave Y pointing to last byte consumed
 1622 A:d1aa  a9 2c                              lda #','
 1623 A:d1ac  20 60 d6                           jsr puta
 1624 A:d1af  a9 59                              lda #'Y'
 1625 A:d1b1  20 60 d6                           jsr puta
 1626 A:d1b4  4c a5 d4                           jmp endline

 1628 A:d1b7                           err       
 1629 A:d1b7                                    ;; can't interpret the opcode
 1630 A:d1b7  a9 3f                              lda #'?'
 1631 A:d1b9  20 60 d6                           jsr puta
 1632 A:d1bc  20 60 d6                           jsr puta
 1633 A:d1bf  20 60 d6                           jsr puta
 1634 A:d1c2  4c a5 d4                           jmp endline

 1636 A:d1c5                                    ;;; the next major block of addresses is those where the two
 1637 A:d1c5                                    ;;; bottom bits are 10. Processing is very similar to those
 1638 A:d1c5                                    ;;; where cc=01, above.
 1639 A:d1c5                                    ;;; almost all this code is just reproduced from above.
 1640 A:d1c5                                    ;;; TODO-- restructure to share more of the mechanics.
 1641 A:d1c5                                    ;;;
 1642 A:d1c5                           branch10  

 1644 A:d1c5                                    ;; first, take care of the unusual case of the 65C02 instructions
 1645 A:d1c5                                    ;; which use a different logic

 1647 A:d1c5                                    ;; look up and process opcode
 1648 A:d1c5                                    ;;
 1649 A:d1c5  b1 1a                              lda (BASE),y            ; reload instruction
 1650 A:d1c7  29 e0                              and #%11100000             ; grab top three bits
 1651 A:d1c9  4a                                 lsr                    ; shift right for times
 1652 A:d1ca  4a                                 lsr 
 1653 A:d1cb  4a                                 lsr                    ; result is the aaa code * 2, ...
 1654 A:d1cc  4a                                 lsr                    ; ... the better to use as index into opcode table
 1655 A:d1cd  aa                                 tax 

 1657 A:d1ce                                    ;; before we proceed, decide which table to look up. the 65C02 codes
 1658 A:d1ce                                    ;; in the range bbb=100 use a differnt logic
 1659 A:d1ce  b1 1a                              lda (BASE),y
 1660 A:d1d0  29 1c                              and #%00011100
 1661 A:d1d2  c9 10                              cmp #%00010000
 1662 A:d1d4  f0 0d                              beq specialb10

 1664 A:d1d6                                    ; so now cc10optable,x is the pointer to the right string
 1665 A:d1d6  bd e4 d4                           lda cc10optable,x
 1666 A:d1d9  85 10                              sta SCRATCH
 1667 A:d1db  bd e5 d4                           lda cc10optable+1,x
 1668 A:d1de  85 11                              sta SCRATCH+1
 1669 A:d1e0  4c ed d1                           jmp b10opcode

 1671 A:d1e3                           specialb10 
 1672 A:d1e3  bd c4 d4                           lda cc01optable,x              ; not an error... we're using the cc01 table for 65c02
 1673 A:d1e6  85 10                              sta SCRATCH
 1674 A:d1e8  bd c5 d4                           lda cc01optable+1,x
 1675 A:d1eb  85 11                              sta SCRATCH+1

 1677 A:d1ed                           b10opcode 
 1678 A:d1ed  5a                                 phy 
 1679 A:d1ee                                    ; print the three characters pointed to there
 1680 A:d1ee  a0 00                              ldy #0
 1681 A:d1f0  b1 10                              lda (SCRATCH),y            ; first character...
 1682 A:d1f2  20 60 d6                           jsr puta                ; print it
 1683 A:d1f5  c8                                 iny 
 1684 A:d1f6  b1 10                              lda (SCRATCH),y            ; second character...
 1685 A:d1f8  20 60 d6                           jsr puta                ; print it
 1686 A:d1fb  c8                                 iny 
 1687 A:d1fc  b1 10                              lda (SCRATCH),y            ; third character...
 1688 A:d1fe  20 60 d6                           jsr puta                ; print it
 1689 A:d201  a9 20                              lda #$20             ; print a space
 1690 A:d203  20 60 d6                           jsr puta
 1691 A:d206  7a                                 ply 

 1693 A:d207                                    ;; handle each addressing mode
 1694 A:d207                                    ;;
 1695 A:d207  b1 1a                              lda (BASE),y            ; get the instruction again
 1696 A:d209  c9 96                              cmp #$96             ; check fos special cases
 1697 A:d20b  f0 26                              beq specialstx                ; STX in ZP,X mode becomes ZP,Y
 1698 A:d20d  c9 b6                              cmp #$b6
 1699 A:d20f  f0 22                              beq specialldx1                ; LDX in ZP,X mode becomes ZP,Y
 1700 A:d211  c9 be                              cmp #$be
 1701 A:d213  f0 21                              beq specialldx2                ; LDX in ZP,X mode becomes ZP,Y

 1703 A:d215                                    ;; otherwise, proceed as usual
 1704 A:d215  29 1c                              and #%00011100             ; extract the bbb bits -- addressing mode
 1705 A:d217  4a                                 lsr                    ; shift just once
 1706 A:d218                                    ;; acc now holds the offset of the right entry in the table
 1707 A:d218                                    ;; now add in the base address of the table, and store it in SCRATCH
 1708 A:d218  18                                 clc 
 1709 A:d219  69 f4                              adc #<cc10adtable
 1710 A:d21b  85 10                              sta SCRATCH                ; less significant byte
 1711 A:d21d  a9 d4                              lda #>cc10adtable
 1712 A:d21f  69 00                              adc #0
 1713 A:d221  85 11                              sta SCRATCH+1          ; most significant byte
 1714 A:d223                                    ;; one more level of indirection -- fetch the address listed there
 1715 A:d223  5a                                 phy 
 1716 A:d224  a0 00                              ldy #0
 1717 A:d226  b1 10                              lda (SCRATCH),y
 1718 A:d228  85 12                              sta SCRATCH+2
 1719 A:d22a  c8                                 iny 
 1720 A:d22b  b1 10                              lda (SCRATCH),y
 1721 A:d22d  85 13                              sta SCRATCH+3
 1722 A:d22f  7a                                 ply 
 1723 A:d230  6c 12 00                           jmp (SCRATCH+2)        ; jump to address specified in table

 1725 A:d233                           specialstx 
 1726 A:d233                           specialldx1 
 1727 A:d233  4c 77 d1                           jmp zpy
 1728 A:d236                           specialldx2 
 1729 A:d236  4c 97 d1                           jmp absy

 1731 A:d239                                    ;;; This code for the block of instructions with cc=00. Note again
 1732 A:d239                                    ;;; that this is simply repeated from above and should be fixed.
 1733 A:d239                                    ;;; TODO-- refactor this code to eliminate duplication
 1734 A:d239                                    ;;;
 1735 A:d239                           branch00  
 1736 A:d239  b1 1a                              lda (BASE),y            ; reload instruction
 1737 A:d23b  29 e0                              and #%11100000             ; grab top three bits
 1738 A:d23d  4a                                 lsr                    ; shift right for times
 1739 A:d23e  4a                                 lsr 
 1740 A:d23f  4a                                 lsr                    ; result is the aaa code * 2, ...
 1741 A:d240  4a                                 lsr                    ; ... the better to use as index into opcode table
 1742 A:d241  aa                                 tax 
 1743 A:d242                                    ; so now cc00optable,x is the pointer to the right string
 1744 A:d242  bd 04 d5                           lda cc00optable,x
 1745 A:d245  85 10                              sta SCRATCH
 1746 A:d247  bd 05 d5                           lda cc00optable+1,x
 1747 A:d24a  85 11                              sta SCRATCH+1
 1748 A:d24c  5a                                 phy 
 1749 A:d24d                                    ; print the three characters pointed to there
 1750 A:d24d  a0 00                              ldy #0
 1751 A:d24f  b1 10                              lda (SCRATCH),y            ; first character...
 1752 A:d251  20 60 d6                           jsr puta                ; print it
 1753 A:d254  c8                                 iny 
 1754 A:d255  b1 10                              lda (SCRATCH),y            ; second character...
 1755 A:d257  20 60 d6                           jsr puta                ; print it
 1756 A:d25a  c8                                 iny 
 1757 A:d25b  b1 10                              lda (SCRATCH),y            ; third character...
 1758 A:d25d  20 60 d6                           jsr puta                ; print it
 1759 A:d260  a9 20                              lda #$20             ; print a space
 1760 A:d262  20 60 d6                           jsr puta
 1761 A:d265  7a                                 ply 

 1763 A:d266                                    ;; handle each addressing mode
 1764 A:d266                                    ;;
 1765 A:d266  b1 1a                              lda (BASE),y            ; get the instruction again
 1766 A:d268  c9 89                              cmp #$89             ; special case for BIT #
 1767 A:d26a  f0 26                              beq specialbit
 1768 A:d26c  c9 6c                              cmp #$6c             ; indirect JMP is a special case, handle separately
 1769 A:d26e  f0 25                              beq specialindjmp
 1770 A:d270  c9 7c                              cmp #$7c             ; similarly for indirect JMP,X
 1771 A:d272  f0 24                              beq specialindxjmp
 1772 A:d274  29 1c                              and #%00011100             ; extract the bbb bits -- addressing mode
 1773 A:d276  4a                                 lsr                    ; shift just once
 1774 A:d277                                    ;; acc now holds the offset of the right entry in the table
 1775 A:d277                                    ;; now add in the base address of the table, and store it in SCRATCH
 1776 A:d277  18                                 clc 
 1777 A:d278  69 14                              adc #<cc00adtable
 1778 A:d27a  85 10                              sta SCRATCH                ; less significant byte
 1779 A:d27c  a9 d5                              lda #>cc00adtable
 1780 A:d27e  69 00                              adc #0
 1781 A:d280  85 11                              sta SCRATCH+1          ; most significant byte
 1782 A:d282                                    ;; one more level of indirection -- fetch the address listed there
 1783 A:d282  5a                                 phy 
 1784 A:d283  a0 00                              ldy #0
 1785 A:d285  b1 10                              lda (SCRATCH),y
 1786 A:d287  85 12                              sta SCRATCH+2
 1787 A:d289  c8                                 iny 
 1788 A:d28a  b1 10                              lda (SCRATCH),y
 1789 A:d28c  85 13                              sta SCRATCH+3
 1790 A:d28e  7a                                 ply 
 1791 A:d28f  6c 12 00                           jmp (SCRATCH+2)        ; jump to address specified in table

 1793 A:d292                           specialbit 
 1794 A:d292                                    ;; treat this specially -- 65C02 opcode slightly out of place
 1795 A:d292  4c ac d0                           jmp imm

 1797 A:d295                           specialindjmp 
 1798 A:d295                                    ;; treat JMP (address) specially
 1799 A:d295  4c 0d d1                           jmp ind

 1801 A:d298                           specialindxjmp 
 1802 A:d298                                    ;; treat JMP (address,X) specially
 1803 A:d298  4c 2d d1                           jmp indx

 1806 A:d29b                                    ;;; branch instructions -- actually, these don't follow pattern so do FIRST
 1807 A:d29b                                    ;;; branches have the form xxy10000
 1808 A:d29b                                    ;;; xxy*2 should index into branchtable
 1809 A:d29b                           branch    
 1810 A:d29b  b1 1a                              lda (BASE),y
 1811 A:d29d  29 e0                              and #%11100000
 1812 A:d29f  4a                                 lsr 
 1813 A:d2a0  4a                                 lsr 
 1814 A:d2a1  4a                                 lsr 
 1815 A:d2a2  4a                                 lsr 
 1816 A:d2a3  aa                                 tax 

 1818 A:d2a4                                    ;; now index into table
 1819 A:d2a4                                    ; so now branchoptable,x is the pointer to the right string
 1820 A:d2a4  bd 24 d5                           lda branchoptable,x
 1821 A:d2a7  85 10                              sta SCRATCH
 1822 A:d2a9  bd 25 d5                           lda branchoptable+1,x
 1823 A:d2ac  85 11                              sta SCRATCH+1
 1824 A:d2ae  5a                                 phy 
 1825 A:d2af                                    ; print the three characters pointed to there
 1826 A:d2af  a0 00                              ldy #0
 1827 A:d2b1  b1 10                              lda (SCRATCH),y            ; first character...
 1828 A:d2b3  20 60 d6                           jsr puta                ; print it
 1829 A:d2b6  c8                                 iny 
 1830 A:d2b7  b1 10                              lda (SCRATCH),y            ; second character...
 1831 A:d2b9  20 60 d6                           jsr puta                ; print it
 1832 A:d2bc  c8                                 iny 
 1833 A:d2bd  b1 10                              lda (SCRATCH),y            ; third character...
 1834 A:d2bf  20 60 d6                           jsr puta                ; print it
 1835 A:d2c2  a9 20                              lda #$20             ; print a space
 1836 A:d2c4  20 60 d6                           jsr puta
 1837 A:d2c7  7a                                 ply 

 1839 A:d2c8                                    ;; we use a variant form of immediate mode to print the operand
 1840 A:d2c8                                    ;; for branch instructions
 1841 A:d2c8  4c bf d0                           jmp immb

 1843 A:d2cb                                    ;;; these are the single-byte instructions with 8 in their lower nybble
 1844 A:d2cb                                    ;;; again, code borrowed from above (branch) -- TODO -- refactor.
 1845 A:d2cb                           single8   
 1846 A:d2cb  b1 1a                              lda (BASE),y
 1847 A:d2cd  29 f0                              and #%11110000
 1848 A:d2cf  4a                                 lsr 
 1849 A:d2d0  4a                                 lsr 
 1850 A:d2d1  4a                                 lsr 
 1851 A:d2d2  aa                                 tax 

 1853 A:d2d3                                    ;; now index into table
 1854 A:d2d3                                    ;; so now single08table,x is the pointer to the right string
 1855 A:d2d3  bd 34 d5                           lda single08table,x
 1856 A:d2d6  85 10                              sta SCRATCH
 1857 A:d2d8  bd 35 d5                           lda single08table+1,x
 1858 A:d2db  85 11                              sta SCRATCH+1
 1859 A:d2dd  5a                                 phy 
 1860 A:d2de                                    ; print the three characters pointed to there
 1861 A:d2de  a0 00                              ldy #0
 1862 A:d2e0  b1 10                              lda (SCRATCH),y            ; first character...
 1863 A:d2e2  20 60 d6                           jsr puta                ; print it
 1864 A:d2e5  c8                                 iny 
 1865 A:d2e6  b1 10                              lda (SCRATCH),y            ; second character...
 1866 A:d2e8  20 60 d6                           jsr puta                ; print it
 1867 A:d2eb  c8                                 iny 
 1868 A:d2ec  b1 10                              lda (SCRATCH),y            ; third character...
 1869 A:d2ee  20 60 d6                           jsr puta                ; print it
 1870 A:d2f1  a9 20                              lda #$20             ; print a space
 1871 A:d2f3  20 60 d6                           jsr puta
 1872 A:d2f6  7a                                 ply 
 1873 A:d2f7  4c a5 d4                           jmp endline

 1875 A:d2fa                                    ;;; these are the single-byte instructions at 8A, 9A, etc.
 1876 A:d2fa                                    ;;; again, code borrowed from above (branch) -- TODO -- refactor.
 1877 A:d2fa                           singlexa  
 1878 A:d2fa  b1 1a                              lda (BASE),y
 1879 A:d2fc  29 70                              and #%01110000
 1880 A:d2fe  4a                                 lsr 
 1881 A:d2ff  4a                                 lsr 
 1882 A:d300  4a                                 lsr 
 1883 A:d301  aa                                 tax 

 1885 A:d302                                    ;; now index into table
 1886 A:d302                                    ;; so now singlexatable,x is the pointer to the right string
 1887 A:d302  bd 54 d5                           lda singlexatable,x
 1888 A:d305  85 10                              sta SCRATCH
 1889 A:d307  bd 55 d5                           lda singlexatable+1,x
 1890 A:d30a  85 11                              sta SCRATCH+1
 1891 A:d30c  5a                                 phy 
 1892 A:d30d                                    ; print the three characters pointed to there
 1893 A:d30d  a0 00                              ldy #0
 1894 A:d30f  b1 10                              lda (SCRATCH),y            ; first character...
 1895 A:d311  20 60 d6                           jsr puta                ; print it
 1896 A:d314  c8                                 iny 
 1897 A:d315  b1 10                              lda (SCRATCH),y            ; second character...
 1898 A:d317  20 60 d6                           jsr puta                ; print it
 1899 A:d31a  c8                                 iny 
 1900 A:d31b  b1 10                              lda (SCRATCH),y            ; third character...
 1901 A:d31d  20 60 d6                           jsr puta                ; print it
 1902 A:d320  a9 20                              lda #$20             ; print a space
 1903 A:d322  20 60 d6                           jsr puta
 1904 A:d325  7a                                 ply 
 1905 A:d326  4c a5 d4                           jmp endline

 1907 A:d329                                    ;;; this is where we end up if we haven't figured anything else out
 1908 A:d329                                    ;;;
 1909 A:d329                           others    
 1910 A:d329  a9 3f                              lda #'?'
 1911 A:d32b  20 60 d6                           jsr puta
 1912 A:d32e  20 60 d6                           jsr puta
 1913 A:d331  20 60 d6                           jsr puta
 1914 A:d334  4c a5 d4                           jmp endline

 1916 A:d337                                    ;; special cases go here
 1917 A:d337                                    ;;
 1918 A:d337                           dobrk     
 1919 A:d337  a9 42                              lda #'B'
 1920 A:d339  20 60 d6                           jsr puta
 1921 A:d33c  a9 52                              lda #'R'
 1922 A:d33e  20 60 d6                           jsr puta
 1923 A:d341  a9 4b                              lda #'K'
 1924 A:d343  20 60 d6                           jsr puta
 1925 A:d346  4c a5 d4                           jmp endline

 1927 A:d349                           dojsr     
 1928 A:d349  a9 4a                              lda #'J'
 1929 A:d34b  20 60 d6                           jsr puta
 1930 A:d34e  a9 53                              lda #'S'
 1931 A:d350  20 60 d6                           jsr puta
 1932 A:d353  a9 52                              lda #'R'
 1933 A:d355  20 60 d6                           jsr puta
 1934 A:d358  a9 20                              lda #$20
 1935 A:d35a  20 60 d6                           jsr puta
 1936 A:d35d  4c cd d0                           jmp abs

 1938 A:d360                           dorti     
 1939 A:d360  a9 52                              lda #'R'
 1940 A:d362  20 60 d6                           jsr puta
 1941 A:d365  a9 54                              lda #'T'
 1942 A:d367  20 60 d6                           jsr puta
 1943 A:d36a  a9 49                              lda #'I'
 1944 A:d36c  20 60 d6                           jsr puta
 1945 A:d36f  4c a5 d4                           jmp endline

 1947 A:d372                           dorts     
 1948 A:d372  a9 52                              lda #'R'
 1949 A:d374  20 60 d6                           jsr puta
 1950 A:d377  a9 54                              lda #'T'
 1951 A:d379  20 60 d6                           jsr puta
 1952 A:d37c  a9 53                              lda #'S'
 1953 A:d37e  20 60 d6                           jsr puta
 1954 A:d381  4c a5 d4                           jmp endline

 1956 A:d384                           dobra     
 1957 A:d384  a9 42                              lda #'B'
 1958 A:d386  20 60 d6                           jsr puta
 1959 A:d389  a9 52                              lda #'R'
 1960 A:d38b  20 60 d6                           jsr puta
 1961 A:d38e  a9 41                              lda #'A'
 1962 A:d390  20 60 d6                           jsr puta
 1963 A:d393  a9 20                              lda #$20
 1964 A:d395  20 60 d6                           jsr puta
 1965 A:d398  4c bf d0                           jmp immb

 1967 A:d39b                           dotrbzp   
 1968 A:d39b  a9 54                              lda #'T'
 1969 A:d39d  20 60 d6                           jsr puta
 1970 A:d3a0  a9 52                              lda #'R'
 1971 A:d3a2  20 60 d6                           jsr puta
 1972 A:d3a5  a9 42                              lda #'B'
 1973 A:d3a7  20 60 d6                           jsr puta
 1974 A:d3aa  a9 20                              lda #$20
 1975 A:d3ac  20 60 d6                           jsr puta
 1976 A:d3af  4c 76 d0                           jmp zp

 1978 A:d3b2                           dotrbabs  
 1979 A:d3b2  a9 54                              lda #'T'
 1980 A:d3b4  20 60 d6                           jsr puta
 1981 A:d3b7  a9 52                              lda #'R'
 1982 A:d3b9  20 60 d6                           jsr puta
 1983 A:d3bc  a9 42                              lda #'B'
 1984 A:d3be  20 60 d6                           jsr puta
 1985 A:d3c1  a9 20                              lda #$20
 1986 A:d3c3  20 60 d6                           jsr puta
 1987 A:d3c6  4c cd d0                           jmp abs

 1989 A:d3c9                           dostzzp   
 1990 A:d3c9  a9 53                              lda #'S'
 1991 A:d3cb  20 60 d6                           jsr puta
 1992 A:d3ce  a9 54                              lda #'T'
 1993 A:d3d0  20 60 d6                           jsr puta
 1994 A:d3d3  a9 5a                              lda #'Z'
 1995 A:d3d5  20 60 d6                           jsr puta
 1996 A:d3d8  a9 20                              lda #$20
 1997 A:d3da  20 60 d6                           jsr puta
 1998 A:d3dd  4c 76 d0                           jmp zp

 2000 A:d3e0                           dostzabs  
 2001 A:d3e0  a9 53                              lda #'S'
 2002 A:d3e2  20 60 d6                           jsr puta
 2003 A:d3e5  a9 54                              lda #'T'
 2004 A:d3e7  20 60 d6                           jsr puta
 2005 A:d3ea  a9 5a                              lda #'Z'
 2006 A:d3ec  20 60 d6                           jsr puta
 2007 A:d3ef  a9 20                              lda #$20
 2008 A:d3f1  20 60 d6                           jsr puta
 2009 A:d3f4  4c cd d0                           jmp abs

 2011 A:d3f7                           dostzzpx  
 2012 A:d3f7  a9 53                              lda #'S'
 2013 A:d3f9  20 60 d6                           jsr puta
 2014 A:d3fc  a9 54                              lda #'T'
 2015 A:d3fe  20 60 d6                           jsr puta
 2016 A:d401  a9 5a                              lda #'Z'
 2017 A:d403  20 60 d6                           jsr puta
 2018 A:d406  a9 20                              lda #$20
 2019 A:d408  20 60 d6                           jsr puta
 2020 A:d40b  4c 57 d1                           jmp zpx

 2022 A:d40e                           dostzabsx 
 2023 A:d40e  a9 53                              lda #'S'
 2024 A:d410  20 60 d6                           jsr puta
 2025 A:d413  a9 54                              lda #'T'
 2026 A:d415  20 60 d6                           jsr puta
 2027 A:d418  a9 5a                              lda #'Z'
 2028 A:d41a  20 60 d6                           jsr puta
 2029 A:d41d  a9 20                              lda #$20
 2030 A:d41f  20 60 d6                           jsr puta
 2031 A:d422  4c 2c d0                           jmp absx

 2033 A:d425                           doplx     
 2034 A:d425  a9 50                              lda #'P'
 2035 A:d427  20 60 d6                           jsr puta
 2036 A:d42a  a9 4c                              lda #'L'
 2037 A:d42c  20 60 d6                           jsr puta
 2038 A:d42f  a9 58                              lda #'X'
 2039 A:d431  20 60 d6                           jsr puta
 2040 A:d434  4c a5 d4                           jmp endline

 2042 A:d437                           dophx     
 2043 A:d437  a9 50                              lda #'P'
 2044 A:d439  20 60 d6                           jsr puta
 2045 A:d43c  a9 48                              lda #'H'
 2046 A:d43e  20 60 d6                           jsr puta
 2047 A:d441  a9 58                              lda #'X'
 2048 A:d443  20 60 d6                           jsr puta
 2049 A:d446  4c a5 d4                           jmp endline

 2051 A:d449                           doply     
 2052 A:d449  a9 50                              lda #'P'
 2053 A:d44b  20 60 d6                           jsr puta
 2054 A:d44e  a9 4c                              lda #'L'
 2055 A:d450  20 60 d6                           jsr puta
 2056 A:d453  a9 59                              lda #'Y'
 2057 A:d455  20 60 d6                           jsr puta
 2058 A:d458  4c a5 d4                           jmp endline

 2060 A:d45b                           dophy     
 2061 A:d45b  a9 50                              lda #'P'
 2062 A:d45d  20 60 d6                           jsr puta
 2063 A:d460  a9 48                              lda #'H'
 2064 A:d462  20 60 d6                           jsr puta
 2065 A:d465  a9 59                              lda #'Y'
 2066 A:d467  20 60 d6                           jsr puta
 2067 A:d46a  4c a5 d4                           jmp endline

 2069 A:d46d                           doinca    
 2070 A:d46d  a9 49                              lda #'I'
 2071 A:d46f  20 60 d6                           jsr puta
 2072 A:d472  a9 4e                              lda #'N'
 2073 A:d474  20 60 d6                           jsr puta
 2074 A:d477  a9 43                              lda #'C'
 2075 A:d479  20 60 d6                           jsr puta
 2076 A:d47c  a9 20                              lda #$20
 2077 A:d47e  20 60 d6                           jsr puta
 2078 A:d481  a9 41                              lda #'A'
 2079 A:d483  20 60 d6                           jsr puta
 2080 A:d486  4c a5 d4                           jmp endline

 2082 A:d489                           dodeca    
 2083 A:d489  a9 49                              lda #'I'
 2084 A:d48b  20 60 d6                           jsr puta
 2085 A:d48e  a9 4e                              lda #'N'
 2086 A:d490  20 60 d6                           jsr puta
 2087 A:d493  a9 43                              lda #'C'
 2088 A:d495  20 60 d6                           jsr puta
 2089 A:d498  a9 20                              lda #$20
 2090 A:d49a  20 60 d6                           jsr puta
 2091 A:d49d  a9 41                              lda #'A'
 2092 A:d49f  20 60 d6                           jsr puta
 2093 A:d4a2  4c a5 d4                           jmp endline

 2096 A:d4a5                           endline   
 2097 A:d4a5  20 45 d6                           jsr crlf

 2099 A:d4a8                                    ;; at this point, Y points to the last processed byte. Increment
 2100 A:d4a8                                    ;; to move on, and add it to base.
 2101 A:d4a8  c8                                 iny 
 2102 A:d4a9  18                                 clc 
 2103 A:d4aa  98                                 tya                    ; move Y to ACC and add to BASE address
 2104 A:d4ab  65 1a                              adc BASE
 2105 A:d4ad  85 1a                              sta BASE                ; low byte
 2106 A:d4af  a5 1b                              lda BASE+1
 2107 A:d4b1  69 00                              adc #0
 2108 A:d4b3  85 1b                              sta BASE+1          ; high byte
 2109 A:d4b5  a0 00                              ldy #0             ; reset Y

 2111 A:d4b7                                    ;; test if we should terminate... goes here...
 2112 A:d4b7  c6 1c                              dec COUNT
 2113 A:d4b9  f0 03                              beq finishdis

 2115 A:d4bb  4c 71 cf                           jmp nextinst

 2117 A:d4be                           finishdis 
 2118 A:d4be  fa                                 plx                    ; restore the stack pointer
 2119 A:d4bf                           exitdis   
 2120 A:d4bf  e8                                 inx                    ; pop one item off stack (one param)
 2121 A:d4c0  e8                                 inx 
 2122 A:d4c1  e8                                 inx                    ; pop second item off stack (other param)
 2123 A:d4c2  e8                                 inx 
 2124 A:d4c3  60                                 rts 

 2127 A:d4c4                           cc01optable 
 2128 A:d4c4  9a d5 9d d5 a0 d5 a3 ...           .word ORAstr,ANDstr,EORstr,ADCstr,STAstr,LDAstr,CMPstr,SBCstr
 2129 A:d4d4                           cc01adtable 
 2130 A:d4d4  4c d0 76 d0 ac d0 cd ...           .word izpx,zp,imm,abs,izpy,zpx,absy,absx

 2132 A:d4e4                           cc10optable 
 2133 A:d4e4  b2 d5 b5 d5 b8 d5 bb ...           .word ASLstr,ROLstr,LSRstr,RORstr,STXstr,LDXstr,DECstr,INCstr
 2134 A:d4f4                           cc10adtable 
 2135 A:d4f4  ac d0 76 d0 24 d0 cd ...           .word imm,zp,acc,abs,izp,zpx,err,absx

 2137 A:d504                           cc00optable 
 2138 A:d504                                    ;; yes, JMP appears here twice... it's not a mistake...
 2139 A:d504  3f d6 cd d5 d0 d5 d0 ...           .word TSBstr,BITstr,JMPstr,JMPstr,STYstr,LDYstr,CPYstr,CPXstr
 2140 A:d514                           cc00adtable 
 2141 A:d514  ac d0 76 d0 b7 d1 cd ...           .word imm,zp,err,abs,err,zpx,err,absx

 2143 A:d524                           branchoptable 
 2144 A:d524  df d5 e2 d5 e5 d5 e8 ...           .word BPLstr,BMIstr,BVCstr,BVSstr,BCCstr,BCSstr,BNEstr,BEQstr

 2146 A:d534                           single08table 
 2147 A:d534  f7 d5 fa d5 fd d5 00 ...           .word PHPstr,CLCstr,PLPstr,SECstr,PHAstr,CLIstr,PLAstr,SEIstr
 2148 A:d544  0f d6 12 d6 15 d6 18 ...           .word DEYstr,TYAstr,TAYstr,CLVstr,INYstr,CLDstr,INXstr,SEDstr

 2150 A:d554                           singlexatable 
 2151 A:d554  27 d6 2a d6 2d d6 30 ...           .word TXAstr,TXSstr,TAXstr,TSXstr,DEXstr,PHXstr,NOPstr,PLXstr

 2153 A:d564                           specialcasetable 
 2154 A:d564  00                                 .byt $00
 2155 A:d565  37 d3                              .word dobrk
 2156 A:d567  20                                 .byt $20
 2157 A:d568  49 d3                              .word dojsr
 2158 A:d56a  40                                 .byt $40
 2159 A:d56b  60 d3                              .word dorti
 2160 A:d56d  60                                 .byt $60
 2161 A:d56e  72 d3                              .word dorts
 2162 A:d570  80                                 .byt $80
 2163 A:d571  84 d3                              .word dobra
 2164 A:d573  14                                 .byt $14
 2165 A:d574  9b d3                              .word dotrbzp
 2166 A:d576  1c                                 .byt $1c
 2167 A:d577  b2 d3                              .word dotrbabs
 2168 A:d579  64                                 .byt $64
 2169 A:d57a  c9 d3                              .word dostzzp
 2170 A:d57c  9c                                 .byt $9c
 2171 A:d57d  e0 d3                              .word dostzabs
 2172 A:d57f  74                                 .byt $74
 2173 A:d580  f7 d3                              .word dostzzpx
 2174 A:d582  9e                                 .byt $9e
 2175 A:d583  0e d4                              .word dostzabsx
 2176 A:d585  1a                                 .byt $1a
 2177 A:d586  6d d4                              .word doinca
 2178 A:d588  3a                                 .byt $3a
 2179 A:d589  89 d4                              .word dodeca
 2180 A:d58b  5a                                 .byt $5a
 2181 A:d58c  5b d4                              .word dophy
 2182 A:d58e  7a                                 .byt $7a
 2183 A:d58f  49 d4                              .word doply
 2184 A:d591  da                                 .byt $da
 2185 A:d592  37 d4                              .word dophx
 2186 A:d594  fa                                 .byt $fa
 2187 A:d595  25 d4                              .word doplx
 2188 A:d597  ff                                 .byt $ff
 2189 A:d598  ff ff                              .word $ffff

 2192 A:d59a  4f 52 41                 ORAstr    .byt "ORA"
 2193 A:d59d  41 4e 44                 ANDstr    .byt "AND"
 2194 A:d5a0  45 4f 52                 EORstr    .byt "EOR"
 2195 A:d5a3  41 44 43                 ADCstr    .byt "ADC"
 2196 A:d5a6  53 54 41                 STAstr    .byt "STA"
 2197 A:d5a9  4c 44 41                 LDAstr    .byt "LDA"
 2198 A:d5ac  43 4d 50                 CMPstr    .byt "CMP"
 2199 A:d5af  53 42 43                 SBCstr    .byt "SBC"
 2200 A:d5b2  41 53 4c                 ASLstr    .byt "ASL"
 2201 A:d5b5  52 4f 4c                 ROLstr    .byt "ROL"
 2202 A:d5b8  4c 53 52                 LSRstr    .byt "LSR"
 2203 A:d5bb  52 4f 52                 RORstr    .byt "ROR"
 2204 A:d5be  53 54 58                 STXstr    .byt "STX"
 2205 A:d5c1  4c 44 58                 LDXstr    .byt "LDX"
 2206 A:d5c4  44 45 43                 DECstr    .byt "DEC"
 2207 A:d5c7  49 4e 43                 INCstr    .byt "INC"
 2208 A:d5ca  3f 3f 3f                 NONstr    .byt "???"
 2209 A:d5cd  42 49 54                 BITstr    .byt "BIT"
 2210 A:d5d0  4a 4d 50                 JMPstr    .byt "JMP"
 2211 A:d5d3  53 54 59                 STYstr    .byt "STY"
 2212 A:d5d6  4c 44 59                 LDYstr    .byt "LDY"
 2213 A:d5d9  43 50 59                 CPYstr    .byt "CPY"
 2214 A:d5dc  43 50 58                 CPXstr    .byt "CPX"
 2215 A:d5df  42 50 4c                 BPLstr    .byt "BPL"
 2216 A:d5e2  42 4d 49                 BMIstr    .byt "BMI"
 2217 A:d5e5  42 56 43                 BVCstr    .byt "BVC"
 2218 A:d5e8  42 56 53                 BVSstr    .byt "BVS"
 2219 A:d5eb  42 43 43                 BCCstr    .byt "BCC"
 2220 A:d5ee  42 43 53                 BCSstr    .byt "BCS"
 2221 A:d5f1  42 4e 45                 BNEstr    .byt "BNE"
 2222 A:d5f4  42 45 51                 BEQstr    .byt "BEQ"

 2224 A:d5f7  50 48 50                 PHPstr    .byt "PHP"
 2225 A:d5fa  43 4c 43                 CLCstr    .byt "CLC"
 2226 A:d5fd  50 4c 50                 PLPstr    .byt "PLP"
 2227 A:d600  53 45 43                 SECstr    .byt "SEC"
 2228 A:d603  50 48 41                 PHAstr    .byt "PHA"
 2229 A:d606  43 4c 49                 CLIstr    .byt "CLI"
 2230 A:d609  50 4c 41                 PLAstr    .byt "PLA"
 2231 A:d60c  53 45 49                 SEIstr    .byt "SEI"
 2232 A:d60f  44 45 59                 DEYstr    .byt "DEY"
 2233 A:d612  54 59 41                 TYAstr    .byt "TYA"
 2234 A:d615  54 41 59                 TAYstr    .byt "TAY"
 2235 A:d618  43 4c 56                 CLVstr    .byt "CLV"
 2236 A:d61b  49 4e 59                 INYstr    .byt "INY"
 2237 A:d61e  43 4c 44                 CLDstr    .byt "CLD"
 2238 A:d621  49 4e 58                 INXstr    .byt "INX"
 2239 A:d624  53 45 44                 SEDstr    .byt "SED"

 2241 A:d627  54 58 41                 TXAstr    .byt "TXA"
 2242 A:d62a  54 58 53                 TXSstr    .byt "TXS"
 2243 A:d62d  54 41 58                 TAXstr    .byt "TAX"
 2244 A:d630  54 53 58                 TSXstr    .byt "TSX"
 2245 A:d633  44 45 58                 DEXstr    .byt "DEX"
 2246 A:d636  4e 4f 50                 NOPstr    .byt "NOP"

 2248 A:d639  50 4c 41                 PLXstr    .byt "PLA"
 2249 A:d63c  50 48 58                 PHXstr    .byt "PHX"
 2250 A:d63f  54 53 42                 TSBstr    .byt "TSB"

 2252 A:d642  3f 3f 3f                 errstr    .byt "???"

 2254 A:d645                                     .) 

 2256 A:d645                                    ;;;;;;;;;;;;;
 2257 A:d645                                    ;;;
 2258 A:d645                                    ;;; END OF DISASSEMBLER
 2259 A:d645                                    ;;;
 2260 A:d645                                    ;;;;;;;;;;;;;

 2263 A:d645                                    ;;;;;;;;;;;;;
 2264 A:d645                                    ;;;
 2265 A:d645                                    ;;; Various utility routines
 2266 A:d645                                    ;;;
 2267 A:d645                                    ;;;;;;;;;;;;;

 2269 A:d645                                    ;;;
 2270 A:d645                                    ;;; Ouptut carriage return and line feed
 2271 A:d645                                    ;;;
 2272 A:d645                           crlf      
 2273 A:d645  48                                 pha 
 2274 A:d646                                     .( 
 2275 A:d646                           wait_txd_empty 
 2276 A:d646  ad 01 80                           lda ACIA_STATUS
 2277 A:d649  29 10                              and #$10
 2278 A:d64b  f0 f9                              beq wait_txd_empty
 2279 A:d64d                                     .) 
 2280 A:d64d  a9 0d                              lda #$0d
 2281 A:d64f  8d 00 80                           sta ACIA_DATA
 2282 A:d652                                     .( 
 2283 A:d652                           wait_txd_empty 
 2284 A:d652  ad 01 80                           lda ACIA_STATUS
 2285 A:d655  29 10                              and #$10
 2286 A:d657  f0 f9                              beq wait_txd_empty
 2287 A:d659                                     .) 
 2288 A:d659  a9 0a                              lda #$0a
 2289 A:d65b  8d 00 80                           sta ACIA_DATA
 2290 A:d65e  68                                 pla 
 2291 A:d65f  60                                 rts 

 2294 A:d660                                    ;;;
 2295 A:d660                                    ;;; output the character code in the accumulator
 2296 A:d660                                    ;;;
 2297 A:d660                           puta      
 2298 A:d660                                     .( 
 2299 A:d660  48                                 pha 
 2300 A:d661                           wait_txd_empty 
 2301 A:d661  ad 01 80                           lda ACIA_STATUS
 2302 A:d664  29 10                              and #$10
 2303 A:d666  f0 f9                              beq wait_txd_empty
 2304 A:d668  68                                 pla 
 2305 A:d669  8d 00 80                           sta ACIA_DATA
 2306 A:d66c                                     .) 
 2307 A:d66c  60                                 rts 

 2309 A:d66d                                    ;;;
 2310 A:d66d                                    ;;; output the value in the accumulator as a hex pattern
 2311 A:d66d                                    ;;; NB x cannot be guaranteed to be stack ptr during this... check...
 2312 A:d66d                                    ;;;
 2313 A:d66d                           putax     
 2314 A:d66d                                     .( 
 2315 A:d66d  5a                                 phy 

 2317 A:d66e  48                                 pha 
 2318 A:d66f                           wait_txd_empty 
 2319 A:d66f  ad 01 80                           lda ACIA_STATUS
 2320 A:d672  29 10                              and #$10
 2321 A:d674  f0 f9                              beq wait_txd_empty
 2322 A:d676  68                                 pla 
 2323 A:d677  48                                 pha                    ; put a copy back
 2324 A:d678  18                                 clc 
 2325 A:d679  29 f0                              and #$f0
 2326 A:d67b  6a                                 ror 
 2327 A:d67c  6a                                 ror 
 2328 A:d67d  6a                                 ror 
 2329 A:d67e  6a                                 ror 
 2330 A:d67f  a8                                 tay 
 2331 A:d680  b9 d5 eb                           lda hextable,y
 2332 A:d683  8d 00 80                           sta ACIA_DATA
 2333 A:d686                           wait_txd_empty2 
 2334 A:d686  ad 01 80                           lda ACIA_STATUS
 2335 A:d689  29 10                              and #$10
 2336 A:d68b  f0 f9                              beq wait_txd_empty2
 2337 A:d68d  68                                 pla 
 2338 A:d68e  18                                 clc 
 2339 A:d68f  29 0f                              and #$0f
 2340 A:d691  a8                                 tay 
 2341 A:d692  b9 d5 eb                           lda hextable,y
 2342 A:d695  8d 00 80                           sta ACIA_DATA
 2343 A:d698                                     .) 
 2344 A:d698  7a                                 ply 
 2345 A:d699  60                                 rts 

 2348 A:d69a                                    ;;; read a line of input from the serial interface
 2349 A:d69a                                    ;;; leaves data in the buffer at INPUT
 2350 A:d69a                                    ;;; y is the number of characters in the line, so it will fail if
 2351 A:d69a                                    ;;; more then 255 characters are entered
 2352 A:d69a                                    ;;; line terminated by carriage return. backspaces processed internally.
 2353 A:d69a                                    ;;;
 2354 A:d69a                           readline  
 2355 A:d69a  a0 00                              ldy #0
 2356 A:d69c                           readchar  
 2357 A:d69c                                     .( 
 2358 A:d69c                           wait_rxd_full 
 2359 A:d69c  ad 01 80                           lda ACIA_STATUS
 2360 A:d69f  29 08                              and #$08
 2361 A:d6a1  f0 f9                              beq wait_rxd_full
 2362 A:d6a3                                     .) 
 2363 A:d6a3  ad 00 80                           lda ACIA_DATA
 2364 A:d6a6  c9 08                              cmp #$08             ; check for backspace
 2365 A:d6a8  f0 0e                              beq backspace
 2366 A:d6aa  c9 0d                              cmp #$0d             ; check for newline
 2367 A:d6ac  f0 15                              beq done
 2368 A:d6ae  99 00 02                           sta INPUT,y              ; track the input
 2369 A:d6b1  c8                                 iny 
 2370 A:d6b2  20 60 d6                           jsr puta                ; echo the typed character
 2371 A:d6b5  4c 9c d6                           jmp readchar                ; loop to repeat
 2372 A:d6b8                           backspace 
 2373 A:d6b8  c0 00                              cpy #0             ; beginning of line?
 2374 A:d6ba  f0 e0                              beq readchar
 2375 A:d6bc  88                                 dey                    ; if not, go back one character
 2376 A:d6bd  20 60 d6                           jsr puta                ; move cursor back
 2377 A:d6c0  4c 9c d6                           jmp readchar

 2379 A:d6c3                                    ;; this is where we land if the line input has finished
 2380 A:d6c3                                    ;;
 2381 A:d6c3                           done      
 2382 A:d6c3  60                                 rts 

 2384 A:d6c4                                    ;; data receive
 2385 A:d6c4                                    ;; receives data from serial
 2386 A:d6c4                                    ;;
 2387 A:d6c4                                    ;; !! DISABLED !!

 2389 A:d6c4                                    ;receivecmd
 2390 A:d6c4                                    ;  pha
 2391 A:d6c4                                    ;  phx  ; save registers
 2392 A:d6c4                                    ;  phy
 2393 A:d6c4                                    ;  lda XYLODSAV2
 2394 A:d6c4                                    ;  pha
 2395 A:d6c4                                    ;  lda XYLODSAV2+1
 2396 A:d6c4                                    ;  pha
 2397 A:d6c4                                    ;;  ldx #<transferstring
 2398 A:d6c4                                    ;;  ldy #>transferstring
 2399 A:d6c4                                    ;;  jsr w_acia_full
 2400 A:d6c4                                    ;END_LOAD_MSG
 2401 A:d6c4                                    ;SERIAL_LOAD
 2402 A:d6c4                                    ;  ldx #0
 2403 A:d6c4                                    ;WRMSG
 2404 A:d6c4                                    ;  ldx #<serialstring
 2405 A:d6c4                                    ;  ldy #>serialstring ; Start serial load. <CRLF>
 2406 A:d6c4                                    ;  jsr w_acia_full
 2407 A:d6c4                                    ;receive_serial
 2408 A:d6c4                                    ;  lda #$55
 2409 A:d6c4                                    ;  sta serialvar
 2410 A:d6c4                                    ;  lda $0208  ; if "receive h"
 2411 A:d6c4                                    ;  cmp #'h'
 2412 A:d6c4                                    ;  bne rcloopstart ; then header mode
 2413 A:d6c4                                    ;  lda #0  ; otherwize, receive <addr>
 2414 A:d6c4                                    ;  sta serialvar  ; let rsl know
 2415 A:d6c4                                    ;  jmp serialheader
 2416 A:d6c4                                    ;rcloopstart
 2417 A:d6c4                                    ;  ldx #$04  ; 4 bytes
 2418 A:d6c4                                    ;rcloopadd
 2419 A:d6c4                                    ;  lda $0207,x  ; operand addr -1 (because of the loop)
 2420 A:d6c4                                    ;  pha   ; preserve a
 2421 A:d6c4                                    ;  cmp #$41  ; alphabet? (operand >= $41)
 2422 A:d6c4                                    ;  bcc rcloopadd1 ; no
 2423 A:d6c4                                    ;  pla   ; yes, restore a
 2424 A:d6c4                                    ;  sec   ; $57 cuz $A = #10
 2425 A:d6c4                                    ;  sbc #$57  ; $61 - $A = $57
 2426 A:d6c4                                    ;  jmp rcloopadd2 ; continue
 2427 A:d6c4                                    ;rcloopadd1  ; it is a number
 2428 A:d6c4                                    ;  pla   ; restore a so we can compare it
 2429 A:d6c4                                    ;  sec   ; (operand - $30)
 2430 A:d6c4                                    ;  sbc #$30
 2431 A:d6c4                                    ;rcloopadd2
 2432 A:d6c4                                    ;  sta $0207,x  ; store the created nibble, one per byte...
 2433 A:d6c4                                    ;  dex
 2434 A:d6c4                                    ;  bne rcloopadd
 2435 A:d6c4                                    ;
 2436 A:d6c4                                    ;  lda $0208  ; load the 4 nibbles into 2 bytes
 2437 A:d6c4                                    ;  asl   ; a nibble per byte to 2 nibbles per byte
 2438 A:d6c4                                    ;  asl   ; so it can be readable (little endian)
 2439 A:d6c4                                    ;  asl
 2440 A:d6c4                                    ;  asl
 2441 A:d6c4                                    ;  ora $0209
 2442 A:d6c4                                    ;  sta XYLODSAV2+1
 2443 A:d6c4                                    ;  lda $020a
 2444 A:d6c4                                    ;  asl
 2445 A:d6c4                                    ;  asl
 2446 A:d6c4                                    ;  asl
 2447 A:d6c4                                    ;  asl
 2448 A:d6c4                                    ;  ora $020b
 2449 A:d6c4                                    ;  sta XYLODSAV2
 2450 A:d6c4                                    ;
 2451 A:d6c4                                    ;  ldy #0
 2452 A:d6c4                                    ;  jmp rsl
 2453 A:d6c4                                    ;
 2454 A:d6c4                                    ;wop
 2454 A:d6c4                                    
 2455 A:d6c4                                    ;  jsr MONRDKEY  ; read a byte
 2456 A:d6c4                                    ;  bcc wop
 2457 A:d6c4                                    ;  lda ACIA_DATA
 2458 A:d6c4                                    ;  rts
 2459 A:d6c4                                    ;serialheader
 2459 A:d6c4                                    
 2460 A:d6c4                                    ;  jsr wop  ; load addr
 2461 A:d6c4                                    ;  sta XYLODSAV2  ; (where the load to)
 2462 A:d6c4                                    ;  jsr wop
 2463 A:d6c4                                    ;  sta XYLODSAV2+1
 2464 A:d6c4                                    ;  jsr wop  ; start addr
 2465 A:d6c4                                    ;  sta STARTADDR  ; (where to jump to)
 2466 A:d6c4                                    ;  jsr wop
 2467 A:d6c4                                    ;  sta STARTADDR+1
 2468 A:d6c4                                    ;  jsr wop  ; end addr
 2469 A:d6c4                                    ;  sta ENDADDR  ; (when the program ends)
 2470 A:d6c4                                    ;  jsr wop
 2471 A:d6c4                                    ;  sta ENDADDR+1
 2472 A:d6c4                                    ;  stz serialvar  ; a zero here means header mode
 2473 A:d6c4                                    ;  ldy #0
 2474 A:d6c4                                    ;rsl
 2475 A:d6c4                                    ;  jsr MONRDKEY  ; byte received?
 2476 A:d6c4                                    ;  bcc rsl
 2477 A:d6c4                                    ;  ldy #0
 2478 A:d6c4                                    ;  lda ACIA_DATA  ; then load it,
 2479 A:d6c4                                    ;  sta (XYLODSAV2),y ; and store it at the address (indexed because "sta (XYLODSAV2)" is illegal)
 2480 A:d6c4                                    ;  lda #$2e  ; print a period
 2481 A:d6c4                                    ;  jsr MONCOUT  ; to show it is working
 2482 A:d6c4                                    ;  inc XYLODSAV2
 2483 A:d6c4                                    ;  lda XYLODSAV2  ; increment 16-bit address
 2484 A:d6c4                                    ;  bne checkit
 2485 A:d6c4                                    ;  inc XYLODSAV2+1
 2486 A:d6c4                                    ;checkit
 2486 A:d6c4                                    
 2487 A:d6c4                                    ;  lda serialvar  ; header mode?
 2488 A:d6c4                                    ;  bne rsl
 2489 A:d6c4                                    ;   ; if so,
 2490 A:d6c4                                    ;  lda XYLODSAV2  ; check if we are done.
 2491 A:d6c4                                    ;  cmp ENDADDR
 2492 A:d6c4                                    ;  bne rsl
 2493 A:d6c4                                    ;  lda XYLODSAV2+1
 2494 A:d6c4                                    ;  cmp ENDADDR+1
 2495 A:d6c4                                    ;  bne rsl
 2496 A:d6c4                                    ;
 2497 A:d6c4                                    ;  ; done
 2498 A:d6c4                                    ;  jmp (STARTADDR) ; jump to the start address.
 2499 A:d6c4                                    ;
 2500 A:d6c4                                    ;serialdone
 2500 A:d6c4                                    
 2501 A:d6c4                                    ;  ldx #0
 2502 A:d6c4                                    ;sdone
 2503 A:d6c4                                    ;  lda loaddonestring,x
 2504 A:d6c4                                    ;  beq esl2  ; idk
 2505 A:d6c4                                    ;  jsr MONCOUT  ; not used
 2506 A:d6c4                                    ;  inx
 2507 A:d6c4                                    ;  jmp sdone
 2508 A:d6c4                                    ;esl2
 2509 A:d6c4                                    ;  pla
 2510 A:d6c4                                    ;  sta XYLODSAV2+1
 2511 A:d6c4                                    ;  pla
 2512 A:d6c4                                    ;  sta XYLODSAV2
 2513 A:d6c4                                    ;  ply
 2514 A:d6c4                                    ;  plx
 2515 A:d6c4                                    ;  pla
 2516 A:d6c4                                    ;  rts

 2518 A:d6c4                           MONCOUT   
 2519 A:d6c4  48                                 pha 
 2520 A:d6c5                           SerialOutWait 
 2521 A:d6c5  ad 01 80                           lda ACIA_STATUS
 2522 A:d6c8  29 10                              and #$10
 2523 A:d6ca  c9 10                              cmp #$10
 2524 A:d6cc  d0 f7                              bne SerialOutWait
 2525 A:d6ce  68                                 pla 
 2526 A:d6cf  8d 00 80                           sta ACIA_DATA
 2527 A:d6d2  60                                 rts 

 2529 A:d6d3                           MONRDKEY  
 2530 A:d6d3  ad 01 80                           lda ACIA_STATUS
 2531 A:d6d6  29 08                              and #$08
 2532 A:d6d8  c9 08                              cmp #$08
 2533 A:d6da  d0 05                              bne NoDataIn
 2534 A:d6dc  ad 00 80                           lda ACIA_DATA
 2535 A:d6df  38                                 sec 
 2536 A:d6e0  60                                 rts 
 2537 A:d6e1                           NoDataIn  
 2538 A:d6e1  18                                 clc 
 2539 A:d6e2  60                                 rts 

 2541 A:d6e3                           MONISCNTC 
 2542 A:d6e3  20 d3 d6                           jsr MONRDKEY
 2543 A:d6e6  90 06                              bcc NotCTRLC                ; If no key pressed then exit
 2544 A:d6e8  c9 03                              cmp #3
 2545 A:d6ea  d0 02                              bne NotCTRLC                ; if CTRL-C not pressed then exit
 2546 A:d6ec  38                                 sec                    ; Carry set if control C pressed
 2547 A:d6ed  60                                 rts 
 2548 A:d6ee                           NotCTRLC  
 2549 A:d6ee  18                                 clc                    ; Carry clear if control C not pressed
 2550 A:d6ef  60                                 rts 

 2552 A:d6f0                           via_init  
 2552 A:d6f0                                    
 2553 A:d6f0  a9 ff                              lda #%11111111             ; Set all pins on port B to output
 2554 A:d6f2  8d 02 b0                           sta VIA_DDRB
 2555 A:d6f5  a9 1c                              lda #PORTA_OUTPUTPINS               ; Set various pins on port A to output
 2556 A:d6f7  8d 03 b0                           sta VIA_DDRA
 2557 A:d6fa  60                                 rts 

 2559 A:d6fb                                    ; sd

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
  276 A:d83b  20 85 e0                           jsr w_acia_full
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


 2562 A:d8da                                    ; fat32

libfat32.a65

    1 A:d8da                                    ; FAT32/SD interface library
    2 A:d8da                                    ;
    3 A:d8da                                    ; This module requires some RAM workspace to be defined elsewhere
    3 A:d8da                                    
    4 A:d8da                                    ; 
    5 A:d8da                                    ; fat32_workspace    - a large page-aligned 512-byte workspace
    6 A:d8da                                    ; zp_fat32_variables - 55 bytes of zero-page storage for variables etc

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
   19 A:d8da                                    fat32_filenamepointer=zp_fat32_variables+$1c       ; 2 bytes
   20 A:d8da                                    fat32_lastcluster=fat32_variables+$00       ; 4 bytes
   21 A:d8da                                    fat32_lastsector=fat32_variables+$04       ; 4 bytes
   22 A:d8da                                    fat32_numfats=fat32_variables+$08       ; 1 byte
   23 A:d8da                                    fat32_filecluster=fat32_variables+$09       ; 4 bytes
   24 A:d8da                                    fat32_sectorsperfat=fat32_variables+$0d       ; 4 bytes
   25 A:d8da                                    fat32_cdcluster=fat32_variables+$11       ; 4 bytes
   26 A:d8da                                    fat32_buffer_index=fat32_variables+$15       ; 1 byte

   28 A:d8da                                    fat32_errorstage=fat32_bytesremaining             ; only used during initialization

   30 A:d8da                           fat32_init 
   30 A:d8da                                    
   31 A:d8da                                     .( 
   32 A:d8da                                    ; Initialize the module - read the MBR etc, find the partition,
   33 A:d8da                                    ; and set up the variables ready for navigating the filesystem

   35 A:d8da                                    ; Read the MBR and extract pertinent information

   37 A:d8da  a9 00                              lda #0
   38 A:d8dc  85 62                              sta fat32_errorstage

   40 A:d8de                                    ; Sector 0
   41 A:d8de  a9 00                              lda #0
   42 A:d8e0  85 4a                              sta zp_sd_currentsector
   43 A:d8e2  85 4b                              sta zp_sd_currentsector+1
   44 A:d8e4  85 4c                              sta zp_sd_currentsector+2
   45 A:d8e6  85 4d                              sta zp_sd_currentsector+3

   47 A:d8e8                                    ; Target buffer
   48 A:d8e8  a9 00                              lda #<fat32_readbuffer
   49 A:d8ea  85 5c                              sta fat32_address
   50 A:d8ec  85 48                              sta zp_sd_address
   51 A:d8ee  a9 05                              lda #>fat32_readbuffer
   52 A:d8f0  85 5d                              sta fat32_address+1
   53 A:d8f2  85 49                              sta zp_sd_address+1

   55 A:d8f4                                    ; Do the read
   56 A:d8f4  20 f6 d7                           jsr sd_readsector

   59 A:d8f7  e6 62                              inc fat32_errorstage                ; stage 1 = boot sector signature check

   61 A:d8f9                                    ; Check some things
   62 A:d8f9  ad fe 06                           lda fat32_readbuffer+510          ; Boot sector signature 55
   63 A:d8fc  c9 55                              cmp #$55
   64 A:d8fe  d0 2d                              bne fail
   65 A:d900  ad ff 06                           lda fat32_readbuffer+511          ; Boot sector signature aa
   66 A:d903  c9 aa                              cmp #$aa
   67 A:d905  d0 26                              bne fail

   70 A:d907  e6 62                              inc fat32_errorstage                ; stage 2 = finding partition

   72 A:d909                                    ; Find a FAT32 partition
   73 A:d909                                    FSTYPE_FAT32=12
   74 A:d909  a2 00                              ldx #0
   75 A:d90b  bd c2 06                           lda fat32_readbuffer+$01c2,x
   76 A:d90e  c9 0c                              cmp #FSTYPE_FAT32
   77 A:d910  f0 1e                              beq foundpart
   78 A:d912  a2 10                              ldx #16
   79 A:d914  bd c2 06                           lda fat32_readbuffer+$01c2,x
   80 A:d917  c9 0c                              cmp #FSTYPE_FAT32
   81 A:d919  f0 15                              beq foundpart
   82 A:d91b  a2 20                              ldx #32
   83 A:d91d  bd c2 06                           lda fat32_readbuffer+$01c2,x
   84 A:d920  c9 0c                              cmp #FSTYPE_FAT32
   85 A:d922  f0 0c                              beq foundpart
   86 A:d924  a2 30                              ldx #48
   87 A:d926  bd c2 06                           lda fat32_readbuffer+$01c2,x
   88 A:d929  c9 0c                              cmp #FSTYPE_FAT32
   89 A:d92b  f0 03                              beq foundpart

   91 A:d92d                           fail      
   91 A:d92d                                    
   92 A:d92d  4c 17 da                           jmp error

   94 A:d930                           foundpart 
   94 A:d930                                    

   96 A:d930                                    ; Read the FAT32 BPB
   97 A:d930  bd c6 06                           lda fat32_readbuffer+$01c6,x
   98 A:d933  85 4a                              sta zp_sd_currentsector
   99 A:d935  bd c7 06                           lda fat32_readbuffer+$01c7,x
  100 A:d938  85 4b                              sta zp_sd_currentsector+1
  101 A:d93a  bd c8 06                           lda fat32_readbuffer+$01c8,x
  102 A:d93d  85 4c                              sta zp_sd_currentsector+2
  103 A:d93f  bd c9 06                           lda fat32_readbuffer+$01c9,x
  104 A:d942  85 4d                              sta zp_sd_currentsector+3

  106 A:d944  20 f6 d7                           jsr sd_readsector

  109 A:d947  e6 62                              inc fat32_errorstage                ; stage 3 = BPB signature check

  111 A:d949                                    ; Check some things
  112 A:d949  ad fe 06                           lda fat32_readbuffer+510          ; BPB sector signature 55
  113 A:d94c  c9 55                              cmp #$55
  114 A:d94e  d0 dd                              bne fail
  115 A:d950  ad ff 06                           lda fat32_readbuffer+511          ; BPB sector signature aa
  116 A:d953  c9 aa                              cmp #$aa
  117 A:d955  d0 d6                              bne fail

  119 A:d957  e6 62                              inc fat32_errorstage                ; stage 4 = RootEntCnt check

  121 A:d959  ad 11 05                           lda fat32_readbuffer+17          ; RootEntCnt should be 0 for FAT32
  122 A:d95c  0d 12 05                           ora fat32_readbuffer+18
  123 A:d95f  d0 cc                              bne fail

  125 A:d961  e6 62                              inc fat32_errorstage                ; stage 5 = TotSec16 check

  127 A:d963  ad 13 05                           lda fat32_readbuffer+19          ; TotSec16 should be 0 for FAT32
  128 A:d966  0d 14 05                           ora fat32_readbuffer+20
  129 A:d969  d0 c2                              bne fail

  131 A:d96b  e6 62                              inc fat32_errorstage                ; stage 6 = SectorsPerCluster check

  133 A:d96d                                    ; Check bytes per filesystem sector, it should be 512 for any SD card that supports FAT32
  134 A:d96d  ad 0b 05                           lda fat32_readbuffer+11          ; low byte should be zero
  135 A:d970  d0 bb                              bne fail
  136 A:d972  ad 0c 05                           lda fat32_readbuffer+12          ; high byte is 2 (512), 4, 8, or 16
  137 A:d975  c9 02                              cmp #2
  138 A:d977  d0 b4                              bne fail

  140 A:d979                                    ; Calculate the starting sector of the FAT
  141 A:d979  18                                 clc 
  142 A:d97a  a5 4a                              lda zp_sd_currentsector
  143 A:d97c  6d 0e 05                           adc fat32_readbuffer+14          ; reserved sectors lo
  144 A:d97f  85 4e                              sta fat32_fatstart
  145 A:d981  85 52                              sta fat32_datastart
  146 A:d983  a5 4b                              lda zp_sd_currentsector+1
  147 A:d985  6d 0f 05                           adc fat32_readbuffer+15          ; reserved sectors hi
  148 A:d988  85 4f                              sta fat32_fatstart+1
  149 A:d98a  85 53                              sta fat32_datastart+1
  150 A:d98c  a5 4c                              lda zp_sd_currentsector+2
  151 A:d98e  69 00                              adc #0
  152 A:d990  85 50                              sta fat32_fatstart+2
  153 A:d992  85 54                              sta fat32_datastart+2
  154 A:d994  a5 4d                              lda zp_sd_currentsector+3
  155 A:d996  69 00                              adc #0
  156 A:d998  85 51                              sta fat32_fatstart+3
  157 A:d99a  85 55                              sta fat32_datastart+3

  159 A:d99c                                    ; Calculate the starting sector of the data area
  160 A:d99c  ae 10 05                           ldx fat32_readbuffer+16          ; number of FATs
  161 A:d99f  8e 08 03                           stx fat32_numfats                ; (stash for later as well)
  162 A:d9a2                           skipfatsloop 
  162 A:d9a2                                    
  163 A:d9a2  18                                 clc 
  164 A:d9a3  a5 52                              lda fat32_datastart
  165 A:d9a5  6d 24 05                           adc fat32_readbuffer+36          ; fatsize 0
  166 A:d9a8  85 52                              sta fat32_datastart
  167 A:d9aa  a5 53                              lda fat32_datastart+1
  168 A:d9ac  6d 25 05                           adc fat32_readbuffer+37          ; fatsize 1
  169 A:d9af  85 53                              sta fat32_datastart+1
  170 A:d9b1  a5 54                              lda fat32_datastart+2
  171 A:d9b3  6d 26 05                           adc fat32_readbuffer+38          ; fatsize 2
  172 A:d9b6  85 54                              sta fat32_datastart+2
  173 A:d9b8  a5 55                              lda fat32_datastart+3
  174 A:d9ba  6d 27 05                           adc fat32_readbuffer+39          ; fatsize 3
  175 A:d9bd  85 55                              sta fat32_datastart+3
  176 A:d9bf  ca                                 dex 
  177 A:d9c0  d0 e0                              bne skipfatsloop

  179 A:d9c2                                    ; Sectors-per-cluster is a power of two from 1 to 128
  180 A:d9c2  ad 0d 05                           lda fat32_readbuffer+13
  181 A:d9c5  85 5a                              sta fat32_sectorspercluster

  183 A:d9c7                                    ; Remember the root cluster
  184 A:d9c7  ad 2c 05                           lda fat32_readbuffer+44
  185 A:d9ca  85 56                              sta fat32_rootcluster
  186 A:d9cc  ad 2d 05                           lda fat32_readbuffer+45
  187 A:d9cf  85 57                              sta fat32_rootcluster+1
  188 A:d9d1  ad 2e 05                           lda fat32_readbuffer+46
  189 A:d9d4  85 58                              sta fat32_rootcluster+2
  190 A:d9d6  ad 2f 05                           lda fat32_readbuffer+47
  191 A:d9d9  85 59                              sta fat32_rootcluster+3

  193 A:d9db                                    ; Save Sectors Per FAT
  194 A:d9db  ad 24 05                           lda fat32_readbuffer+36
  195 A:d9de  8d 0d 03                           sta fat32_sectorsperfat
  196 A:d9e1  ad 25 05                           lda fat32_readbuffer+37
  197 A:d9e4  8d 0e 03                           sta fat32_sectorsperfat+1
  198 A:d9e7  ad 26 05                           lda fat32_readbuffer+38
  199 A:d9ea  8d 0f 03                           sta fat32_sectorsperfat+2
  200 A:d9ed  ad 27 05                           lda fat32_readbuffer+39
  201 A:d9f0  8d 10 03                           sta fat32_sectorsperfat+3

  203 A:d9f3                                    ; Set the last found free cluster to 0.
  204 A:d9f3  a9 00                              lda #0
  205 A:d9f5  85 66                              sta fat32_lastfoundfreecluster
  206 A:d9f7  85 67                              sta fat32_lastfoundfreecluster+1
  207 A:d9f9  85 68                              sta fat32_lastfoundfreecluster+2
  208 A:d9fb  85 69                              sta fat32_lastfoundfreecluster+3

  210 A:d9fd                                    ; As well as the last read clusters and sectors
  211 A:d9fd  8d 00 03                           sta fat32_lastcluster
  212 A:da00  8d 01 03                           sta fat32_lastcluster+1
  213 A:da03  8d 02 03                           sta fat32_lastcluster+2
  214 A:da06  8d 03 03                           sta fat32_lastcluster+3
  215 A:da09  8d 04 03                           sta fat32_lastsector
  216 A:da0c  8d 05 03                           sta fat32_lastsector+1
  217 A:da0f  8d 06 03                           sta fat32_lastsector+2
  218 A:da12  8d 07 03                           sta fat32_lastsector+3

  220 A:da15  18                                 clc 
  221 A:da16  60                                 rts 

  223 A:da17                           error     
  223 A:da17                                    
  224 A:da17  38                                 sec 
  225 A:da18  60                                 rts 
  226 A:da19                                     .) 

  228 A:da19                           fat32_seekcluster 
  228 A:da19                                    
  229 A:da19                                     .( 
  230 A:da19                                    ; Calculates the FAT sector given fat32_nextcluster and stores in zp_sd_currentsector
  231 A:da19                                    ; Optionally will load the 512 byte FAT sector into memory at fat32_readbuffer
  232 A:da19                                    ; If carry is set, subroutine is optimized to skip the loading if the expected
  233 A:da19                                    ; sector is already loaded. Clearing carry before calling will skip optimization
  234 A:da19                                    ; and force reload of the FAT sector. Once the FAT sector is loaded,
  235 A:da19                                    ; the next cluster in the chain is loaded into fat32_nextcluster and
  236 A:da19                                    ; zp_sd_currentsector is updated to point to the referenced data sector

  238 A:da19                                    ; This routine also leaves Y pointing to the LSB for the 32 bit next cluster.

  240 A:da19                                    ; Gets ready to read fat32_nextcluster, and advances it according to the FAT                            
  241 A:da19                                    ; Before calling, set carry to compare the current FAT sector with lastsector.
  242 A:da19                                    ; Otherwize, clear carry to force reading the FAT.            

  244 A:da19  08                                 php 

  246 A:da1a                                    ; Target buffer
  247 A:da1a  a9 00                              lda #<fat32_readbuffer
  248 A:da1c  85 48                              sta zp_sd_address
  249 A:da1e  a9 05                              lda #>fat32_readbuffer
  250 A:da20  85 49                              sta zp_sd_address+1

  252 A:da22                                    ; FAT sector = (cluster*4) / 512 = (cluster*2) / 256
  253 A:da22  a5 5e                              lda fat32_nextcluster
  254 A:da24  0a                                 asl 
  255 A:da25  a5 5f                              lda fat32_nextcluster+1
  256 A:da27  2a                                 rol 
  257 A:da28  85 4a                              sta zp_sd_currentsector
  258 A:da2a  a5 60                              lda fat32_nextcluster+2
  259 A:da2c  2a                                 rol 
  260 A:da2d  85 4b                              sta zp_sd_currentsector+1
  261 A:da2f  a5 61                              lda fat32_nextcluster+3
  262 A:da31  2a                                 rol 
  263 A:da32  85 4c                              sta zp_sd_currentsector+2
  264 A:da34                                    ; note - cluster numbers never have the top bit set, so no carry can occur

  266 A:da34                                    ; Add FAT starting sector
  267 A:da34  a5 4a                              lda zp_sd_currentsector
  268 A:da36  65 4e                              adc fat32_fatstart
  269 A:da38  85 4a                              sta zp_sd_currentsector
  270 A:da3a  a5 4b                              lda zp_sd_currentsector+1
  271 A:da3c  65 4f                              adc fat32_fatstart+1
  272 A:da3e  85 4b                              sta zp_sd_currentsector+1
  273 A:da40  a5 4c                              lda zp_sd_currentsector+2
  274 A:da42  65 50                              adc fat32_fatstart+2
  275 A:da44  85 4c                              sta zp_sd_currentsector+2
  276 A:da46  a9 00                              lda #0
  277 A:da48  65 51                              adc fat32_fatstart+3
  278 A:da4a  85 4d                              sta zp_sd_currentsector+3

  280 A:da4c                                    ; Branch if we don't need to check
  281 A:da4c  28                                 plp 
  282 A:da4d  90 1c                              bcc newsector

  284 A:da4f                                    ; Check if this sector is the same as the last one
  285 A:da4f  ad 04 03                           lda fat32_lastsector
  286 A:da52  c5 4a                              cmp zp_sd_currentsector
  287 A:da54  d0 15                              bne newsector
  288 A:da56  ad 05 03                           lda fat32_lastsector+1
  289 A:da59  c5 4b                              cmp zp_sd_currentsector+1
  290 A:da5b  d0 0e                              bne newsector
  291 A:da5d  ad 06 03                           lda fat32_lastsector+2
  292 A:da60  c5 4c                              cmp zp_sd_currentsector+2
  293 A:da62  d0 07                              bne newsector
  294 A:da64  ad 07 03                           lda fat32_lastsector+3
  295 A:da67  c5 4d                              cmp zp_sd_currentsector+3
  296 A:da69  f0 17                              beq notnew

  298 A:da6b                           newsector 

  300 A:da6b                                    ; Read the sector from the FAT
  301 A:da6b  20 f6 d7                           jsr sd_readsector

  303 A:da6e                                    ; Update fat32_lastsector

  305 A:da6e  a5 4a                              lda zp_sd_currentsector
  306 A:da70  8d 04 03                           sta fat32_lastsector
  307 A:da73  a5 4b                              lda zp_sd_currentsector+1
  308 A:da75  8d 05 03                           sta fat32_lastsector+1
  309 A:da78  a5 4c                              lda zp_sd_currentsector+2
  310 A:da7a  8d 06 03                           sta fat32_lastsector+2
  311 A:da7d  a5 4d                              lda zp_sd_currentsector+3
  312 A:da7f  8d 07 03                           sta fat32_lastsector+3

  314 A:da82                           notnew    

  316 A:da82                                    ; Before using this FAT data, set currentsector ready to read the cluster itself
  317 A:da82                                    ; We need to multiply the cluster number minus two by the number of sectors per 
  318 A:da82                                    ; cluster, then add the data region start sector

  320 A:da82                                    ; Subtract two from cluster number
  321 A:da82  38                                 sec 
  322 A:da83  a5 5e                              lda fat32_nextcluster
  323 A:da85  e9 02                              sbc #2
  324 A:da87  85 4a                              sta zp_sd_currentsector
  325 A:da89  a5 5f                              lda fat32_nextcluster+1
  326 A:da8b  e9 00                              sbc #0
  327 A:da8d  85 4b                              sta zp_sd_currentsector+1
  328 A:da8f  a5 60                              lda fat32_nextcluster+2
  329 A:da91  e9 00                              sbc #0
  330 A:da93  85 4c                              sta zp_sd_currentsector+2
  331 A:da95  a5 61                              lda fat32_nextcluster+3
  332 A:da97  e9 00                              sbc #0
  333 A:da99  85 4d                              sta zp_sd_currentsector+3

  335 A:da9b                                    ; Multiply by sectors-per-cluster which is a power of two between 1 and 128
  336 A:da9b  a5 5a                              lda fat32_sectorspercluster
  337 A:da9d                           spcshiftloop 
  337 A:da9d                                    
  338 A:da9d  4a                                 lsr 
  339 A:da9e  b0 0b                              bcs spcshiftloopdone
  340 A:daa0  06 4a                              asl zp_sd_currentsector
  341 A:daa2  26 4b                              rol zp_sd_currentsector+1
  342 A:daa4  26 4c                              rol zp_sd_currentsector+2
  343 A:daa6  26 4d                              rol zp_sd_currentsector+3
  344 A:daa8  4c 9d da                           jmp spcshiftloop
  345 A:daab                           spcshiftloopdone 
  345 A:daab                                    

  347 A:daab                                    ; Add the data region start sector
  348 A:daab  18                                 clc 
  349 A:daac  a5 4a                              lda zp_sd_currentsector
  350 A:daae  65 52                              adc fat32_datastart
  351 A:dab0  85 4a                              sta zp_sd_currentsector
  352 A:dab2  a5 4b                              lda zp_sd_currentsector+1
  353 A:dab4  65 53                              adc fat32_datastart+1
  354 A:dab6  85 4b                              sta zp_sd_currentsector+1
  355 A:dab8  a5 4c                              lda zp_sd_currentsector+2
  356 A:daba  65 54                              adc fat32_datastart+2
  357 A:dabc  85 4c                              sta zp_sd_currentsector+2
  358 A:dabe  a5 4d                              lda zp_sd_currentsector+3
  359 A:dac0  65 55                              adc fat32_datastart+3
  360 A:dac2  85 4d                              sta zp_sd_currentsector+3

  362 A:dac4                                    ; That's now ready for later code to read this sector in - tell it how many consecutive
  363 A:dac4                                    ; sectors it can now read
  364 A:dac4  a5 5a                              lda fat32_sectorspercluster
  365 A:dac6  85 5b                              sta fat32_pendingsectors

  367 A:dac8                                    ; Now go back to looking up the next cluster in the chain
  368 A:dac8                                    ; Find the offset to this cluster's entry in the FAT sector we loaded earlier

  370 A:dac8                                    ; Offset = (cluster*4) & 511 = (cluster & 127) * 4

  372 A:dac8  a5 5e                              lda fat32_nextcluster
  373 A:daca  29 7f                              and #$7f
  374 A:dacc  0a                                 asl 
  375 A:dacd  0a                                 asl 
  376 A:dace  a8                                 tay                    ; Y = low byte of offset

  378 A:dacf                                    ; cluster_offset = (cluster * 4) & 511
  379 A:dacf                                    ;lda fat32_nextcluster
  380 A:dacf                                    ;asl                         ; ×2
  381 A:dacf                                    ;rol fat32_nextcluster+1     ; bit 7 → bit 0 of high byte
  382 A:dacf                                    ;asl                         ; ×4
  383 A:dacf                                    ;rol fat32_nextcluster+1     ; bit 7 → bit 0 again
  384 A:dacf                                    ;tay                         ; Y = offset low byte

  386 A:dacf                                    ; Add the potentially carried bit to the high byte of the address
  387 A:dacf  a5 49                              lda zp_sd_address+1
  388 A:dad1  69 00                              adc #0
  389 A:dad3  85 49                              sta zp_sd_address+1

  391 A:dad5  5a                                 phy                    ; stash the index to next value for the cluster

  393 A:dad6                                    ; Store the previous cluster
  394 A:dad6                                    ;lda fat32_nextcluster
  395 A:dad6                                    ;sta fat32_prevcluster
  396 A:dad6                                    ;lda fat32_nextcluster+1
  397 A:dad6                                    ;sta fat32_prevcluster+1
  398 A:dad6                                    ;lda fat32_nextcluster+2
  399 A:dad6                                    ;sta fat32_prevcluster+2
  400 A:dad6                                    ;lda fat32_nextcluster+3
  401 A:dad6                                    ;sta fat32_prevcluster+3

  403 A:dad6                                    ; Copy out the next cluster in the chain for later use
  404 A:dad6  b1 48                              lda (zp_sd_address),y
  405 A:dad8  85 5e                              sta fat32_nextcluster
  406 A:dada  c8                                 iny 
  407 A:dadb  b1 48                              lda (zp_sd_address),y
  408 A:dadd  85 5f                              sta fat32_nextcluster+1
  409 A:dadf  c8                                 iny 
  410 A:dae0  b1 48                              lda (zp_sd_address),y
  411 A:dae2  85 60                              sta fat32_nextcluster+2
  412 A:dae4  c8                                 iny 
  413 A:dae5  b1 48                              lda (zp_sd_address),y
  414 A:dae7  29 0f                              and #$0f
  415 A:dae9  85 61                              sta fat32_nextcluster+3

  417 A:daeb  7a                                 ply                    ; restore index to the table entry for the cluster

  419 A:daec                                    ; See if it's the end of the chain
  420 A:daec                                    ; Save raw value for EOC check
  421 A:daec                                    ;lda fat32_nextcluster+3
  422 A:daec  c9 0f                              cmp #$0f
  423 A:daee  90 18                              bcc notendofchain
  424 A:daf0  a5 60                              lda fat32_nextcluster+2
  425 A:daf2  c9 ff                              cmp #$ff
  426 A:daf4  d0 12                              bne notendofchain
  427 A:daf6  a5 5f                              lda fat32_nextcluster+1
  428 A:daf8  c9 ff                              cmp #$ff
  429 A:dafa  d0 0c                              bne notendofchain
  430 A:dafc  a5 5e                              lda fat32_nextcluster
  431 A:dafe  c9 f8                              cmp #$f8
  432 A:db00  90 06                              bcc notendofchain

  434 A:db02                                    ; It's EOC
  435 A:db02  a9 ff                              lda #$ff
  436 A:db04  85 61                              sta fat32_nextcluster+3
  437 A:db06  38                                 sec 
  438 A:db07  60                                 rts 
  439 A:db08                           notendofchain 
  439 A:db08                                    
  440 A:db08  18                                 clc 
  441 A:db09  60                                 rts 
  442 A:db0a                                     .) 

  445 A:db0a                           fat32_readnextsector 
  445 A:db0a                                    
  446 A:db0a                                     .( 
  447 A:db0a                                    ; Reads the next sector from a cluster chain into the buffer at fat32_address.
  448 A:db0a                                    ;
  449 A:db0a                                    ; Advances the current sector ready for the next read and looks up the next cluster
  450 A:db0a                                    ; in the chain when necessary.
  451 A:db0a                                    ;
  452 A:db0a                                    ; On return, carry is clear if data was read, or set if the cluster chain has ended.

  454 A:db0a                                    ; Maybe there are pending sectors in the current cluster
  455 A:db0a  a5 5b                              lda fat32_pendingsectors
  456 A:db0c  d0 1f                              bne readsector

  458 A:db0e                                    ; No pending sectors, check for end of cluster chain
  459 A:db0e  a5 61                              lda fat32_nextcluster+3
  460 A:db10  c9 0f                              cmp #$0f
  461 A:db12  d0 15                              bne not_eoc
  462 A:db14  a5 60                              lda fat32_nextcluster+2
  463 A:db16  c9 ff                              cmp #$ff
  464 A:db18  d0 0f                              bne not_eoc
  465 A:db1a  a5 5f                              lda fat32_nextcluster+1
  466 A:db1c  c9 ff                              cmp #$ff
  467 A:db1e  d0 09                              bne not_eoc
  468 A:db20  a5 5e                              lda fat32_nextcluster
  469 A:db22  c9 f8                              cmp #$f8             ; EOC starts at F8
  470 A:db24  90 03                              bcc not_eoc

  472 A:db26  4c 4a db                           jmp endofchain

  474 A:db29                           not_eoc   
  474 A:db29                                    

  476 A:db29                                    ; Prepare to read the next cluster
  477 A:db29  38                                 sec 
  478 A:db2a  20 19 da                           jsr fat32_seekcluster

  480 A:db2d                           readsector 
  480 A:db2d                                    
  481 A:db2d  c6 5b                              dec fat32_pendingsectors

  483 A:db2f                                    ; Set up target address  
  484 A:db2f  a5 5c                              lda fat32_address
  485 A:db31  85 48                              sta zp_sd_address
  486 A:db33  a5 5d                              lda fat32_address+1
  487 A:db35  85 49                              sta zp_sd_address+1

  489 A:db37                                    ; Read the sector
  490 A:db37  20 f6 d7                           jsr sd_readsector

  492 A:db3a                                    ; Advance to next sector
  493 A:db3a  e6 4a                              inc zp_sd_currentsector
  494 A:db3c  d0 0a                              bne sectorincrementdone
  495 A:db3e  e6 4b                              inc zp_sd_currentsector+1
  496 A:db40  d0 06                              bne sectorincrementdone
  497 A:db42  e6 4c                              inc zp_sd_currentsector+2
  498 A:db44  d0 02                              bne sectorincrementdone
  499 A:db46  e6 4d                              inc zp_sd_currentsector+3
  500 A:db48                           sectorincrementdone 
  500 A:db48                                    

  502 A:db48                                    ; Success - clear carry and return
  503 A:db48  18                                 clc 
  504 A:db49  60                                 rts 

  506 A:db4a                           endofchain 
  506 A:db4a                                    
  507 A:db4a                                    ; End of chain - set carry and return
  508 A:db4a  38                                 sec 
  509 A:db4b  60                                 rts 
  510 A:db4c                                     .) 

  512 A:db4c                           fat32_writenextsector 
  512 A:db4c                                    
  513 A:db4c                                     .( 
  514 A:db4c                                    ; Writes the next sector into the buffer at fat32_address.
  515 A:db4c                                    ;
  516 A:db4c                                    ; On return, carry is set if its the end of the chain. 

  518 A:db4c                                    ; Maybe there are pending sectors in the current cluster
  519 A:db4c  a5 5b                              lda fat32_pendingsectors
  520 A:db4e  d0 1f                              bne wr

  522 A:db50                                    ; No pending sectors, check for end of cluster chain
  523 A:db50  a5 61                              lda fat32_nextcluster+3
  524 A:db52  c9 0f                              cmp #$0f
  525 A:db54  d0 15                              bne not_eoc
  526 A:db56  a5 60                              lda fat32_nextcluster+2
  527 A:db58  c9 ff                              cmp #$ff
  528 A:db5a  d0 0f                              bne not_eoc
  529 A:db5c  a5 5f                              lda fat32_nextcluster+1
  530 A:db5e  c9 ff                              cmp #$ff
  531 A:db60  d0 09                              bne not_eoc
  532 A:db62  a5 5e                              lda fat32_nextcluster
  533 A:db64  c9 f8                              cmp #$f8             ; EOC starts at F8
  534 A:db66  90 03                              bcc not_eoc

  536 A:db68  4c 74 db                           jmp endofchain

  538 A:db6b                           not_eoc   
  538 A:db6b                                    

  540 A:db6b                                    ; Prepare to read the next cluster
  541 A:db6b  38                                 sec 
  542 A:db6c  20 19 da                           jsr fat32_seekcluster

  544 A:db6f                           wr        
  544 A:db6f                                    
  545 A:db6f  20 79 db                           jsr writesector

  547 A:db72                                    ; Success - clear carry and return
  548 A:db72  18                                 clc 
  549 A:db73  60                                 rts 

  551 A:db74                           endofchain 
  551 A:db74                                    
  552 A:db74                                    ; End of chain - set carry and return
  553 A:db74  20 79 db                           jsr writesector
  554 A:db77  38                                 sec 
  555 A:db78  60                                 rts 

  557 A:db79                           writesector 
  557 A:db79                                    
  558 A:db79  c6 5b                              dec fat32_pendingsectors

  560 A:db7b                                    ; Set up target address
  561 A:db7b  a5 5c                              lda fat32_address
  562 A:db7d  85 48                              sta zp_sd_address
  563 A:db7f  a5 5d                              lda fat32_address+1
  564 A:db81  85 49                              sta zp_sd_address+1

  566 A:db83                                    ; Write the sector
  567 A:db83  20 4c d8                           jsr sd_writesector

  569 A:db86                                    ; Advance to next sector
  570 A:db86  e6 4a                              inc zp_sd_currentsector
  571 A:db88  d0 0a                              bne nextsectorincrementdone
  572 A:db8a  e6 4b                              inc zp_sd_currentsector+1
  573 A:db8c  d0 06                              bne nextsectorincrementdone
  574 A:db8e  e6 4c                              inc zp_sd_currentsector+2
  575 A:db90  d0 02                              bne nextsectorincrementdone
  576 A:db92  e6 4d                              inc zp_sd_currentsector+3
  577 A:db94                           nextsectorincrementdone 
  577 A:db94                                    
  578 A:db94  60                                 rts 

  580 A:db95                                     .) 

  582 A:db95                           fat32_updatefat 
  582 A:db95                                    
  583 A:db95                                     .( 
  584 A:db95                                    ; Preserve the current sector
  585 A:db95  a5 4a                              lda zp_sd_currentsector
  586 A:db97  48                                 pha 
  587 A:db98  a5 4b                              lda zp_sd_currentsector+1
  588 A:db9a  48                                 pha 
  589 A:db9b  a5 4c                              lda zp_sd_currentsector+2
  590 A:db9d  48                                 pha 
  591 A:db9e  a5 4d                              lda zp_sd_currentsector+3
  592 A:dba0  48                                 pha 

  594 A:dba1                                    ; Write FAT sector
  595 A:dba1  ad 04 03                           lda fat32_lastsector
  596 A:dba4  85 4a                              sta zp_sd_currentsector
  597 A:dba6  ad 05 03                           lda fat32_lastsector+1
  598 A:dba9  85 4b                              sta zp_sd_currentsector+1
  599 A:dbab  ad 06 03                           lda fat32_lastsector+2
  600 A:dbae  85 4c                              sta zp_sd_currentsector+2
  601 A:dbb0  ad 07 03                           lda fat32_lastsector+3
  602 A:dbb3  85 4d                              sta zp_sd_currentsector+3

  604 A:dbb5                                    ; Target buffer
  605 A:dbb5  a9 00                              lda #<fat32_readbuffer
  606 A:dbb7  85 48                              sta zp_sd_address
  607 A:dbb9  a9 05                              lda #>fat32_readbuffer
  608 A:dbbb  85 49                              sta zp_sd_address+1

  610 A:dbbd                                    ; Write the FAT sector
  611 A:dbbd  20 4c d8                           jsr sd_writesector

  613 A:dbc0                                    ; Check if FAT mirroring is enabled
  614 A:dbc0  ad 08 03                           lda fat32_numfats
  615 A:dbc3  c9 02                              cmp #2
  616 A:dbc5  d0 23                              bne onefat

  618 A:dbc7                                    ; Add the last sector to the amount of sectors per FAT
  619 A:dbc7                                    ; (to get the second fat location)
  620 A:dbc7  ad 04 03                           lda fat32_lastsector
  621 A:dbca  6d 0d 03                           adc fat32_sectorsperfat
  622 A:dbcd  85 4a                              sta zp_sd_currentsector
  623 A:dbcf  ad 05 03                           lda fat32_lastsector+1
  624 A:dbd2  6d 0e 03                           adc fat32_sectorsperfat+1
  625 A:dbd5  85 4b                              sta zp_sd_currentsector+1
  626 A:dbd7  ad 06 03                           lda fat32_lastsector+2
  627 A:dbda  6d 0f 03                           adc fat32_sectorsperfat+2
  628 A:dbdd  85 4c                              sta zp_sd_currentsector+2
  629 A:dbdf  ad 07 03                           lda fat32_lastsector+3
  630 A:dbe2  6d 10 03                           adc fat32_sectorsperfat+3
  631 A:dbe5  85 4d                              sta zp_sd_currentsector+3

  633 A:dbe7                                    ; Write the FAT sector
  634 A:dbe7  20 4c d8                           jsr sd_writesector

  636 A:dbea                           onefat    
  636 A:dbea                                    
  637 A:dbea                                    ; Pull back the current sector
  638 A:dbea  68                                 pla 
  639 A:dbeb  85 4d                              sta zp_sd_currentsector+3
  640 A:dbed  68                                 pla 
  641 A:dbee  85 4c                              sta zp_sd_currentsector+2
  642 A:dbf0  68                                 pla 
  643 A:dbf1  85 4b                              sta zp_sd_currentsector+1
  644 A:dbf3  68                                 pla 
  645 A:dbf4  85 4a                              sta zp_sd_currentsector

  647 A:dbf6  60                                 rts 
  648 A:dbf7                                     .) 

  651 A:dbf7                           fat32_openroot 
  651 A:dbf7                                    
  652 A:dbf7                                     .( 
  653 A:dbf7                                    ; Prepare to read the root directory

  655 A:dbf7  a5 56                              lda fat32_rootcluster
  656 A:dbf9  85 5e                              sta fat32_nextcluster
  657 A:dbfb  8d 11 03                           sta fat32_cdcluster
  658 A:dbfe  a5 57                              lda fat32_rootcluster+1
  659 A:dc00  85 5f                              sta fat32_nextcluster+1
  660 A:dc02  8d 12 03                           sta fat32_cdcluster+1
  661 A:dc05  a5 58                              lda fat32_rootcluster+2
  662 A:dc07  85 60                              sta fat32_nextcluster+2
  663 A:dc09  8d 13 03                           sta fat32_cdcluster+2
  664 A:dc0c  a5 59                              lda fat32_rootcluster+3
  665 A:dc0e  85 61                              sta fat32_nextcluster+3
  666 A:dc10  8d 14 03                           sta fat32_cdcluster+3

  668 A:dc13  18                                 clc 
  669 A:dc14  20 19 da                           jsr fat32_seekcluster

  671 A:dc17                                    ; Set the pointer to a large value so we always read a sector the first time through
  672 A:dc17  a9 ff                              lda #$ff
  673 A:dc19  85 49                              sta zp_sd_address+1

  675 A:dc1b  60                                 rts 
  676 A:dc1c                                     .) 

  678 A:dc1c                           fat32_allocatecluster 
  678 A:dc1c                                    
  679 A:dc1c                                     .( 
  680 A:dc1c                                    ; Allocate the first cluster to store a file at.

  682 A:dc1c                                    ; Find a free cluster
  683 A:dc1c  20 0e dd                           jsr fat32_findnextfreecluster

  685 A:dc1f                                    ; Cache the value so we can add the address of the next one later, if any
  686 A:dc1f  a5 66                              lda fat32_lastfoundfreecluster
  687 A:dc21  8d 00 03                           sta fat32_lastcluster
  688 A:dc24  8d 09 03                           sta fat32_filecluster
  689 A:dc27  a5 67                              lda fat32_lastfoundfreecluster+1
  690 A:dc29  8d 01 03                           sta fat32_lastcluster+1
  691 A:dc2c  8d 0a 03                           sta fat32_filecluster+1
  692 A:dc2f  a5 68                              lda fat32_lastfoundfreecluster+2
  693 A:dc31  8d 02 03                           sta fat32_lastcluster+2
  694 A:dc34  8d 0b 03                           sta fat32_filecluster+2
  695 A:dc37  a5 69                              lda fat32_lastfoundfreecluster+3
  696 A:dc39  8d 03 03                           sta fat32_lastcluster+3
  697 A:dc3c  8d 0c 03                           sta fat32_filecluster+3

  699 A:dc3f                                    ; Add marker for the following routines, so we don't think this is free.
  700 A:dc3f  a9 0f                              lda #$0f
  701 A:dc41  91 48                              sta (zp_sd_address),y

  703 A:dc43  60                                 rts 
  704 A:dc44                                     .) 

  706 A:dc44                           fat32_allocatefile 
  706 A:dc44                                    
  707 A:dc44                                     .( 
  708 A:dc44                                    ; Allocate an entire file in the FAT, with the
  709 A:dc44                                    ; file's size in fat32_bytesremaining

  711 A:dc44                                    ; We will read a new sector the first time around
  712 A:dc44  9c 04 03                           stz fat32_lastsector
  713 A:dc47  9c 05 03                           stz fat32_lastsector+1
  714 A:dc4a  9c 06 03                           stz fat32_lastsector+2
  715 A:dc4d  9c 07 03                           stz fat32_lastsector+3

  717 A:dc50                                    ; BUG if we have a FAT enty at the end of a sector, it may be ignored! 

  719 A:dc50                                    ; Allocate the first cluster.
  720 A:dc50  20 1c dc                           jsr fat32_allocatecluster

  722 A:dc53                                    ; We don't properly support 64k+ files, as it's unnecessary complication given
  723 A:dc53                                    ; the 6502's small address space. So we'll just empty out the top two bytes.
  724 A:dc53  a9 00                              lda #0
  725 A:dc55  85 64                              sta fat32_bytesremaining+2
  726 A:dc57  85 65                              sta fat32_bytesremaining+3

  728 A:dc59                                    ; Stash filesize, as we will be clobbering it here
  729 A:dc59  a5 62                              lda fat32_bytesremaining
  730 A:dc5b  48                                 pha 
  731 A:dc5c  a5 63                              lda fat32_bytesremaining+1
  732 A:dc5e  48                                 pha 

  734 A:dc5f                                    ; Round the size up to the next whole sector
  735 A:dc5f  a5 62                              lda fat32_bytesremaining
  736 A:dc61  c9 01                              cmp #1             ; set carry if bottom 8 bits not zero
  737 A:dc63  a5 63                              lda fat32_bytesremaining+1
  738 A:dc65  69 00                              adc #0             ; add carry, if any
  739 A:dc67  4a                                 lsr                    ; divide by 2
  740 A:dc68  69 00                              adc #0             ; round up

  742 A:dc6a                                    ; No data?
  743 A:dc6a  d0 03                              bne nofail
  744 A:dc6c  4c 07 dd                           jmp fail

  746 A:dc6f                           nofail    
  746 A:dc6f                                    
  747 A:dc6f                                    ; This will be clustersremaining now.
  748 A:dc6f  85 62                              sta fat32_bytesremaining

  750 A:dc71                                    ; Divide by sectors per cluster (power of 2)
  751 A:dc71  a5 5a                              lda fat32_sectorspercluster
  752 A:dc73                           cloop     
  753 A:dc73  c9 01                              cmp #1
  754 A:dc75  f0 08                              beq one
  755 A:dc77  4a                                 lsr 
  756 A:dc78  46 63                              lsr fat32_bytesremaining+1          ; high byte
  757 A:dc7a  66 62                              ror fat32_bytesremaining                ; low byte, with carry from high

  759 A:dc7c  4c 73 dc                           jmp cloop

  761 A:dc7f                           one       

  763 A:dc7f                                    ; We will be making a new cluster every time
  764 A:dc7f  64 5b                              stz fat32_pendingsectors

  766 A:dc81                                    ; Find free clusters and allocate them for use for this file.
  767 A:dc81                           allocatelp 
  768 A:dc81                                    ; Check if it's the last cluster in the chain 
  769 A:dc81  a5 62                              lda fat32_bytesremaining
  770 A:dc83  f0 04                              beq lastcluster
  771 A:dc85  c9 01                              cmp #1             ; CHECK! is 1 the right amound for this?
  772 A:dc87  90 2f                              bcc notlastcluster                ; clustersremaining <=1?

  774 A:dc89                                    ; It is the last one.

  776 A:dc89                           lastcluster 

  778 A:dc89                                    ; go back the previous one
  779 A:dc89  ad 00 03                           lda fat32_lastcluster
  780 A:dc8c  85 5e                              sta fat32_nextcluster
  781 A:dc8e  ad 01 03                           lda fat32_lastcluster+1
  782 A:dc91  85 5f                              sta fat32_nextcluster+1
  783 A:dc93  ad 02 03                           lda fat32_lastcluster+2
  784 A:dc96  85 60                              sta fat32_nextcluster+2
  785 A:dc98  ad 03 03                           lda fat32_lastcluster+3
  786 A:dc9b  85 61                              sta fat32_nextcluster+3

  788 A:dc9d  38                                 sec 
  789 A:dc9e  20 19 da                           jsr fat32_seekcluster

  791 A:dca1                                    ; Write 0x0FFFFFFE (EOC)
  792 A:dca1  a9 0f                              lda #$0f
  793 A:dca3  91 48                              sta (zp_sd_address),y
  794 A:dca5  88                                 dey 
  795 A:dca6  a9 ff                              lda #$ff
  796 A:dca8  91 48                              sta (zp_sd_address),y
  797 A:dcaa  88                                 dey 
  798 A:dcab  91 48                              sta (zp_sd_address),y
  799 A:dcad  88                                 dey 
  800 A:dcae  a9 fe                              lda #$fe
  801 A:dcb0  91 48                              sta (zp_sd_address),y

  803 A:dcb2                                    ; Update the FAT
  804 A:dcb2  20 95 db                           jsr fat32_updatefat

  806 A:dcb5                                    ; End of chain - exit
  807 A:dcb5  4c 07 dd                           jmp fail

  809 A:dcb8                           notlastcluster 
  810 A:dcb8                                    ; Wait! Is there exactly 1 cluster left?
  811 A:dcb8  f0 cf                              beq lastcluster

  813 A:dcba                                    ; Find the next cluster
  814 A:dcba  20 0e dd                           jsr fat32_findnextfreecluster

  816 A:dcbd                                    ; Add marker so we don't think this is free.
  817 A:dcbd  a9 0f                              lda #$0f
  818 A:dcbf  91 48                              sta (zp_sd_address),y

  820 A:dcc1                                    ; Seek to the previous cluster
  821 A:dcc1  ad 00 03                           lda fat32_lastcluster
  822 A:dcc4  85 5e                              sta fat32_nextcluster
  823 A:dcc6  ad 01 03                           lda fat32_lastcluster+1
  824 A:dcc9  85 5f                              sta fat32_nextcluster+1
  825 A:dccb  ad 02 03                           lda fat32_lastcluster+2
  826 A:dcce  85 60                              sta fat32_nextcluster+2
  827 A:dcd0  ad 03 03                           lda fat32_lastcluster+3
  828 A:dcd3  85 61                              sta fat32_nextcluster+3

  830 A:dcd5  38                                 sec 
  831 A:dcd6  20 19 da                           jsr fat32_seekcluster

  833 A:dcd9  5a                                 phy 
  834 A:dcda                                    ; Enter the address of the next one into the FAT
  835 A:dcda  a5 69                              lda fat32_lastfoundfreecluster+3
  836 A:dcdc  8d 03 03                           sta fat32_lastcluster+3
  837 A:dcdf  91 48                              sta (zp_sd_address),y
  838 A:dce1  88                                 dey 
  839 A:dce2  a5 68                              lda fat32_lastfoundfreecluster+2
  840 A:dce4  8d 02 03                           sta fat32_lastcluster+2
  841 A:dce7  91 48                              sta (zp_sd_address),y
  842 A:dce9  88                                 dey 
  843 A:dcea  a5 67                              lda fat32_lastfoundfreecluster+1
  844 A:dcec  8d 01 03                           sta fat32_lastcluster+1
  845 A:dcef  91 48                              sta (zp_sd_address),y
  846 A:dcf1  88                                 dey 
  847 A:dcf2  a5 66                              lda fat32_lastfoundfreecluster
  848 A:dcf4  8d 00 03                           sta fat32_lastcluster
  849 A:dcf7  91 48                              sta (zp_sd_address),y
  850 A:dcf9  7a                                 ply 

  852 A:dcfa                                    ; Update the FAT
  853 A:dcfa  20 95 db                           jsr fat32_updatefat

  855 A:dcfd  a6 62                              ldx fat32_bytesremaining                ; note - actually loads clusters remaining
  856 A:dcff  ca                                 dex 
  857 A:dd00  86 62                              stx fat32_bytesremaining                ; note - actually stores clusters remaining

  859 A:dd02  f0 03                              beq fail
  860 A:dd04  4c 81 dc                           jmp allocatelp

  862 A:dd07                                    ; Done!
  863 A:dd07                           fail      
  864 A:dd07                                    ; Pull the filesize back from the stack
  865 A:dd07  68                                 pla 
  866 A:dd08  85 63                              sta fat32_bytesremaining+1
  867 A:dd0a  68                                 pla 
  868 A:dd0b  85 62                              sta fat32_bytesremaining
  869 A:dd0d  60                                 rts 

  871 A:dd0e                                     .) 

  873 A:dd0e                           fat32_findnextfreecluster 
  873 A:dd0e                                    
  874 A:dd0e                                     .( 
  875 A:dd0e                                    ; Find next free cluster
  876 A:dd0e                                    ; 
  877 A:dd0e                                    ; This program will search the FAT for an empty entry, and
  878 A:dd0e                                    ; save the 32-bit cluster number at fat32_lastfoundfreecluster.
  879 A:dd0e                                    ;
  880 A:dd0e                                    ; Also sets the carry bit if the SD card is full.
  881 A:dd0e                                    ;

  883 A:dd0e                                    ; Find a free cluster and store it's location in fat32_lastfoundfreecluster
  884 A:dd0e                                    ; skip reserved clusters
  885 A:dd0e  a9 02                              lda #2
  886 A:dd10  85 5e                              sta fat32_nextcluster
  887 A:dd12  85 66                              sta fat32_lastfoundfreecluster
  888 A:dd14  a9 00                              lda #0
  889 A:dd16  85 5f                              sta fat32_nextcluster+1
  890 A:dd18  85 67                              sta fat32_lastfoundfreecluster+1
  891 A:dd1a  85 60                              sta fat32_nextcluster+2
  892 A:dd1c  85 68                              sta fat32_lastfoundfreecluster+2
  893 A:dd1e  85 61                              sta fat32_nextcluster+3
  894 A:dd20  85 69                              sta fat32_lastfoundfreecluster+3

  896 A:dd22                           searchclusters 

  898 A:dd22                                    ; Seek cluster
  899 A:dd22  38                                 sec 
  900 A:dd23  20 19 da                           jsr fat32_seekcluster

  902 A:dd26                                    ; Is the cluster free?
  903 A:dd26  a5 5e                              lda fat32_nextcluster
  904 A:dd28  05 5f                              ora fat32_nextcluster+1
  905 A:dd2a  05 60                              ora fat32_nextcluster+2
  906 A:dd2c  05 61                              ora fat32_nextcluster+3
  907 A:dd2e  f0 29                              beq foundcluster

  909 A:dd30                                    ; No, increment the cluster count
  910 A:dd30  e6 66                              inc fat32_lastfoundfreecluster
  911 A:dd32  d0 10                              bne copycluster
  912 A:dd34  e6 67                              inc fat32_lastfoundfreecluster+1
  913 A:dd36  d0 0c                              bne copycluster
  914 A:dd38  e6 68                              inc fat32_lastfoundfreecluster+2
  915 A:dd3a  d0 08                              bne copycluster
  916 A:dd3c  e6 69                              inc fat32_lastfoundfreecluster+3

  918 A:dd3e  a5 66                              lda fat32_lastfoundfreecluster
  919 A:dd40  c9 10                              cmp #$10
  920 A:dd42  b0 17                              bcs sd_full

  922 A:dd44                           copycluster 

  924 A:dd44                                    ; Copy the cluster count to the next cluster
  925 A:dd44  a5 66                              lda fat32_lastfoundfreecluster
  926 A:dd46  85 5e                              sta fat32_nextcluster
  927 A:dd48  a5 67                              lda fat32_lastfoundfreecluster+1
  928 A:dd4a  85 5f                              sta fat32_nextcluster+1
  929 A:dd4c  a5 68                              lda fat32_lastfoundfreecluster+2
  930 A:dd4e  85 60                              sta fat32_nextcluster+2
  931 A:dd50  a5 69                              lda fat32_lastfoundfreecluster+3
  932 A:dd52  29 0f                              and #$0f
  933 A:dd54  85 61                              sta fat32_nextcluster+3

  935 A:dd56                                    ; Go again for another pass
  936 A:dd56  4c 22 dd                           jmp searchclusters

  938 A:dd59                           foundcluster 
  939 A:dd59                                    ; done.
  940 A:dd59  18                                 clc 
  941 A:dd5a  60                                 rts 

  943 A:dd5b                           sd_full   
  944 A:dd5b  38                                 sec 
  945 A:dd5c  60                                 rts 
  946 A:dd5d                                     .) 

  948 A:dd5d                           fat32_opendirent 
  948 A:dd5d                                    
  949 A:dd5d                                     .( 
  950 A:dd5d                                    ; Prepare to read/write a file or directory based on a dirent
  951 A:dd5d                                    ;
  952 A:dd5d                                    ; Point zp_sd_address at the dirent

  954 A:dd5d                                    ; Remember file size in bytes remaining
  955 A:dd5d  a0 1c                              ldy #28
  956 A:dd5f  b1 48                              lda (zp_sd_address),y
  957 A:dd61  85 62                              sta fat32_bytesremaining
  958 A:dd63  c8                                 iny 
  959 A:dd64  b1 48                              lda (zp_sd_address),y
  960 A:dd66  85 63                              sta fat32_bytesremaining+1
  961 A:dd68  c8                                 iny 
  962 A:dd69  b1 48                              lda (zp_sd_address),y
  963 A:dd6b  85 64                              sta fat32_bytesremaining+2
  964 A:dd6d  c8                                 iny 
  965 A:dd6e  b1 48                              lda (zp_sd_address),y
  966 A:dd70  85 65                              sta fat32_bytesremaining+3

  968 A:dd72                                    ; Seek to first cluster
  969 A:dd72  a0 1a                              ldy #26
  970 A:dd74  b1 48                              lda (zp_sd_address),y
  971 A:dd76  85 5e                              sta fat32_nextcluster
  972 A:dd78  c8                                 iny 
  973 A:dd79  b1 48                              lda (zp_sd_address),y
  974 A:dd7b  85 5f                              sta fat32_nextcluster+1
  975 A:dd7d  a0 14                              ldy #20
  976 A:dd7f  b1 48                              lda (zp_sd_address),y
  977 A:dd81  85 60                              sta fat32_nextcluster+2
  978 A:dd83  c8                                 iny 
  979 A:dd84  b1 48                              lda (zp_sd_address),y
  980 A:dd86  85 61                              sta fat32_nextcluster+3

  982 A:dd88  18                                 clc 
  983 A:dd89  a0 0b                              ldy #$0b
  984 A:dd8b  b1 48                              lda (zp_sd_address),Y
  985 A:dd8d  29 10                              and #$10             ; is it a directory?
  986 A:dd8f  f0 14                              beq fatskip_cd_cache

  988 A:dd91                                    ; If it's a directory, cache the cluster
  989 A:dd91  a5 5e                              lda fat32_nextcluster
  990 A:dd93  8d 11 03                           sta fat32_cdcluster
  991 A:dd96  a5 5f                              lda fat32_nextcluster+1
  992 A:dd98  8d 12 03                           sta fat32_cdcluster+1
  993 A:dd9b  a5 60                              lda fat32_nextcluster+2
  994 A:dd9d  8d 13 03                           sta fat32_cdcluster+2
  995 A:dda0  a5 61                              lda fat32_nextcluster+3
  996 A:dda2  8d 14 03                           sta fat32_cdcluster+3

  998 A:dda5                           fatskip_cd_cache 
  998 A:dda5                                    

 1000 A:dda5                                    ; if we're opening a directory entry with 0 cluster, use the root cluster
 1001 A:dda5  a5 61                              lda fat32_nextcluster+3
 1002 A:dda7  d0 13                              bne fseek
 1003 A:dda9  a5 60                              lda fat32_nextcluster+2
 1004 A:ddab  d0 0f                              bne fseek
 1005 A:ddad  a5 5f                              lda fat32_nextcluster+1
 1006 A:ddaf  d0 0b                              bne fseek
 1007 A:ddb1  a5 5e                              lda fat32_nextcluster
 1008 A:ddb3  d0 07                              bne fseek
 1009 A:ddb5  a5 56                              lda fat32_rootcluster
 1010 A:ddb7  85 5e                              sta fat32_nextcluster
 1011 A:ddb9  8d 11 03                           sta fat32_cdcluster

 1013 A:ddbc                           fseek     
 1013 A:ddbc                                    
 1014 A:ddbc  18                                 clc 
 1015 A:ddbd  20 19 da                           jsr fat32_seekcluster

 1017 A:ddc0                                    ; Set the pointer to a large value so we always read a sector the first time through
 1018 A:ddc0  a9 ff                              lda #$ff
 1019 A:ddc2  85 49                              sta zp_sd_address+1

 1021 A:ddc4  60                                 rts 
 1022 A:ddc5                                     .) 

 1024 A:ddc5                           fat32_writedirent 
 1024 A:ddc5                                    
 1025 A:ddc5                                     .( 
 1026 A:ddc5                                    ; Write a directory entry from the open directory
 1027 A:ddc5                                    ; requires
 1027 A:ddc5                                    
 1028 A:ddc5                                    ;   fat32bytesremaining (2 bytes) = file size in bytes (little endian)

 1030 A:ddc5                                    ; Increment pointer by 32 to point to next entry
 1031 A:ddc5  18                                 clc 
 1032 A:ddc6  a5 48                              lda zp_sd_address
 1033 A:ddc8  69 20                              adc #32
 1034 A:ddca  85 48                              sta zp_sd_address
 1035 A:ddcc  a5 49                              lda zp_sd_address+1
 1036 A:ddce  69 00                              adc #0
 1037 A:ddd0  85 49                              sta zp_sd_address+1

 1039 A:ddd2                                    ; If it's not at the end of the buffer, we have data already
 1040 A:ddd2  c9 07                              cmp #>(fat32_readbuffer+$0200)
 1041 A:ddd4  90 0f                              bcc gotdirrent

 1043 A:ddd6                                    ; Read another sector
 1044 A:ddd6  a9 00                              lda #<fat32_readbuffer
 1045 A:ddd8  85 5c                              sta fat32_address
 1046 A:ddda  a9 05                              lda #>fat32_readbuffer
 1047 A:dddc  85 5d                              sta fat32_address+1

 1049 A:ddde  20 0a db                           jsr fat32_readnextsector
 1050 A:dde1  90 02                              bcc gotdirrent

 1052 A:dde3                           endofdirectorywrite 
 1052 A:dde3                                    
 1053 A:dde3  38                                 sec 
 1054 A:dde4  60                                 rts 

 1056 A:dde5                           gotdirrent 
 1056 A:dde5                                    
 1057 A:dde5                                    ; Check first character
 1058 A:dde5  18                                 clc 
 1059 A:dde6  a0 00                              ldy #0
 1060 A:dde8  b1 48                              lda (zp_sd_address),y
 1061 A:ddea  d0 d9                              bne fat32_writedirent                ; go again
 1062 A:ddec                                    ; End of directory. Now make a new entry.
 1063 A:ddec                           dloop     
 1063 A:ddec                                    
 1064 A:ddec  b1 6a                              lda (fat32_filenamepointer),y            ; copy filename
 1065 A:ddee  91 48                              sta (zp_sd_address),y
 1066 A:ddf0  c8                                 iny 
 1067 A:ddf1  c0 0b                              cpy #$0b
 1068 A:ddf3  d0 f7                              bne dloop
 1069 A:ddf5                                    ; The full Short filename is #11 bytes long so,
 1070 A:ddf5                                    ; this start at 0x0b - File type
 1071 A:ddf5                                    ; BUG assumes that we are making a file, not a folder...
 1072 A:ddf5  a9 20                              lda #$20             ; File Type
 1072 A:ddf7                           ARCHIVE   
 1073 A:ddf7  91 48                              sta (zp_sd_address),y
 1074 A:ddf9  c8                                 iny                    ; 0x0c - Checksum/File accsess password
 1075 A:ddfa  a9 10                              lda #$10             ; No checksum or password
 1076 A:ddfc  91 48                              sta (zp_sd_address),y
 1077 A:ddfe  c8                                 iny                    ; 0x0d - first char of deleted file - 0x7d for nothing
 1078 A:ddff  a9 7d                              lda #$7d
 1079 A:de01  91 48                              sta (zp_sd_address),y
 1080 A:de03  c8                                 iny                    ; 0x0e-0x11 - File creation time/date
 1081 A:de04  a9 00                              lda #0
 1082 A:de06                           empty     
 1083 A:de06  91 48                              sta (zp_sd_address),y            ; No time/date because I don't have an RTC
 1084 A:de08  c8                                 iny 
 1085 A:de09  c0 14                              cpy #$14             ; also empty the user ID (0x12-0x13)
 1086 A:de0b  d0 f9                              bne empty
 1087 A:de0d                                    ;sta (zp_sd_address),y
 1088 A:de0d                                    ;iny
 1089 A:de0d                                    ;sta (zp_sd_address),y
 1090 A:de0d                                    ;iny
 1091 A:de0d                                    ;sta (zp_sd_address),y
 1092 A:de0d                                    ; if you have an RTC, refer to https
 1092 A:de0d                                    
 1093 A:de0d                                    ; show the "Directory entry" table and look at at 0x0E onward.
 1094 A:de0d                                    ;iny   ; 0x12-0x13 - User ID
 1095 A:de0d                                    ;lda #0
 1096 A:de0d                                    ;sta (zp_sd_address),y ; No ID
 1097 A:de0d                                    ;iny
 1098 A:de0d                                    ;sta (zp_sd_address),y
 1099 A:de0d                                    ;iny 
 1100 A:de0d                                    ; 0x14-0x15 - File start cluster (high word)
 1101 A:de0d  ad 0b 03                           lda fat32_filecluster+2
 1102 A:de10  91 48                              sta (zp_sd_address),y
 1103 A:de12  c8                                 iny 
 1104 A:de13  ad 0c 03                           lda fat32_filecluster+3
 1105 A:de16  91 48                              sta (zp_sd_address),y
 1106 A:de18  c8                                 iny                    ; 0x16-0x19 - File modifiaction date
 1107 A:de19  a9 00                              lda #0
 1108 A:de1b  91 48                              sta (zp_sd_address),y
 1109 A:de1d  c8                                 iny 
 1110 A:de1e  91 48                              sta (zp_sd_address),y            ; no rtc
 1111 A:de20  c8                                 iny 
 1112 A:de21  91 48                              sta (zp_sd_address),y
 1113 A:de23  c8                                 iny 
 1114 A:de24  91 48                              sta (zp_sd_address),y
 1115 A:de26  c8                                 iny                    ; 0x1a-0x1b - File start cluster (low word)
 1116 A:de27  ad 09 03                           lda fat32_filecluster
 1117 A:de2a  91 48                              sta (zp_sd_address),y
 1118 A:de2c  c8                                 iny 
 1119 A:de2d  ad 0a 03                           lda fat32_filecluster+1
 1120 A:de30  91 48                              sta (zp_sd_address),y
 1121 A:de32  c8                                 iny                    ; 0x1c-0x1f File size in bytes
 1122 A:de33  a5 62                              lda fat32_bytesremaining
 1123 A:de35  91 48                              sta (zp_sd_address),y
 1124 A:de37  c8                                 iny 
 1125 A:de38  a5 63                              lda fat32_bytesremaining+1
 1126 A:de3a  91 48                              sta (zp_sd_address),y
 1127 A:de3c  c8                                 iny 
 1128 A:de3d  a9 00                              lda #0
 1129 A:de3f  91 48                              sta (zp_sd_address),y            ; No bigger that 64k
 1130 A:de41  c8                                 iny 
 1131 A:de42  91 48                              sta (zp_sd_address),y
 1132 A:de44  c8                                 iny 
 1133 A:de45                                    ; are we over the buffer?
 1134 A:de45  a5 49                              lda zp_sd_address+1
 1135 A:de47  c9 07                              cmp #>(fat32_readbuffer+$0200)
 1136 A:de49  90 12                              bcc notoverbuffer
 1137 A:de4b  20 84 de                           jsr fat32_wrcurrent                ; if so, write the current sector
 1138 A:de4e  20 0a db                           jsr fat32_readnextsector                ; then read the next one.
 1139 A:de51  b0 2f                              bcs dfail
 1140 A:de53  a0 00                              ldy #0
 1141 A:de55  a9 00                              lda #<fat32_readbuffer
 1142 A:de57  85 48                              sta zp_sd_address
 1143 A:de59  a9 05                              lda #>fat32_readbuffer
 1144 A:de5b  85 49                              sta zp_sd_address+1
 1145 A:de5d                           notoverbuffer 
 1146 A:de5d                                    ; next entry is 0 (end of dir)
 1147 A:de5d  a9 00                              lda #0
 1148 A:de5f  91 48                              sta (zp_sd_address),y
 1149 A:de61                                    ; write all the data...
 1150 A:de61  20 84 de                           jsr fat32_wrcurrent

 1152 A:de64                                    ; Great, lets get this ready for other code to use.

 1154 A:de64                                    ; Seek to first cluster
 1155 A:de64  ad 09 03                           lda fat32_filecluster
 1156 A:de67  85 5e                              sta fat32_nextcluster
 1157 A:de69  ad 0a 03                           lda fat32_filecluster+1
 1158 A:de6c  85 5f                              sta fat32_nextcluster+1
 1159 A:de6e  ad 0b 03                           lda fat32_filecluster+2
 1160 A:de71  85 60                              sta fat32_nextcluster+2
 1161 A:de73  ad 0c 03                           lda fat32_filecluster+3
 1162 A:de76  85 61                              sta fat32_nextcluster+3

 1164 A:de78  18                                 clc 
 1165 A:de79  20 19 da                           jsr fat32_seekcluster

 1167 A:de7c                                    ; Set the pointer to a large value so we always read a sector the first time through
 1168 A:de7c  a9 ff                              lda #$ff
 1169 A:de7e  85 49                              sta zp_sd_address+1

 1171 A:de80  18                                 clc 
 1172 A:de81  60                                 rts 

 1174 A:de82                           dfail     
 1174 A:de82                                    
 1175 A:de82                                    ; Card Full
 1176 A:de82  38                                 sec 
 1177 A:de83  60                                 rts 
 1178 A:de84                                     .) 

 1180 A:de84                           fat32_wrcurrent 
 1180 A:de84                                    
 1181 A:de84                                     .( 
 1182 A:de84                                    ; decrement the sector so we write the current one (not the next one)
 1183 A:de84  a5 4a                              lda zp_sd_currentsector
 1184 A:de86  d0 0a                              bne skip
 1185 A:de88  c6 4b                              dec zp_sd_currentsector+1
 1186 A:de8a  d0 06                              bne skip
 1187 A:de8c  c6 4c                              dec zp_sd_currentsector+2
 1188 A:de8e  d0 02                              bne skip
 1189 A:de90  c6 4d                              dec zp_sd_currentsector+3

 1191 A:de92                           skip      
 1192 A:de92  c6 4a                              dec zp_sd_currentsector

 1194 A:de94                           nodec     

 1196 A:de94  a5 5c                              lda fat32_address
 1197 A:de96  85 48                              sta zp_sd_address
 1198 A:de98  a5 5d                              lda fat32_address+1
 1199 A:de9a  85 49                              sta zp_sd_address+1

 1201 A:de9c                                    ; Read the sector
 1202 A:de9c  20 4c d8                           jsr sd_writesector

 1204 A:de9f                                    ; Advance to next sector
 1205 A:de9f  e6 4a                              inc zp_sd_currentsector
 1206 A:dea1  d0 0a                              bne sectorincrementdone
 1207 A:dea3  e6 4b                              inc zp_sd_currentsector+1
 1208 A:dea5  d0 06                              bne sectorincrementdone
 1209 A:dea7  e6 4c                              inc zp_sd_currentsector+2
 1210 A:dea9  d0 02                              bne sectorincrementdone
 1211 A:deab  e6 4d                              inc zp_sd_currentsector+3

 1213 A:dead                           sectorincrementdone 
 1214 A:dead  60                                 rts 
 1215 A:deae                                     .) 

 1217 A:deae                           fat32_readdirent 
 1217 A:deae                                    
 1218 A:deae                                     .( 
 1219 A:deae                                    ; Read a directory entry from the open directory
 1220 A:deae                                    ;
 1221 A:deae                                    ; On exit the carry is set if there were no more directory entries.
 1222 A:deae                                    ;
 1223 A:deae                                    ; Otherwise, A is set to the file's attribute byte and
 1224 A:deae                                    ; zp_sd_address points at the returned directory entry.
 1225 A:deae                                    ; LFNs and empty entries are ignored automatically.

 1227 A:deae                                    ; Increment pointer by 32 to point to next entry
 1228 A:deae  18                                 clc 
 1229 A:deaf  a5 48                              lda zp_sd_address
 1230 A:deb1  69 20                              adc #32
 1231 A:deb3  85 48                              sta zp_sd_address
 1232 A:deb5  a5 49                              lda zp_sd_address+1
 1233 A:deb7  69 00                              adc #0
 1234 A:deb9  85 49                              sta zp_sd_address+1

 1236 A:debb                                    ; If it's not at the end of the buffer, we have data already
 1237 A:debb  c9 07                              cmp #>(fat32_readbuffer+$0200)
 1238 A:debd  90 0f                              bcc gotdata

 1240 A:debf                                    ; Read another sector
 1241 A:debf  a9 00                              lda #<fat32_readbuffer
 1242 A:dec1  85 5c                              sta fat32_address
 1243 A:dec3  a9 05                              lda #>fat32_readbuffer
 1244 A:dec5  85 5d                              sta fat32_address+1

 1246 A:dec7  20 0a db                           jsr fat32_readnextsector
 1247 A:deca  90 02                              bcc gotdata

 1249 A:decc                           endofdirectory 
 1249 A:decc                                    
 1250 A:decc  38                                 sec 
 1251 A:decd  60                                 rts 

 1253 A:dece                           gotdata   
 1253 A:dece                                    
 1254 A:dece                                    ; Check first character
 1255 A:dece  a0 00                              ldy #0
 1256 A:ded0  b1 48                              lda (zp_sd_address),y

 1258 A:ded2                                    ; End of directory => abort
 1259 A:ded2  f0 f8                              beq endofdirectory

 1261 A:ded4                                    ; Empty entry => start again
 1262 A:ded4  c9 e5                              cmp #$e5
 1263 A:ded6  f0 d6                              beq fat32_readdirent

 1265 A:ded8                                    ; Check attributes
 1266 A:ded8  a0 0b                              ldy #11
 1267 A:deda  b1 48                              lda (zp_sd_address),y
 1268 A:dedc  29 3f                              and #$3f
 1269 A:dede  c9 0f                              cmp #$0f             ; LFN => start again
 1270 A:dee0  f0 cc                              beq fat32_readdirent

 1272 A:dee2                                    ; Yield this result
 1273 A:dee2  18                                 clc 
 1274 A:dee3  60                                 rts 
 1275 A:dee4                                     .) 

 1277 A:dee4                           fat32_finddirent 
 1277 A:dee4                                    
 1278 A:dee4                                     .( 
 1279 A:dee4                                    ; Finds a particular directory entry. X,Y point to the 11-character filename to seek.
 1280 A:dee4                                    ; The directory should already be open for iteration.

 1282 A:dee4                                    ; Form ZP pointer to user's filename
 1283 A:dee4  86 6a                              stx fat32_filenamepointer
 1284 A:dee6  84 6b                              sty fat32_filenamepointer+1

 1286 A:dee8                                    ; Iterate until name is found or end of directory
 1287 A:dee8                           direntloop 
 1287 A:dee8                                    
 1288 A:dee8  20 ae de                           jsr fat32_readdirent
 1289 A:deeb  a0 0a                              ldy #10
 1290 A:deed  90 01                              bcc comparenameloop
 1291 A:deef  60                                 rts                    ; with carry set

 1293 A:def0                           comparenameloop 
 1293 A:def0                                    
 1294 A:def0  b1 48                              lda (zp_sd_address),y
 1295 A:def2  d1 6a                              cmp (fat32_filenamepointer),y
 1296 A:def4  d0 f2                              bne direntloop                ; no match
 1297 A:def6  88                                 dey 
 1298 A:def7  10 f7                              bpl comparenameloop

 1300 A:def9                                    ; Found it
 1301 A:def9  18                                 clc 
 1302 A:defa  60                                 rts 
 1303 A:defb                                     .) 

 1305 A:defb                           fat32_markdeleted 
 1305 A:defb                                    
 1306 A:defb                                    ; Mark the file as deleted
 1307 A:defb                                    ; We need to stash the first character at index 0x0D
 1308 A:defb  a0 00                              ldy #$00
 1309 A:defd  b1 48                              lda (zp_sd_address),y
 1310 A:deff  a0 0d                              ldy #$0d
 1311 A:df01  91 48                              sta (zp_sd_address),y

 1313 A:df03                                    ; Now put 0xE5 at the first byte
 1314 A:df03  a0 00                              ldy #$00
 1315 A:df05  a9 e5                              lda #$e5
 1316 A:df07  91 48                              sta (zp_sd_address),y

 1318 A:df09                                    ; Get start cluster high word
 1319 A:df09  a0 14                              ldy #$14
 1320 A:df0b  b1 48                              lda (zp_sd_address),y
 1321 A:df0d  85 60                              sta fat32_nextcluster+2
 1322 A:df0f  c8                                 iny 
 1323 A:df10  b1 48                              lda (zp_sd_address),y
 1324 A:df12  85 61                              sta fat32_nextcluster+3

 1326 A:df14                                    ; And low word
 1327 A:df14  a0 1a                              ldy #$1a
 1328 A:df16  b1 48                              lda (zp_sd_address),y
 1329 A:df18  85 5e                              sta fat32_nextcluster
 1330 A:df1a  c8                                 iny 
 1331 A:df1b  b1 48                              lda (zp_sd_address),y
 1332 A:df1d  85 5f                              sta fat32_nextcluster+1

 1334 A:df1f                                    ; Write the dirent
 1335 A:df1f  20 84 de                           jsr fat32_wrcurrent

 1337 A:df22                                    ; Done
 1338 A:df22  18                                 clc 
 1339 A:df23  60                                 rts 

 1341 A:df24                           fat32_deletefile 
 1341 A:df24                                    
 1342 A:df24                                     .( 
 1343 A:df24                                    ; Removes the open file from the SD card.
 1344 A:df24                                    ; The directory needs to be open and
 1345 A:df24                                    ; zp_sd_address pointed to the first byte of the file entry.

 1347 A:df24                                    ; Mark the file as "Removed"
 1348 A:df24  20 fb de                           jsr fat32_markdeleted

 1350 A:df27                                    ; We will read a new sector the first time around
 1351 A:df27  9c 04 03                           stz fat32_lastsector
 1352 A:df2a  9c 05 03                           stz fat32_lastsector+1
 1353 A:df2d  9c 06 03                           stz fat32_lastsector+2
 1354 A:df30  9c 07 03                           stz fat32_lastsector+3

 1356 A:df33                                    ; Now we need to iterate through this file's cluster chain, and remove it from the FAT.
 1357 A:df33  a0 00                              ldy #0
 1358 A:df35                           chainloop 
 1359 A:df35                                    ; Seek to cluster
 1360 A:df35  38                                 sec 
 1361 A:df36  20 19 da                           jsr fat32_seekcluster

 1363 A:df39                                    ; Is this the end of the chain?
 1364 A:df39  a5 61                              lda fat32_nextcluster+3
 1365 A:df3b  30 13                              bmi endofchain

 1367 A:df3d                                    ; Zero it out
 1368 A:df3d  a9 00                              lda #0
 1369 A:df3f  91 48                              sta (zp_sd_address),y
 1370 A:df41  88                                 dey 
 1371 A:df42  91 48                              sta (zp_sd_address),y
 1372 A:df44  88                                 dey 
 1373 A:df45  91 48                              sta (zp_sd_address),y
 1374 A:df47  88                                 dey 
 1375 A:df48  91 48                              sta (zp_sd_address),y

 1377 A:df4a                                    ; Write the FAT
 1378 A:df4a  20 95 db                           jsr fat32_updatefat

 1380 A:df4d                                    ; And go again for another pass.
 1381 A:df4d  4c 35 df                           jmp chainloop

 1383 A:df50                           endofchain 
 1384 A:df50                                    ; This is the last cluster in the chain.

 1386 A:df50                                    ; Just zero it out,
 1387 A:df50  a9 00                              lda #0
 1388 A:df52  91 48                              sta (zp_sd_address),y
 1389 A:df54  88                                 dey 
 1390 A:df55  91 48                              sta (zp_sd_address),y
 1391 A:df57  88                                 dey 
 1392 A:df58  91 48                              sta (zp_sd_address),y
 1393 A:df5a  88                                 dey 
 1394 A:df5b  91 48                              sta (zp_sd_address),y

 1396 A:df5d                                    ; Write the FAT
 1397 A:df5d  20 95 db                           jsr fat32_updatefat

 1399 A:df60                                    ; And we're done!
 1400 A:df60  18                                 clc 
 1401 A:df61  60                                 rts 
 1402 A:df62                                     .) 

 1404 A:df62                           fat32_file_readbyte 
 1404 A:df62                                    
 1405 A:df62                                     .( 
 1406 A:df62                                    ; Read a byte from an open file
 1407 A:df62                                    ;
 1408 A:df62                                    ; The byte is returned in A with C clear; or if end-of-file was reached, C is set instead

 1410 A:df62  38                                 sec 

 1412 A:df63                                    ; Is there any data to read at all?
 1413 A:df63  a5 62                              lda fat32_bytesremaining
 1414 A:df65  05 63                              ora fat32_bytesremaining+1
 1415 A:df67  05 64                              ora fat32_bytesremaining+2
 1416 A:df69  05 65                              ora fat32_bytesremaining+3
 1417 A:df6b  f0 35                              beq rtss

 1419 A:df6d                                    ; Decrement the remaining byte count
 1420 A:df6d  a5 62                              lda fat32_bytesremaining
 1421 A:df6f  e9 01                              sbc #1
 1422 A:df71  85 62                              sta fat32_bytesremaining
 1423 A:df73  a5 63                              lda fat32_bytesremaining+1
 1424 A:df75  e9 00                              sbc #0
 1425 A:df77  85 63                              sta fat32_bytesremaining+1
 1426 A:df79  a5 64                              lda fat32_bytesremaining+2
 1427 A:df7b  e9 00                              sbc #0
 1428 A:df7d  85 64                              sta fat32_bytesremaining+2
 1429 A:df7f  a5 65                              lda fat32_bytesremaining+3
 1430 A:df81  e9 00                              sbc #0
 1431 A:df83  85 65                              sta fat32_bytesremaining+3

 1433 A:df85                                    ; Need to read a new sector?
 1434 A:df85  a5 49                              lda zp_sd_address+1
 1435 A:df87  c9 07                              cmp #>(fat32_readbuffer+$0200)
 1436 A:df89  90 0d                              bcc gotdata

 1438 A:df8b                                    ; Read another sector
 1439 A:df8b  a9 00                              lda #<fat32_readbuffer
 1440 A:df8d  85 5c                              sta fat32_address
 1441 A:df8f  a9 05                              lda #>fat32_readbuffer
 1442 A:df91  85 5d                              sta fat32_address+1

 1444 A:df93  20 0a db                           jsr fat32_readnextsector
 1445 A:df96  b0 0a                              bcs rtss

 1447 A:df98                           gotdata   
 1447 A:df98                                    
 1448 A:df98  a0 00                              ldy #0
 1449 A:df9a  b1 48                              lda (zp_sd_address),y

 1451 A:df9c  e6 48                              inc zp_sd_address
 1452 A:df9e  d0 02                              bne rtss
 1453 A:dfa0  e6 49                              inc zp_sd_address+1

 1455 A:dfa2                           rtss      
 1455 A:dfa2                                    
 1456 A:dfa2  60                                 rts 
 1457 A:dfa3                                     .) 

 1459 A:dfa3                           fat32_file_read 
 1459 A:dfa3                                    
 1460 A:dfa3                                     .( 
 1461 A:dfa3                                    ; Read a whole file into memory.  It's assumed the file has just been opened 
 1462 A:dfa3                                    ; and no data has been read yet.
 1463 A:dfa3                                    ;
 1464 A:dfa3                                    ; Also we read whole sectors, so data in the target region beyond the end of the 
 1465 A:dfa3                                    ; file may get overwritten, up to the next 512-byte boundary.
 1466 A:dfa3                                    ;
 1467 A:dfa3                                    ; And we don't properly support 64k+ files, as it's unnecessary complication given
 1468 A:dfa3                                    ; the 6502's small address space

 1470 A:dfa3                                    ; Round the size up to the next whole sector
 1471 A:dfa3  a5 62                              lda fat32_bytesremaining
 1472 A:dfa5  c9 01                              cmp #1             ; set carry if bottom 8 bits not zero
 1473 A:dfa7  a5 63                              lda fat32_bytesremaining+1
 1474 A:dfa9  69 00                              adc #0             ; add carry, if any
 1475 A:dfab  4a                                 lsr                    ; divide by 2
 1476 A:dfac  69 00                              adc #0             ; round up

 1478 A:dfae                                    ; No data?
 1479 A:dfae  f0 12                              beq donee

 1481 A:dfb0                                    ; Store sector count - not a byte count any more
 1482 A:dfb0  85 62                              sta fat32_bytesremaining

 1484 A:dfb2                                    ; Read entire sectors to the user-supplied buffer
 1485 A:dfb2                           wholesectorreadloop 
 1485 A:dfb2                                    
 1486 A:dfb2                                    ; Read a sector to fat32_address
 1487 A:dfb2  20 0a db                           jsr fat32_readnextsector

 1489 A:dfb5                                    ; Advance fat32_address by 512 bytes
 1490 A:dfb5  a5 5d                              lda fat32_address+1
 1491 A:dfb7  69 02                              adc #2             ; carry already clear
 1492 A:dfb9  85 5d                              sta fat32_address+1

 1494 A:dfbb  a6 62                              ldx fat32_bytesremaining                ; note - actually loads sectors remaining
 1495 A:dfbd  ca                                 dex 
 1496 A:dfbe  86 62                              stx fat32_bytesremaining                ; note - actually stores sectors remaining

 1498 A:dfc0  d0 f0                              bne wholesectorreadloop

 1500 A:dfc2                           donee     
 1500 A:dfc2                                    
 1501 A:dfc2  60                                 rts 
 1502 A:dfc3                                     .) 

 1504 A:dfc3                           fat32_file_write 
 1504 A:dfc3                                    
 1505 A:dfc3                                     .( 
 1506 A:dfc3                                    ; Write a whole file from memory.  It's assumed the file has just been opened 
 1507 A:dfc3                                    ; and no data has been written yet.

 1509 A:dfc3                                    ; Start at the first cluster for this file
 1510 A:dfc3  ad 09 03                           lda fat32_filecluster
 1511 A:dfc6  8d 00 03                           sta fat32_lastcluster
 1512 A:dfc9  ad 0a 03                           lda fat32_filecluster+1
 1513 A:dfcc  8d 01 03                           sta fat32_lastcluster+1
 1514 A:dfcf  ad 0b 03                           lda fat32_filecluster+2
 1515 A:dfd2  8d 02 03                           sta fat32_lastcluster+2
 1516 A:dfd5  ad 0c 03                           lda fat32_filecluster+3
 1517 A:dfd8  8d 03 03                           sta fat32_lastcluster+3

 1519 A:dfdb  ad 09 03                           lda fat32_filecluster
 1520 A:dfde  85 5e                              sta fat32_nextcluster
 1521 A:dfe0  ad 0a 03                           lda fat32_filecluster+1
 1522 A:dfe3  85 5f                              sta fat32_nextcluster+1
 1523 A:dfe5  ad 0b 03                           lda fat32_filecluster+2
 1524 A:dfe8  85 60                              sta fat32_nextcluster+2
 1525 A:dfea  ad 0c 03                           lda fat32_filecluster+3
 1526 A:dfed  85 61                              sta fat32_nextcluster+3

 1528 A:dfef                                    ; Round the size up to the next whole sector
 1529 A:dfef  a5 62                              lda fat32_bytesremaining
 1530 A:dff1  c9 01                              cmp #1             ; set carry if bottom 8 bits not zero
 1531 A:dff3  a5 63                              lda fat32_bytesremaining+1
 1532 A:dff5  69 00                              adc #0             ; add carry, if any
 1533 A:dff7  4a                                 lsr                    ; divide by 2
 1534 A:dff8  69 00                              adc #0             ; round up

 1536 A:dffa                                    ; No data?
 1537 A:dffa  f0 15                              beq fail

 1539 A:dffc                                    ; Store sector count - not a byte count anymore.
 1540 A:dffc  85 62                              sta fat32_bytesremaining

 1542 A:dffe                                    ; We will be making a new cluster the first time around
 1543 A:dffe  64 5b                              stz fat32_pendingsectors

 1545 A:e000                                    ; Write entire sectors from the user-supplied buffer
 1546 A:e000                           wholesectorwriteloop 
 1546 A:e000                                    
 1547 A:e000                                    ; Write a sector from fat32_address
 1548 A:e000  20 4c db                           jsr fat32_writenextsector
 1549 A:e003                                    ;bcs fail ; this shouldn't happen

 1551 A:e003  18                                 clc 
 1552 A:e004                                    ; Advance fat32_address by 512 bytes
 1553 A:e004  a5 5d                              lda fat32_address+1
 1554 A:e006  69 02                              adc #2             ; carry already clear
 1555 A:e008  85 5d                              sta fat32_address+1

 1557 A:e00a  a6 62                              ldx fat32_bytesremaining                ; note - actually loads sectors remaining
 1558 A:e00c  ca                                 dex 
 1559 A:e00d  86 62                              stx fat32_bytesremaining                ; note - actually stores sectors remaining

 1561 A:e00f  d0 ef                              bne wholesectorwriteloop

 1563 A:e011                                    ; Done!
 1564 A:e011                           fail      
 1565 A:e011  60                                 rts 
 1566 A:e012                                     .) 

 1568 A:e012                           fat32_open_cd 
 1568 A:e012                                    
 1569 A:e012                                    ; Prepare to read from a file or directory based on a dirent
 1570 A:e012                                    ;

 1572 A:e012  48                                 pha 
 1573 A:e013  da                                 phx 
 1574 A:e014  5a                                 phy 

 1576 A:e015                                    ; Seek to first cluster of current directory
 1577 A:e015  ad 11 03                           lda fat32_cdcluster
 1578 A:e018  85 5e                              sta fat32_nextcluster
 1579 A:e01a  ad 12 03                           lda fat32_cdcluster+1
 1580 A:e01d  85 5f                              sta fat32_nextcluster+1
 1581 A:e01f  ad 13 03                           lda fat32_cdcluster+2
 1582 A:e022  85 60                              sta fat32_nextcluster+2
 1583 A:e024  ad 14 03                           lda fat32_cdcluster+3
 1584 A:e027  85 61                              sta fat32_nextcluster+3

 1586 A:e029  a9 00                              lda #<fat32_readbuffer
 1587 A:e02b  85 5c                              sta fat32_address
 1588 A:e02d  a9 05                              lda #>fat32_readbuffer
 1589 A:e02f  85 5d                              sta fat32_address+1

 1591 A:e031  18                                 clc 
 1592 A:e032  20 19 da                           jsr fat32_seekcluster

 1594 A:e035                                    ; Set the pointer to a large value so we always read a sector the first time through
 1595 A:e035  a9 ff                              lda #$ff
 1596 A:e037  85 49                              sta zp_sd_address+1

 1598 A:e039  7a                                 ply 
 1599 A:e03a  fa                                 plx 
 1600 A:e03b  68                                 pla 
 1601 A:e03c  60                                 rts 

main.a65


 2565 A:e03d                                    ; include ACIA library

acia.a65

    1 A:e03d                                    ;;;       ------------------ 6551 ACIA Subroutine Library -------------------
    2 A:e03d                                    ;;; Includes
    2 A:e03d                                    
    3 A:e03d                                    ;;; acia_init       - Initializes the ACIA
    4 A:e03d                                    ;;; print_hex_acia  - Prints a hex value in A
    5 A:e03d                                    ;;; clear_display   - Sends a <CLS> command
    6 A:e03d                                    ;;; txpoll          - Polls the TX bit to see if the ACIA is ready
    7 A:e03d                                    ;;; print_chara     - Prints a Character that is stored in A
    8 A:e03d                                    ;;; print_char_acia - Same as print_chara
    9 A:e03d                                    ;;; ascii_home      - Home the cursor
   10 A:e03d                                    ;;; w_acia_full     - Print a NULL-Termintated String with >HIGH in Y and <LOW in X

   12 A:e03d                           acia_init 
   13 A:e03d  48                                 pha 
   14 A:e03e  a9 0b                              lda #%00001011             ; No parity, no echo, no interrupt
   15 A:e040  8d 02 80                           sta $8002
   16 A:e043  a9 1f                              lda #%00011111             ; 1 stop bit, 8 data bits, 19200 baud
   17 A:e045  8d 03 80                           sta $8003
   18 A:e048  68                                 pla 
   19 A:e049  60                                 rts 

   21 A:e04a                           print_hex_acia 
   22 A:e04a  48                                 pha 
   23 A:e04b  6a                                 ror 
   24 A:e04c  6a                                 ror 
   25 A:e04d  6a                                 ror 
   26 A:e04e  6a                                 ror 
   27 A:e04f  20 53 e0                           jsr print_nybble                ; This is just som usful hex cod
   28 A:e052  68                                 pla 
   29 A:e053                           print_nybble 
   30 A:e053  29 0f                              and #15
   31 A:e055  c9 0a                              cmp #10
   32 A:e057  30 02                              bmi skipletter
   33 A:e059  69 06                              adc #6
   34 A:e05b                           skipletter 
   35 A:e05b  69 30                              adc #48
   36 A:e05d                                    ; jsr print_char
   37 A:e05d  20 74 e0                           jsr print_chara
   38 A:e060  60                                 rts 

   40 A:e061                           cleardisplay 
   41 A:e061  48                                 pha 
   42 A:e062  20 6c e0                           jsr txpoll                ; Poll the TX bit
   43 A:e065  a9 0c                              lda #12             ; Print decimal 12 (CLS)
   44 A:e067  8d 00 80                           sta $8000
   45 A:e06a  68                                 pla 
   46 A:e06b  60                                 rts 

   48 A:e06c                           txpoll    
   49 A:e06c  ad 01 80                           lda $8001
   50 A:e06f  29 10                              and #$10             ; Poll the TX bit
   51 A:e071  f0 f9                              beq txpoll
   52 A:e073  60                                 rts 

   54 A:e074                           print_char_acia                  ; same command
   55 A:e074                           print_chara 
   56 A:e074  48                                 pha 
   57 A:e075  20 6c e0                           jsr txpoll                ; Poll the TX bit
   58 A:e078  68                                 pla 
   59 A:e079  8d 00 80                           sta $8000              ; Print character from A
   60 A:e07c  60                                 rts 

   62 A:e07d                           ascii_home 
   63 A:e07d  48                                 pha 
   64 A:e07e  a9 01                              lda #1
   65 A:e080  20 74 e0                           jsr print_chara                ; Print 1 (HOME)
   66 A:e083  68                                 pla 
   67 A:e084  60                                 rts 

   69 A:e085                                    ; TODO FIX VARIABLES

   71 A:e085                           w_acia_full 
   72 A:e085  48                                 pha 
   73 A:e086  a5 ff                              lda $ff
   74 A:e088  48                                 pha                    ; Push Previous States onto the stack
   75 A:e089  a5 fe                              lda $fe
   76 A:e08b  48                                 pha 
   77 A:e08c  84 ff                              sty $ff              ; Set Y as the Upper Address (8-15)
   78 A:e08e  86 fe                              stx $fe              ; Set X as the Lower Adderss (0-7)
   79 A:e090  a0 00                              ldy #0
   80 A:e092                           acia_man  
   81 A:e092  20 6c e0                           jsr txpoll                ; Poll TX
   82 A:e095  b1 fe                              lda ($fe),y          ; Load the Address
   83 A:e097  8d 00 80                           sta $8000              ; Print what is at the address
   84 A:e09a  f0 04                              beq endwacia                ; If Done, End
   85 A:e09c  c8                                 iny                    ; Next Character
   86 A:e09d  4c 92 e0                           jmp acia_man                ; Back to the top
   87 A:e0a0                           endwacia  
   88 A:e0a0  68                                 pla 
   89 A:e0a1  85 fe                              sta $fe
   90 A:e0a3  68                                 pla                    ; Restore Variables
   91 A:e0a4  85 ff                              sta $ff
   92 A:e0a6  68                                 pla 
   93 A:e0a7  60                                 rts 

main.a65


 2568 A:e0a8                                    ; error sound
 2569 A:e0a8                           error_sound 
 2569 A:e0a8                                    
 2570 A:e0a8  20 f0 e0                           jsr clear_sid
 2571 A:e0ab  a9 06                              lda #$06
 2572 A:e0ad  85 0c                              sta mem_copy
 2573 A:e0af  a9 10                              lda #$10
 2574 A:e0b1  85 0d                              sta mem_copy+1
 2575 A:e0b3  a9 09                              lda #<sounddata
 2576 A:e0b5  85 0a                              sta mem_source
 2577 A:e0b7  a9 c4                              lda #>sounddata
 2578 A:e0b9  85 0b                              sta mem_source+1
 2579 A:e0bb  a9 0a                              lda #$0a
 2580 A:e0bd  85 0e                              sta mem_end
 2581 A:e0bf  a9 11                              lda #$11
 2582 A:e0c1  85 0f                              sta mem_end+1
 2583 A:e0c3  20 2d eb                           jsr memcopy
 2584 A:e0c6  a9 0a                              lda #$0a
 2585 A:e0c8  85 0c                              sta mem_copy
 2586 A:e0ca  a9 11                              lda #$11
 2587 A:e0cc  85 0d                              sta mem_copy+1
 2588 A:e0ce  a9 f9                              lda #<errordat
 2589 A:e0d0  85 0a                              sta mem_source
 2590 A:e0d2  a9 e0                              lda #>errordat
 2591 A:e0d4  85 0b                              sta mem_source+1
 2592 A:e0d6  a9 2e                              lda #$2e
 2593 A:e0d8  85 0e                              sta mem_end
 2594 A:e0da  a9 12                              lda #$12
 2595 A:e0dc  85 0f                              sta mem_end+1
 2596 A:e0de  20 2d eb                           jsr memcopy
 2597 A:e0e1  a9 55                              lda #$55
 2598 A:e0e3  85 00                              sta donefact
 2599 A:e0e5  64 01                              stz irqcount
 2600 A:e0e7  a9 0f                              lda #$0f
 2601 A:e0e9  8d 18 b8                           sta $b818
 2602 A:e0ec  20 c0 c3                           jsr runthesound
 2603 A:e0ef  60                                 rts 

 2605 A:e0f0                           clear_sid 
 2606 A:e0f0  a2 17                              ldx #$17
 2607 A:e0f2                           csid      
 2608 A:e0f2  9e 00 b8                           stz $b800,x
 2609 A:e0f5  ca                                 dex 
 2610 A:e0f6  d0 fa                              bne csid
 2611 A:e0f8  60                                 rts 

 2613 A:e0f9                                    ; error sound
 2614 A:e0f9                           errordat  
 2614 A:e0f9                                    
 2615 A:e0f9  f0 0f 77 11 01 00                  .byt $f0,$0f,$77,$11,$01,$00
 2616 A:e0ff  12 0d 04 05 0b 14 08 ...           .byt $12,$0d,$04,$05,$0b,$14,$08,$09,$07,$06,$0c,$03,$0e,$0f,$10,$11
 2617 A:e10f  17 13 0a 15 16 18 02 ...           .byt $17,$13,$0a,$15,$16,$18,$02,$00,$b6,$00,$6e,$b6,$01,$16,$ff,$3e
 2618 A:e11f  03 20 f0 41 08 20 ff ...           .byt $03,$20,$f0,$41,$08,$20,$ff,$f0,$00,$fd,$00,$00,$00,$07,$ff,$00
 2619 A:e12f  00 fd 07 00 00 07 1e ...           .byt $00,$fd,$07,$00,$00,$07,$1e,$00,$00,$0f,$fd,$06,$16,$6e,$06,$3e
 2620 A:e13f  03 ff 16 6e 08 00 08 ...           .byt $03,$ff,$16,$6e,$08,$00,$08,$00,$08,$63,$00,$00,$00,$40,$00,$ff
 2621 A:e14f  3e 03 20 f0 41 08 20 ...           .byt $3e,$03,$20,$f0,$41,$08,$20,$9f,$f0,$00,$fd,$00,$07,$bf,$00,$00
 2622 A:e15f  fd 07 00 07 0e 00 00 ...           .byt $fd,$07,$00,$07,$0e,$00,$00,$0f,$11,$2d,$00,$fd,$11,$4a,$a0,$11
 2623 A:e16f  4a a0 11 4a a0 11 4a ...           .byt $4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a
 2624 A:e17f  a0 11 4a a0 11 4a a0 ...           .byt $a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0
 2625 A:e18f  11 4a a0 11 4a a0 11 ...           .byt $11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11
 2626 A:e19f  4a a0 11 4a a0 11 4a ...           .byt $4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a
 2627 A:e1af  a0 11 4a a0 11 4a a0 ...           .byt $a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0
 2628 A:e1bf  11 4a a0 11 4a a0 11 ...           .byt $11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11
 2629 A:e1cf  4a a0 11 4a a0 11 4a ...           .byt $4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a
 2630 A:e1df  a0 11 4a a0 11 4a a0 ...           .byt $a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0
 2631 A:e1ef  11 4a a0 11 4a a0 11 ...           .byt $11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11
 2632 A:e1ff  4a a0 11 4a a0 11 4a ...           .byt $4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a
 2633 A:e20f  a0 11 4a a0 11 4a a0 ...           .byt $a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a0,$11,$4a,$a2,$00,$fe

 2635 A:e21e                           subdirname 
 2636 A:e21e  52 4f 4f 54 20 20 20 ...           .byt "ROOT       "
 2637 A:e229                           filename  
 2638 A:e229  43 4f 44 45 20 20 20 ...           .byt "CODE    XPL"
 2639 A:e234                           loadname  
 2640 A:e234  4c 4f 41 44 41 44 44 ...           .byt "LOADADDRSAR"
 2641 A:e23f                           fat_error 
 2642 A:e23f  46 41 54 33 32 20 45 ...           .byt "FAT32 Error At Stage ",$00

 2644 A:e255                                    ; include xplDOS system

xpldos.a65

    1 A:e255                                    ;; xplDOS
    2 A:e255                                    ;; *NIX-esque SD Card Navigation system.
    3 A:e255                                    ;;
    4 A:e255                                    ;; the first byte of path is 0 if there was an init error.
    5 A:e255                                    ;; otherwise it is a index to PATH for the empty space after the last foldername
    6 A:e255                                    ;; to calculate what value 0 is when v is PATH+0 and f is the amount of folders, use
    6 A:e255                                    
    7 A:e255                                    ;; v = 11f+1
    8 A:e255                                    ;; for example
    8 A:e255                                    
    9 A:e255                                    ;; 23,"FOLDER     ", "TEST       ", $00 <--path points here (11+11+1=23)
   10 A:e255                                    ;; BUG root usage is not possible, thus, it is required that we are in a folder (ls does not seem to like reading the SD root.)
   11 A:e255                                    ;; TODO add path support to a typed command
   12 A:e255                                    ;; TODO need to add /path support to file-based commands  
   13 A:e255                                    ;; Commands
   13 A:e255                                    
   14 A:e255                                    ;; CD
   15 A:e255                                    ;; LS
   16 A:e255                                    ;; LOAD
   17 A:e255                                    ;; CAT
   18 A:e255                                    ;; SAVE
   19 A:e255                                    ;; RM
   20 A:e255                                    ;; MV
   21 A:e255                                    ;; upcoming commands (TODO)
   21 A:e255                                    
   22 A:e255                                    ;; MKDIR
   23 A:e255                                    ;; CP
   24 A:e255                                    ;; TAR?
   25 A:e255                                    ;; MAN?

   27 A:e255                                    ;; resolvepath 
   28 A:e255                                    ;; Handles absolute and relative paths

   30 A:e255                           resolvepath 
   30 A:e255                                    
   31 A:e255                                     .( 
   32 A:e255  a0 00                              ldy #0
   33 A:e257  b1 11                              lda (folderpointer),y
   34 A:e259  c9 2f                              cmp #'/'             ; absolute path?
   35 A:e25b  d0 3d                              bne parsepath

   37 A:e25d                                    ; absolute path, clear PATH
   38 A:e25d  a9 01                              lda #1
   39 A:e25f  8d 00 04                           sta path
   40 A:e262  20 74 e2                           jsr rootalias

   42 A:e265                                    ; check if path is just "/" (i.e., empty after slash)
   43 A:e265  a0 01                              ldy #1
   44 A:e267  98                                 tya 
   45 A:e268  18                                 clc 
   46 A:e269  65 11                              adc folderpointer
   47 A:e26b  85 11                              sta folderpointer
   48 A:e26d  90 02                              bcc qp
   49 A:e26f  e6 12                              inc folderpointer+1
   50 A:e271                           qp        
   50 A:e271                                    
   51 A:e271  4c 9a e2                           jmp parsepath

   53 A:e274                           rootalias 
   53 A:e274                                    
   54 A:e274                                    ; /ROOT
   55 A:e274  a5 11                              lda folderpointer
   56 A:e276  48                                 pha 
   57 A:e277  a9 8e                              lda #<ral
   58 A:e279  85 11                              sta folderpointer
   59 A:e27b  a5 12                              lda folderpointer+1
   60 A:e27d  48                                 pha 
   61 A:e27e  a9 e2                              lda #>ral
   62 A:e280  85 12                              sta folderpointer+1
   63 A:e282  20 50 e3                           jsr addpath
   64 A:e285  68                                 pla 
   65 A:e286  85 12                              sta folderpointer+1
   66 A:e288  68                                 pla 
   67 A:e289  85 11                              sta folderpointer
   68 A:e28b  4c 0e e3                           jmp resdone

   70 A:e28e                           ral       
   70 A:e28e                                    
   71 A:e28e  52 4f 4f 54 20 20 20 ...           .byt "ROOT       ",$00

   73 A:e29a                                    ; relative path, start from current directory
   74 A:e29a                           parsepath 
   74 A:e29a                                    
   75 A:e29a                                    ; skip slashes
   76 A:e29a  a0 00                              ldy #0
   77 A:e29c  b1 11                              lda (folderpointer),y
   78 A:e29e  f0 6e                              beq resdone
   79 A:e2a0  c9 2f                              cmp #'/'
   80 A:e2a2  d0 09                              bne buildseg
   81 A:e2a4  e6 11                              inc folderpointer
   82 A:e2a6  d0 f2                              bne parsepath
   83 A:e2a8  e6 12                              inc folderpointer+1
   84 A:e2aa  4c 9a e2                           jmp parsepath

   86 A:e2ad                           buildseg  
   86 A:e2ad                                    
   87 A:e2ad  a2 00                              ldx #0
   88 A:e2af                           segloop   
   88 A:e2af                                    
   89 A:e2af  b1 11                              lda (folderpointer),y
   90 A:e2b1  f0 0d                              beq endseg
   91 A:e2b3  c9 2f                              cmp #'/'
   92 A:e2b5  f0 09                              beq endseg
   93 A:e2b7  9d 18 03                           sta fnstash,x
   94 A:e2ba  e8                                 inx 
   95 A:e2bb  c8                                 iny 
   96 A:e2bc  e0 0c                              cpx #12
   97 A:e2be  d0 ef                              bne segloop

   99 A:e2c0                           endseg    
   99 A:e2c0                                    
  100 A:e2c0  a9 00                              lda #0
  101 A:e2c2  9d 18 03                           sta fnstash,x              ; null-terminate

  103 A:e2c5  98                                 tya 
  104 A:e2c6  18                                 clc 
  105 A:e2c7  65 11                              adc folderpointer
  106 A:e2c9  85 11                              sta folderpointer
  107 A:e2cb  90 02                              bcc fldr
  108 A:e2cd  e6 12                              inc folderpointer+1
  109 A:e2cf                           fldr      
  109 A:e2cf                                    

  111 A:e2cf                                    ; Check for . and ..
  112 A:e2cf  a0 00                              ldy #0
  113 A:e2d1  b9 18 03                           lda fnstash,y
  114 A:e2d4  c9 2e                              cmp #'.'
  115 A:e2d6  d0 13                              bne notdot
  116 A:e2d8  c8                                 iny 
  117 A:e2d9  b9 18 03                           lda fnstash,y
  118 A:e2dc  f0 bc                              beq parsepath                ; just '.', skip
  119 A:e2de  c9 2e                              cmp #'.'
  120 A:e2e0  d0 b8                              bne parsepath                ; not '..'
  121 A:e2e2  c8                                 iny 
  122 A:e2e3  b9 18 03                           lda fnstash,y
  123 A:e2e6  f0 20                              beq goback                ; confirmed '..'
  124 A:e2e8  4c 9a e2                           jmp parsepath                ; invalid (e.g., '...'), ignore

  126 A:e2eb                           notdot    
  126 A:e2eb                                    
  127 A:e2eb                                    ; CD into this segment
  128 A:e2eb  a5 11                              lda folderpointer
  129 A:e2ed  48                                 pha 
  130 A:e2ee  a9 18                              lda #<fnstash
  131 A:e2f0  85 11                              sta folderpointer
  132 A:e2f2  a5 12                              lda folderpointer+1
  133 A:e2f4  48                                 pha 
  134 A:e2f5  a9 03                              lda #>fnstash
  135 A:e2f7  85 12                              sta folderpointer+1
  136 A:e2f9  20 28 e5                           jsr shortconvert
  137 A:e2fc  20 50 e3                           jsr addpath
  138 A:e2ff  68                                 pla 
  139 A:e300  85 12                              sta folderpointer+1
  140 A:e302  68                                 pla 
  141 A:e303  85 11                              sta folderpointer
  142 A:e305  4c 9a e2                           jmp parsepath

  144 A:e308                           goback    
  144 A:e308                                    
  145 A:e308  20 6d e3                           jsr backpath
  146 A:e30b  4c 9a e2                           jmp parsepath

  148 A:e30e                           resdone   
  148 A:e30e                                    
  149 A:e30e  18                                 clc 
  150 A:e30f  60                                 rts 
  151 A:e310                                     .) 

  153 A:e310                                    ; PATH refresh
  154 A:e310                                    ; goes to the ROOT directory, and CDs to the directory at PATH.
  155 A:e310                                    ;
  156 A:e310                                    ; this is probably equivilent to "Refresh" in Microsoft Windows.
  157 A:e310                           refreshpath 
  157 A:e310                                    
  158 A:e310                                     .( 
  159 A:e310                                    ; No memory card?
  160 A:e310  ad 00 04                           lda path
  161 A:e313  f0 26                              beq patherr
  162 A:e315  a9 01                              lda #1             ; path+1 because path+0 is the path size variable
  163 A:e317  85 16                              sta pathindex
  164 A:e319                                    ; If memory card, then goto dir
  165 A:e319  20 f7 db                           jsr fat32_openroot
  166 A:e31c                           rloop     
  166 A:e31c                                    
  167 A:e31c                                    ; Open the directory
  168 A:e31c  a6 16                              ldx pathindex
  169 A:e31e  a0 04                              ldy #>path
  170 A:e320  20 e4 de                           jsr fat32_finddirent
  171 A:e323  90 03                              bcc fine
  172 A:e325  4c 44 e3                           jmp rlerror
  173 A:e328                           fine      
  173 A:e328                                    
  174 A:e328  20 5d dd                           jsr fat32_opendirent
  175 A:e32b                                    ; advance to the next directory
  176 A:e32b  18                                 clc 
  177 A:e32c  a5 16                              lda pathindex
  178 A:e32e  69 0b                              adc #11
  179 A:e330  85 16                              sta pathindex
  180 A:e332                                    ;lda (pathindex) ; end of path?
  181 A:e332  ad 00 04                           lda path
  182 A:e335  c5 16                              cmp pathindex
  183 A:e337  d0 e3                              bne rloop                ; if not, cd to the next directory
  184 A:e339  18                                 clc 
  185 A:e33a  60                                 rts 
  186 A:e33b                                     .) 
  187 A:e33b                           patherr   
  187 A:e33b                                    
  188 A:e33b  a2 81                              ldx #<patherror
  189 A:e33d  a0 e3                              ldy #>patherror
  190 A:e33f  20 85 e0                           jsr w_acia_full
  191 A:e342  38                                 sec 
  192 A:e343  60                                 rts 
  193 A:e344                           rlerror   
  193 A:e344                                    
  194 A:e344  a2 d6                              ldx #<foldermsg
  195 A:e346  a0 e9                              ldy #>foldermsg
  196 A:e348  20 85 e0                           jsr w_acia_full
  197 A:e34b  20 a8 e0                           jsr error_sound
  198 A:e34e  38                                 sec 
  199 A:e34f  60                                 rts 

  201 A:e350                                    ; add PATH
  202 A:e350                                    ; adds a SHORT formatted folder at (folderpointer) to the PATH variable.
  203 A:e350                           addpath   
  203 A:e350                                    
  204 A:e350                                     .( 
  205 A:e350  48                                 pha 
  206 A:e351  da                                 phx 
  207 A:e352  5a                                 phy 
  208 A:e353  a0 00                              ldy #0
  209 A:e355  ae 00 04                           ldx path
  210 A:e358                           aplp      
  210 A:e358                                    
  211 A:e358  b1 11                              lda (folderpointer),y
  212 A:e35a  9d 00 04                           sta path,x
  213 A:e35d  c8                                 iny 
  214 A:e35e  e8                                 inx 
  215 A:e35f  c0 0b                              cpy #11
  216 A:e361  d0 f5                              bne aplp
  217 A:e363  9e 00 04                           stz path,x
  218 A:e366  8e 00 04                           stx path
  219 A:e369  7a                                 ply 
  220 A:e36a  fa                                 plx 
  221 A:e36b  68                                 pla 
  222 A:e36c  60                                 rts 
  223 A:e36d                                     .) 

  225 A:e36d                                    ; delete PATH
  226 A:e36d                                    ; goes back a directory, used in cd ..
  227 A:e36d                           backpath  
  227 A:e36d                                    
  228 A:e36d                                     .( 
  229 A:e36d  da                                 phx 
  230 A:e36e  48                                 pha 
  231 A:e36f  38                                 sec 
  232 A:e370  ad 00 04                           lda path
  233 A:e373  e9 0b                              sbc #11             ; remove dir
  234 A:e375  8d 00 04                           sta path
  235 A:e378  ae 00 04                           ldx path
  236 A:e37b  9e 00 04                           stz path,x
  237 A:e37e  68                                 pla 
  238 A:e37f  fa                                 plx 
  239 A:e380  60                                 rts 
  240 A:e381                                     .) 

  242 A:e381                           patherror 
  242 A:e381                                    
  243 A:e381  4e 6f 20 4d 65 6d 6f ...           .byt "No Memory Card.",$0d,$0a,$00

  245 A:e393                                    ;; print PATH
  246 A:e393                                    ;; prints the current directory, like *NIX
  247 A:e393                                    ;; for example
  247 A:e393                                    
  248 A:e393                                    ;; /test/ >_
  249 A:e393                                    ;; or
  249 A:e393                                    
  250 A:e393                                    ;; / >_
  251 A:e393                                    ;;
  252 A:e393                           printpath 
  252 A:e393                                    
  253 A:e393                                     .( 
  254 A:e393                                    ; No memory card?
  255 A:e393  ad 00 04                           lda path
  256 A:e396  d0 02                              bne pp
  257 A:e398  38                                 sec 
  258 A:e399  60                                 rts 
  259 A:e39a                           pp        
  260 A:e39a  a9 2f                              lda #'/'
  261 A:e39c  20 74 e0                           jsr print_chara
  262 A:e39f  a9 0c                              lda #12             ; path+12 because we already showed the root
  263 A:e3a1  85 16                              sta pathindex
  264 A:e3a3  a9 04                              lda #>path
  265 A:e3a5  85 17                              sta pathindex+1
  266 A:e3a7  a0 00                              ldy #0
  267 A:e3a9                           pplp      
  267 A:e3a9                                    
  268 A:e3a9                                    ; loop through path and print the folder, in lowercase
  269 A:e3a9  b1 16                              lda (pathindex),y
  270 A:e3ab  f0 23                              beq ppdone                ; exit if only root
  271 A:e3ad  c9 20                              cmp #$20             ; space?
  272 A:e3af  f0 09                              beq ppd
  273 A:e3b1  09 20                              ora #$20             ; if not, print (in lowercase)
  274 A:e3b3  20 74 e0                           jsr print_chara
  275 A:e3b6  c8                                 iny 
  276 A:e3b7  4c a9 e3                           jmp pplp
  277 A:e3ba                           ppd       
  277 A:e3ba                                    
  278 A:e3ba  a9 2f                              lda #'/'             ; if space, dir done.
  279 A:e3bc  20 74 e0                           jsr print_chara
  280 A:e3bf                           ppdl      
  280 A:e3bf                                    
  281 A:e3bf  b1 16                              lda (pathindex),y            ; look for the next entry.
  282 A:e3c1  c9 20                              cmp #$20
  283 A:e3c3  d0 04                              bne notspace
  284 A:e3c5  c8                                 iny 
  285 A:e3c6  4c bf e3                           jmp ppdl
  286 A:e3c9                           notspace  
  286 A:e3c9                                    
  287 A:e3c9  b1 16                              lda (pathindex),y            ; end of path?
  288 A:e3cb  f0 03                              beq ppdone
  289 A:e3cd  4c a9 e3                           jmp pplp                ; no, print another folder name.
  290 A:e3d0                           ppdone    
  290 A:e3d0                                    
  291 A:e3d0                                    ; Print a space for good spacing
  292 A:e3d0  a9 20                              lda #$20
  293 A:e3d2  20 74 e0                           jsr print_chara
  294 A:e3d5  18                                 clc 
  295 A:e3d6  60                                 rts                    ; done!
  296 A:e3d7                                     .) 

  298 A:e3d7                                    ;; CD
  299 A:e3d7                                    ;; Change the directory
  300 A:e3d7                                    ;; if you use cdsub, folderpointer holds the address of the folder name

  302 A:e3d7                           cdcmd     
  302 A:e3d7                                    
  303 A:e3d7                                     .( 
  304 A:e3d7  ad 00 04                           lda path
  305 A:e3da  d0 03                              bne cdf
  306 A:e3dc  4c 3b e3                           jmp patherr
  307 A:e3df                           cdf       
  307 A:e3df                                    
  308 A:e3df                                    ;; check arguments
  309 A:e3df  a5 20                              lda ARGINDEX
  310 A:e3e1  c9 02                              cmp #2             ; if there's two arguments, change to the specified directory
  311 A:e3e3  f0 03                              beq processparam
  312 A:e3e5  4c 0a e4                           jmp error
  313 A:e3e8                           processparam                  ; process the filename parameter
  314 A:e3e8  18                                 clc 
  315 A:e3e9  a9 00                              lda #<INPUT
  316 A:e3eb  65 22                              adc ARGINDEX+2
  317 A:e3ed  85 11                              sta folderpointer
  318 A:e3ef  a9 02                              lda #>INPUT
  319 A:e3f1  85 12                              sta folderpointer+1
  320 A:e3f3                                     .) 
  321 A:e3f3                           cdsub     
  321 A:e3f3                                    
  322 A:e3f3                                     .( 
  323 A:e3f3  20 12 e4                           jsr stashpath
  324 A:e3f6  20 55 e2                           jsr resolvepath
  325 A:e3f9  20 10 e3                           jsr refreshpath
  326 A:e3fc  90 03                              bcc noerr
  327 A:e3fe  20 25 e4                           jsr restorepath
  328 A:e401                           noerr     
  329 A:e401  60                                 rts 
  330 A:e402                                     .) 

  332 A:e402                           fileerror 
  333 A:e402                                    ; no such folder
  334 A:e402  a2 d6                              ldx #<foldermsg
  335 A:e404  a0 e9                              ldy #>foldermsg
  336 A:e406  20 85 e0                           jsr w_acia_full
  337 A:e409  60                                 rts 

  339 A:e40a                           error     
  340 A:e40a  a2 9b                              ldx #<errormsg
  341 A:e40c  a0 f5                              ldy #>errormsg
  342 A:e40e  20 85 e0                           jsr w_acia_full
  343 A:e411  60                                 rts 

  345 A:e412                           stashpath 
  345 A:e412                                    
  346 A:e412                                     .( 
  347 A:e412  48                                 pha 
  348 A:e413  da                                 phx 
  349 A:e414  a2 00                              ldx #0
  350 A:e416                           lp        
  351 A:e416  bd 00 04                           lda path,x
  352 A:e419  9d 00 07                           sta buffer,x
  353 A:e41c  f0 04                              beq st
  354 A:e41e  e8                                 inx 
  355 A:e41f  4c 16 e4                           jmp lp
  356 A:e422                           st        
  357 A:e422  fa                                 plx 
  358 A:e423  68                                 pla 
  359 A:e424  60                                 rts 
  360 A:e425                                     .) 

  362 A:e425                           restorepath 
  362 A:e425                                    
  363 A:e425                                     .( 
  364 A:e425  48                                 pha 
  365 A:e426  da                                 phx 
  366 A:e427  a2 00                              ldx #0
  367 A:e429                           lp        
  368 A:e429  bd 00 07                           lda buffer,x
  369 A:e42c  9d 00 04                           sta path,x
  370 A:e42f  f0 04                              beq st
  371 A:e431  e8                                 inx 
  372 A:e432  4c 29 e4                           jmp lp
  373 A:e435                           st        
  374 A:e435  fa                                 plx 
  375 A:e436  68                                 pla 
  376 A:e437  60                                 rts 
  377 A:e438                                     .) 

  379 A:e438                                    ; checks if we are in the same dir
  380 A:e438                           cmppath   
  380 A:e438                                    
  381 A:e438                                     .( 
  382 A:e438  da                                 phx 
  383 A:e439  48                                 pha 
  384 A:e43a  a2 ff                              ldx #$ff
  385 A:e43c                           lp        
  386 A:e43c  e8                                 inx 
  387 A:e43d  bd 00 04                           lda path,x
  388 A:e440  dd 00 07                           cmp buffer,x
  389 A:e443  d0 08                              bne ne
  390 A:e445                           cn        
  391 A:e445  c9 00                              cmp #0
  392 A:e447  d0 f3                              bne lp
  393 A:e449                           eq        
  394 A:e449  68                                 pla 
  395 A:e44a  fa                                 plx 
  396 A:e44b  38                                 sec 
  397 A:e44c  60                                 rts 
  398 A:e44d                           ne        
  399 A:e44d  68                                 pla 
  400 A:e44e  fa                                 plx 
  401 A:e44f  18                                 clc 
  402 A:e450  60                                 rts 
  403 A:e451                                     .) 

  405 A:e451                                    ; strips the file off of the input path 
  406 A:e451                                    ; (eg. /test/folder/myfile.txt -> /test/folder/)
  407 A:e451                                    ; set carry if in same folder (eg. file.txt)
  408 A:e451                                    ; also stores the last slash pos in last_slash_pos
  409 A:e451                                    ; this can be used if you want to get the file name 
  410 A:e451                                    ; by adding 1 do this value
  411 A:e451                                    ; and then using that as an index to the file name

  413 A:e451                           stripfile 
  413 A:e451                                    
  414 A:e451                                     .( 
  415 A:e451  a0 00                              ldy #0
  416 A:e453  a9 ff                              lda #$ff
  417 A:e455  8d 38 03                           sta last_slash_pos                ; default = not found

  419 A:e458                           find_slash 
  419 A:e458                                    
  420 A:e458  b1 11                              lda (folderpointer),y
  421 A:e45a  f0 0b                              beq check_result
  422 A:e45c  c9 2f                              cmp #'/'
  423 A:e45e  d0 04                              bne not_slash
  424 A:e460  98                                 tya 
  425 A:e461  8d 38 03                           sta last_slash_pos                ; save Y as last slash position

  427 A:e464                           not_slash 
  427 A:e464                                    
  428 A:e464  c8                                 iny 
  429 A:e465  d0 f1                              bne find_slash

  431 A:e467                           check_result 
  431 A:e467                                    
  432 A:e467  ad 38 03                           lda last_slash_pos
  433 A:e46a  c9 ff                              cmp #$ff
  434 A:e46c  f0 0a                              beq no_slash_found                ; no slash → SEC, RTS

  436 A:e46e  ad 38 03                           lda last_slash_pos
  437 A:e471  a8                                 tay                    ; restore index of last slash
  438 A:e472  a9 00                              lda #0
  439 A:e474  91 11                              sta (folderpointer),y
  440 A:e476  18                                 clc 
  441 A:e477  60                                 rts 

  443 A:e478                           no_slash_found 
  443 A:e478                                    
  444 A:e478  38                                 sec 
  445 A:e479  60                                 rts 
  446 A:e47a                                     .) 

  448 A:e47a                                    ;; CAT
  449 A:e47a                                    ;; prints out a file

  451 A:e47a                           catcmd    
  451 A:e47a                                    
  452 A:e47a                                     .( 
  453 A:e47a  ad 00 04                           lda path
  454 A:e47d  d0 03                              bne cdf
  455 A:e47f  4c 3b e3                           jmp patherr
  456 A:e482                           cdf       
  456 A:e482                                    
  457 A:e482                                    ;; check arguments
  458 A:e482  a5 20                              lda ARGINDEX
  459 A:e484  c9 02                              cmp #2
  460 A:e486  d0 82                              bne error
  461 A:e488  18                                 clc 
  462 A:e489  a9 00                              lda #<INPUT
  463 A:e48b  65 22                              adc ARGINDEX+2
  464 A:e48d  85 11                              sta folderpointer
  465 A:e48f  a9 02                              lda #>INPUT
  466 A:e491  85 12                              sta folderpointer+1

  468 A:e493  20 51 e4                           jsr stripfile
  469 A:e496  90 09                              bcc path_has_slash
  470 A:e498                           same_folder 
  471 A:e498                                    ; normal operation
  472 A:e498  20 28 e5                           jsr shortconvert
  473 A:e49b  20 10 e3                           jsr refreshpath
  474 A:e49e  90 47                              bcc find_and_print_file
  475 A:e4a0  60                                 rts 
  476 A:e4a1                           path_has_slash 
  477 A:e4a1                                    ; there's a slash 
  478 A:e4a1                                    ; in the path. 
  479 A:e4a1  a5 11                              lda folderpointer
  480 A:e4a3  85 80                              sta stackaccess
  481 A:e4a5  a5 12                              lda folderpointer+1
  482 A:e4a7  85 81                              sta stackaccess+1
  483 A:e4a9  20 db c0                           jsr push16

  485 A:e4ac  20 12 e4                           jsr stashpath
  486 A:e4af  20 55 e2                           jsr resolvepath
  487 A:e4b2  20 38 e4                           jsr cmppath
  488 A:e4b5  90 0e                              bcc different_folder

  490 A:e4b7                                    ; same folder
  491 A:e4b7                                    ; restore pointer
  492 A:e4b7  20 e6 c0                           jsr pop16
  493 A:e4ba  a5 80                              lda stackaccess
  494 A:e4bc  85 11                              sta folderpointer
  495 A:e4be  a5 81                              lda stackaccess+1
  496 A:e4c0  85 12                              sta folderpointer+1
  497 A:e4c2  4c 98 e4                           jmp same_folder

  499 A:e4c5                           different_folder 
  499 A:e4c5                                    
  500 A:e4c5  20 10 e3                           jsr refreshpath
  501 A:e4c8  20 d4 e4                           jsr extract_and_list
  502 A:e4cb  20 25 e4                           jsr restorepath
  503 A:e4ce  20 10 e3                           jsr refreshpath
  504 A:e4d1  4c e6 c0                           jmp pop16

  506 A:e4d4                           extract_and_list 
  506 A:e4d4                                    
  507 A:e4d4  e6 11                              inc folderpointer
  508 A:e4d6  18                                 clc 
  509 A:e4d7  a5 11                              lda folderpointer
  510 A:e4d9  6d 38 03                           adc last_slash_pos
  511 A:e4dc  85 11                              sta folderpointer
  512 A:e4de  a5 12                              lda folderpointer+1
  513 A:e4e0  69 00                              adc #0
  514 A:e4e2  85 12                              sta folderpointer+1
  515 A:e4e4  20 28 e5                           jsr shortconvert
  516 A:e4e7                                    ; pass through
  517 A:e4e7                           find_and_print_file 
  517 A:e4e7                                    
  518 A:e4e7                                    ; Find the file
  519 A:e4e7  a6 11                              ldx folderpointer
  520 A:e4e9  a4 12                              ldy folderpointer+1
  521 A:e4eb  20 e4 de                           jsr fat32_finddirent
  522 A:e4ee  b0 35                              bcs jmperror

  524 A:e4f0                                    ; Open the file
  525 A:e4f0  20 5d dd                           jsr fat32_opendirent

  527 A:e4f3                                    ; Read file contents into buffer
  528 A:e4f3  a9 00                              lda #<buffer
  529 A:e4f5  85 5c                              sta fat32_address
  530 A:e4f7  a9 07                              lda #>buffer
  531 A:e4f9  85 5d                              sta fat32_address+1

  533 A:e4fb                           readlp    
  533 A:e4fb                                    
  534 A:e4fb  20 62 df                           jsr fat32_file_readbyte
  535 A:e4fe  f0 21                              beq catd
  536 A:e500  c9 0d                              cmp #$0d
  537 A:e502  f0 17                              beq notunix
  538 A:e504  4c 0c e5                           jmp unixloop
  539 A:e507                           unix      
  539 A:e507                                    
  540 A:e507  20 62 df                           jsr fat32_file_readbyte
  541 A:e50a  f0 15                              beq catd
  542 A:e50c                           unixloop  
  542 A:e50c                                    
  543 A:e50c  c9 0a                              cmp #$0a
  544 A:e50e  d0 05                              bne notcr
  545 A:e510  20 74 e0                           jsr print_chara
  546 A:e513  a9 0d                              lda #$0d
  547 A:e515                           notcr     
  547 A:e515                                    
  548 A:e515  20 74 e0                           jsr print_chara
  549 A:e518  4c 07 e5                           jmp unix
  550 A:e51b                           notunix   
  550 A:e51b                                    
  551 A:e51b  20 74 e0                           jsr print_chara
  552 A:e51e  4c fb e4                           jmp readlp
  553 A:e521                           catd      
  553 A:e521                                    
  554 A:e521                                    ; CR+LF
  555 A:e521  20 45 d6                           jsr crlf
  556 A:e524  60                                 rts 
  557 A:e525                           jmperror  
  557 A:e525                                    
  558 A:e525  4c 0a e4                           jmp error
  559 A:e528                                     .) 

  561 A:e528                           shortconvert 
  561 A:e528                                    
  562 A:e528                                     .( 
  563 A:e528                                    ; loop through the null-terminated string at (folderpointer)
  564 A:e528                                    ; and convert it to SHORT format.
  565 A:e528                                    ; ex. "file.xpl",0 --> "FILE    XPL"
  566 A:e528                                    ; check for . or ..
  567 A:e528  a0 00                              ldy #0
  568 A:e52a  b1 11                              lda (folderpointer),y
  569 A:e52c  c9 2e                              cmp #$2e
  570 A:e52e  f0 07                              beq dotf
  571 A:e530  a9 ff                              lda #$ff
  572 A:e532  85 18                              sta backdir
  573 A:e534  4c 49 e5                           jmp nopd
  574 A:e537                           dotf      
  574 A:e537                                    
  575 A:e537  c8                                 iny 
  576 A:e538  b1 11                              lda (folderpointer),y
  577 A:e53a  c9 2e                              cmp #$2e
  578 A:e53c  f0 05                              beq backdire
  579 A:e53e  a9 55                              lda #$55
  580 A:e540  85 18                              sta backdir
  581 A:e542  60                                 rts                    ; do nothing if "."
  582 A:e543                           backdire  
  582 A:e543                                    
  583 A:e543                                    ; ".." means go back
  584 A:e543  20 6d e3                           jsr backpath
  585 A:e546  64 18                              stz backdir
  586 A:e548                                    ;jsr refreshpath
  587 A:e548  60                                 rts 
  588 A:e549                           nopd      
  588 A:e549                                    
  589 A:e549  a0 18                              ldy #24
  590 A:e54b  a9 00                              lda #0
  591 A:e54d  91 11                              sta (folderpointer),y
  592 A:e54f  a9 15                              lda #21
  593 A:e551  85 14                              sta fileext
  594 A:e553  a0 00                              ldy #0
  595 A:e555                           shortlp   
  595 A:e555                                    
  596 A:e555  b1 11                              lda (folderpointer),y
  597 A:e557  f0 08                              beq nodot
  598 A:e559  c9 2e                              cmp #$2e             ; find the dot 
  599 A:e55b  f0 20                              beq extst
  600 A:e55d  c8                                 iny 
  601 A:e55e  4c 55 e5                           jmp shortlp
  602 A:e561                           nodot     
  603 A:e561                                    ; no dot, this is a folder
  604 A:e561                                    ; empty out the extension
  605 A:e561  84 19                              sty sc
  606 A:e563  18                                 clc 
  607 A:e564  a5 19                              lda sc
  608 A:e566  69 0d                              adc #13
  609 A:e568  85 19                              sta sc
  610 A:e56a  a9 0d                              lda #13
  611 A:e56c  85 14                              sta fileext
  612 A:e56e  a9 20                              lda #$20
  613 A:e570  a0 15                              ldy #21
  614 A:e572  91 11                              sta (folderpointer),y
  615 A:e574  c8                                 iny 
  616 A:e575  91 11                              sta (folderpointer),y
  617 A:e577  c8                                 iny 
  618 A:e578  91 11                              sta (folderpointer),y
  619 A:e57a  4c 9e e5                           jmp mvname                ; ok, go ahead and copy the name
  620 A:e57d                           extst     
  620 A:e57d                                    
  621 A:e57d  84 19                              sty sc                ; now move the file extension
  622 A:e57f                           ext       
  622 A:e57f                                    
  623 A:e57f  c8                                 iny 
  624 A:e580  b1 11                              lda (folderpointer),y
  625 A:e582  5a                                 phy 
  626 A:e583  a4 14                              ldy fileext
  627 A:e585  91 11                              sta (folderpointer),y
  628 A:e587  c8                                 iny 
  629 A:e588  84 14                              sty fileext
  630 A:e58a  c0 18                              cpy #24
  631 A:e58c  f0 04                              beq extd
  632 A:e58e  7a                                 ply 
  633 A:e58f  4c 7f e5                           jmp ext
  634 A:e592                           extd      
  634 A:e592                                    
  635 A:e592  7a                                 ply 
  636 A:e593  18                                 clc 
  637 A:e594  a5 19                              lda sc                ; add to sc
  638 A:e596  69 0d                              adc #13
  639 A:e598  85 19                              sta sc
  640 A:e59a  a9 0d                              lda #13
  641 A:e59c  85 14                              sta fileext
  642 A:e59e                           mvname    
  642 A:e59e                                    
  643 A:e59e                                    ; move name
  644 A:e59e  a0 00                              ldy #0
  645 A:e5a0                           mvlp      
  645 A:e5a0                                    
  646 A:e5a0  b1 11                              lda (folderpointer),y
  647 A:e5a2  5a                                 phy 
  648 A:e5a3  a4 14                              ldy fileext
  649 A:e5a5  c4 19                              cpy sc
  650 A:e5a7  f0 0a                              beq ad2sc
  651 A:e5a9  91 11                              sta (folderpointer),y
  652 A:e5ab  c8                                 iny 
  653 A:e5ac  84 14                              sty fileext
  654 A:e5ae  7a                                 ply 
  655 A:e5af  c8                                 iny 
  656 A:e5b0  4c a0 e5                           jmp mvlp
  657 A:e5b3                           ad2sc     
  657 A:e5b3                                    
  658 A:e5b3  7a                                 ply 
  659 A:e5b4  a4 19                              ldy sc
  660 A:e5b6                                    ; the file extention is moved, now pad spaces from the end of the name
  661 A:e5b6                                    ; to the start of the extension.
  662 A:e5b6                           fill      
  662 A:e5b6                                    
  663 A:e5b6  a9 20                              lda #$20
  664 A:e5b8  c0 15                              cpy #21
  665 A:e5ba  f0 07                              beq notfill
  666 A:e5bc                           filllp    
  666 A:e5bc                                    
  667 A:e5bc  91 11                              sta (folderpointer),y
  668 A:e5be  c8                                 iny 
  669 A:e5bf  c0 15                              cpy #21             ; stop if index is 20, we don't want to overwrite the file extension
  670 A:e5c1  d0 f9                              bne filllp
  671 A:e5c3                           notfill   
  672 A:e5c3                                    ; add 11 to folderpointer
  673 A:e5c3  18                                 clc 
  674 A:e5c4  a5 11                              lda folderpointer
  675 A:e5c6  69 0d                              adc #13
  676 A:e5c8  85 11                              sta folderpointer
  677 A:e5ca                                    ; now we need to convert lowercase to uppercase
  678 A:e5ca  a0 00                              ldy #0
  679 A:e5cc                           ldlp      
  679 A:e5cc                                    
  680 A:e5cc  b1 11                              lda (folderpointer),y
  681 A:e5ce  f0 10                              beq ldd                ; if null, stop.
  682 A:e5d0  c9 40                              cmp #$40             ; if numbers/symbols/space, skip.
  683 A:e5d2  90 08                              bcc dontl
  684 A:e5d4  c9 5f                              cmp #$5f             ; if _ skip
  685 A:e5d6  f0 04                              beq dontl
  686 A:e5d8  29 df                              and #$df             ; otherwise convert to uppercase
  687 A:e5da  91 11                              sta (folderpointer),y
  688 A:e5dc                           dontl     
  688 A:e5dc                                    
  689 A:e5dc  c8                                 iny 
  690 A:e5dd  4c cc e5                           jmp ldlp
  691 A:e5e0                           ldd       
  691 A:e5e0                                    
  692 A:e5e0                                    ; ok! now we have a SHORT formatted filename at (folderpointer).
  693 A:e5e0  60                                 rts 
  694 A:e5e1                                     .) 

  696 A:e5e1                           other     
  696 A:e5e1                                    
  697 A:e5e1                                    ; Write a letter of the filename currently being read
  698 A:e5e1  b1 48                              lda (zp_sd_address),y
  699 A:e5e3  09 20                              ora #$20             ; convert uppercase to lowercase
  700 A:e5e5  20 74 e0                           jsr print_chara
  701 A:e5e8  c8                                 iny 
  702 A:e5e9  60                                 rts 

  704 A:e5ea                                    ;; LS
  705 A:e5ea                                    ;; print a directory listing

  707 A:e5ea                           lscmd     
  707 A:e5ea                                    
  708 A:e5ea                                     .( 
  709 A:e5ea  ad 00 04                           lda path
  710 A:e5ed  d0 03                              bne cdf
  711 A:e5ef  4c 3b e3                           jmp patherr
  712 A:e5f2                           cdf       
  712 A:e5f2                                    
  713 A:e5f2                                    ;; check arguments
  714 A:e5f2  a5 20                              lda ARGINDEX
  715 A:e5f4  c9 02                              cmp #2             ; if there's two arguments, list the specified directory
  716 A:e5f6  f0 12                              beq processparam
  717 A:e5f8  a5 20                              lda ARGINDEX
  718 A:e5fa  c9 01                              cmp #1             ; if there's only one argument (ls) then list current directory 
  719 A:e5fc  d0 09                              bne jmperror
  720 A:e5fe                           ll        
  720 A:e5fe                                    
  721 A:e5fe  20 12 e0                           jsr fat32_open_cd
  722 A:e601  20 2c e6                           jsr list
  723 A:e604  4c 12 e0                           jmp fat32_open_cd
  724 A:e607                           jmperror  
  724 A:e607                                    
  725 A:e607  4c 0a e4                           jmp error
  726 A:e60a                           processparam                  ; process the filename parameter
  727 A:e60a  18                                 clc 
  728 A:e60b  a9 00                              lda #<INPUT
  729 A:e60d  65 22                              adc ARGINDEX+2
  730 A:e60f  85 11                              sta folderpointer
  731 A:e611  a9 02                              lda #>INPUT
  732 A:e613  85 12                              sta folderpointer+1
  733 A:e615  20 12 e4                           jsr stashpath
  734 A:e618  20 55 e2                           jsr resolvepath
  735 A:e61b  20 38 e4                           jsr cmppath
  736 A:e61e  b0 de                              bcs ll
  737 A:e620  20 10 e3                           jsr refreshpath
  738 A:e623  20 2c e6                           jsr list
  739 A:e626  20 25 e4                           jsr restorepath
  740 A:e629  4c 10 e3                           jmp refreshpath
  741 A:e62c                                     .) 

  743 A:e62c                           list      
  743 A:e62c                                    ; list file dir
  744 A:e62c                                     .( 
  745 A:e62c  20 ae de                           jsr fat32_readdirent                ; files?
  746 A:e62f  b0 47                              bcs nofiles
  747 A:e631                           ebut      
  747 A:e631                                    
  748 A:e631  a2 00                              ldx #0
  749 A:e633  a0 08                              ldy #8
  750 A:e635                           chklp     
  750 A:e635                                    
  751 A:e635  c0 0b                              cpy #11
  752 A:e637  f0 0b                              beq no
  753 A:e639  b1 48                              lda (zp_sd_address),y
  754 A:e63b  c9 20                              cmp #$20
  755 A:e63d  d0 01                              bne chky
  756 A:e63f  e8                                 inx 
  757 A:e640                           chky      
  757 A:e640                                    
  758 A:e640  c8                                 iny 
  759 A:e641  4c 35 e6                           jmp chklp
  760 A:e644                           no        
  760 A:e644                                    
  761 A:e644  e0 03                              cpx #3
  762 A:e646  d0 07                              bne arc
  763 A:e648                           dir       
  763 A:e648                                    
  764 A:e648  a9 ff                              lda #$ff
  765 A:e64a  85 15                              sta filetype                ; directorys show up as 
  766 A:e64c  4c 51 e6                           jmp name                ; yourfilename     test      folder  ...Etc
  767 A:e64f                           arc       
  767 A:e64f                                    
  768 A:e64f  64 15                              stz filetype                ; files show up as
  769 A:e651                           name      
  769 A:e651                                    ; test.xpl         music.xpl        file.bin  ...Etc
  770 A:e651                                    ; At this point, we know that there are no files, files, or a suddir
  771 A:e651                                    ; Now for the name
  772 A:e651  a0 00                              ldy #0
  773 A:e653                           nameloop  
  773 A:e653                                    
  774 A:e653  c0 08                              cpy #8
  775 A:e655  f0 06                              beq dot
  776 A:e657  20 e1 e5                           jsr other
  777 A:e65a  4c 53 e6                           jmp nameloop
  778 A:e65d                           dot       
  778 A:e65d                                    
  779 A:e65d  a5 15                              lda filetype
  780 A:e65f  d0 0f                              bne endthat                ; if it's a file,
  781 A:e661  a9 2e                              lda #$2e             ; shows its file extention
  782 A:e663  20 74 e0                           jsr print_chara
  783 A:e666                           lopii     
  783 A:e666                                    
  784 A:e666  c0 0b                              cpy #11
  785 A:e668  f0 06                              beq endthat                ; print 3-letter file extention
  786 A:e66a  20 e1 e5                           jsr other
  787 A:e66d  4c 66 e6                           jmp lopii
  788 A:e670                           endthat   
  788 A:e670                                    
  789 A:e670  a9 09                              lda #$09             ; Tab
  790 A:e672  20 74 e0                           jsr print_chara                ; tab
  791 A:e675  4c 2c e6                           jmp list                ; go again ; next file if there are any left
  792 A:e678                           nofiles   
  792 A:e678                                    ; if not,
  793 A:e678                           endlist   
  793 A:e678                                    ; exit listing code
  794 A:e678  20 45 d6                           jsr crlf
  795 A:e67b  60                                 rts 
  796 A:e67c                           jumptolist 
  796 A:e67c                                    
  797 A:e67c  20 45 d6                           jsr crlf
  798 A:e67f  4c 2c e6                           jmp list
  799 A:e682                                     .) 

  801 A:e682                                    ;; load
  802 A:e682                                    ;; Here we load a file from the SD card.
  803 A:e682                                    ;; .SAR stands for Start AddRess.

  805 A:e682                           loadcmd   
  806 A:e682                                     .( 
  807 A:e682  ad 00 04                           lda path
  808 A:e685  d0 03                              bne cdf
  809 A:e687  4c 3b e3                           jmp patherr
  810 A:e68a                           cdf       
  810 A:e68a                                    
  811 A:e68a                                    ;; check arguments
  812 A:e68a  a5 20                              lda ARGINDEX
  813 A:e68c  c9 02                              cmp #2             ; if there's two arguments, load the specified file
  814 A:e68e  f0 0e                              beq lprocessparam
  815 A:e690  a5 20                              lda ARGINDEX
  816 A:e692  c9 01                              cmp #1             ; if there's only one argument, do a handeler load.
  817 A:e694  f0 5b                              beq loadone
  818 A:e696                                     .) 
  819 A:e696                           lderror   
  819 A:e696                                    
  820 A:e696  a2 d6                              ldx #<foldermsg              ; if it was not found, error and return.
  821 A:e698  a0 e9                              ldy #>foldermsg
  822 A:e69a  20 85 e0                           jsr w_acia_full
  823 A:e69d  60                                 rts 
  824 A:e69e                           lprocessparam                  ; the user specified a file, process the filename parameter.
  825 A:e69e  18                                 clc 
  826 A:e69f  a9 00                              lda #<INPUT
  827 A:e6a1  65 22                              adc ARGINDEX+2
  828 A:e6a3  85 11                              sta folderpointer
  829 A:e6a5  a9 02                              lda #>INPUT              ; argument buffer under 256 bytes, so no adc #0.
  830 A:e6a7  85 12                              sta folderpointer+1
  831 A:e6a9                           loadlc    
  831 A:e6a9                                    
  832 A:e6a9                                     .( 
  833 A:e6a9                                    ; convert string
  834 A:e6a9  20 28 e5                           jsr shortconvert
  835 A:e6ac                                    ; is this a .XPL file?
  836 A:e6ac  a0 08                              ldy #$08
  837 A:e6ae  b1 11                              lda (folderpointer),y
  838 A:e6b0  c9 58                              cmp #'X'
  839 A:e6b2  d0 14                              bne ldp
  840 A:e6b4  c8                                 iny 
  841 A:e6b5  b1 11                              lda (folderpointer),y
  842 A:e6b7  c9 50                              cmp #'P'
  843 A:e6b9  d0 0d                              bne ldp
  844 A:e6bb  c8                                 iny 
  845 A:e6bc  b1 11                              lda (folderpointer),y
  846 A:e6be  c9 4c                              cmp #'L'
  847 A:e6c0  d0 06                              bne ldp
  848 A:e6c2  9c 04 07                           stz buffer+4
  849 A:e6c5  4c cd e6                           jmp ldp2
  850 A:e6c8                           ldp       
  850 A:e6c8                                    
  851 A:e6c8  a9 ff                              lda #$ff
  852 A:e6ca  8d 04 07                           sta buffer+4
  853 A:e6cd                           ldp2      
  853 A:e6cd                                    
  854 A:e6cd                                     .) 
  855 A:e6cd                           loadpath  
  855 A:e6cd                                    
  856 A:e6cd                                     .( 
  857 A:e6cd                                    ; Refresh
  858 A:e6cd  20 12 e0                           jsr fat32_open_cd
  859 A:e6d0                                    ; Loading..
  860 A:e6d0  a2 86                              ldx #<loading_msg
  861 A:e6d2  a0 cb                              ldy #>loading_msg
  862 A:e6d4  20 85 e0                           jsr w_acia_full
  863 A:e6d7                                    ; BUG i need to add a start address header to the .XPL file format...
  864 A:e6d7                                    ; at the moment it is assumed that the file will load and run at $0F00
  865 A:e6d7  9c 00 07                           stz buffer
  866 A:e6da  9c 02 07                           stz buffer+2
  867 A:e6dd  a9 0f                              lda #$0f             ; $0F00
  868 A:e6df  8d 01 07                           sta buffer+1
  869 A:e6e2  8d 03 07                           sta buffer+3
  870 A:e6e5  a6 11                              ldx folderpointer
  871 A:e6e7  a4 12                              ldy folderpointer+1          ; find the file
  872 A:e6e9  20 e4 de                           jsr fat32_finddirent
  873 A:e6ec  90 47                              bcc loadfoundcode
  874 A:e6ee  4c 96 e6                           jmp lderror
  875 A:e6f1                                     .) 
  876 A:e6f1                           loadone   
  876 A:e6f1                                    
  877 A:e6f1                                     .( 
  878 A:e6f1                                    ; the user has not specified a filename, so load the SD card handeler program.

  880 A:e6f1  20 83 e7                           jsr loadf

  882 A:e6f4                                    ; Find file by name
  883 A:e6f4  a2 34                              ldx #<loadname
  884 A:e6f6  a0 e2                              ldy #>loadname              ; this is LOADADDR.SAR, which is what I plan 
  885 A:e6f8  20 e4 de                           jsr fat32_finddirent                ; to merge into a header of .XPL files.
  886 A:e6fb  90 0a                              bcc foundfile                ; it holds the load address and jump address
  887 A:e6fd                                    ; of CODE.XPL.
  888 A:e6fd                                    ; File not found
  889 A:e6fd  a0 e9                              ldy #>filmsg
  890 A:e6ff  a2 5a                              ldx #<filmsg
  891 A:e701  20 85 e0                           jsr w_acia_full
  892 A:e704  4c a8 e0                           jmp error_sound

  894 A:e707                           foundfile 

  896 A:e707                                    ; Open file
  897 A:e707  20 5d dd                           jsr fat32_opendirent

  899 A:e70a                                    ; Read file contents into buffer
  900 A:e70a  a9 00                              lda #<buffer
  901 A:e70c  85 5c                              sta fat32_address
  902 A:e70e  a9 07                              lda #>buffer
  903 A:e710  85 5d                              sta fat32_address+1

  905 A:e712  20 a3 df                           jsr fat32_file_read

  907 A:e715  9c 04 07                           stz buffer+4

  909 A:e718  20 83 e7                           jsr loadf                ; BUG really?

  911 A:e71b  a0 e9                              ldy #>lds
  912 A:e71d  a2 8e                              ldx #<lds
  913 A:e71f  20 85 e0                           jsr w_acia_full

  915 A:e722  a2 29                              ldx #<filename              ; CODE.XPL is the sd card's loader
  916 A:e724  a0 e2                              ldy #>filename
  917 A:e726  20 e4 de                           jsr fat32_finddirent
  918 A:e729  90 0a                              bcc loadfoundcode

  920 A:e72b  a0 e9                              ldy #>filmsg2
  921 A:e72d  a2 76                              ldx #<filmsg2
  922 A:e72f  20 85 e0                           jsr w_acia_full
  923 A:e732  4c a8 e0                           jmp error_sound
  924 A:e735                                     .) 
  925 A:e735                           loadfoundcode 
  926 A:e735                                     .( 
  927 A:e735                                    ; backup file size 
  928 A:e735  a0 1c                              ldy #28
  929 A:e737  b1 48                              lda (zp_sd_address),y
  930 A:e739  18                                 clc 
  931 A:e73a  6d 00 07                           adc buffer
  932 A:e73d  48                                 pha 
  933 A:e73e  c8                                 iny 
  934 A:e73f  b1 48                              lda (zp_sd_address),y
  935 A:e741  6d 01 07                           adc buffer+1
  936 A:e744  48                                 pha 

  938 A:e745  20 5d dd                           jsr fat32_opendirent                ; open the file

  940 A:e748  ad 00 07                           lda buffer                ; and load it to the address
  941 A:e74b  85 5c                              sta fat32_address                ; from LOADADDR.SAR
  942 A:e74d  ad 01 07                           lda buffer+1
  943 A:e750  85 5d                              sta fat32_address+1

  945 A:e752  20 a3 df                           jsr fat32_file_read

  947 A:e755                                    ; All done.

  949 A:e755                                    ;ldy #>ends
  950 A:e755                                    ;ldx #<ends
  951 A:e755                                    ;jsr w_acia_full
  952 A:e755  a2 a5                              ldx #<loadedmsg
  953 A:e757  a0 cb                              ldy #>loadedmsg
  954 A:e759  20 85 e0                           jsr w_acia_full
  955 A:e75c  ad 01 07                           lda buffer+1
  956 A:e75f  20 4a e0                           jsr print_hex_acia
  957 A:e762  ad 00 07                           lda buffer
  958 A:e765  20 4a e0                           jsr print_hex_acia
  959 A:e768  a2 b2                              ldx #<tomsg
  960 A:e76a  a0 cb                              ldy #>tomsg
  961 A:e76c  20 85 e0                           jsr w_acia_full
  962 A:e76f  68                                 pla 
  963 A:e770  20 4a e0                           jsr print_hex_acia
  964 A:e773  68                                 pla 
  965 A:e774  20 4a e0                           jsr print_hex_acia
  966 A:e777  20 45 d6                           jsr crlf

  968 A:e77a                                    ; Is this a XPL file?
  969 A:e77a  ad 04 07                           lda buffer+4
  970 A:e77d  d0 03                              bne lo

  972 A:e77f  6c 02 07                           jmp (buffer+2)        ; jump to start address from LOADADDR

  974 A:e782                           lo        
  974 A:e782                                    
  975 A:e782  60                                 rts 
  976 A:e783                                     .) 

  978 A:e783                           loadf     
  978 A:e783                                    
  979 A:e783                                    ; Open root directory
  980 A:e783  20 f7 db                           jsr fat32_openroot

  982 A:e786                                    ; Find subdirectory by name
  983 A:e786  a2 1e                              ldx #<subdirname
  984 A:e788  a0 e2                              ldy #>subdirname
  985 A:e78a  20 e4 de                           jsr fat32_finddirent
  986 A:e78d  90 0a                              bcc foundsubdir

  988 A:e78f                                    ; Subdirectory not found
  989 A:e78f  a0 e9                              ldy #>submsg
  990 A:e791  a2 48                              ldx #<submsg
  991 A:e793  20 85 e0                           jsr w_acia_full
  992 A:e796  4c a8 e0                           jmp error_sound

  994 A:e799                           foundsubdir 

  996 A:e799                                    ; Open subdirectory
  997 A:e799  4c 5d dd                           jmp fat32_opendirent

  999 A:e79c                           savecmd   
  999 A:e79c                                    
 1000 A:e79c                                     .( 
 1001 A:e79c                                    ; Save a file.
 1002 A:e79c  da                                 phx 
 1003 A:e79d  ad 00 04                           lda path
 1004 A:e7a0  d0 03                              bne sv
 1005 A:e7a2  4c 3b e3                           jmp patherr
 1006 A:e7a5                           sv        
 1006 A:e7a5                                    
 1007 A:e7a5  a5 20                              lda ARGINDEX
 1008 A:e7a7  c9 04                              cmp #4
 1009 A:e7a9  f0 03                              beq proc
 1010 A:e7ab  4c 0a e4                           jmp error
 1011 A:e7ae                           proc      
 1011 A:e7ae                                    
 1012 A:e7ae                                    ; filename
 1013 A:e7ae  18                                 clc 
 1014 A:e7af  a9 00                              lda #<INPUT
 1015 A:e7b1  65 24                              adc ARGINDEX+4
 1016 A:e7b3  85 11                              sta folderpointer
 1017 A:e7b5  a9 02                              lda #>INPUT
 1018 A:e7b7  85 12                              sta folderpointer+1
 1019 A:e7b9                                    ; convert it to SHORT
 1020 A:e7b9  20 28 e5                           jsr shortconvert
 1021 A:e7bc  a5 11                              lda folderpointer
 1022 A:e7be  85 1c                              sta savepoint
 1023 A:e7c0  a5 12                              lda folderpointer+1
 1024 A:e7c2  85 1d                              sta savepoint+1
 1025 A:e7c4                                    ; second addr parameter
 1026 A:e7c4  18                                 clc 
 1027 A:e7c5  a9 00                              lda #<INPUT
 1028 A:e7c7  65 23                              adc ARGINDEX+3
 1029 A:e7c9  85 80                              sta stackaccess
 1030 A:e7cb  a9 02                              lda #>INPUT
 1031 A:e7cd  85 81                              sta stackaccess+1
 1032 A:e7cf  20 db c0                           jsr push16
 1033 A:e7d2  20 76 c2                           jsr read16hex
 1034 A:e7d5                                    ; first address parameter
 1035 A:e7d5  18                                 clc 
 1036 A:e7d6  a9 00                              lda #<INPUT
 1037 A:e7d8  65 22                              adc ARGINDEX+2
 1038 A:e7da  85 80                              sta stackaccess
 1039 A:e7dc  a9 02                              lda #>INPUT
 1040 A:e7de  85 81                              sta stackaccess+1
 1041 A:e7e0  20 db c0                           jsr push16
 1042 A:e7e3  20 76 c2                           jsr read16hex
 1043 A:e7e6                                    ; stash them
 1044 A:e7e6  20 e6 c0                           jsr pop16
 1045 A:e7e9  a5 80                              lda stackaccess
 1046 A:e7eb  85 1a                              sta savestart
 1047 A:e7ed  a5 81                              lda stackaccess+1
 1048 A:e7ef  85 1b                              sta savestart+1
 1049 A:e7f1  20 e6 c0                           jsr pop16
 1050 A:e7f4  a5 80                              lda stackaccess
 1051 A:e7f6  85 10                              sta saveend
 1052 A:e7f8  a5 81                              lda stackaccess+1
 1053 A:e7fa  85 11                              sta saveend+1
 1054 A:e7fc  4c 00 e8                           jmp sg
 1055 A:e7ff                                     .) 
 1056 A:e7ff                           savekernal 
 1056 A:e7ff                                    
 1057 A:e7ff  da                                 phx 
 1058 A:e800                           sg        
 1058 A:e800                                    
 1059 A:e800                                     .( 
 1060 A:e800                                    ; now lets begin 
 1061 A:e800                                    ; Refresh PATH
 1062 A:e800  20 10 e3                           jsr refreshpath
 1063 A:e803                                    ; Open the filename
 1064 A:e803  a6 1c                              ldx savepoint
 1065 A:e805  a4 1d                              ldy savepoint+1
 1066 A:e807                                    ; Check if the file exists
 1067 A:e807  20 e4 de                           jsr fat32_finddirent
 1068 A:e80a  90 03                              bcc fileexists
 1069 A:e80c  4c 2b e8                           jmp nf
 1070 A:e80f                           fileexists 
 1070 A:e80f                                    
 1071 A:e80f                                    ; If so, ask the user if they would like to overwrite the file.
 1072 A:e80f  a2 b6                              ldx #<femsg
 1073 A:e811  a0 e9                              ldy #>femsg
 1074 A:e813  20 85 e0                           jsr w_acia_full
 1075 A:e816  20 a4 f5                           jsr rxpoll
 1076 A:e819  ad 00 80                           lda $8000
 1077 A:e81c  c9 79                              cmp #'y'             ; response = 'y'?
 1078 A:e81e  f0 05                              beq yes
 1079 A:e820  20 45 d6                           jsr crlf                ; no, cancel save
 1080 A:e823  fa                                 plx 
 1081 A:e824  60                                 rts 
 1082 A:e825                           yes       
 1083 A:e825                                    ; we would like to overwrite the file.
 1084 A:e825  20 45 d6                           jsr crlf
 1085 A:e828                                    ; delete it to clean the FAT
 1086 A:e828  20 24 df                           jsr fat32_deletefile
 1087 A:e82b                           nf        
 1087 A:e82b                                    
 1088 A:e82b                                    ;jsr fat32_open_cd
 1089 A:e82b  a2 a4                              ldx #<savemsg
 1090 A:e82d  a0 e9                              ldy #>savemsg
 1091 A:e82f  20 85 e0                           jsr w_acia_full
 1092 A:e832                                    ; Calculate file size (end - start)
 1093 A:e832  38                                 sec 
 1094 A:e833  a5 10                              lda saveend
 1095 A:e835  e5 1a                              sbc savestart
 1096 A:e837  85 62                              sta fat32_bytesremaining
 1097 A:e839  48                                 pha 
 1098 A:e83a  a5 11                              lda saveend+1
 1099 A:e83c  e5 1b                              sbc savestart+1
 1100 A:e83e  85 63                              sta fat32_bytesremaining+1
 1101 A:e840  48                                 pha 
 1102 A:e841                                    ; Allocate all the clusters for this file
 1103 A:e841  20 44 dc                           jsr fat32_allocatefile
 1104 A:e844                                    ; Refresh
 1105 A:e844  20 10 e3                           jsr refreshpath
 1106 A:e847                                    ; Put the filename at fat32_filenamepointer
 1107 A:e847  a5 1c                              lda savepoint
 1108 A:e849  85 6a                              sta fat32_filenamepointer
 1109 A:e84b  a5 1d                              lda savepoint+1
 1110 A:e84d  85 6b                              sta fat32_filenamepointer+1
 1111 A:e84f  68                                 pla 
 1112 A:e850  85 63                              sta fat32_bytesremaining+1
 1113 A:e852  68                                 pla 
 1114 A:e853  85 62                              sta fat32_bytesremaining
 1115 A:e855                                    ; Write a directory entry for this file
 1116 A:e855  20 c5 dd                           jsr fat32_writedirent
 1117 A:e858                                    ; Now, to actually write the file...
 1118 A:e858  a5 1a                              lda savestart
 1119 A:e85a  85 5c                              sta fat32_address
 1120 A:e85c  a5 1b                              lda savestart+1
 1121 A:e85e  85 5d                              sta fat32_address+1
 1122 A:e860  20 c3 df                           jsr fat32_file_write
 1123 A:e863                                    ; All Done!
 1124 A:e863  a2 ae                              ldx #<ends
 1125 A:e865  a0 e9                              ldy #>ends
 1126 A:e867  20 85 e0                           jsr w_acia_full
 1127 A:e86a                           saveexit  
 1127 A:e86a                                    
 1128 A:e86a  fa                                 plx 
 1129 A:e86b  60                                 rts 
 1130 A:e86c                                     .) 

 1132 A:e86c                           rmcmd     
 1132 A:e86c                                    
 1133 A:e86c                                     .( 
 1134 A:e86c                                    ; Remove a file
 1135 A:e86c  da                                 phx 
 1136 A:e86d  ad 00 04                           lda path
 1137 A:e870  d0 03                              bne rm
 1138 A:e872  4c 3b e3                           jmp patherr
 1139 A:e875                           rm        
 1139 A:e875                                    
 1140 A:e875                                    ;; check arguments
 1141 A:e875  a5 20                              lda ARGINDEX
 1142 A:e877  c9 02                              cmp #2             ; if there's two arguments, load the specified file
 1143 A:e879  f0 03                              beq proc
 1144 A:e87b  4c 0a e4                           jmp error
 1145 A:e87e                           proc      
 1145 A:e87e                                    
 1146 A:e87e                                    ; filename
 1147 A:e87e  18                                 clc 
 1148 A:e87f  a9 00                              lda #<INPUT
 1149 A:e881  65 22                              adc ARGINDEX+2
 1150 A:e883  85 11                              sta folderpointer
 1151 A:e885  a9 02                              lda #>INPUT
 1152 A:e887  85 12                              sta folderpointer+1
 1153 A:e889                                    ; convert it to SHORT
 1154 A:e889  20 28 e5                           jsr shortconvert
 1155 A:e88c  a5 11                              lda folderpointer
 1156 A:e88e  85 1c                              sta savepoint
 1157 A:e890  a5 12                              lda folderpointer+1
 1158 A:e892  85 1d                              sta savepoint+1
 1159 A:e894                                    ; path refresh
 1160 A:e894  20 12 e0                           jsr fat32_open_cd
 1161 A:e897                                    ; load
 1162 A:e897  a6 1c                              ldx savepoint
 1163 A:e899  a4 1d                              ldy savepoint+1
 1164 A:e89b                                    ; find it
 1165 A:e89b  20 e4 de                           jsr fat32_finddirent
 1166 A:e89e  90 05                              bcc foundfile
 1167 A:e8a0  20 44 e3                           jsr rlerror
 1168 A:e8a3  fa                                 plx 
 1169 A:e8a4  60                                 rts 
 1170 A:e8a5                           foundfile 
 1170 A:e8a5                                    
 1171 A:e8a5  20 24 df                           jsr fat32_deletefile
 1172 A:e8a8                                    ; done
 1173 A:e8a8  fa                                 plx 
 1174 A:e8a9  60                                 rts 
 1175 A:e8aa                                     .) 

 1177 A:e8aa                           mvcmd     
 1177 A:e8aa                                    
 1178 A:e8aa                                     .( 
 1179 A:e8aa                                    ; Move a file.
 1180 A:e8aa  da                                 phx 
 1181 A:e8ab  ad 00 04                           lda path
 1182 A:e8ae  d0 03                              bne mv
 1183 A:e8b0  4c 3b e3                           jmp patherr
 1184 A:e8b3                           mv        
 1184 A:e8b3                                    
 1185 A:e8b3                                    ;; check arguments
 1186 A:e8b3  a5 20                              lda ARGINDEX
 1187 A:e8b5  c9 03                              cmp #3
 1188 A:e8b7  f0 03                              beq proc
 1189 A:e8b9  4c 0a e4                           jmp error
 1190 A:e8bc                           proc      
 1190 A:e8bc                                    
 1191 A:e8bc                                    ; fetch first filename
 1192 A:e8bc  18                                 clc 
 1193 A:e8bd  a9 00                              lda #<INPUT
 1194 A:e8bf  65 22                              adc ARGINDEX+2
 1195 A:e8c1  85 11                              sta folderpointer
 1196 A:e8c3  a9 02                              lda #>INPUT
 1197 A:e8c5  85 12                              sta folderpointer+1
 1198 A:e8c7  20 33 e9                           jsr overf
 1199 A:e8ca                                    ; convert it to SHORT
 1200 A:e8ca  20 28 e5                           jsr shortconvert
 1201 A:e8cd  a5 11                              lda folderpointer
 1202 A:e8cf  85 1c                              sta savepoint
 1203 A:e8d1  a5 12                              lda folderpointer+1
 1204 A:e8d3  85 1d                              sta savepoint+1
 1205 A:e8d5                                    ; path refresh
 1206 A:e8d5  20 12 e0                           jsr fat32_open_cd
 1207 A:e8d8                                    ; load
 1208 A:e8d8  a6 1c                              ldx savepoint
 1209 A:e8da  a4 1d                              ldy savepoint+1
 1210 A:e8dc                                    ; find it
 1211 A:e8dc  20 e4 de                           jsr fat32_finddirent
 1212 A:e8df  90 03                              bcc gotit
 1213 A:e8e1  4c 0e e9                           jmp mvfail
 1214 A:e8e4                           gotit     
 1214 A:e8e4                                    
 1215 A:e8e4                                    ; carry already clear
 1216 A:e8e4                                    ; get the folder to move it to
 1217 A:e8e4  a9 00                              lda #<INPUT
 1218 A:e8e6  65 23                              adc ARGINDEX+3
 1219 A:e8e8  85 11                              sta folderpointer
 1220 A:e8ea  a9 02                              lda #>INPUT
 1221 A:e8ec  85 12                              sta folderpointer+1
 1222 A:e8ee  20 33 e9                           jsr overf
 1223 A:e8f1                                    ; convert it to SHORT
 1224 A:e8f1  20 28 e5                           jsr shortconvert
 1225 A:e8f4  a5 11                              lda folderpointer
 1226 A:e8f6  85 1c                              sta savepoint
 1227 A:e8f8  a5 12                              lda folderpointer+1
 1228 A:e8fa  85 1d                              sta savepoint+1
 1229 A:e8fc                                    ; Now, for the copy
 1230 A:e8fc                                    ; Store the dirent temporaraly
 1231 A:e8fc  a0 00                              ldy #0
 1232 A:e8fe                           stlp      
 1233 A:e8fe  b1 48                              lda (zp_sd_address),y
 1234 A:e900  99 00 02                           sta INPUT,y
 1235 A:e903  c8                                 iny 
 1236 A:e904  c0 20                              cpy #$20
 1237 A:e906  d0 f6                              bne stlp
 1238 A:e908                                    ; Now, mark it as a deleted file
 1239 A:e908  20 fb de                           jsr fat32_markdeleted
 1240 A:e90b  20 12 e0                           jsr fat32_open_cd
 1241 A:e90e                                    ; Find the directory
 1242 A:e90e                                    ;lda backdir
 1243 A:e90e                                    ;beq nono ;TODO CHECK
 1244 A:e90e                                    ;nono
 1244 A:e90e                                    
 1245 A:e90e                                    ;  ldx savepoint
 1246 A:e90e                                    ;  ldy savepoint+1
 1247 A:e90e                                    ;  jsr fat32_finddirent
 1248 A:e90e                                    ;  bcc mvgotdirent 
 1249 A:e90e                           mvfail    
 1250 A:e90e                                    ; The directory was not found
 1251 A:e90e  20 44 e3                           jsr rlerror
 1252 A:e911  fa                                 plx 
 1253 A:e912  60                                 rts 
 1254 A:e913                           mvgotdirent 
 1255 A:e913                                    ; It was, open it.
 1256 A:e913  20 5d dd                           jsr fat32_opendirent
 1257 A:e916                                    ; Ok. now we need to find a free entry
 1258 A:e916                           mvlp      
 1259 A:e916  20 ae de                           jsr fat32_readdirent
 1260 A:e919  90 fb                              bcc mvlp
 1261 A:e91b                                    ; Got it. now paste the file here
 1262 A:e91b  a0 00                              ldy #0
 1263 A:e91d                           mvpaste   
 1264 A:e91d  b9 00 02                           lda INPUT,y
 1265 A:e920  91 48                              sta (zp_sd_address),y
 1266 A:e922  c8                                 iny 
 1267 A:e923  c0 20                              cpy #$20
 1268 A:e925  d0 f6                              bne mvpaste
 1269 A:e927                                    ; Just to be sure, zero out the next entry.
 1270 A:e927  a9 00                              lda #0
 1271 A:e929  91 48                              sta (zp_sd_address),y
 1272 A:e92b                                    ; Now write the sector
 1273 A:e92b  20 84 de                           jsr fat32_wrcurrent
 1274 A:e92e                                    ; Done!
 1275 A:e92e  20 10 e3                           jsr refreshpath
 1276 A:e931  fa                                 plx 
 1277 A:e932  60                                 rts 
 1278 A:e933                           overf     
 1278 A:e933                                    
 1279 A:e933                                    ; copy it to the buffer so we don't overwrite the foldername
 1280 A:e933  a0 00                              ldy #0
 1281 A:e935                           mvff      
 1282 A:e935  b1 11                              lda (folderpointer),y
 1283 A:e937  99 18 03                           sta fnstash,y
 1284 A:e93a  c8                                 iny 
 1285 A:e93b  c0 0d                              cpy #13
 1286 A:e93d  d0 f6                              bne mvff
 1287 A:e93f                           mvdn      
 1287 A:e93f                                    
 1288 A:e93f                                    ; store location
 1289 A:e93f  a9 18                              lda #<fnstash
 1290 A:e941  85 11                              sta folderpointer
 1291 A:e943  a9 03                              lda #>fnstash
 1292 A:e945  85 12                              sta folderpointer+1
 1293 A:e947  60                                 rts 
 1294 A:e948                                     .) 

 1296 A:e948                           submsg    
 1297 A:e948  52 6f 6f 74 20 4e 6f ...           .byt "Root Not Found!",$0d,$0a,$00
 1298 A:e95a                           filmsg    
 1299 A:e95a  27 6c 6f 61 64 61 64 ...           .byt "'loadaddr.sar' Not Found!",$0d,$0a,$00
 1300 A:e976                           filmsg2   
 1301 A:e976  27 63 6f 64 65 2e 78 ...           .byt "'code.xpl' Not Found!",$0d,$0a,$00
 1302 A:e98e                           lds       
 1303 A:e98e  4c 6f 61 64 69 6e 67 ...           .byt "Loading SD Handler...",$00
 1304 A:e9a4                           savemsg   
 1304 A:e9a4                                    
 1305 A:e9a4  53 61 76 69 6e 67 2e ...           .byt "Saving...",$00
 1306 A:e9ae                           ends      
 1307 A:e9ae  44 6f 6e 65 2e 0d 0a 00            .byt "Done.",$0d,$0a,$00
 1308 A:e9b6                           femsg     
 1308 A:e9b6                                    
 1309 A:e9b6  46 69 6c 65 20 65 78 ...           .byt "File exists. Overwrite? (y/n): ",$00
 1310 A:e9d6                           foldermsg 
 1310 A:e9d6                                    
 1311 A:e9d6  4e 6f 20 73 75 63 68 ...           .byt "No such file or directory.",$0d,$0a,$00

 1313 A:e9f3                                    ; THE FOLLOWING MESSAGES ARE ALREADY IN TAPE.A65!
 1314 A:e9f3                                    ;loadedmsg
 1314 A:e9f3                                    
 1315 A:e9f3                                    ;  .byte "Loaded from ", $00
 1316 A:e9f3                                    ;tomsg
 1316 A:e9f3                                    
 1317 A:e9f3                                    ;  .byte " to ", $00

main.a65


 2648 A:e9f3                                    ; goofy ahh fake vi

vi65s.a65

    1 A:e9f3                                    ; VI
    2 A:e9f3                                    ; requires xplDOS
    3 A:e9f3                                    ;

    5 A:e9f3                           vicmd     
    5 A:e9f3                                    
    6 A:e9f3                                     .( 
    7 A:e9f3  da                                 phx 
    8 A:e9f4  20 61 e0                           jsr cleardisplay
    9 A:e9f7  a9 0f                              lda #$0f
   10 A:e9f9  20 74 e0                           jsr print_chara
   11 A:e9fc  a9 18                              lda #24
   12 A:e9fe  20 74 e0                           jsr print_chara
   13 A:ea01  a9 02                              lda #$02
   14 A:ea03  20 74 e0                           jsr print_chara
   15 A:ea06  a9 00                              lda #0
   16 A:ea08  20 74 e0                           jsr print_chara
   17 A:ea0b                                    ;; check arguments
   18 A:ea0b  a5 20                              lda ARGINDEX
   19 A:ea0d  c9 02                              cmp #2             ; if there's two arguments, edit the typed file
   20 A:ea0f  f0 0c                              beq processparam
   21 A:ea11  a5 20                              lda ARGINDEX
   22 A:ea13  c9 01                              cmp #1             ; if there's only one argument, edit an unnamed file
   23 A:ea15  d0 03                              bne jer
   24 A:ea17  4c 8a ea                           jmp vnf
   25 A:ea1a                           jer       
   25 A:ea1a                                    
   26 A:ea1a  4c 0a e4                           jmp error
   27 A:ea1d                           processparam                  ; process the filename parameter
   28 A:ea1d  18                                 clc 
   29 A:ea1e  a9 00                              lda #<INPUT
   30 A:ea20  65 22                              adc ARGINDEX+2
   31 A:ea22  85 11                              sta folderpointer
   32 A:ea24  aa                                 tax 
   33 A:ea25  a0 02                              ldy #>INPUT
   34 A:ea27  84 12                              sty folderpointer+1
   35 A:ea29  da                                 phx 
   36 A:ea2a  5a                                 phy 
   37 A:ea2b                                    ; print filename
   38 A:ea2b  a9 22                              lda #$22
   39 A:ea2d  20 74 e0                           jsr print_chara
   40 A:ea30  7a                                 ply 
   41 A:ea31  fa                                 plx 
   42 A:ea32  20 85 e0                           jsr w_acia_full
   43 A:ea35  a9 22                              lda #$22
   44 A:ea37  20 74 e0                           jsr print_chara
   45 A:ea3a  a9 20                              lda #$20
   46 A:ea3c  20 74 e0                           jsr print_chara
   47 A:ea3f                                    ; convert to SHORT
   48 A:ea3f  20 28 e5                           jsr shortconvert
   49 A:ea42                                    ; refresh
   50 A:ea42  20 10 e3                           jsr refreshpath
   51 A:ea45                                    ; chech if the file exists
   52 A:ea45  a6 11                              ldx folderpointer
   53 A:ea47  a4 12                              ldy folderpointer+1
   54 A:ea49  20 e4 de                           jsr fat32_finddirent
   55 A:ea4c  b0 3c                              bcs vnf
   56 A:ea4e                                    ; if it exists, load it to $0900
   57 A:ea4e                                    ; WARNING this will overwrite RAM! 
   58 A:ea4e  20 5d dd                           jsr fat32_opendirent
   59 A:ea51  a9 09                              lda #$09
   60 A:ea53  85 5d                              sta fat32_address+1
   61 A:ea55  64 5c                              stz fat32_address
   62 A:ea57  20 a3 df                           jsr fat32_file_read
   63 A:ea5a                                    ; now print first part to screen
   64 A:ea5a                                    ; BUG files can go past the screen limit, and glitch the viewer.
   65 A:ea5a  20 7d e0                           jsr ascii_home
   66 A:ea5d  a2 00                              ldx #0
   67 A:ea5f  a0 00                              ldy #0
   68 A:ea61  64 1a                              stz viaddr
   69 A:ea63  a9 09                              lda #$09
   70 A:ea65  85 1b                              sta viaddr+1
   71 A:ea67                           vcplp     
   71 A:ea67                                    
   72 A:ea67  b2 1a                              lda (viaddr)
   73 A:ea69  f0 28                              beq veof
   74 A:ea6b  c9 0d                              cmp #$0d
   75 A:ea6d  f0 15                              beq cr
   76 A:ea6f  c8                                 iny 
   77 A:ea70  c0 50                              cpy #80
   78 A:ea72  f0 10                              beq cr
   79 A:ea74                           otherv    
   79 A:ea74                                    
   80 A:ea74  20 74 e0                           jsr print_chara
   81 A:ea77  f0 3a                              beq startcsr                ; file displayed, no eof yet
   82 A:ea79  e6 1a                              inc viaddr
   83 A:ea7b  a5 1a                              lda viaddr
   84 A:ea7d  d0 02                              bne nnon
   85 A:ea7f  e6 1b                              inc viaddr+1
   86 A:ea81                           nnon      
   86 A:ea81                                    
   87 A:ea81  4c 67 ea                           jmp vcplp
   88 A:ea84                           cr        
   88 A:ea84                                    
   89 A:ea84  e8                                 inx 
   90 A:ea85  a0 00                              ldy #0
   91 A:ea87  4c 74 ea                           jmp otherv
   92 A:ea8a                           vnf       
   92 A:ea8a                                    
   93 A:ea8a  a2 22                              ldx #<nfm
   94 A:ea8c  a0 eb                              ldy #>nfm
   95 A:ea8e  20 85 e0                           jsr w_acia_full
   96 A:ea91  a2 00                              ldx #0
   97 A:ea93                           veof      
   97 A:ea93                                    
   98 A:ea93                                    ; eof reached. fill the screen with ~
   99 A:ea93  e8                                 inx 
  100 A:ea94  86 1e                              stx vif_end
  101 A:ea96                           vinlp     
  101 A:ea96                                    
  102 A:ea96  a9 0f                              lda #$0f
  103 A:ea98  20 74 e0                           jsr print_chara
  104 A:ea9b  8a                                 txa 
  105 A:ea9c  20 74 e0                           jsr print_chara
  106 A:ea9f  a9 0e                              lda #$0e
  107 A:eaa1  20 74 e0                           jsr print_chara
  108 A:eaa4  a9 00                              lda #0
  109 A:eaa6  20 74 e0                           jsr print_chara
  110 A:eaa9  a9 7e                              lda #'~'
  111 A:eaab  20 74 e0                           jsr print_chara
  112 A:eaae  e8                                 inx 
  113 A:eaaf  e0 18                              cpx #24
  114 A:eab1  d0 e3                              bne vinlp
  115 A:eab3                           startcsr  
  115 A:eab3                                    
  116 A:eab3  a9 0e                              lda #$0e
  117 A:eab5  20 74 e0                           jsr print_chara
  118 A:eab8  a9 46                              lda #70
  119 A:eaba  20 74 e0                           jsr print_chara
  120 A:eabd  a9 0f                              lda #$0f
  121 A:eabf  20 74 e0                           jsr print_chara
  122 A:eac2  a9 18                              lda #24
  123 A:eac4  20 74 e0                           jsr print_chara
  124 A:eac7  a9 30                              lda #'0'
  125 A:eac9  20 74 e0                           jsr print_chara
  126 A:eacc  a9 2c                              lda #','
  127 A:eace  20 74 e0                           jsr print_chara
  128 A:ead1  a9 30                              lda #'0'
  129 A:ead3  20 74 e0                           jsr print_chara
  130 A:ead6  20 7d e0                           jsr ascii_home
  131 A:ead9  a9 02                              lda #$02
  132 A:eadb  20 74 e0                           jsr print_chara
  133 A:eade  a9 db                              lda #$db
  134 A:eae0  20 74 e0                           jsr print_chara
  135 A:eae3  64 1c                              stz cursor_x
  136 A:eae5  64 1d                              stz cursor_y
  137 A:eae7                           vlp       
  137 A:eae7                                    
  138 A:eae7                                    ; wait until key pressed
  139 A:eae7  20 a4 f5                           jsr rxpoll
  140 A:eaea  ad 00 80                           lda $8000
  141 A:eaed                                    ; parse arrow keys
  142 A:eaed  c9 18                              cmp #$18
  143 A:eaef  f0 11                              beq vi_down
  144 A:eaf1  c9 05                              cmp #$05
  145 A:eaf3  f0 15                              beq vi_up
  146 A:eaf5  c9 10                              cmp #$10
  147 A:eaf7  f0 19                              beq vi_left
  148 A:eaf9  c9 04                              cmp #$04
  149 A:eafb  f0 1d                              beq vi_right
  150 A:eafd  4c e7 ea                           jmp vlp
  151 A:eb00  fa                                 plx 
  152 A:eb01  60                                 rts 
  153 A:eb02                           vi_down   
  153 A:eb02                                    
  154 A:eb02  a9 1f                              lda #$1f
  155 A:eb04  20 74 e0                           jsr print_chara
  156 A:eb07  4c e7 ea                           jmp vlp
  157 A:eb0a                           vi_up     
  157 A:eb0a                                    
  158 A:eb0a  a9 1e                              lda #$1e
  159 A:eb0c  20 74 e0                           jsr print_chara
  160 A:eb0f  4c e7 ea                           jmp vlp
  161 A:eb12                           vi_left   
  161 A:eb12                                    
  162 A:eb12  a9 1d                              lda #$1d
  163 A:eb14  20 74 e0                           jsr print_chara
  164 A:eb17  4c e7 ea                           jmp vlp
  165 A:eb1a                           vi_right  
  165 A:eb1a                                    
  166 A:eb1a  a9 1c                              lda #$1c
  167 A:eb1c  20 74 e0                           jsr print_chara
  168 A:eb1f  4c e7 ea                           jmp vlp
  169 A:eb22                                     .) 

  171 A:eb22                           nfm       
  171 A:eb22  5b 4e 65 77 20 46 69 ...           .byt "[New File]",0

main.a65


 2652 A:eb2d                                    ;; memory copy
 2653 A:eb2d                                    ;; copies from (mem_source) to (mem_copy), all the way to (mem_end).
 2654 A:eb2d                           memcopy   
 2654 A:eb2d                                    
 2655 A:eb2d                                     .( 
 2656 A:eb2d  a0 00                              ldy #0
 2657 A:eb2f                           loopbring 
 2658 A:eb2f  b1 0a                              lda (mem_source),y  
 2659 A:eb31  91 0c                              sta (mem_copy),y
 2660 A:eb33  e6 0a                              inc mem_source
 2661 A:eb35  d0 02                              bne dontinc
 2662 A:eb37  e6 0b                              inc mem_source+1
 2663 A:eb39                           dontinc   
 2664 A:eb39  e6 0c                              inc mem_copy
 2665 A:eb3b  d0 02                              bne calc
 2666 A:eb3d  e6 0d                              inc mem_copy+1
 2667 A:eb3f                           calc      
 2668 A:eb3f  a5 0d                              lda mem_copy+1
 2669 A:eb41  c5 0f                              cmp mem_end+1
 2670 A:eb43  d0 ea                              bne loopbring
 2671 A:eb45  a5 0c                              lda mem_copy
 2672 A:eb47  c5 0e                              cmp mem_end
 2673 A:eb49  d0 e4                              bne loopbring
 2674 A:eb4b  60                                 rts 
 2675 A:eb4c                                     .) 

 2677 A:eb4c                                    ;; memory test
 2678 A:eb4c                                    ;; the process is, for each page of memory (and MEMTESTBASE points
 2679 A:eb4c                                    ;; to the starting point), we write the number of that page into
 2680 A:eb4c                                    ;; each byte of that page (ie, each byte on page $1200 gets written
 2681 A:eb4c                                    ;; with $12, each byte on page $4600 gets written with $46).
 2682 A:eb4c                                    ;; then we read back and report errors. Leave the memory as it
 2683 A:eb4c                                    ;; is at the end of the test so that I can poke around with the
 2684 A:eb4c                                    ;; monitor later
 2685 A:eb4c                                    ;;
 2686 A:eb4c                           memtestcmd 
 2687 A:eb4c  da                                 phx                    ; preserve the stack, we're going to need x...
 2688 A:eb4d                                    ;; stage one is the write
 2689 A:eb4d                           writetest 
 2690 A:eb4d  64 46                              stz MEMTESTBASE
 2691 A:eb4f  a9 05                              lda #$05             ;; we start at page $05
 2692 A:eb51  85 47                              sta MEMTESTBASE+1

 2694 A:eb53                                    ;; for page x, write x into each byte
 2695 A:eb53                                     .( 
 2696 A:eb53                           fillpage  
 2697 A:eb53  a0 00                              ldy #$00
 2698 A:eb55  a5 47                              lda MEMTESTBASE+1          ; load bit pattern
 2699 A:eb57                           loop      
 2700 A:eb57  91 46                              sta (MEMTESTBASE),y
 2701 A:eb59  c8                                 iny 
 2702 A:eb5a  d0 fb                              bne loop

 2704 A:eb5c                                    ;; move onto the next page, as long as we're still in the RAM
 2705 A:eb5c                           nextpage  
 2706 A:eb5c                                    ;lda BASE+1
 2707 A:eb5c  1a                                 inc                    ; accumulator still holds page numner
 2708 A:eb5d  c9 80                              cmp #$80             ; stop when we hit the upper half of memory
 2709 A:eb5f  f0 04                              beq readtest
 2710 A:eb61  85 47                              sta MEMTESTBASE+1
 2711 A:eb63  80 ee                              bra fillpage
 2712 A:eb65                                     .) 

 2714 A:eb65                                    ;; stage two. read it back and check.
 2715 A:eb65                           readtest  
 2716 A:eb65                                    ;; start at the beginning again
 2717 A:eb65  64 46                              stz MEMTESTBASE
 2718 A:eb67  a9 05                              lda #$05
 2719 A:eb69  85 47                              sta MEMTESTBASE+1

 2721 A:eb6b                                     .( 
 2722 A:eb6b                                    ;; each byte should be the same as the page
 2723 A:eb6b                           nextpage  
 2724 A:eb6b  a0 00                              ldy #$00
 2725 A:eb6d                           loop      
 2726 A:eb6d  b1 46                              lda (MEMTESTBASE),y
 2727 A:eb6f  c5 47                              cmp MEMTESTBASE+1
 2728 A:eb71  d0 0e                              bne testerr
 2729 A:eb73  c8                                 iny 
 2730 A:eb74  d0 f7                              bne loop

 2732 A:eb76  a5 47                              lda MEMTESTBASE+1
 2733 A:eb78  1a                                 inc 
 2734 A:eb79  c9 80                              cmp #$80
 2735 A:eb7b  f0 10                              beq exit
 2736 A:eb7d  85 47                              sta MEMTESTBASE+1
 2737 A:eb7f  80 ea                              bra nextpage
 2738 A:eb81                           testerr   
 2739 A:eb81  a5 47                              lda MEMTESTBASE+1
 2740 A:eb83  20 6d d6                           jsr putax
 2741 A:eb86  98                                 tya 
 2742 A:eb87  20 6d d6                           jsr putax
 2743 A:eb8a  20 8f eb                           jsr memtesterr
 2744 A:eb8d                           exit      
 2745 A:eb8d  fa                                 plx 
 2746 A:eb8e  60                                 rts 
 2747 A:eb8f                                     .) 

 2750 A:eb8f                           memtesterr 
 2751 A:eb8f  a0 00                              ldy #0
 2752 A:eb91                                     .( 
 2753 A:eb91                           next_char 
 2754 A:eb91                           wait_txd_empty 
 2755 A:eb91  ad 01 80                           lda ACIA_STATUS
 2756 A:eb94  29 10                              and #$10
 2757 A:eb96  f0 f9                              beq wait_txd_empty
 2758 A:eb98  b9 f6 f4                           lda memerrstr,y
 2759 A:eb9b  f0 06                              beq endstr
 2760 A:eb9d  8d 00 80                           sta ACIA_DATA
 2761 A:eba0  c8                                 iny 
 2762 A:eba1  80 ee                              bra next_char
 2763 A:eba3                           endstr    
 2764 A:eba3  20 45 d6                           jsr crlf
 2765 A:eba6                                     .) 
 2766 A:eba6  60                                 rts 

 2769 A:eba7                                    ;;; print the string pointed to at PRINTVEC
 2770 A:eba7                                    ;;;
 2771 A:eba7                           printvecstr 
 2772 A:eba7  a0 00                              ldy #0
 2773 A:eba9                                     .( 
 2774 A:eba9                           next_char 
 2775 A:eba9                           wait_txd_empty 
 2776 A:eba9  ad 01 80                           lda ACIA_STATUS
 2777 A:ebac  29 10                              and #$10             ;; if you have a wdc 65c51 installed, replace this 
 2778 A:ebae  f0 f9                              beq wait_txd_empty                ;; with a loop.
 2779 A:ebb0  b1 42                              lda (PRINTVEC),y            ;;
 2780 A:ebb2  f0 06                              beq endstr                ;; be sure to also change the code in acia.a65!
 2781 A:ebb4  8d 00 80                           sta ACIA_DATA
 2782 A:ebb7  c8                                 iny 
 2783 A:ebb8  80 ef                              bra next_char
 2784 A:ebba                           endstr    
 2785 A:ebba                                     .) 
 2786 A:ebba  60                                 rts 

 2788 A:ebbb                                    ;;; print a string bigger than 256 bytes. 
 2789 A:ebbb                                    ;;; start at PRINTVEC and end at ENDVEC
 2790 A:ebbb                                    ;;;
 2791 A:ebbb                           printveclong 
 2791 A:ebbb                                    
 2792 A:ebbb                                     .( 
 2793 A:ebbb  da                                 phx 
 2794 A:ebbc                           lp        
 2794 A:ebbc                                    
 2795 A:ebbc  b2 42                              lda (PRINTVEC)
 2796 A:ebbe  20 74 e0                           jsr print_chara
 2797 A:ebc1  e6 42                              inc PRINTVEC
 2798 A:ebc3  d0 02                              bne pvl
 2799 A:ebc5  e6 43                              inc PRINTVEC+1
 2800 A:ebc7                           pvl       
 2800 A:ebc7                                    
 2801 A:ebc7  a5 42                              lda PRINTVEC
 2802 A:ebc9  c5 0e                              cmp ENDVEC
 2803 A:ebcb  d0 ef                              bne lp
 2804 A:ebcd  a5 43                              lda PRINTVEC+1
 2805 A:ebcf  c5 0f                              cmp ENDVEC+1
 2806 A:ebd1  d0 e9                              bne lp
 2807 A:ebd3  fa                                 plx 
 2808 A:ebd4  60                                 rts 
 2809 A:ebd5                                     .) 

 2812 A:ebd5                                    ;;;
 2813 A:ebd5                                    ;;; Various string constants
 2814 A:ebd5                                    ;;;

 2816 A:ebd5                           hextable  
 2816 A:ebd5  30 31 32 33 34 35 36 ...           .byt "0123456789ABCDEF"
 2817 A:ebe5                           greeting  
 2817 A:ebe5  58 50 4c 2d 33 32 20 ...           .byt "XPL-32 monitor",$0d,$0a,$00
 2818 A:ebf6                           prompt    
 2818 A:ebf6  3e                                 .byt ">"
 2819 A:ebf7                           aboutstring 
 2819 A:ebf7  58 50 4c 2d 33 32 20 ...           .byt "XPL-32 monitor - a command prompt for the XPL-32.",$0d,$0a
 2820 A:ec2a  54 68 69 73 20 70 72 ...           .byt "This program was original developed by Paul Dourish, and it was called Mitemon.",$0d,$0a
 2821 A:ec7b  49 6e 20 74 68 69 73 ...           .byt "In this version, I have added XPL-32 support, and a couple new commands.",$0d,$0a,$0d,$0a
 2822 A:ecc7  43 6f 70 79 72 69 67 ...           .byt "Copyright (C) 2023  Waverider & Paul Dourish",$0d,$0a,$0d,$0a
 2823 A:ecf7  54 68 69 73 20 70 72 ...           .byt "This program is free software: you can redistribute it and/or modify",$0d,$0a
 2824 A:ed3d  69 74 20 75 6e 64 65 ...           .byt "it under the terms of the GNU General Public License as published by",$0d,$0a
 2825 A:ed83  74 68 65 20 46 72 65 ...           .byt "the Free Software Foundation, either version 3 of the License, or",$0d,$0a
 2826 A:edc6  28 61 74 20 79 6f 75 ...           .byt "(at your option) any later version.",$0d,$0a,$0d,$0a
 2827 A:eded  54 68 69 73 20 70 72 ...           .byt "This program is distributed in the hope that it will be useful,",$0d,$0a
 2828 A:ee2e  62 75 74 20 57 49 54 ...           .byt "but WITHOUT ANY WARRANTY",$3b," without even the implied warranty of",$0d,$0a
 2829 A:ee6e  4d 45 52 43 48 41 4e ...           .byt "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the",$0d,$0a
 2830 A:eead  47 4e 55 20 47 65 6e ...           .byt "GNU General Public License for more details.",$0d,$0a,$0d,$0a
 2831 A:eedd  59 6f 75 20 73 68 6f ...           .byt "You should have received a copy of the GNU General Public License",$0d,$0a
 2832 A:ef20  61 6c 6f 6e 67 20 77 ...           .byt "along with this program.  If not, see <https://www.gnu.org/licenses/>.",$0d,$0a
 2833 A:ef68                           aboutstringend 
 2833 A:ef68  00                                 .byt $00
 2834 A:ef69                           helpstring 
 2834 A:ef69  43 6f 6d 6d 61 6e 64 ...           .byt "Commands available:",$0d,$0a,$0d,$0a
 2835 A:ef80  65 63 68 6f 09 20 2d ...           .byt "echo",$09," - Echos a string to the screen.",$0d,$0a
 2836 A:efa7  68 65 6c 70 09 20 2d ...           .byt "help",$09," - displays this screen",$0d,$0a
 2837 A:efc5  61 62 6f 75 74 09 20 ...           .byt "about",$09," - displays information about this software",$0d,$0a
 2838 A:eff8  64 75 6d 70 09 20 2d ...           .byt "dump",$09," - dumps memory contents at a specific address",$0d,$0a
 2839 A:f02d  70 6f 6b 65 09 20 2d ...           .byt "poke",$09," - puts a value at an address",$0d,$0a,$00
 2840 A:f052  7a 65 72 6f 09 20 2d ...           .byt "zero",$09," - fills a memory range with zeros",$0d,$0a
 2841 A:f07b  67 6f 09 20 2d 20 6a ...           .byt "go",$09," - jumps to an address",$0d,$0a
 2842 A:f096  78 72 65 63 65 69 76 ...           .byt "xreceive - receive from the serial port with xmodem to a specified address",$0d,$0a
 2843 A:f0e2  64 69 73 09 20 2d 20 ...           .byt "dis",$09," - disassembles machine code a memory range into assembly, and prints that onto the screen",$0d,$0a,$00
 2844 A:f143  69 6e 70 75 74 09 20 ...           .byt "input",$09," - inputs hexadecimal bytes from the keyboard to an address. terminated by a double return.",$0d,$0a
 2845 A:f1a6  6d 65 6d 74 65 73 74 ...           .byt "memtest  - tests memory integrity",$0d,$0a
 2846 A:f1c9                                    ;.byte "receive  - like xreceive, but no protocol is used", $0d, $0a
 2847 A:f1c9  76 69 09 20 2d 20 65 ...           .byt "vi",$09," - edits a file on the sd card (NOT DONE)",$0d,$0a
 2848 A:f1f7  6c 6f 61 64 09 20 2d ...           .byt "load",$09," - load a memory card's automatic loading system - also can load the specified file",$0d,$0a
 2849 A:f251  73 61 76 65 09 20 2d ...           .byt "save",$09," - saves a file to the memory card",$0d,$0a
 2850 A:f27a  6c 73 09 20 2d 20 6c ...           .byt "ls",$09," - list the current directory",$0d,$0a
 2851 A:f29c  63 64 09 20 2d 20 63 ...           .byt "cd",$09," - change to the specified directory",$0d,$0a
 2852 A:f2c5  63 61 74 09 20 2d 20 ...           .byt "cat",$09," - dumps a file directly to the screen",$0d,$0a
 2853 A:f2f1  72 6d 09 20 2d 20 72 ...           .byt "rm",$09," - removes a file",$0d,$0a
 2854 A:f307  6d 76 09 20 2d 20 6d ...           .byt "mv",$09," - moves a file",$0d,$0a
 2855 A:f31b  63 6c 65 61 72 09 20 ...           .byt "clear",$09," - clears the screen",$0d,$0a
 2856 A:f337  74 6c 6f 61 64 09 20 ...           .byt "tload",$09," - loads a file from the tape system",$0d,$0a
 2857 A:f363  74 73 61 76 65 09 20 ...           .byt "tsave",$09," - saves a file to the tape system",$0d,$0a
 2858 A:f38d  72 74 69 09 20 2d 20 ...           .byt "rti",$09," - return from any pending interuppts. warning-might crash",$0d,$0a
 2859 A:f3cd                           helpstringend 
 2859 A:f3cd  00                                 .byt $00
 2860 A:f3ce                           nocmderrstr 
 2860 A:f3ce  43 6f 6d 6d 61 6e 64 ...           .byt "Command not recognized",$0d,$0a,$00
 2861 A:f3e7                           implementstring 
 2861 A:f3e7  4e 6f 74 20 79 65 74 ...           .byt "Not yet implemented",$0d,$0a,$00
 2862 A:f3fd                           dumperrstring 
 2862 A:f3fd  55 73 61 67 65 3a 20 ...           .byt "Usage: dump hexaddress [count:10]",$00
 2863 A:f41f                           pokeerrstring 
 2863 A:f41f  55 73 61 67 65 3a 20 ...           .byt "Usage: poke hexaddress hexvalue",$00
 2864 A:f43f                           goerrstring 
 2864 A:f43f  55 73 61 67 65 3a 20 ...           .byt "Usage: go hexaddress",$00
 2865 A:f454                           zeroerrstring 
 2865 A:f454  55 73 61 67 65 3a 20 ...           .byt "Usage: zero hexaddress [count:10]",$00
 2866 A:f476                           xrecverrstring 
 2866 A:f476  55 73 61 67 65 3a 20 ...           .byt "Usage: xreceive hexaddress",$00
 2867 A:f491                           tsaveerrstring 
 2867 A:f491  55 73 61 67 65 3a 20 ...           .byt "Usage: tsave startaddr endaddr",$00
 2868 A:f4b0                           inputhelpstring 
 2868 A:f4b0  45 6e 74 65 72 20 74 ...           .byt "Enter two-digit hex bytes. Blank line to end.",$00
 2869 A:f4de                           inputerrstring 
 2869 A:f4de  55 73 61 67 65 3a 20 ...           .byt "Usage: input hexaddress",$00
 2870 A:f4f6                           memerrstr 
 2870 A:f4f6  4d 65 6d 6f 72 79 20 ...           .byt "Memory test failed",$00
 2871 A:f509                           diserrorstring 
 2871 A:f509  55 73 61 67 65 3a 20 ...           .byt "Usage: dis hexaddress [count: 10]",$00
 2872 A:f52b                                    ; transferstring
 2872 A:f52b  53 65 72 69 61 6c 20 ...           .byt "Serial [S] or Memory Card [M] Transfer?",$0d,$0a,$00
 2873 A:f555                           serialstring 
 2873 A:f555  53 74 61 72 74 20 53 ...           .byt "Start Serial Load.",$0d,$0a,$00
 2874 A:f56a                           loaddonestring 
 2874 A:f56a  4c 6f 61 64 20 43 6f ...           .byt "Load Complete.",$0d,$0a,$00
 2875 A:f57b                           char      
 2875 A:f57b  2e                                 .byt "."
 2876 A:f57c                           sd_error  
 2876 A:f57c  53 44 20 43 61 72 64 ...           .byt "SD Card failed to initialize",$0d,$0a,$00
 2877 A:f59b                           errormsg  
 2877 A:f59b  45 72 72 6f 72 21 0d ...           .byt "Error!",$0d,$0a,$00

 2879 A:f5a4                           rxpoll    
 2879 A:f5a4                                    
 2880 A:f5a4  ad 01 80                           lda ACIA_STATUS
 2881 A:f5a7  29 08                              and #$08
 2882 A:f5a9  f0 f9                              beq rxpoll
 2883 A:f5ab  60                                 rts 

 2885 A:f5ac                           interrupt 
 2886 A:f5ac  6c fe 7f                           jmp ($7ffe)
 2887 A:f5af  40                                 rti 

 2889 A:f5b0  00 ff de 09 00 64 2c ...           .dsb 2526,$00

 2891 A:ff8e                                    ; ----KERNAL----

 2893 A:ff8e                                     *= $ff8e

 2895 A:ff8e                                    ; New SD/fat32 commands
 2896 A:ff8e                           KERNAL_sd_writesector 
 2897 A:ff8e  4c 4c d8                           jmp sd_writesector
 2898 A:ff91                                    ;fat
 2899 A:ff91                           KERNAL_fat32_writenextsector 
 2899 A:ff91                                    
 2900 A:ff91  20 4c db                           jsr fat32_writenextsector
 2901 A:ff94                           KERNAL_fat32_allocatecluster 
 2901 A:ff94                                    
 2902 A:ff94  20 1c dc                           jsr fat32_allocatecluster
 2903 A:ff97                           KERNAL_fat32_findnextfreecluster 
 2903 A:ff97                                    
 2904 A:ff97  20 0e dd                           jsr fat32_findnextfreecluster
 2905 A:ff9a                           KERNAL_fat32_writedirent 
 2905 A:ff9a                                    
 2906 A:ff9a  20 c5 dd                           jsr fat32_writedirent
 2907 A:ff9d                           KERNAL_fat32_deletefile 
 2907 A:ff9d                                    
 2908 A:ff9d  20 24 df                           jsr fat32_deletefile
 2909 A:ffa0                           KERNAL_fat32_file_write 
 2909 A:ffa0                                    
 2910 A:ffa0  20 c3 df                           jsr fat32_file_write

 2912 A:ffa3                                    ; DOS commands
 2913 A:ffa3                           KERNAL_save 
 2913 A:ffa3                                    
 2914 A:ffa3  4c ff e7                           jmp savekernal
 2915 A:ffa6                           KERNAL_cd 
 2915 A:ffa6                                    
 2916 A:ffa6  4c f3 e3                           jmp cdsub
 2917 A:ffa9                           KERNAL_ls 
 2917 A:ffa9                                    
 2918 A:ffa9  4c 2c e6                           jmp list

 2920 A:ffac                                    ; inits

 2922 A:ffac                           KERNAL_acia_init 
 2922 A:ffac                                    
 2923 A:ffac  4c 3d e0                           jmp acia_init
 2924 A:ffaf                           KERNAL_via_init 
 2924 A:ffaf                                    
 2925 A:ffaf  4c f0 d6                           jmp via_init
 2926 A:ffb2                           KERNAL_sd_init 
 2926 A:ffb2                                    
 2927 A:ffb2  4c 05 d7                           jmp sd_init
 2928 A:ffb5                           KERNAL_fat32_init 
 2928 A:ffb5                                    
 2929 A:ffb5  4c da d8                           jmp fat32_init

 2931 A:ffb8                                    ; acia

 2933 A:ffb8                           KERNAL_print_hex_acia 
 2933 A:ffb8                                    
 2934 A:ffb8  4c 4a e0                           jmp print_hex_acia
 2935 A:ffbb                           KERNAL_crlf 
 2935 A:ffbb                                    
 2936 A:ffbb  4c 45 d6                           jmp crlf
 2937 A:ffbe                           KERNAL_cleardisplay 
 2937 A:ffbe                                    
 2938 A:ffbe  4c 61 e0                           jmp cleardisplay
 2939 A:ffc1                           KERNAL_rxpoll 
 2939 A:ffc1                                    
 2940 A:ffc1  4c a4 f5                           jmp rxpoll
 2941 A:ffc4                           KERNAL_txpoll 
 2941 A:ffc4                                    
 2942 A:ffc4  4c 6c e0                           jmp txpoll
 2943 A:ffc7                           KERNAL_print_chara 
 2943 A:ffc7                                    
 2944 A:ffc7                           KERNAL_print_char_acia 
 2944 A:ffc7                                    
 2945 A:ffc7  4c 74 e0                           jmp print_chara
 2946 A:ffca                           KERNAL_ascii_home 
 2946 A:ffca                                    
 2947 A:ffca  4c 7d e0                           jmp ascii_home
 2948 A:ffcd                           KERNAL_w_acia_full 
 2949 A:ffcd  4c 85 e0                           jmp w_acia_full

 2951 A:ffd0                                    ; fat32

 2953 A:ffd0                           KERNAL_fat32_seekcluster 
 2953 A:ffd0                                    
 2954 A:ffd0  4c 19 da                           jmp fat32_seekcluster
 2955 A:ffd3                           KERNAL_fat32_readnextsector 
 2956 A:ffd3  4c 0a db                           jmp fat32_readnextsector
 2957 A:ffd6                           KERNAL_fat32_openroot 
 2957 A:ffd6                                    
 2958 A:ffd6  4c f7 db                           jmp fat32_openroot
 2959 A:ffd9                           KERNAL_fat32_opendirent 
 2959 A:ffd9                                    
 2960 A:ffd9  4c 5d dd                           jmp fat32_opendirent
 2961 A:ffdc                           KERNAL_fat32_readdirent 
 2962 A:ffdc  4c ae de                           jmp fat32_readdirent
 2963 A:ffdf                           KERNAL_fat32_finddirent 
 2963 A:ffdf                                    
 2964 A:ffdf  4c e4 de                           jmp fat32_finddirent
 2965 A:ffe2                           KERNAL_fat32_file_readbyte 
 2965 A:ffe2                                    
 2966 A:ffe2  4c 62 df                           jmp fat32_file_readbyte
 2967 A:ffe5                           KERNAL_fat32_file_read 
 2967 A:ffe5                                    
 2968 A:ffe5  4c a3 df                           jmp fat32_file_read

 2970 A:ffe8                                    ; sd

 2972 A:ffe8                           KERNAL_sd_readbyte 
 2972 A:ffe8                                    
 2973 A:ffe8  4c 82 d7                           jmp sd_readbyte
 2974 A:ffeb                           KERNAL_sd_sendcommand 
 2974 A:ffeb                                    
 2975 A:ffeb  4c bc d7                           jmp sd_sendcommand
 2976 A:ffee                           KERNAL_sd_readsector 
 2976 A:ffee                                    
 2977 A:ffee  4c f6 d7                           jmp sd_readsector

 2979 A:fff1                                    ; other

 2981 A:fff1                           KERNAL_loadcmd 
 2981 A:fff1                                    
 2982 A:fff1  4c f1 e6                           jmp loadone
 2983 A:fff4                           KERNAL_tsave 
 2983 A:fff4                                    
 2984 A:fff4  4c 04 ca                           jmp tsavecmd+94
 2985 A:fff7                           KERNAL_tload 
 2985 A:fff7                                    
 2986 A:fff7  4c d3 cb                           jmp tload_kernal

 2988 A:fffa                                     *= $fffa
 2989 A:fffa  ac f5                              .word interrupt
 2990 A:fffc  00 c0                              .word reset
 2991 A:fffe  ac f5                              .word interrupt
