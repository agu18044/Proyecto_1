; Archivo:     reloj.s
; Dispositivo: PIC16F887
; Autor:       Diego Aguilar
; Compilador:  pic-as (v2.30), MBPLABX v5.40

PROCESSOR 16F887
 #include <xc.inc>
 
;configuration word 1
  CONFIG FOSC=INTRC_NOCLKOUT   // Oscilador interno
  CONFIG WDTE=OFF  // WDT disabled (reinicio repetitivo del pic)
  CONFIG PWRTE=ON  // PWRT enabled (espera de 72ms al iniciar)
  CONFIG MCLRE=OFF // El pin MCLR se utiliza como I/0
  CONFIG CP=OFF    // Sin proteccion de codigo
  CONFIG CPD=OFF   // Sin proteccion de datos
    
  CONFIG BOREN=OFF // Sin reinicio cuando el voltaje de alimentacion baja de 4V
  CONFIG IESO=OFF  // Reinicio sin cambio de reloj de interno a externo
  CONFIG FCMEN=OFF // Cambio de reloj externo a interno en caso de fallo
  CONFIG LVP=OFF   // Programacion en bajo voltaje permitida
    
;configuration word 2
  CONFIG WRT=OFF   // Proteccion de autoescritura por el programa desactivada
  CONFIG BOR4V=BOR40V  // Reinicio abajo de 4V, (BOR21V=2.1V)
  
reinicio_tmr0 macro ;macro para el reinicio del tmr 0
 banksel PORTA	    ;se llama al bank
 movlw  61	    ;valor inicial que sera colocado en el tmr0
 movwf  TMR0
 bcf	T0IF	    ;se resetea el T0IF
 endm
 
PSECT	udata_bank0 
  var:		DS  1
  banderas:	DS  1
  nibble:	DS  2
  display_var:	DS  2
  
  
;   VARIABLES  
PSECT udata_shr
 W_TEMP:	DS 1
 STATUS_TEMP:	DS 1

;   VECTOR DE RESET    
PSECT resVect, class=code, abs, delta=2
    ORG 00h
resetVec:
    PAGESEL main
    goto    main
    
;   VECT INTERUPT     
PSECT intVect, class=code, abs, delta=2 
ORG 04h
push:
    movf    W_TEMP
    swapf   STATUS, W
    movf    STATUS_TEMP    
    
isr: 
    btfsc   T0IF
    call    int_t0

pop:
   swapf    STATUS_TEMP 
   movf	    STATUS
   swapf    W_TEMP, F
   swapf    W_TEMP, W
   retfie
   
   
;   SUB RUTINAS DE INTERRUPT    
int_t0:
    reinicio_tmr0
    clrf    PORTD
    btfsc   banderas, 0
    goto    display_1
display_0:
    movf    display_var, W
    movwf   PORTC
    bsf	    PORTD,0
    goto    siguiente_display
display_1:
    movf    display_var+1, W
    movwf   PORTC
    bsf	    PORTD,1
siguiente_display: 
    movlw   1
    xorwf   banderas, F 
    return

;   TABLA
PSECT code, delta=2, abs
ORG 100h
  tabla:
    clrf    PCLATH
    bsf	    PCLATH, 0   ;PCLATH = 01
    andlw   0x0f
    addwf   PCL         ;PC = PCLATH + PCL
    retlw   00111111B  ;0
    retlw   00000110B  ;1
    retlw   01011011B  ;2
    retlw   01001111B  ;3
    retlw   01100110B  ;4
    retlw   01101101B  ;5
    retlw   01111101B  ;6
    retlw   00000111B  ;7
    retlw   01111111B  ;8
    retlw   01100111B  ;9
   /*retlw   01110111B  ;A
    retlw   01111100B  ;B
    retlw   00111001B  ;C
    retlw   01011110B  ;D
    retlw   01111001B  ;E
    retlw   01110001B  ;F*/
   
;   CODIGO PRINCIPAL
    
main:
    call    config_io
    call    config_reloj
    call    config_tmr0
    banksel PORTA
    
loop:
    movlw   0x59
    movwf   var 
    
    call    separar_nibbles
    call    preparar_displays
    goto    loop

;   SUB RUTINAS 

separar_nibbles:
    movf    var, W
    andlw   0x0f
    movwf   nibble
    swapf   var, W
    andlw   0x0f
    movwf   nibble+1
    return
 
preparar_displays:
    movf    nibble, W
    call    tabla
    movwf   display_var
    
    movf    nibble+1, W
    call    tabla
    movwf   display_var+1
    return
config_reloj:
    banksel OSCCON
    bsf	    IRCF2
    bsf	    IRCF1
    bcf	    IRCF0
    bsf	    SCS
    return

config_tmr0:
    banksel TRISA
    bcf	    T0CS       ;reloj interno
    bcf	    PSA	       ;Prescaler
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0        ; PS = 111   rate 1:256
    banksel PORTA
    reinicio_tmr0
    bsf	    GIE		;config int
    bsf	    T0IE
    bcf	    T0IF
    return
    
config_io:
    banksel ANSEL
    clrf    ANSEL
    clrf    ANSELH
    
    banksel TRISA
    clrf    TRISC
    bcf	    TRISD, 0
    bcf	    TRISD, 1
    
    banksel PORTA
    clrf    PORTC
    clrf    PORTD
    
    return
    
    
    
    
    
END


