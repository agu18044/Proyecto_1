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
 movlw  240	    ;valor inicial que sera colocado en el tmr0
 movwf  TMR0
 bcf	T0IF	    ;se resetea el T0IF
 endm

/*reinicio_tmr1 macro
 banksel TMR1H	    ;se llama al bank del timer1
 movlw  0xB	    ;valor inicial que sera colocado en el tmr1
 movwf  TMR1H
 movlw	0x98
 movwf	TMR1L
 bcf	TMR1IF
 endm*/
 
PSECT	udata_bank0 
  BANDERAS_HORA:	DS  1
  BANDERA_MINUTO:	DS  1  
  BANDERA_MINUTO2:	DS  1
  BANDERA_DIAS:		DS  1
  COUNT10:		DS  1
  COUNT20:		DS  1
  MIN:			DS  1
  M2:			DS  1
  SEG:			DS  1
  H0:			DS  1
  MIN3:			DS  1  
  M0:			DS  1  
  S1:			DS  1  
  SELE:			DS 1	
 VAR_DISPLAY_HORA_UNIDAD:	DS 1
 VAR_DISPLAY_HORA_DECENA:	DS 1
 VAR_DISPLAY_SEGUNDO_UNIDAD:	DS 1
 VAR_DISPLAY_SEGUNDO_DECENA:	DS 1
 VAR_DISPLAY_MINUTO2_UNIDAD:	DS 1
 VAR_DISPLAY_MINUTO2_DECENA:	DS 1
 VAR_DISPLAY_DIA_UNIDAD:	DS 1
 VAR_DISPLAY_MES_UNIDAD:	DS 1
 VAR_DISPLAY_DIA_DECENA:	DS 1  
 VAR_DISPLAY_MES_DECENA:	DS 1    
 VAR_DISPLAY_MINUTO_UNIDAD:	DS 1	
 VAR_DISPLAY_MINUTO_DECENA:	DS 1
    
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
    goto    pop
    reinicio_tmr0
    call    DISPLAY_VAR_HORA    
    call    DISPLAY_VAR_TIMER 
    call    DISPLAY_VAR_FECHA
    call    COUNT_10
    call    COUNT_20
    call    _INCREMENTO_MINUTO2  
    call    _INCREMENTO_SEGUNDO2 
    
pop:
   swapf    STATUS_TEMP 
   movf	    STATUS
   swapf    W_TEMP, F
   swapf    W_TEMP, W
   retfie
      
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
    call    config_int
    banksel PORTA
    
loop:
    btfsc   PORTA, 0
    call    push_uno
    
    btfsc   PORTA, 1
    call    push_dos
    
    btfsc   PORTA, 2
    call    push_tres
    
    btfsc   PORTA, 3
    call    push_cuatro
    
    btfsc   PORTA, 4
    call    push_cinco

    goto    loop

;   ----------------------------------------------------
TOGGLE_B0:
    movf       BANDERAS_HORA, 0
    xorlw      0
    btfss      STATUS, 2
    goto    _D2	   ;No
    goto    TOG_0  ;Si   
TOG_0:
    movlw   1
    movwf   BANDERAS_HORA
    return   
_D2:
    movf       BANDERAS_HORA, 0
    xorlw      1
    btfss      STATUS, 2
    goto    _D3	    ;No
    goto    TOG_1   ;Si    
    
TOG_1:
    movlw   2
    movfw   BANDERAS_HORA
    return
_D3:
    movf       BANDERAS_HORA, 0
    xorlw      2
    btfss      STATUS, 2
    goto    _D4	    ;No
    goto    TOG_2   ;Si    
    
TOG_2:
    movlw   3
    movfw   BANDERAS_HORA
    return
_D4:
    movf       BANDERAS_HORA, 0
    xorlw      3
    btfss      STATUS, 2
    goto    TOGGLE_B0	;No
    goto    TOG_3	;Si    
TOG_3:
    movlw   0
    movfw   BANDERAS_HORA
    return 
;   ----------------------------------------------------
   

    
;   ----------------------------------------------------    
config_reloj:
    banksel OSCCON
    bsf	    IRCF2
    bcf	    IRCF1
    bsf	    IRCF0   ;4Mhz
    bsf	    SCS
    return

config_tmr0:
    banksel TRISA
    bcf	    T0CS       ;reloj interno
    bcf	    PSA	       ;Prescaler
    bcf	    PS2
    bcf	    PS1
    bcf	    PS0        ; PS = 000   rate 1:2
    banksel PORTA
    reinicio_tmr0
    return
    
    
config_int:
    bsf	    GIE		;INTCON
    bsf	    T0IE
    bsf	    T0IF	
    return
    
config_io:
    banksel ANSEL
    clrf    ANSEL
    clrf    ANSELH
    
    banksel TRISA
    movlw   b'00011111'
    movwf   TRISA
    clrf    TRISB
    clrf    TRISC
    bcf	    TRISD, 0
    bcf	    TRISD, 1
    bcf	    TRISD, 2
    bcf	    TRISD, 3
    
    banksel PORTA
    clrf    PORTA
    clrf    PORTC
    clrf    PORTC
    clrf    PORTD

    return
       
END


