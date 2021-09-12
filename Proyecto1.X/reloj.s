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
  TABLA_7SEG:
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
   
DISPLAY_VAR_HORA:
    clrf    PORTD
    movf       BANDERAS_HORA, 0
    xorlw      0
    btfss      STATUS, 2
    goto    __D2
    goto    DISPLAY_0
DISPLAY_0:
    movfw    VAR_DISPLAY_HORA_DECENA
    call    TABLA_7SEG
    movwf   PORTC
    bsf	    PORTD, RD2
    bcf	    PORTD, RD0
    bcf	    PORTD, RD1
    bcf	    PORTD, RD3
    goto    DISP_FIN
__D2:
    movf       BANDERAS_HORA, 0
    xorlw      1
    btfss      STATUS, 2
    goto    __D3
    goto    DISPLAY_1    
DISPLAY_1:
    movfw    VAR_DISPLAY_HORA_UNIDAD
    call    TABLA_7SEG
    movwf   PORTC
    bsf	    PORTD, RD3 
    bcf	    PORTD, RD0
    bcf	    PORTD, RD1
    bcf	    PORTD, RD2    
    goto    DISP_FIN 
__D3:
    movf       BANDERAS_HORA, 0
    xorlw      2
    btfss      STATUS, 2
    goto    __D4
    goto    DISPLAY_2    
DISPLAY_2:
    movfw    VAR_DISPLAY_MINUTO_DECENA
    call    TABLA_7SEG
    movwf   PORTC
    bsf	    PORTD, RD1 
    bcf	    PORTD, RD0
    bcf	    PORTD, RD2
    bcf	    PORTD, RD3    
    goto    DISP_FIN     
__D4:
    movf       BANDERAS_HORA, 0
    xorlw      3
    btfss      STATUS, 2
    goto    DISPLAY_VAR_HORA
    goto    DISPLAY_3    
DISPLAY_3:
    movfw    VAR_DISPLAY_MINUTO_UNIDAD
    call    TABLA_7SEG
    movwf   PORTC
    bsf	    PORTD, RD0 
    bcf	    PORTD, RD2
    bcf	    PORTD, RD1
    bcf	    PORTD, RD3    
    goto    DISP_FIN 
    
DISP_FIN:  
    call    TOGGLE_B0
    return  
    
;   ----------------------------------------------------
   
PUSH_UNO:
    btfsc   PORTA, 0
    goto    $-1
    call    INCREMENTO_HORA
    call    INCREMENTO_MINUTO2
    return

PUSH_DOS:
    btfsc   PORTA, 1
    goto    $-1
    call    DECREMENTO_HORA
    call    DECREMENTO_MINUTO2
    return
    
PUSH_TRES:
    btfsc   PORTA, 2
    goto    $-1
    call    INCREMENTO_MINUTO
    call    INCREMENTO_SEGUNDO
    return

PUSH_CUATRO:
    btfsc   PORTA, 3
    goto    $-1
    call    DECREMENTO_MINUTO
    call    DECREMENTO_SEGUNDO
    return
    
PUSH_CINCO:
    btfsc   PORTA, 4
    goto    $-1
    call    SELECTOR
    return     
    
;   ----------------------------------------------------
 
SELECTOR: 
    incf    SELE, 1
    movf    SELE, 0
    btfss   STATUS, 2
    goto    _S1
_S1:    
    movf   SELE,0
    xorlw  2
    btfss   STATUS, 2
    goto    _S2
    movlw   b'00000010'
    movfw   PORTB  
_S2:    
    movf   SELE,0
    xorlw  3
    btfss   STATUS, 2
    goto    _S3
    movlw   b'00000100'
    movwf   PORTB
_S3:    
    movf   SELE,0
    xorlw  4
    btfss   STATUS, 2
    goto    _S4
    movlw   b'00001000'
    movfw   PORTB
_S4:
    movf   SELE,0
    xorlw  5
    btfss   STATUS, 2
    goto    _S5
    movlw   b'00010000'
    movfw   PORTB    
_S5:    
    movf   SELE,0
    xorlw  6
    btfss   STATUS, 2
    goto    _S6
    movlw   b'00100000'
    movfw   PORTB    
_S6:    
    movf   SELE,0
    xorlw  7
    btfss   STATUS, 2
    return
    movlw   b'00000000'
    movfw   SELE 
    goto    _S
    return
    
