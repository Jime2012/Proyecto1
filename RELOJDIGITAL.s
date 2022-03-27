;Archivo: PROYECTORELOJ.s
;Dispositivo: PIC16F887
;Autor: Jimena de la Rosa
;Compilador: pic-as (v2.30). MPLABX v5.40
;Programa: Prelab 6
;Hardware: LEDs en el puerto A y led intermitente en el PORTB
;Creado: 13 MAR, 2022
;Ultima modificacion: 03 MAR, 2022
    
PROCESSOR 16F887

; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>
  
PSECT UDATA_BANK0,global,class=RAM,space=1,delta=1,noexec
GLOBAL  BANDERAS,CONTM1,DISPLAY,CONT60,CONTM2,CONTH1,CONTH2,MODO,MODOIP
GLOBAL  CONTR,MODOEA,CONTMES,CONTDIA,CONTD1,CONTD2,CONTME1,CONTME2,FECHAEA
GLOBAL  CONTMT1,CONTMT2,CONTST1,CONTST2,MODOIPT,TIMEREA,MESES,DIAS,FECHAEA,CONT
GLOBAL  MODODIAS, CONTLED
    CONT60:     DS 1 ;SE NOMBRAN VARIABLES A UTILIZAR EN EL RELOJ
    CONTM1:     DS 1
    CONTM2:     DS 1
    CONTH1:     DS 1   
    CONTH2:     DS 1
    DISPLAY:    DS 4
    BANDERAS:   DS 1
    MODO:       DS 1
    CONTR:      DS 1
    MODOEA:     DS 1
    MODOIP:	DS 1
    CONTMES:    DS 1
    CONTDIA:    DS 1
    CONTD1:     DS 1
    CONTD2:     DS 1
    CONTME1:    DS 1
    CONTME2:    DS 1
    CONTST1:    DS 1
    CONTST2:    DS 1
    CONTMT1:    DS 1
    CONTMT2:    DS 1
    TIMEREA:    DS 1
    MODOIPT:    DS 1
    MESES:      DS 1
    DIAS:       DS 1
    FECHAEA:    DS 1
    MODODIAS:   DS 1
    CONT:       DS 1
    CONTLED:    DS 1


; -------------- MACROS --------------- 
; Macro para reiniciar el valor del TMR0
; Recibe el valor a configurar en TMR_VAR
RESET_TMR0 MACRO TMR_VAR
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   TMR_VAR
    MOVWF   TMR0	    ; configuramos tiempo de retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    ENDM
    
; Macro para reiniciar el valor del TMR1
; Recibe el valor a configurar en TMR1_H y TMR1_L
RESET_TMR1 MACRO TMR1_H, TMR1_L
    MOVLW   TMR1_H	    ; Literal a guardar en TMR1H
    MOVWF   TMR1H	    ; Guardamos literal en TMR1H
    MOVLW   TMR1_L	    ; Literal a guardar en TMR1L
    MOVWF   TMR1L	    ; Guardamos literal en TMR1L
    BCF	    TMR1IF	    ; Limpiamos bandera de int. TMR1
    ENDM
  
; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr		    ; Memoria compartida
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1

PSECT resVect, class=CODE, abs, delta=2
ORG 00h			    ; posición 0000h para el reset
;------------ VECTOR RESET --------------
resetVec:
    PAGESEL MAIN	; Cambio de pagina
    GOTO    MAIN
    
PSECT intVect, class=CODE, abs, delta=2
ORG 04h			    ; posición 0004h para interrupciones
;------- VECTOR INTERRUPCIONES ----------
PUSH:
    MOVWF   W_TEMP	    ; Guardamos W
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	    ; Guardamos STATUS
    
ISR:
    
    BTFSC   T0IF	    ; Interrupcion de TMR0?
    CALL    INT_TMR0
    BTFSC   TMR1IF	    ; Interrupcion de TMR1?
    CALL    INT_TMR1
    BTFSC   RBIF	    ; Fue interrupción del PORTB? No=0 Si=1
    CALL    INT_IOCB	    ; Si -> Subrutina o macro con codigo a ejecutar
    
POP:
    SWAPF   STATUS_TEMP,W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   W_TEMP,F	    
    SWAPF   W_TEMP,W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal  
; ------ SUBRUTINAS DE INTERRUPCIONES ------
INT_TMR0:
    RESET_TMR0 252	        ; Reiniciamos TMR0 para 2ms
    CALL   MOSTRAR_VALOR	; Mostramos valor en hexadecimal en los displays
    CALL   LEDS
    RETURN
    
INT_TMR1:
    RESET_TMR1 0x0B, 0xCD   ; Reiniciamos TMR1 para 1000ms
    CALL MINUTO_ALARMA	    ;SE UTILIZA LA SUBRUTINA QUE REVISA QUE LA ALARMA SOLO DURE UN MINUTO
    BTFSS MODOIP,0	    ;SI EN EL MODO RELOJ, ESTA INICIADO EL CONTEO...
    GOTO $+2			;SI NO ESTA INICIADO, REVISA DOS INSTR. DESPUES
    CALL RELOJ               ;SE HACE EL CONTEO DE INCREMENTO EN EL RELOJ
    BTFSC MODOIPT,0          ;SI EN EL MODO TIMER, ESTA INICIADO EL CONTEO...
    RETURN		     ;SI NO ESTA INICIADO, REGRESA
    BTFSC MODOIPT,1
    RETURN
    CALL SEG_TIMER1	    ;SE HACE EL CONTEO DE DECREMENTO EN EL RELOJ
    RETURN
 
