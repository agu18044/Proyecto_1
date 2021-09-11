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

reinicio_tmr1 macro
 banksel TMR1H	    ;se llama al bank del timer1
 movlw  0xB	    ;valor inicial que sera colocado en el tmr1
 movwf  TMR1H
 movlw	0x47
 movwf	TMR1L
 bcf	TMR1IF
 endm
 
PSECT	udata_bank0 
  var:		DS  1
  banderas:	DS  1  
  ;nibble:	DS  2
  display_var:	DS  4
  UNIDADES:	DS  1
  DECENAS:	DS  1
  cont:		DS  1
  cont1:	DS  1
  cont2:	DS  1
  
  
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
    btfsc   TMR1IF
    call    int_t1
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
    
    btfsc   banderas, 1
    goto    display_2
    
    btfsc   banderas, 2
    goto    display_3
    
       
display_0:
    movf    display_var, W
    movwf   PORTC
    bsf	    PORTD,0
    goto    siguiente_display
    
display_1:
    movf    display_var+1, W
    movwf   PORTC
    bsf	    PORTD,1
    goto    siguiente_display1
    
display_2:
    movf    display_var+2, W
    movwf   PORTC
    bsf	    PORTD,2
    goto    siguiente_display2
    
display_3:
    movf    display_var+3, W
    movwf   PORTC
    bsf	    PORTD,3
    goto    siguiente_display3
    
siguiente_display: 
    movlw   1
    xorwf   banderas, F 
    return
    
siguiente_display1: 
    movlw   3
    xorwf   banderas, F 
    return

siguiente_display2: 
    movlw   6
    xorwf   banderas, F 
    return
    
siguiente_display3: 
    movlw   4
    xorwf   banderas, F 
    return
    
int_t1:
    reinicio_tmr1
    incf    UNIDADES
    incf    cont
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
    
   
;   CODIGO PRINCIPAL
    
main:
    call    config_io
    call    config_reloj
    call    config_tmr0
    call    config_tmr1
    call    config_int
    banksel PORTA
    
loop:
    movf    UNIDADES, W
    sublw   10
    btfsc   ZERO
    call    display2
    
    movf    cont, W
    sublw   15
    btfsc   ZERO
    call    display3
    
  /*  movf    cont1, W
    sublw   10
    btfsc   ZERO
    call    display4*/
    
    call    preparar_displays

    goto    loop

;   SUB RUTINAS 
    
display2:
    incf    DECENAS
    clrf    UNIDADES
    return
    
display3:
    incf    cont1
    clrf    DECENAS
    clrf    UNIDADES
    clrf    cont
    return
    
/*display4:
    incf    cont2
    clrf    cont1
    clrf    DECENAS
    clrf    UNIDADES
    clrf    cont
    return*/
preparar_displays:
    movf    UNIDADES, W
    call    tabla
    movwf   display_var
    
    movf    DECENAS, W
    call    tabla
    movwf   display_var+1
    
    movf    cont1, W
    call    tabla
    movwf   display_var+2
    
    movf    cont2, W
    call    tabla
    movwf   display_var+3
    return
    
config_reloj:
    banksel OSCCON
    bsf	    IRCF2
    bsf	    IRCF1
    bcf	    IRCF0   ;4Mhz
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
    return
    
config_tmr1:    
    banksel T1CON  
    bcf	    TMR1GE
    bsf	    T1CKPS1	; Prescaler de 11   rate 1:8
    bsf	    T1CKPS0	;
    bcf	    T1OSCEN
    bcf	    TMR1CS     ; Se utiliza reloj interno
    bsf	    TMR1ON     ; Se activa timer1
    reinicio_tmr1
    return
    
config_int:
    banksel TRISA
    bsf	    TMR1IE
    banksel PORTA
    bsf	    T0IE	; TMR0
    bcf	    T0IF	;
    bcf	    TMR1IF	; TMR
    bsf	    PEIE	;
    bsf	    GIE		
    return
    
config_io:
    banksel ANSEL
    clrf    ANSEL
    clrf    ANSELH
    
    banksel TRISA
    clrf    TRISC
    bcf	    TRISD, 0
    bcf	    TRISD, 1
    bcf	    TRISD, 2
    bcf	    TRISD, 3
    clrf    TRISB
    
    banksel PORTA
    clrf    PORTC
    clrf    PORTD
    clrf    PORTB
    clrf    UNIDADES
    clrf    DECENAS
    clrf    cont
    clrf    cont1
    clrf    cont2
    clrf    banderas
    return
    
    
    
    
    
END