;   ----------------------------------------------------       

INCREMENTO_HORA:
    movf   SELE,0
    xorlw  4
    btfss   STATUS, 2
    return
    
    incf    VAR_DISPLAY_HORA_DECENA, 1
    incf    H0,1
    movf    H0,0
    movf    VAR_DISPLAY_HORA_DECENA, 0
    xorlw   10
    btfss STATUS, 2 
    goto    _C1
        
    clrf   VAR_DISPLAY_HORA_DECENA 
    movf   VAR_DISPLAY_HORA_DECENA, 0
    movwf PORTC 
    
    incf   VAR_DISPLAY_HORA_UNIDAD,1
    movf   VAR_DISPLAY_HORA_UNIDAD, 0
    movwf  PORTC 
    
_C1:    
    movf    H0, 0
    xorlw   24
    btfss STATUS, 2 
    return
        
    movlw  0
    movwf  VAR_DISPLAY_HORA_DECENA
    movf   VAR_DISPLAY_HORA_DECENA, 0
    movwf PORTC
    
    movlw  0
    movwf  VAR_DISPLAY_HORA_UNIDAD
    movf   VAR_DISPLAY_HORA_UNIDAD, 0
    movwf PORTC   
   
    movlw  0
    movwf  H0
    movf   H0, 0    
    return
        
    
;   ----------------------------------------------------  
    
DECREMENTO_HORA:
    movf   SELE,0
    xorlw  4
    btfss   STATUS, 2
    return
    
    decf    VAR_DISPLAY_HORA_DECENA, 1
    decf    H0,1
    movf    H0,0
    movf    H0, 0
    xorlw   9
    btfss STATUS, 2 
    goto    _C2
    
    clrf   VAR_DISPLAY_HORA_UNIDAD
    movf   VAR_DISPLAY_HORA_UNIDAD, 0
    movwf PORTC
    
    movlw  9
    movwf  VAR_DISPLAY_HORA_DECENA
    movf   VAR_DISPLAY_HORA_DECENA, 0
    movwf PORTC    

_C2:   
    movf    H0, 0
    xorlw   255
    btfss STATUS, 2 
    goto    _C3
        
    movlw  3
    movwf  VAR_DISPLAY_HORA_DECENA
    movf   VAR_DISPLAY_HORA_DECENA, 0
    movwf PORTC
    
    movlw  2
    movwf  VAR_DISPLAY_HORA_UNIDAD
    movf   VAR_DISPLAY_HORA_UNIDAD, 0
    
    movlw  23
    movwf  H0
    movf   H0, 0     
       
_C3:  
    movf    H0, 0
    xorlw   19
    btfss STATUS, 2 
    return
        
    movlw  9
    movwf  VAR_DISPLAY_HORA_DECENA
    movf   VAR_DISPLAY_HORA_DECENA, 0
    movwf PORTC
    
    movlw  1
    movwf  VAR_DISPLAY_HORA_UNIDAD
    movf   VAR_DISPLAY_HORA_UNIDAD, 0
    movwf PORTC     
    return    
    
;   ----------------------------------------------------  
    
 INCREMENTO_MINUTO:
    movf   SELE,0
    xorlw  4
    btfss   STATUS, 2
    return
    
    incf    VAR_DISPLAY_MINUTO_DECENA, 1
    incf    M0,1
    movf    M0,0
    movf    VAR_DISPLAY_MINUTO_DECENA, 0
    xorlw   10
    btfss STATUS, 2 
    return
        
    clrf   VAR_DISPLAY_MINUTO_DECENA 
    movf   VAR_DISPLAY_MINUTO_DECENA, 0
    movwf PORTC 
    
    incf   VAR_DISPLAY_MINUTO_UNIDAD,1
    movf   VAR_DISPLAY_MINUTO_UNIDAD, 0  
    xorlw   6
    btfss STATUS, 2 
    return
       
    clrf   VAR_DISPLAY_MINUTO_UNIDAD
    movf   VAR_DISPLAY_MINUTO_UNIDAD, 0
    movwf PORTC
    
    clrf   VAR_DISPLAY_MINUTO_DECENA
    movf   VAR_DISPLAY_MINUTO_DECENA, 0
    movwf PORTC  
    
    clrf   M0
    movf   M0, 0

    return   
    
;   ----------------------------------------------------  
    