INT_IOCB:
    BTFSS PORTB,4         ;EL PIN 4 DEL PORTB CAMBIA LOS MODOS
    GOTO MODOS
    
    BTFSC MODO, 0         ; SE REVISA EN QUE MODO SE ENCEUNTRA
    GOTO  INT_FECHA	   ; SI ESTA EN MODO 1, LLAMA LAS INT. DE LA FECHA
    BTFSC MODO, 1	    
    GOTO  INT_TIMER	    ; SI ESTA EN MODO 2, LLAMA LAS INT DEL TIMER
    
    INT_RELOJ:		    ; SI ESTA EN MODO 0, LLAMA LAS INT DEL RELOJ
    CALL INTERHORAS
    BCF RBIF		    ; EN TODAS LAS INT. SE LIMPIA LA BANDERA LA INT
    RETURN
    
    INT_TIMER:
    CALL INTERTIMER
    BCF RBIF
    RETURN
    
    INT_FECHA:
    CALL INTERFECHA
    BCF RBIF
    RETURN
    
PSECT code, delta=2, abs
ORG 100h		    ; posición 100h para el codigo
 
TABLA:
    CLRF PCLATH
    BSF  PCLATH, 0
    ANDLW 0X0F; SE ASEGURA QUE SOLO EXISTAN 4 BITS
    ADDWF PCL
    RETLW 00111111B; 01000000B 0
    RETLW 00000110B ;01111001B 1
    RETLW 01011011B; 00100100B;2
    RETLW 01001111B ;00110000B;3
    RETLW 01100110B ;00011001B;4
    RETLW 01101101B ;00010010B;5
    RETLW 01111101B ;00000010B;6
    RETLW 00000111B ;01111000B;7
    RETLW 01111111B ;00000000B;8
    RETLW 01101111B ;00010000B;9
    RETLW 01110111B ;00001000B;A
;------------- CONFIGURACION ------------
MAIN:
    CALL    CONFIG_IO	    ; Configuración de I/O
    CALL    CONFIG_RELOJ    ; Configuración de Oscilador
    CALL    CONFIG_TMR0	    ; Configuración de TMR0
    CALL    CONFIG_TMR1	    ; Configuración de TMR1
    CALL    CONFIG_INT	    ; Configuración de interrupciones
    CALL    CONFIG_IOCRB
    BANKSEL PORTD	    ; Cambio a banco 00
 
    
LOOP: 
    CALL ALARMA    ;SE REVISA TODO EL TIEMPO SI EL TIMER LLEGA A PARA ACTIVAR LA ALARMA
    BTFSC MODO, 0  ;SE REVISA SI EL MODO ESTA EN RELOJ, TIMER O FECHA
    GOTO  LFECHA   ;SI ESTA EN MODO FECHA, SE REVISA
    BTFSC MODO, 1
    GOTO  LTIMER   ;SI ESTA EN MODO TIMER, SE REVISA
    
    LRELOJ:        ;SI ESTA EN MODO RELOJ, SE REVISA
    CALL SET_RELOJ ;SE LLAMA PARA QUE SE SETEE EL RELOJ
    GOTO LOOP
    
    LTIMER:	    ;SI ESTA EN MODO DE TIMER, SE REVISA
    CALL SET_TIMER  ;SE LLAMA PARA QUE SE SETEE EL TIMER
    GOTO LOOP
    
    LFECHA:	     ;SI ESTA EN MODO DE TIMER, SE REVISA
    CALL SET_FECHA   ;SE LLAMA PARA QUE SE SETEE EL TIMER
    GOTO LOOP
    	    
;------------- SUBRUTINAS ---------------
CONFIG_RELOJ:
    BANKSEL OSCCON	    ; cambiamos a banco 01
    BSF	    OSCCON,0	    ; SCS -> 1, Usamos reloj interno
    BSF	    OSCCON,6
    BCF	    OSCCON,5
    BCF	    OSCCON,4	    ; IRCF<2:0> -> 100 1MHz
    RETURN
    
; Configuramos el TMR0 para obtener un retardo de 2ms
CONFIG_TMR0:
    BANKSEL OPTION_REG	    ; cambiamos de banco
    BCF	    T0CS	    ; TMR0 como temporizador
    BCF	    PSA		    ; prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BCF	    PS0		    ; PS<2:0> -> 110 prescaler 1 : 128
    
    BANKSEL TMR0	    ; Cambiamos a banco 00
    MOVLW   252
    MOVWF   TMR0	    ; 50ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    RETURN 
    
CONFIG_TMR1:
    BANKSEL T1CON	    ; Cambiamos a banco 00
    BCF	    TMR1GE	    ; TMR1 siempre cuenta
    BSF	    T1CKPS1	    ; prescaler 1:4
    BCF	    T1CKPS0
    BCF	    T1OSCEN	    ; LP deshabilitado
    BCF	    TMR1CS	    ; Reloj interno
    BSF	    TMR1ON	    ; Prendemos TMR1
    
    RESET_TMR1 0x0B, 0xCD   ; Reiniciamos TMR1 para 1s
    RETURN
    
    
 CONFIG_IO:
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH	    ; I/O digitales
    
    BANKSEL TRISD
    CLRF    TRISC	    ; PORTC como salida
    CLRF    TRISD	    ; PORTD como salida
    CLRF    TRISA	    ; PORTA como salida
    BSF     TRISB,0         ; PORTB como ENTRADA
    BSF     TRISB,1
    BSF     TRISB,2
    BSF     TRISB,3
    BSF     TRISB,4
    BCF	    OPTION_REG,7; SE HABILITAN LOS PULL_UPS
    BSF	    WPUB,0	
    BSF	    WPUB,1
    BSF	    WPUB,2
    BSF	    WPUB,3
    BSF	    WPUB,4
    
    LIMPIAR:
    BANKSEL PORTD
    CLRF    PORTB	    ; Apagamos PORTB
    CLRF    PORTA	    ; Apagamos PORTA
    CLRF    PORTC	    ; Apagamos PORTC
    CLRF    PORTD
    BSF     PORTD,6
    BSF     PORTD,7
    CLRF    BANDERAS       ;SE LIMPIAN LAS VARIABLES
    CLRF    CONTM1         
    CLRF    CONTM2         
    CLRF    CONTH1         
    CLRF    CONTH2          
    CLRF    DISPLAY      
    CLRF    MODOEA
    BCF   MODOEA,0
    BCF   MODOEA,1
    CLRF    MODOIP
    BCF     MODOIP,0
    MOVLW   60          ;SE DEJA EL CONTADOR DE SEGUNDOS EN 60
    MOVWF   CONT60
    MOVLW 12		;SE DEJA EL CONTADOR DE MESES EN 12
    MOVWF CONTMES
    CLRF CONTDIA
    CLRF CONTD1
    CLRF CONTD2
    CLRF CONTME1
    CLRF CONTME2
    CLRF CONTST2
    CLRF CONTST1
    CLRF CONTMT1
    CLRF CONTMT2
    CLRF TIMEREA
    BCF TIMEREA,0
    BCF TIMEREA,1
    CLRF MODOIPT
    BCF MODOIPT,0
    BSF MODOIPT,1
    CLRF MESES
    CLRF DIAS
    MOVLW 1       ; SE DEJA EL CONTADOR DE DIAS Y MESES EN 1
    MOVWF MESES
    MOVWF DIAS
    MOVWF CONTD1
    MOVWF CONTME1
    CLRF  FECHAEA
    BCF   FECHAEA,0 ;SE DEJA EL MODO DE EDITAR FECHA EN 2
    BSF   FECHAEA,1
    CLRF CONT  
    MOVLW 60   ;SE DEJA EL CONTADOR DE LA ALARMA EN 60
    MOVWF CONT
    CLRF MODO
    BCF  MODO,0; SE DEJA EL MODO EN 0 (RELOJ)
    BCF  MODO,1 
    BSF  PORTA,0
    CLRF CONTLED ; SE DEJA EL CONTADOR DEL LED EN 250
    MOVLW 250		
    MOVWF CONTLED
    RETURN
    