DECREMENTO_MINUTO:
    movf   SELE,0
    xorlw  4
    btfss   STATUS, 2
    return
    
    decf    VAR_DISPLAY_MINUTO_DECENA, 1
    decf    M0,1
    movf    M0,0
    movf    M0, 0
    xorlw   9
    btfss STATUS, 2 
    goto    __C2
    
    clrf   VAR_DISPLAY_MINUTO_UNIDAD
    movf   VAR_DISPLAY_MINUTO_UNIDAD, 0
    movwf PORTC
    
    movlw  9
    movwf  VAR_DISPLAY_MINUTO_DECENA
    movf   VAR_DISPLAY_MINUTO_DECENA, 0
    movwf PORTC    

__C2:   
    movf    M0, 0
    xorlw   255
    btfss STATUS, 2 
    goto    __C3
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO_DECENA
    movf   VAR_DISPLAY_MINUTO_DECENA, 0
    movwf PORTC
    
    movlw  5
    movwf  VAR_DISPLAY_MINUTO_UNIDAD
    movf   VAR_DISPLAY_MINUTO_UNIDAD, 0
    
    movlw  59
    movwf  M0
    movf   M0, 0     
       
__C3:  
    movf    M0, 0
    xorlw   49
    btfss STATUS, 2 
    goto   __C4
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO_DECENA
    movf   VAR_DISPLAY_MINUTO_DECENA, 0
    movwf PORTC
    
    movlw  4
    movwf  VAR_DISPLAY_MINUTO_UNIDAD
    movf   VAR_DISPLAY_MINUTO_UNIDAD, 0
    movwf PORTC 
    
__C4:  
    movf    M0, 0
    xorlw   39
    btfss STATUS, 2 
    goto   __C5
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO_DECENA
    movf   VAR_DISPLAY_MINUTO_DECENA, 0
    movwf PORTC
    
    movlw  3
    movwf  VAR_DISPLAY_MINUTO_UNIDAD
    movf   VAR_DISPLAY_MINUTO_UNIDAD, 0
    movwf PORTC 
__C5:  
    movf    M0, 0
    xorlw   29
    btfss STATUS, 2 
    goto   __C6
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO_DECENA
    movf   VAR_DISPLAY_MINUTO_DECENA, 0
    movwf PORTC
    
    movlw  2
    movwf  VAR_DISPLAY_MINUTO_UNIDAD
    movf   VAR_DISPLAY_MINUTO_UNIDAD, 0
    movwf PORTC  
    
__C6:  
    movf    M0, 0
    xorlw   19
    btfss STATUS, 2 
    return
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO_DECENA
    movf   VAR_DISPLAY_MINUTO_DECENA, 0
    movwf PORTC
    
    movlw  1
    movwf  VAR_DISPLAY_MINUTO_UNIDAD
    movf   VAR_DISPLAY_MINUTO_UNIDAD, 0
    movwf PORTC     
    return    
    
;   ----------------------------------------------------  
    
COUNT_10:   
    decfsz  COUNT10
    return    
    movlw   122
    movwf   COUNT10
    call    _PARPADEO_LED
    call    _INCREMENTO_MINUTO
    return     
    
;   ----------------------------------------------------     
    
_INCREMENTO_MINUTO: ;Incrementando la variable min cada 500ms  
    incf    MIN, 1
    btfss   STATUS, 2	 
    return
    clrf    MIN
    return    
    
;   ---------------------------------------------------- 
    
_INCREMENTO_MINUTO2: ;60*2 = 120, MODO1
    movf    MIN, 0
    xorlw   120
    btfss   STATUS, 2
    return
    clrf    MIN
    incf    VAR_DISPLAY_MINUTO_DECENA, 1
    incf    M0,1
    movf    M0,0
    movf    VAR_DISPLAY_MINUTO_DECENA, 0
    xorlw   10
    btfss STATUS, 2 
    return
        
    clrf   VAR_DISPLAY_MINUTO_DECENA 
    movf   VAR_DISPLAY_MINUTO_DECENA, 0
    movwf PORTC 
    
    incf   VAR_DISPLAY_MINUTO_UNIDAD,1
    movf   VAR_DISPLAY_MINUTO_UNIDAD, 0  
    xorlw   6
    btfss STATUS, 2 
    return
       
    clrf   VAR_DISPLAY_MINUTO_UNIDAD
    movf   VAR_DISPLAY_MINUTO_UNIDAD, 0
    movwf PORTC
    
    clrf   VAR_DISPLAY_MINUTO_DECENA
    movf   VAR_DISPLAY_MINUTO_DECENA, 0
    movwf PORTC  
    
    clrf   M0
    movf   M0, 0
    incf    VAR_DISPLAY_HORA_DECENA, 1
    incf    H0,1
    movf    H0,0
    movf    VAR_DISPLAY_HORA_DECENA, 0
    xorlw   10
    btfss STATUS, 2 
    goto    _CMIN2
        
    clrf   VAR_DISPLAY_HORA_DECENA 
    movf   VAR_DISPLAY_HORA_DECENA, 0
    movwf PORTC 
    
    incf   VAR_DISPLAY_HORA_UNIDAD,1
    movf   VAR_DISPLAY_HORA_UNIDAD, 0
    movwf  PORTC 
    
_CMIN2:    
    movf    H0, 0
    xorlw   24
    btfss STATUS, 2 
    return
        
    movlw  0
    movwf  VAR_DISPLAY_HORA_DECENA
    movf   VAR_DISPLAY_HORA_DECENA, 0
    movwf PORTC
    
    movlw  0
    movwf  VAR_DISPLAY_HORA_UNIDAD
    movf   VAR_DISPLAY_HORA_UNIDAD, 0
    movwf PORTC   
   
    movlw  0
    movwf  H0
    movf   H0, 0    
            
    return    
    
;   ----------------------------------------------------     

 _PARPADEO_LED: ;LED INDICANDO 500ms 
    btfss   PORTD, 5
    goto    ON
    goto    OFF
OFF:
    bcf	    PORTD, 5
    return
ON:
    bsf	    PORTD, 5
    return   
    
;   ----------------------------------------------------       
    
TOGGLE_B1:
    movf   SELE,0
    xorlw  6
    btfss   STATUS, 2
    goto    _MODODOS
    goto    _MODOUNO
    
_MODODOS:
    movf   SELE,0
    xorlw  3
    btfss   STATUS, 2
    return
    goto    _MODOUNO
    
_MODOUNO:    
    movf       BANDERAS_MINUTO2, 0
    xorlw      0
    btfss      STATUS, 2
    goto    __DD2	   ;No
    goto    TOG__0	   ;Si   
TOG__0:
    movlw   1
    movwf   BANDERAS_MINUTO2
    return   
__DD2:
    movf       BANDERAS_MINUTO2, 0
    xorlw      1
    btfss      STATUS, 2
    goto    __DD3	;No
    goto    TOG__1	;Si    
    
TOG__1:
    movlw   2
    movwf   BANDERAS_MINUTO2
    return
__DD3:
    movf       BANDERAS_MINUTO2, 0
    xorlw      2
    btfss      STATUS, 2
    goto     __DD4	;No
    goto    TOG__2	;Si    
    
TOG__2:
    movlw   3
    movwf   BANDERAS_MINUTO2
    return
__DD4:
    movf       BANDERAS_MINUTO2, 0
    xorlw      3
    btfss      STATUS, 2
    goto     TOGGLE_B1	;No
    goto    TOG__3	;Si    
TOG__3:
    movlw   0
    movwf   BANDERAS_MINUTO2
    return
    
;   ----------------------------------------------------    
    
DISPLAY_VAR_TIMER:
    movf   SELE,0
    xorlw  6
    btfss   STATUS, 2
    goto    __MODODOS
    goto    __MODOUNO
__MODODOS:
    movf   SELE,0
    xorlw  3
    btfss   STATUS, 2
    return
    goto    __MODOUNO
__MODOUNO:    
    clrf    PORTD
    movf       BANDERAS_MINUTO2, 0
    xorlw      0
    btfss      STATUS, 2
    goto    ____D2
    goto    DISPLAY__0
DISPLAY__0:
    MOVFW    VAR_DISPLAY_MINUTO2_DECENA
    call    TABLA_7SEG
    movwf   PORTC
    bsf	    PORTD, 2
    bcf	    PORTD, 0
    bcf	    PORTD, 1
    bcf	    PORTD, 3
    goto    DISP__FIN
____D2:
    movf       BANDERAS_MINUTO2, 0
    xorlw      1
    btfss      STATUS, 2
    goto    ____D3
    goto    DISPLAY__1    