CONFIG_INT:
    BANKSEL PIE1	    ; Cambiamos a banco 01
    BSF	    TMR1IE	    ; Habilitamos interrupciones de TMR1
    BSF	    TMR2IE	    ; Habilitamos interrupciones de TMR2
    
    BANKSEL INTCON	    ; Cambiamos a banco 00
    BSF	    PEIE	    ; Habilitamos interrupciones de perifericos
    BSF	    GIE		    ; Habilitamos interrupciones
    BSF	    T0IE	    ; Habilitamos interrupcion TMR0
    BCF	    T0IF	    ; Limpiamos bandera de TMR0
    BCF	    TMR1IF	    ; Limpiamos bandera de TMR1
    BCF	    TMR2IF	    ; Limpiamos bandera de TMR2
    BSF	    RBIE
    BCF	    RBIF
    RETURN
 
CONFIG_IOCRB:
    BANKSEL TRISB
    BSF IOCB,0    ; SE CONFIGURAN LAS ENTRADAS QUE SE QUIERE QUE CAMBIEN EN LA INT DE B
    BSF IOCB,1
    BSF IOCB,2
    BSF IOCB,3
    BSF IOCB,4
    
    BANKSEL PORTB
    MOVF    PORTB,W ; SE HACE UNA LECTURA DE b PARA EVITAR ERRORES
    BCF	    RBIF    ; SE LIMPIA LA BANDERA DEL CAMBIO EN EL PORT B
    RETURN

MOSTRAR_VALOR:
    BCF	    PORTD,0		; Apagamos display 0
    BCF	    PORTD,1		; Apagamos display 1
    BCF	    PORTD,2		; Apagamos display 2
    BCF	    PORTD,3		; Apagamos display 3
    
    BTFSC   BANDERAS,0		; Verificamos bandera
    GOTO    BANDERA1
    GOTO    BANDERA0
    		       

DISPLAY_0:			
	MOVF    DISPLAY,W	; Movemos display a W
	MOVWF   PORTC		; Movemos Valor de tabla a PORTC
	BSF	PORTD,0	         ; Encendemos display 0
	BSF	BANDERAS,0	; Cambiamos bandera para cambiar el otro display en la siguiente interrupción
	BCF	BANDERAS,1
    RETURN
    
DISPLAY_1:
	MOVF    DISPLAY+1, W	; Movemos display+1 a W
	MOVWF   PORTC		; Movemos Valor de tabla a PORTC
	BSF	PORTD,1	         ; Encendemos display 1
	BCF	BANDERAS,0	; Cambiamos bandera para cambiar el otro display en la siguiente interrupción
	BSF	BANDERAS,1
    RETURN
    
DISPLAY_2:
	MOVF    DISPLAY+2, W	; Movemos display+1 a W
	MOVWF   PORTC		; Movemos Valor de tabla a PORTC
	BSF	PORTD,2	        ; Encendemos display 2
	BSF	BANDERAS,0	; Cambiamos bandera para cambiar el otro display en la siguiente interrupción
	BSF	BANDERAS,1
    RETURN
    
DISPLAY_3:
	MOVF    DISPLAY+3, W	; Movemos display+1 a W
	MOVWF   PORTC		; Movemos Valor de tabla a PORTC
	BSF	PORTD, 3	; Encendemos display 3
	BCF	BANDERAS, 0	; Cambiamos bandera para cambiar el otro display en la siguiente interrupción
	BCF	BANDERAS, 1
    RETURN


BANDERA0: 
    BTFSC BANDERAS,1
    GOTO DISPLAY_2
    GOTO DISPLAY_0
    
    
BANDERA1:
    BTFSC BANDERAS,1
    GOTO DISPLAY_3
    GOTO DISPLAY_1
    
    
;FUNCION RELOJ 
RELOJ:
    DECFSZ   CONT60 ; SE REALIZA UN DECREMENTO DESDE 60
    RETURN
    
MINUTOS1:
    MOVLW    60
    MOVWF    CONT60
    INCF CONTM1  ;SE INCREMENTA EL CONTADOR DE MINUTOS 1
    MOVF CONTM1,W
    SUBLW 10; se resta el valor 10
    BANKSEL STATUS
    BTFSS STATUS,2; se revisa si la resta es igual a cero
    RETURN; si NO ES se regresa
 
    
MINUTOS2:   
    CLRF   CONTM1 ;SE LIMPIA EL CONTADOR DE MINUTOS 1
    INCF CONTM2	    ;SE INCREMENTA EL CONTADOR DE MINUTOS 2
    MOVF CONTM2,W; se mueve el valor del contador a W
    SUBLW 6; se resta el valor 10
    BANKSEL STATUS
    BTFSS STATUS,2; se revisa si la resta es igual a cero
    RETURN; si NO ES se regresa
    
    
HORAS1:
    BTFSC CONTH2, 0  ; SE REVISA SI EL CONTADOR DE HORAS 2 ESTA EN 0,1 O 2
    GOTO  HORA10 ; SI ESTA EN 1 SE LLAMA ESTE CONTADOR DE HORAS
    BTFSC CONTH2, 1
    GOTO  HORA4 ; SI ESTA EN 2 SE LLAMA ESTE CONTADOR DE HORAS
    GOTO  HORA10 ; SI ESTA EN 0 SE LLAMA ESTE CONTADOR DE HORAS
    
    HORA4: 
    CLRF   CONTM2 ;SE LIMPIA EL CONTADOR DE MINUTOS 2
    INCF CONTH1  ;SE INCREMENTA EL CONTADOR DE HORAS 1
    MOVF CONTH1, W
    SUBLW 4; se resta el valor 4 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN; si tiene se regresa
    GOTO HORAS2
    
    HORA10:
    CLRF   CONTM2 ;SE LIMPIA EL CONTADOR DE MINUTOS 2
    INCF CONTH1  ;SE INCREMENTA EL CONTADOR DE HORAS 1
    MOVF CONTH1, W
    SUBLW 10; se resta el valor 10 A W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN; si NO tiene se regresa
    GOTO HORAS2
    
HORAS2:   
    CLRF   CONTH1 ;SE LIMPIA EL CONTADOR DE HORAS 1
    INCF CONTH2  ;SE INCREMENTA EL CONTADOR DE HORAS 2
    MOVF CONTH2, W
    SUBLW 3; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN
    CLRF   CONTH2 ;SE LIMPIA EL CONTADOR DE HORAS 2
    RETURN

SET_RELOJ:
    MOVF    CONTM1,W		; Movemos CONTADOR DE  MINUTOS 1  a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY		; Guardamos en display
    
    MOVF    CONTM2,W	        ; Movemos CONTADOR DE  MINUTOS 2 A W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY+1		; Guardamos en display+1
    
    MOVF    CONTH1,W	        ; Movemos CONTADOR DE  HORAS 1  a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY+2		; Guardamos en display+2
    
    MOVF    CONTH2,W	        ; Movemos CONTADOR DE HORAS 2 a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY+3		; Guardamos en display+3
    RETURN
    
    
INTERHORAS:
    BTFSS  PORTB,0 ;SE REVISA QUE BOTON SE ESTA PRESIONANDO Y SE REALIZA LA FUNCION ADECUADA
    GOTO   INC_RELOJ
    BTFSS  PORTB,3
    GOTO   INPA_RELOJ
    BTFSS  PORTB,2
    GOTO   EDAC_RELOJ
    BTFSS  PORTB,1
    GOTO   DEC_RELOJ
   RETURN

INPA_RELOJ: ; MODO 1 INICIAR, MODO 0 PARAR
    BTFSS MODOIP,0
    GOTO  INICIAR_RELOJ

PARAR_RELOJ: ;SI EL RELOJ ESTA PARADO, ENTONCES SE INICIA
    BCF   MODOIP,0
    BSF   MODOEA,0
    BSF   MODOEA,1
    RETURN
 

INICIAR_RELOJ: ; SI EL RELOJ ESTA INICIADO, SE DEBE PARAR
    BSF MODOIP,0
    RETURN

EDAC_RELOJ:     
    BTFSC MODOIP,0
    RETURN
    
EDITAR_RELOJ: ; EDITAR EL RELOJ
    BTFSC   MODOEA,0 ; SE VERIFCA QUE EL RELOJ ESTE PARADO PARA EDITAR
    GOTO    MODOEA1
    GOTO    MODOEA0
    
MODOEA1:
    BTFSC   MODOEA,1; SE REVISA QUE DISPLAY SE DEBE DE EDITAR
    GOTO    OPERAR_H2
    GOTO    OPERAR_M2
    
MODOEA0:
    BTFSC   MODOEA, 1
    GOTO    OPERAR_H1
    GOTO    OPERAR_M1
    
OPERAR_H2:   ; DEPENDIENDO DE EN QUE DISPLAY SE ENCEUNTRE, SE VA AL SIGUIENTE...
    BCF MODOEA,0
    BSF MODOEA,1
    RETURN
    
OPERAR_M2:
    BCF MODOEA,0
    BCF MODOEA,1
    RETURN
    
OPERAR_H1:
    BSF MODOEA,0
    BCF MODOEA,1
    RETURN
    
OPERAR_M1:
    CLRF CONTH1
    BSF MODOEA,0
    BSF MODOEA,1
    RETURN

INC_RELOJ:   ; INCREMENTAR
    BTFSC MODOIP, 0 ; SE VERIFICA QUE ESTE PARADO EL RELOJ
    RETURN
    
    BTFSC   MODOEA, 0 ; DEPENDIENDO DEL DISPLAY SECCIONADO, SE INCREMNENTA
    GOTO    INCEA1
    GOTO    INCEA0
    
    INCEA1:
    BTFSC   MODOEA, 1
    GOTO    INCH2
    GOTO    INCM2
    
    INCEA0:
    BTFSC   MODOEA, 1
    GOTO    INCH1
    GOTO    INCM1
      
INCM1:
    INCF  CONTM1
    MOVF CONTM1, W
    SUBLW 10; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2; se revisa si la resta es igual a cero
    CLRF CONTM1
    RETURN
      