DISPLAY__1:
    MOVFW   VAR_DISPLAY_MINUTO2_UNIDAD
    call    TABLA_7SEG
    movwf   PORTC
    bsf	    PORTD, 3 
    bcf	    PORTD, 0
    bcf	    PORTD, 1
    bcf	    PORTD, 2    
    goto    DISP__FIN 
____D3:
    movf       BANDERAS_MINUTO2, 0
    xorlw      2
    btfss      STATUS, 2
    goto    ____D4
    goto    DISPLAY__2    
DISPLAY__2:
    MOVFW   VAR_DISPLAY_SEGUNDO_DECENA
    call    TABLA_7SEG
    movwf   PORTC
    bsf	    PORTD, 1 
    bcf	    PORTD, 0
    bcf	    PORTD, 2
    bcf	    PORTD, 3    
    goto    DISP__FIN 
____D4:
    movf       BANDERAS_MINUTO2, 0
    xorlw      3
    btfss      STATUS, 2
    goto    DISPLAY_VAR_TIMER
    goto    DISPLAY__3    
DISPLAY__3:
    MOVFW    VAR_DISPLAY_SEGUNDO_UNIDAD
    call    TABLA_7SEG
    movwf   PORTC
    bsf	    PORTD, 0 
    bcf	    PORTD, 2
    bcf	    PORTD, 1
    bcf	    PORTD, 3    
    goto    DISP__FIN 
    
DISP__FIN:  
    call    TOGGLE_B1
    return    
    
;   ----------------------------------------------------     
    
INCREMENTO_MINUTO2:
    movf   SELE,0
    xorlw  6
    btfss   STATUS, 2
    return
    
    incf    VAR_DISPLAY_MINUTO2_DECENA, 1
    incf    M2,1
    movf    M2,0
    movf    VAR_DISPLAY_MINUTO2_DECENA, 0
    xorlw   10
    btfss STATUS, 2 
    goto    __C1
        
    clrf   VAR_DISPLAY_MINUTO2_DECENA 
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC 
    
    incf   VAR_DISPLAY_MINUTO2_UNIDAD,1
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf  PORTC 
    
__C1:    
    movf    M2, 0
    xorlw   100
    btfss STATUS, 2 
    return
        
    movlw  0
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  0
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC   
   
    movlw  0
    movwf  M2
    movf   M2, 0 
    ;
    return    
    
;   ----------------------------------------------------     
    
DECREMENTO_MINUTO2:
    movf   SELE,0
    xorlw  6
    btfss   STATUS, 2
    return
    
    decf    VAR_DISPLAY_MINUTO2_DECENA, 1
    decf    M2,1
    movf    M2,0
    movf    M2, 0
    xorlw   9
    btfss STATUS, 2 
    goto    __CC2
    
    clrf   VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC
    
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC    

__CC2:   
    movf    M2, 0
    xorlw   255
    btfss STATUS, 2 
    goto    __CC3
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    
    movlw  99
    movwf  M2
    movf   M2, 0     
       
__CC3:  
    movf    M2, 0
    xorlw   89
    btfss STATUS, 2 
    goto    __CC4  
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  8
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC    
    
__CC4:  
    movf    M2, 0
    xorlw   79
    btfss STATUS, 2 
    goto    __CC5  
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  7
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC 
    
__CC5:  
    movf    M2, 0
    xorlw   69
    btfss STATUS, 2 
    goto    __CC6  
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  6
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC 
    
__CC6:  
    movf    M2, 0
    xorlw   59
    btfss STATUS, 2 
    goto    __CC7  
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  5
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC 
    
__CC7:  
    movf    M2, 0
    xorlw   49
    btfss STATUS, 2 
    goto    __CC8  
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  4
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC  
    
__CC8:  
    movf    M2, 0
    xorlw   39
    btfss STATUS, 2 
    goto    __CC9  
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  3
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC
    
__CC9:  
    movf    M2, 0
    xorlw   29
    btfss STATUS, 2 
    goto    __CC10  
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  2
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC   
    