INCM2:
    BANKSEL PORTA
    INCF  CONTM2
    MOVF CONTM2, W
    SUBLW 6; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2; se revisa si la resta es igual a cero
    CLRF CONTM2
    RETURN
     
INCH1:
    BTFSC CONTH2, 0
    GOTO  INC9
    BTFSC CONTH2, 1
    GOTO  INC3
    GOTO  INC9
    
    
    INC3:
    INCF  CONTH1
    MOVF CONTH1, W
    SUBLW 4; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN
    CLRF CONTH1
    RETURN
    
    INC9:
    INCF  CONTH1
    MOVF CONTH1, W
    SUBLW 10; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN
    CLRF CONTH1
    RETURN
    
INCH2:
    INCF  CONTH2
    MOVF CONTH2, W
    SUBLW 3; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN
    CLRF CONTH2
    RETURN  
 
DEC_RELOJ:
    BTFSC MODOIP, 0
    RETURN
    
    BTFSC   MODOEA, 0		; Verificamos bandera
    GOTO    DECEA1
    GOTO    DECEA0
    
    DECEA1:
    BTFSC   MODOEA, 1
    GOTO    DECH2
    GOTO    DECM2
    
    DECEA0:
    BTFSC   MODOEA, 1
    GOTO    DECH1
    GOTO    DECM1
      
DECM1:
    MOVF CONTM1, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 9
    MOVWF CONTM1
    RETURN
    DECF  CONTM1
    RETURN
      
DECM2:
    MOVF CONTM2, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 5
    MOVWF CONTM2
    RETURN
    DECF  CONTM2
    RETURN
     
DECH1:
    BTFSC CONTH2, 0
    GOTO  DEC9
    BTFSC CONTH2, 1
    GOTO  DEC3
    GOTO  DEC9
    
    DEC3:
    MOVF CONTH1, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 3
    MOVWF CONTH1
    RETURN
    DECF  CONTH1
    RETURN
    
    DEC9:
    MOVF CONTH1, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 9
    MOVWF CONTH1
    RETURN
    DECF  CONTH1
    RETURN
    
DECH2:
    MOVF CONTH2, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 3
    MOVWF CONTH2
    RETURN
    DECF  CONTH2
    RETURN

;FUNCION  FECHA 
INTERFECHA:
    BTFSS  PORTB, 0
    GOTO   INC_FECHA
    BTFSS  PORTB,2
    GOTO   EDAC_FECHA
    BTFSS  PORTB, 1
    GOTO   DEC_FECHA
    BTFSS  PORTB,3
    NOP
    RETURN

EDAC_FECHA:
    BTFSC   FECHAEA,0		; Verificamos bandera
    GOTO    EDITAR_DIA
    BTFSC   FECHAEA,1
    GOTO    ACEPTAR_FECHA
    GOTO    EDITAR_MES
    
    EDITAR_DIA:
    BCF FECHAEA,0
    BSF FECHAEA,1
    RETURN
    
    EDITAR_MES:
    BSF FECHAEA,0
    BCF FECHAEA,1
    MOVLW 1
    MOVWF CONTD1
    CLRF  CONTD2
    RETURN
    
   ACEPTAR_FECHA:
    BCF FECHAEA,0
    BCF FECHAEA,1
    RETURN


 OBTENER_DIA:
    CLRF    CONTD1
    CLRF    CONTD2
    CLRF    CONTDIA
    MOVF    DIAS, W		; Valor del PORTA a W
    MOVWF   CONTDIA
    MOVLW   10		    ;se gurada en W el literal 100
    SUBWF   CONTDIA,F	    ; se le resta el literal al numero y se guarda en si mismo
    INCF    CONTD2	    ; se incrementa el contador de centenas
    BTFSC   STATUS,0	    ; se revisa si hubo un bit de BORROW 
    GOTO    $-4		    ; si no hubo, regresa a restar
    DECF    CONTD2	    ; si hubo, se decrementa el conatdor de centenas
    MOVLW   10		    ;se gurada en W el literal 10
    ADDWF   CONTDIA,F	    ; se le resta el literal al numero y se guarda en si mismo
    MOVLW   1		    ;se gurada en W el literal 1
    SUBWF   CONTDIA,F	    ; se le resta el literal al numero y se guarda en si mismo
    INCF    CONTD1	    ; se incrementa el contador de unidades
    BTFSC   STATUS, 0	    ; se revisa si hubo un bit de BORROW
    GOTO    $-4		    ; si no hubo, regresa a restar
    DECF    CONTD1	    ; si hubo, se decrementa el conatdor de unidades
   RETURN
   
OBTENER_MES:
    CLRF    CONTME1
    CLRF    CONTME2
    CLRF    CONTMES
    MOVF    MESES, W		; Valor del PORTA a W
    MOVWF   CONTMES
    MOVLW   10		    ;se gurada en W el literal 100
    SUBWF   CONTMES,F	    ; se le resta el literal al numero y se guarda en si mismo
    INCF    CONTME2	    ; se incrementa el contador de centenas
    BTFSC   STATUS,0	    ; se revisa si hubo un bit de BORROW 
    GOTO    $-4		    ; si no hubo, regresa a restar
    DECF    CONTME2	    ; si hubo, se decrementa el conatdor de centenas
    MOVLW   10		    ;se gurada en W el literal 100
    ADDWF   CONTMES,F	    ; se le resta el literal al numero y se guarda en si mismo
    MOVLW   1		    ;se gurada en W el literal 1
    SUBWF   CONTMES,F	    ; se le resta el literal al numero y se guarda en si mismo
    INCF    CONTME1	    ; se incrementa el contador de unidades
    BTFSC   STATUS,0	    ; se revisa si hubo un bit de BORROW
    GOTO    $-4		    ; si no hubo, regresa a restar
    DECF    CONTME1	    ; si hubo, se decrementa el conatdor de unidades
    RETURN
    