__CC10:  
    movf    M2, 0
    xorlw   19
    btfss STATUS, 2 
    return
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  1
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC      
    return   
    
 ;   ---------------------------------------------------- 
 
 INCREMENTO_SEGUNDO:
    movf   SELE,0
    xorlw  6
    btfss   STATUS, 2
    return
    
    incf    VAR_DISPLAY_SEGUNDO_DECENA, 1
    incf    S1,1
    movf    S1,0
    movf    VAR_DISPLAY_SEGUNDO_DECENA, 0
    xorlw   10
    btfss STATUS, 2 
    return
        
    clrf   VAR_DISPLAY_SEGUNDO_DECENA 
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC 
    
    incf   VAR_DISPLAY_SEGUNDO_UNIDAD,1
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0  
    xorlw   6
    btfss STATUS, 2 
    return
       
    clrf   VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC
    
    clrf   VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC  
    clrf   S1
    
    movf    S1, 0
    xorlw   0
    btfss STATUS, 2 
    return
        
    movlw  1
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC
    
    movlw  0
    movwf  VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC 
    
    return
 
 ;   ---------------------------------------------------- 
 
DECREMENTO_SEGUNDO:
    movf   SELE,0
    xorlw  6
    btfss   STATUS, 2
    return
    
    decf    VAR_DISPLAY_SEGUNDO_DECENA, 1
    decf    S1,1
    movf    S1,0
    movf    S1, 0
    xorlw   9
    btfss STATUS, 2 
    goto    __CS2
    
    clrf   VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC
    
    movlw  9
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC    

__CS2:   
    movf    S1, 0
    xorlw   255
    btfss STATUS, 2 
    goto    __CS3
        
    movlw  9
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC
    
    movlw  5
    movwf  VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    
    movlw  59
    movwf  S1
    movf   S1, 0    
    ;     
       
__CS3:  
    movf    S1, 0
    xorlw   49
    btfss STATUS, 2 
    goto   __CS4
        
    movlw  9
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC
    
    movlw  4
    movwf  VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC 
    
__CS4:  
    movf    S1, 0
    xorlw   39
    btfss STATUS, 2 
    goto   __CS5
        
    movlw  9
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC
    
    movlw  3
    movwf  VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC 
__CS5:  
    movf    S1, 0
    xorlw   29
    btfss STATUS, 2 
    goto   __CS6
        
    movlw  9
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC
    
    movlw  2
    movwf  VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC  
    
__CS6:  
    movf    S1, 0
    xorlw   19
    btfss STATUS, 2 
    goto    __CS7
        
    movlw  9
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC
    
    movlw  1
    movwf  VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC    
    
__CS7:  
    movf    S1, 0
    xorlw   0
    btfss STATUS, 2 
    return
        
    movlw  1
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC
    
    movlw  0
    movwf  VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC     
    return
 
 ;   ---------------------------------------------------- 
 
 COUNT_20: 
    movf   SELE,0
    xorlw  3
    btfss   STATUS, 2
    return
    
    decfsz  COUNT20
    return    
    movlw   122
    movwf   COUNT20
    call    _INCREMENTO_SEGUNDO
    return
 
 ;   ---------------------------------------------------- 
 
_INCREMENTO_SEGUNDO:	; Incrementando la variable seg cada 500ms 1segundo MODO6
    incf    SEG, 1
    btfss   STATUS, Z	 
    return
    clrf    SEG
    return
 
 ;   ---------------------------------------------------- 
 
_INCREMENTO_SEGUNDO2:
    movf    SEG, 0
    xorlw   2
    btfss   STATUS, 2
    return
    clrf    SEG
    decf    VAR_DISPLAY_SEGUNDO_DECENA, 1
    decf    S1,1
    movf    S1,0
    xorlw   0
    btfss STATUS, 2 
    goto    ___CSS0
    
    clrf   VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC
    
    movlw  0
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC  
    
___CSS0:    
    movf    S1,0
    xorlw   9
    btfss STATUS, 2 
    goto    ___CSS2
    
    bcf	  PORTE, RE0
    clrf   VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC
    
    movlw  9
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC    

___CSS2:   
    movf    S1, 0
    xorlw   255
    btfss STATUS, 2 
    goto    ___CSS3
        
    movlw  9
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC
    
    movlw  5
    movwf  VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    
    movlw  59
    movwf  S1
    movf   S1, 0    
 
       
___CSS3:  
    movf    S1, 0
    xorlw   49
    btfss STATUS, 2 
    goto   ___CSS4
        
    movlw  9
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC
    
    movlw  4
    movwf  VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC 
    
___CSS4:  
    movf    S1, 0
    xorlw   39
    btfss STATUS, 2 
    goto   ___CSS5
        
    movlw  9
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC
    
    movlw  3
    movwf  VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC 