SET_FECHA:
    MOVF    CONTME1,W		; Movemos nibble bajo a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY		; Guardamos en display
    
    MOVF    CONTME2,W	        ; Movemos nibble alto a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY+1		; Guardamos en display+1
    
    MOVF    CONTD1,W	        ; Movemos nibble alto a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY+2		; Guardamos en display+1
    
    MOVF    CONTD2,W	        ; Movemos nibble alto a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY+3		; Guardamos en display+1
    RETURN
    
    
   
INC_FECHA:
    BTFSC   FECHAEA,0		; Verificamos bandera
    GOTO    INC_DIA
    BTFSC   FECHAEA,1
    RETURN
    
    INC_MES:
    BSF PORTA,7
    INCF  MESES
    MOVF MESES, W
    SUBLW 13; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO OBTENER_MES
    CLRF  MESES
    INCF MESES
    GOTO OBTENER_MES
    
    INC_DIA:
    CALL REVISAR_MES
    BTFSC   MODODIAS,0		; Verificamos bandera
    GOTO    INC_30
    BTFSC   MODODIAS,1
    GOTO    INC_28
    
    INC_31:
    INCF  DIAS
    MOVF DIAS, W
    SUBLW 32; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO OBTENER_DIA
    CLRF  DIAS
    INCF  DIAS
    GOTO OBTENER_DIA
    
    INC_30:
    INCF  DIAS
    MOVF DIAS, W
    SUBLW 31; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO OBTENER_DIA
    CLRF  DIAS
    INCF  DIAS
    GOTO OBTENER_DIA
    
    INC_28:
    INCF  DIAS
    MOVF DIAS, W
    SUBLW 29; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO OBTENER_DIA
    CLRF  DIAS
    INCF  DIAS
    GOTO OBTENER_DIA

    
DEC_FECHA:
    BTFSC   FECHAEA,0		; Verificamos bandera
    GOTO    DEC_DIA
    BTFSC   FECHAEA,1
    RETURN
    
    DEC_MES:
    MOVF MESES, W
    SUBLW 1; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 12
    MOVWF MESES
    GOTO OBTENER_MES
    DECF  MESES
    GOTO OBTENER_MES
    
    DEC_DIA:
    CALL    REVISAR_MES
    BTFSC   MODODIAS,0		; Verificamos bandera
    GOTO    DEC_30
    BTFSC   MODODIAS,1
    GOTO    DEC_28
    
    DEC_31:
    MOVF DIAS, W
    SUBLW 1; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 31
    MOVWF DIAS
    GOTO OBTENER_DIA
    DECF  DIAS
    GOTO OBTENER_DIA
    
    DEC_30:
    MOVF DIAS, W
    SUBLW 1; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 30
    MOVWF DIAS
    GOTO OBTENER_DIA
    DECF  DIAS
    GOTO OBTENER_DIA
    
    DEC_28:
    MOVF DIAS, W
    SUBLW 1; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 28
    MOVWF DIAS
    GOTO  OBTENER_DIA
    DECF  DIAS
    GOTO  OBTENER_DIA

REVISAR_MES: ;MODO 0:31 DIAS, MODO 1:30 DIAD, MODO 2:28 DIAS
    MOVF MESES, W
    SUBLW 1; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    BCF MODODIAS,0
    BCF MODODIAS,1
    MOVF MESES, W
    SUBLW 2; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    BCF MODODIAS,0
    BSF MODODIAS,1
    MOVF MESES, W
    SUBLW 3; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    BCF MODODIAS,0
    BCF MODODIAS,1
    MOVF MESES, W
    SUBLW 4; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    BSF MODODIAS,0
    BCF MODODIAS,1
    MOVF MESES, W
    SUBLW 5; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    BCF MODODIAS,0
    BCF MODODIAS,1
    MOVF MESES, W
    SUBLW 6; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    BSF MODODIAS,0
    BCF MODODIAS,1
    MOVF MESES, W
    SUBLW 7; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    BCF MODODIAS,0
    BCF MODODIAS,1
    MOVF MESES, W
    SUBLW 8; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    BCF MODODIAS,0
    BCF MODODIAS,1
    MOVF MESES, W
    SUBLW 9; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    BSF MODODIAS,0
    BCF MODODIAS,1
    MOVF MESES, W
    SUBLW 10; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    BCF MODODIAS,0
    BCF MODODIAS,1
    MOVF MESES, W
    SUBLW 11; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    BSF MODODIAS,0
    BCF MODODIAS,1
    MOVF MESES, W
    SUBLW 12; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    BCF MODODIAS,0
    BCF MODODIAS,1
    RETURN
    
    
    
    
 ;FUNCION_TIMER:

    
SEG_TIMER1:
    MOVF CONTST1, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    DECF  CONTST1
    RETURN
    MOVF CONTST2, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2
    GOTO $+2
    GOTO SEG_TIMER2
    MOVF CONTMT1, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2
    GOTO $+2
    GOTO MIN_TIMER1
    MOVF CONTMT2, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2
    RETURN
    GOTO MIN_TIMER2
 
    
SEG_TIMER2:   
    MOVLW 9
    MOVWF CONTST1
    MOVF CONTST2, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    DECF  CONTST2
    RETURN
     MOVF CONTMT1, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2
    GOTO $+2
    GOTO MIN_TIMER1
    MOVF CONTMT2, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2
    RETURN
    GOTO MIN_TIMER2
    
    
MIN_TIMER1:
    MOVLW 9
    MOVWF CONTST1
    MOVLW 5
    MOVWF CONTST2
    MOVF CONTMT1, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+3
    DECF  CONTMT1
    RETURN
    MOVF CONTMT2, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2
    RETURN
    
MIN_TIMER2:
    MOVLW 9
    MOVWF CONTST1
    MOVLW 5
    MOVWF CONTST2
    MOVLW 9
    MOVWF CONTMT1
    MOVF CONTMT2, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    DECF  CONTMT2
    RETURN
    