___CSS5:  
    movf    S1, 0
    xorlw   29
    btfss STATUS, 2 
    goto   ___CSS6
        
    movlw  9
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC
    
    movlw  2
    movwf  VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC  
    
___CSS6:  
    movf    S1, 0
    xorlw   19
    btfss STATUS, 2 
    goto    ___CSS7
        
    movlw  9
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC
    
    movlw  1
    movwf  VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC    
    
___CSS7:  
    movf    S1, 0
    xorlw   59
    btfss STATUS, 2 
    return
        
    movlw  9
    movwf  VAR_DISPLAY_SEGUNDO_DECENA
    movf   VAR_DISPLAY_SEGUNDO_DECENA, 0
    movwf PORTC
    
    movlw  5
    movwf  VAR_DISPLAY_SEGUNDO_UNIDAD
    movf   VAR_DISPLAY_SEGUNDO_UNIDAD, 0
    movwf PORTC     

    decf    VAR_DISPLAY_MINUTO2_DECENA, 1
    decf    M2,1
    movf    M2,0
    movf    M2, 0
    xorlw   9
    btfss STATUS, 2 
    goto    ___CC2
    
    clrf   VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC
    
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC    

___CC2:   
    movf    M2, 0
    xorlw   255
    btfss STATUS, 2 
    goto    ___CC3
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    
    movlw  99
    movwf  M2
    movf   M2, 0    
    ; 
       
___CC3:  
    movf    M2, 0
    xorlw   89
    btfss STATUS, 2 
    goto    ___CC4  
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  8
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC    
    
___CC4:  
    movf    M2, 0
    xorlw   79
    btfss STATUS, 2 
    goto    ___CC5  
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  7
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC 
    
___CC5:  
    movf    M2, 0
    xorlw   69
    btfss STATUS, 2 
    goto    ___CC6  
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  6
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC 
    
___CC6:  
    movf    M2, 0
    xorlw   59
    btfss STATUS, 2 
    goto    ___CC7  
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  5
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC 
    
___CC7:  
    movf    M2, 0
    xorlw   49
    btfss STATUS, 2 
    goto    ___CC8  
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  4
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC  
    
___CC8:  
    movf    M2, 0
    xorlw   39
    btfss STATUS, 2 
    goto    ___CC9  
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  3
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC
    
___CC9:  
    movf    M2, 0
    xorlw   29
    btfss STATUS, 2 
    goto    ___CC10  
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  2
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC   
    
___CC10:  
    movf    M2, 0
    xorlw   19
    btfss STATUS, 2 
    return
        
    movlw  9
    movwf  VAR_DISPLAY_MINUTO2_DECENA
    movf   VAR_DISPLAY_MINUTO2_DECENA, 0
    movwf PORTC
    
    movlw  1
    movwf  VAR_DISPLAY_MINUTO2_UNIDAD
    movf   VAR_DISPLAY_MINUTO2_UNIDAD, 0
    movwf PORTC      
    
    return 
 
 ;   ----------------------------------------------------
 
 TOGGLE_B2:
    movf   SELE,0
    xorlw  5
    btfss   STATUS, 2
    goto    ___MODODOS
    goto    ___MODOUNO
___MODODOS:
    movf   SELE,0
    xorlw  2
    btfss   STATUS, 2
    return
    goto    ___MODOUNO 
    
___MODOUNO:    
    movf       BANDERAS_DIAS, 0
    xorlw      0
    btfss      STATUS, 2
    goto    __DDD2	   ;No
    goto    TOG___0	    ;Si   
TOG___0:
    movlw   1
    movwf   BANDERAS_DIAS
    return   
__DDD2:
    movf       BANDERAS_DIAS, 0
    xorlw      1
    btfss      STATUS, 2
    goto    __DDD3	    ;No
    goto    TOG___1	    ;Si    
    
TOG___1:
    movlw   2
    movwf   BANDERAS_DIAS
    return
__DDD3:
    movf       BANDERAS_DIAS, 0
    xorlw      2
    btfss      STATUS, 2
    goto     __DDD4	    ;No
    goto    TOG___2	    ;Si    
    
TOG___2:
    movlw   3
    movwf   BANDERAS_DIAS
    return
__DDD4:
    movf       BANDERAS_DIAS, 0
    xorlw      3
    btfss      STATUS, 2
    goto     TOGGLE_B2	    ;No
    goto    TOG___3	    ;Si    