SET_TIMER:
    MOVF    CONTST1,W		; Movemos nibble bajo a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY		; Guardamos en display
    
    MOVF    CONTST2,W	        ; Movemos nibble alto a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY+1		; Guardamos en display+1
    
    MOVF    CONTMT1,W	        ; Movemos nibble alto a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY+2		; Guardamos en display+1
    
    MOVF    CONTMT2,W	        ; Movemos nibble alto a W
    CALL    TABLA		; Buscamos valor a cargar en PORTC
    MOVWF   DISPLAY+3		; Guardamos en display+1
    RETURN
    
    
INTERTIMER:
    BTFSS  PORTB,0
    GOTO   INC_TIMER
    BTFSS  PORTB,3
    CALL   INPA_TIMER
    BTFSS  PORTB,2
    GOTO   EDAC_TIMER
    BTFSS  PORTB,1
    GOTO   DEC_TIMER
   RETURN

INPA_TIMER: ; MODO 00 INICIAR, MODO 01 PARAR
    BTFSC   MODOIPT,0		; Verificamos bandera
    GOTO    PARAR_CALARMA
    BTFSC   MODOIPT,1
    GOTO    PARAR_SALARMA
    GOTO    INICIAR_TIMER

PARAR_CALARMA:
    BCF   MODOIPT,0
    BSF   MODOIPT,1
    BCF   PORTA, 4
    RETURN
 

PARAR_SALARMA:
    CALL VERIFICAR
    BCF TIMEREA,0
    BCF TIMEREA,1
    RETURN
    
INICIAR_TIMER:
    BCF   MODOIPT,0
    BSF   MODOIPT,1
    BSF   TIMEREA,0
    BSF   TIMEREA,1
    RETURN

EDAC_TIMER:
    BTFSC MODOIPT,0
    RETURN
    BTFSS MODOIPT,1
    RETURN

EDITAR_TIMER:
    BTFSC   TIMEREA,0		; Verificamos bandera
    GOTO    TIMEREA1
    GOTO    TIMEREA0
    
TIMEREA1:
    BTFSC   TIMEREA,1
    GOTO    OPERAR_MT2
    GOTO    OPERAR_ST2
    
TIMEREA0:
    BTFSC   TIMEREA, 1
    GOTO    OPERAR_MT1
    GOTO    OPERAR_ST1
    
OPERAR_MT2:
    BCF TIMEREA,0
    BSF TIMEREA,1
    RETURN
    
OPERAR_ST2:
    BCF TIMEREA,0
    BCF TIMEREA,1
    RETURN
    
OPERAR_MT1:
    BSF TIMEREA,0
    BCF TIMEREA,1
    RETURN
    
OPERAR_ST1:
    BSF TIMEREA,0
    BSF TIMEREA,1
    RETURN

INC_TIMER:
    BTFSC MODOIPT,0
    RETURN
    BTFSS MODOIPT,1
    RETURN
    
    BTFSC   TIMEREA, 0		; Verificamos bandera
    GOTO    INCT1
    GOTO    INCT0
    
    INCT1:
    BTFSC   TIMEREA, 1
    GOTO    INCMT2
    GOTO    INCST2
    
    INCT0:
    BTFSC   TIMEREA, 1
    GOTO    INCMT1
    GOTO    INCST1
      
INCST1:
    MOVF CONTST2, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO INC0
    MOVF CONTMT1, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO INC0
    MOVF CONTMT2, W
    SUBLW 0; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2; se revisa si la resta es igual a cero
    GOTO INC1
    
    INC0:
    INCF  CONTST1
    MOVF CONTST1, W
    SUBLW 10; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2; se revisa si la resta es igual a cero
    CLRF  CONTST1
    RETURN
    
    
    INC1:
    INCF  CONTST1
    MOVF CONTST1, W
    SUBLW 10; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN
    CLRF  CONTST1
    INCF CONTST1
    RETURN
      
INCST2:
    BANKSEL PORTA
    INCF  CONTST2
    MOVF CONTST2, W
    SUBLW 6; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSC STATUS, 2; se revisa si la resta es igual a cero
    CLRF CONTST2
    RETURN
     
INCMT1:
    INCF  CONTMT1
    MOVF CONTMT1, W
    SUBLW 10; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN
    CLRF CONTMT1
    RETURN
    
INCMT2:
    INCF  CONTMT2
    MOVF CONTMT2, W
    SUBLW 10; se resta el valor del PortD a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN
    CLRF CONTMT2
    RETURN  
 
DEC_TIMER:
    BTFSC MODOIPT,0 ; SE VERIFICA QUE SE ESTE EN EL MODO DE TIMER
    RETURN
    BTFSS MODOIPT,1
    RETURN
    
    BTFSC   TIMEREA, 0		
    GOTO    DECT1
    GOTO    DECT0
    
    DECT1:		;SE VERIFICA QUE DISPLAY SE TIENE PARA EDITAR
    BTFSC   TIMEREA, 1
    GOTO    DECMT2
    GOTO    DECST2
    
    DECT0:
    BTFSC   TIMEREA, 1
    GOTO    DECMT1
    GOTO    DECST1
      
DECST1:
    MOVF CONTST2, W
    SUBLW 0; se resta el valor 0 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO DEC0     ; SI NO ESTA EN CERO, SE DIRIGE A DEC0
    MOVF CONTMT1, W
    SUBLW 0; se resta el valor 0 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO DEC0  ; SI NO ESTA EN CERO, SE DIRIGE A DEC0
    MOVF CONTMT2, W
    SUBLW 0; se resta el valor 0 a W
    BANKSEL STATUS
    BTFSC STATUS, 2; se revisa si la resta es igual a cero
    GOTO DEC1   ; SI TODOS ESTAN EN CERO, SE DIRIGE A DEC1
    
    DEC0:
    MOVF CONTST1, W
    SUBLW 0; se resta el valor 0 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 9    ; SI ESTA EN 0, SE ESCRIBE UN 9 EN EL CONTADOR
    MOVWF CONTST1 
    RETURN
    DECF  CONTST1 ; SI NO ESTA EN 0, SE DECREMENTA
    RETURN
    
    DEC1:
    MOVF CONTST1, W
    SUBLW 1; se resta el valor 1 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 9
    MOVWF CONTST1 ; SI ESTA EN 1, SE ESCRIBE UN 9 EN EL CONTADOR
    RETURN
    DECF  CONTST1 ; SI NO ESTA EN 1, SE DECREMENTA
    RETURN
      
DECST2:
    MOVF CONTST2, W
    SUBLW 0; se resta el valor 0 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 5
    MOVWF CONTST2 ; SI ESTA EN 0, SE ESCRIBE UN 5 EN EL CONTADOR
    RETURN
    DECF  CONTST2 ; SI NO ESTA EN 0, SE DECREMENTA
    RETURN
     
DECMT1:
    MOVF CONTMT1, W
    SUBLW 0; se resta el valor 0 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 9  ; SI ESTA EN 0, SE ESCRIBE UN 9 EN EL CONTADOR
    MOVWF CONTMT1
    RETURN
    DECF  CONTMT1; SI NO ESTA EN 0, SE DECREMENTA
    RETURN
    
DECMT2:
    MOVF CONTMT2, W
    SUBLW 0; se resta el valor del 0 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO $+4
    MOVLW 9; SI ESTA EN 0, SE ESCRIBE UN 9 EN EL CONTADOR
    MOVWF CONTMT2
    RETURN
    DECF  CONTMT2; SI NO ESTA EN 0, SE DECREMENTA
    RETURN

ALARMA:
    BTFSC MODOIPT,0; SE REVISA SI ESTA ACTIVADO EL CONTEO DEL TIMER
    RETURN
    BTFSC MODOIPT,1
    RETURN 
    MOVF CONTST1, W
    SUBLW 0; se resta el valor 0 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN ; SI NO REGRESA
    MOVF CONTST2, W
    SUBLW 0; se resta el valor 0 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN ; SI NO REGRESA
    MOVF CONTMT1, W
    SUBLW 0; se resta el valor del 0 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN ; SI NO REGRESA
    MOVF CONTMT2, W
    SUBLW 0; se resta el valor del 0 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    RETURN ; SI NO REGRESA
    BSF PORTA, 4 ; SE ENCIENDE LA ALARMA
    BSF MODOIPT,0 ; SE ACTIVA EL MODO DE PARAR EL CONTEO CON ALARMA ENCENDIDA
    BCF MODOIPT,1
    MOVLW 60	    ; SE LE INGRESA EL VALOR DE 60 AL CONTADOR DE LA ALARMA
    MOVWF   CONT
    RETURN
    
VERIFICAR:
    MOVF CONTST1, W
    SUBLW 0; se resta el valor 0 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO MODO1
    MOVF CONTST2, W
    SUBLW 0; se resta el valor 0 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO MODO1
    MOVF CONTMT1, W
    SUBLW 0; se resta el valor 0 a W
    BANKSEL STATUS
    BTFSS STATUS, 2; se revisa si la resta es igual a cero
    GOTO MODO1
    MOVF CONTMT2, W
    SUBLW 0; se resta el valor 0 a W
    BANKSEL STATUS
    BTFSC STATUS, 2; se revisa si la resta es igual a cero
    RETURN ; SI NO REGRESA
    
    MODO1:
    BCF   MODOIPT,0; SE HACE QUE EL TIMER ESTE EN 0 SIEMPRE QUE NO HAYA NADA EN LOS DISPLAYS
    BCF   MODOIPT,1
    RETURN
    
  MINUTO_ALARMA: 
    BTFSS  PORTA,4 ; SE REVISA SI LA ALARMA ESTA ENCENDIDA
    RETURN
    DECFSZ CONT ; SI ESTA ENCENDIDA, SE DECREMENTA EL CONTADOR QUE ESTA EN 60
    RETURN
    BCF   MODOIPT,0 ; SI PASA UN MINUTO, PARA
    BSF   MODOIPT,1
    BCF   PORTA, 4
    RETURN
   
   MODOS: ;MODO0:RELOJ, MODO1:FECHA, MODO2:TIMER
    BTFSC MODO, 0 ; SE REVISA EN QUE MODO SE ENCEUNTRA Y SE VA A ESE MODO
    GOTO  MODO_FECHA
    BTFSC MODO, 1
    GOTO  MODO_TIMER
    
    MODO_RELOJ: 
    BSF MODO,0; EN ESTE MODO, SE PASA AL MODO DE FECHA
    BCF MODO,1
    BCF PORTA,0
    BSF PORTA,1; SE ENCEINDE EL PIN1, O EL SEGUNDO LED DE LOS MODOS
    BCF PORTA,2
    BCF RBIF
    RETURN
    
    MODO_FECHA:
    BCF MODO,0; EN ESTE MODO, SE PASA AL MODO DE TIMER
    BSF MODO,1
    BSF PORTA,2; SE ENCEINDE EL PIN2, O EL TERCER LED DE LOS MODOS
    BCF PORTA,0
    BCF PORTA,1
    BCF RBIF
    RETURN
    
    MODO_TIMER:
    BCF MODO,0; EN ESTE MODO, SE PASA AL MODO DE RELOJ
    BCF MODO,1
    BSF PORTA,0 ; SE ENCEINDE EL PIN0, O EL PRIMER LED DE LOS MODOS
    BCF PORTA,1
    BCF PORTA,2
    BCF RBIF
    RETURN
    
    LEDS:
    DECFSZ   CONTLED ;SE ASEGURA DE QUE HAYAN PASADO 500 MS
    RETURN
    
    MOVLW 250
    MOVWF CONTLED
    BTFSC PORTD,6; VERIFICAR SI ESTA ENCENDIDO O APAGADO
    GOTO APAGAR
    
    ENCENDER:
    BSF PORTD,6; SI ESTA APAGAD0, SE ENCIENDE
    BSF PORTD,7
    RETURN
    
    APAGAR:
    BCF PORTD,6; SI ESTA ENCENDIDO, SE APAGA
    BCF PORTD,7
    RETURN
 
END