TOG___3:
    movlw   0
    movwf   BANDERAS_DIAS
    return
 
 ;   ---------------------------------------------------- 
  
DISPLAY_VAR_FECHA:
    movf   SELE,0
    xorlw  5
    btfss   STATUS, 2
    goto    __MOODODOS
    goto    __MOODOUNO
__MOODODOS:
    movf   SELE,0
    xorlw  2
    btfss   STATUS, 2
    return
    goto    __MOODOUNO
__MOODOUNO:    
    clrf    PORTD
    movf       BANDERAS_DIAS, 0
    xorlw      0
    btfss      STATUS, 2
    goto    ____D22
    goto    DISPLAY___0
DISPLAY___0:
    MOVFW    VAR_DISPLAY_DIA_DECENA
    call    TABLA_7SEG
    movwf   PORTC
    bsf	    PORTD, 2
    bcf	    PORTD, 0
    bcf	    PORTD, 1
    bcf	    PORTD, 3
    goto    DISP___FIN
____D22:
    movf       BANDERAS_DIAS, 0
    xorlw      1
    btfss      STATUS, 2
    goto    ____D33
    goto    DISPLAY___1    
DISPLAY___1:
    MOVFW   VAR_DISPLAY_DIA_UNIDAD
    call    TABLA_7SEG
    movwf   PORTC
    bsf	    PORTD, 3 
    bcf	    PORTD, 0
    bcf	    PORTD, 1
    bcf	    PORTD, 2    
    goto    DISP___FIN 
____D33:
    movf       BANDERAS_DIAS, 0
    xorlw      .2
    btfss      STATUS, 2
    goto    ____D44
    goto    DISPLAY___2    
DISPLAY___2:
    MOVFW   VAR_DISPLAY_MES_DECENA
    call    TABLA_7SEG
    movwf   PORTC
    bsf	    PORTD, 1 
    bcf	    PORTD, 0
    bcf	    PORTD, 2
    bcf	    PORTD, 3    
    goto    DISP___FIN 
    
____D44:
    movf       BANDERAS_DIAS, 0
    xorlw      3
    btfss      STATUS, 2
    goto    DISPLAY_VAR_FECHA
    goto    DISPLAY___3    
DISPLAY___3:
    MOVFW    VAR_DISPLAY_MES_UNIDAD
    call    TABLA_7SEG
    movwf   PORTC
    bsf	    PORTD, 0 
    bcf	    PORTD, 2
    bcf	    PORTD, 1
    bcf	    PORTD, 3    
    goto    DISP___FIN 
    
DISP___FIN:  
    call    TOGGLE_B2
    return   
  
 ;   ---------------------------------------------------- 
   
 
   
 ;   ---------------------------------------------------- 
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
    bsf	    PS0        ; PS = 000   rate 1:256
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

    ;variables empiezan en cero
    clrf    VAR_DISPLAY_MINUTO_UNIDAD
    clrf    VAR_DISPLAY_MINUTO_DECENA
    clrf    VAR_DISPLAY_HORA_DECENA
    clrf    VAR_DISPLAY_HORA_UNIDAD
    clrf    BANDERAS_HORA
    clrf    BANDERAS_MINUTO
    clrf    BANDERAS_MINUTO2
    clrf    VAR_DISPLAY_MINUTO2_UNIDAD
    clrf    VAR_DISPLAY_MINUTO2_DECENA
    clrf    VAR_DISPLAY_SEGUNDO_UNIDAD
    clrf    VAR_DISPLAY_SEGUNDO_DECENA
    clrf    H0
    clrf    MIN
    clrf    M2
    clrf    S1
    clrf    MIN3
    clrf    COUNT10
    clrf    COUNT20
    clrf    BANDERAS_DIAS
    clrf    VAR_DISPLAY_DIA_DECENA
    clrf    VAR_DISPLAY_MES_DECENA
    clrf    VAR_DISPLAY_DIA_UNIDAD
    clrf    VAR_DISPLAY_MES_UNIDAD    
    clrf    SEG
    clrf    M0
    BANKSEL SELE
    clrf    SELE
    return
    
_S:       
    movf   SELE,0
    xorlw  0
    btfss   STATUS, 2
    return

    movlw   1
    movwf   SELE
    movf    SELE,0
    movwf   PORTB       
END


