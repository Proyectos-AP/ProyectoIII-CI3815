#
# Relojhandler.asm
#
# Descripcion: Este manejador de interrupciones
# modifica el tiempo de un reloj de acuerdo a 
# interrupciones por teclado.
#
# Nombres:
#	Alejandra Cordero / Carnet: 12-10645
#	Pablo Maldonado   / Carnet: 12-10561
#
# Ultima modificacion: 05/03/2015
#

##############################################################
#                    SECCION DE DATOS                        #
##############################################################

	.kdata

.globl reloj
reloj:		.word		0	
registros:	.word		0,1,2,3,4,5,6
m_tiempo:		.asciiz		"Time:   :   \n"
m_fin:		.asciiz		"Finalizara la ejecucion del programa. \n"

##############################################################
#                    SECCION DE MACROS                       #
##############################################################

.macro finalizarPrograma()
	li $v0,10
	syscall
.end_macro

.macro imprimir_t(%direccion)
	li $v0,4
	la $a0,%direccion
	syscall
.end_macro

##############################################################
#              MANEJADOR DE LA INTERRUPCION                  #
##############################################################

	# Direccion donde se almacenan los manejadores de instrucciones:

	.ktext 0x80000180
	
	# Respaldamos $at:
	move $k0,$at

	# Primero se deben guardar todos los registros antes de manejar la interrupcion:
	sw $a0, registros
	sw $t0, registros+4
	sw $t1, registros+8
	sw $t2, registros+12
	sw $t3, registros+16
	sw $v0, registros+20
	sw $v1, registros+24

	# Se verifica si la interrupcion fue un syscall:

	mfc0 $k0 $13				# $k0 almacena el contenido del $13 del Coprocesador 0 
	srl $a0 $k0 2				# Se hace un shift para extraer el codigo de la interrupcion
	andi $a0 $a0 0x1f   		# Se extrae el codigo de la interrupcion
	
	beq $a0,8,verificar_scall 	# Se verifica si es un syscall
	beq $a0,0,interrup_reloj 	# Se verifica si es una interrupicion por hardware


verificar_scall:		
	# Se verifica si el syscall fue el numero 100	
	beq $v0,100,scall_100
	bne $v0,100,noScall_100


##############################################################
#              INTERRUPCION POR SOFTWARE                     #
##############################################################
	
noScall_100:

	# En caso de que no sea un syscall 100, se vuelve 
	# al programa principal:

	# Se actualiza el EPC antes de volver (Interrupcion por Software): 
	mfc0,$t0,$14  		# $t0 contiene el valor del $14 del coprocesador 0 
	addi $t0,$t0,4
	mtc0 $t0,$14
	b volver

scall_100:

	# Se habilitan las interrupciones por Software: Con el 
	# ori de la linea 100 se encienden los siguientes bits:
	#	- Bit 0 : Leer y Escribir (Interruptions Enabled)
	#	- Bit 1 : Exception Label (Nivel Hardware)
	#	- Bit 8 : Interrupciones de Teclado
	#	- Bit 9 : Interrupciones del Monitor (Display)

	mfc0 $k0 $12	# $k0 contiene el valor del $12 del coprocesador 0 		
	ori  $k0 0x0301
	mtc0 $k0 $12

	# Se habilitan las interrupciones por Software: 

	li $t0, 0xffff0000     # Se carga en $t0 el registro de control del Teclado
	li $t1, 0x00000002     # Se habilitan las interrupciones
	sw $t1, ($t0)

	li $t0, 0xffff0008     # Se carga en $t0 el registro de control del Monitor
	li $t1, 0x00000002     # Se habilitan las interrupciones
	sw $t1, ($t0)

	# Se resetea el reloj:
	sb $zero,reloj+3
	sb $zero,reloj+2
	sb $zero,reloj+1
	sb $zero,reloj

	# Se actualiza el EPC antes de volver (Interrupcion por Software):
	mfc0,$t0,$14 		# $t0 contiene el valor del $14 del coprocesador 0 
	addi $t0,$t0,4
	mtc0 $t0,$14

	b volver

##############################################################
#            INTERRUPCION POR HARDWARE (RELOJ)               #
##############################################################

interrup_reloj:

	# Se revisa la tecla que se marco:	
	lb  $t0, 0xffff0004		# $t0 contiene la letra (ASCII) correspondiente
	beq $t0,116,letra_t		# a la tecla que se marco en el MMIO Keyboard
	beq $t0,114,letra_r
	beq $t0,113,letra_q
	b volver
	
letra_t:
		
	# Se obtiene el valor de la primera cifra de los segundos 12:3X:
	lb $t1,reloj

	# Se verifica si es necesario aumentar una decima a 
	# los segundos:
	beq $t1,9,s_agregarDecimas

	# Aumenta el tiempo en 1 segundo 12:3X -> 12:3[X+1]:
	addi $t1,$t1,1	
	
	# En caso de que no sea necesario aumentar una decima
	# a los segundos, se almacena el nuevo valor en el 
	# reloj, y se imprime el tiempo nuevo:
	sb $t1,reloj
	b imprime_monitor

s_agregarDecimas:
	
	# Se resetea el primer valor de los segundos 12:3X -> 12:30:	
	sb $zero,reloj		

	# Se obtiene el valor de segunda cifra de los segundos 12:X3
	lb $t2,reloj+1

	# Se verifica si es necesario aumentar un minuto: (12:59):
	beq $t2,5,m_agregarUnidad

	# Se agrega una unidad a las decimas de los segundos 12:X3 -> 12:[X+1]3:
	addi $t2,$t2,1
	sb $t2,reloj+1
	b imprime_monitor
	
m_agregarUnidad:

	# Se obtiene el valor de la primera cifra de los minutos 1X:34:
	lb $t1,reloj+2

	# Se verifica si es necesario aumentar una decima a 
	# los segundos:
	beq $t1,9,m_agregarDecimas

	# Aumenta el tiempo en 1 minuto:
	addi $t1,$t1,1
		
	# En caso de que no sea necesario aumentar una decima
	# a los minutos, se almacena el nuevo valor en el 
	# reloj, y se imprime el tiempo nuevo:
	sb $t1,reloj+2
	sb $zero reloj+1
	b imprime_monitor

m_agregarDecimas:

	# Se resetea el primer valor de los minutos 19:59 -> 20:00:
	sb $zero,reloj+2	

	# Se obtiene el valor de la segunda cifra de los minutos X3:34:
	lb $t2,reloj+3

	# Se verifica si es necesario resetear el reloj 59:59:
	beq $t2,5,letra_r

	# En caso de que no sea necesario resetear el reloj,
	# se almacena el nuevo valor y se imprime el 
	#tiempo nuevo:
	addi $t2,$t2,1
	sb $t2,reloj+3
	b imprime_monitor
	

imprime_monitor:

	# Nota: Como los numeros se trabajaron como enteros,
	# al momento de imprimir se les suma 48 unidades
	# para obtener su codigo ASCII correspondiente:

	lb $t0,reloj+3		# $t0 contiene la segunda cifra de los minutos X2:30
	addi $t0,$t0,48

	lb $t1,reloj+2  	# $t1 contiene la primera cifra de los minutos 1X:30
	addi $t1,$t1,48

	lb $t2,reloj+1		# $t2 contiene la segunda cifra de los segundos 12:X0
	addi $t2,$t2,48

	lb $t3,reloj		# $t3 contiene la primera cifra de los segundos 12:0X
	addi $t3,$t3,48

	# Se actualiza la estructura del mensaje de salida
	# del tiempo actual:
	sb $t0,m_tiempo+6
	sb $t1,m_tiempo+7
	sb $t2,m_tiempo+9
	sb $t3,m_tiempo+10

	# Se inicializan las variables de iteracion
	# del ciclo de impresion del monitor	
	lb $t0,m_tiempo 	# $t0 contiene la primera letra de m_tiempo
	li $t2,0			# $t2 es el registro de iteracion

loopMonitorTime:
	# Se carga en $t1 el registro de control del Monitor
	lw $t1, 0xFFFF0008

	# Se verifica el bit de Ready
	andi $t1,$t1,1
	beqz $t1,loopMonitorTime

	# Se almacena en el registro de datos del Monitor
	# el caracter a imprimir:
	sw $t0,0xFFFF000C
	
	# Se actualizan las variables de iteracion del ciclo:
	addi $t2,$t2,1
	lb  $t0,m_tiempo($t2)
	bnez $t0 loopMonitorTime

	# Se imprime el tiempo actual: (por consola)
	imprimir_t(m_tiempo)
 	b volver

letra_r:
	# Se resetea el reloj:	
	li $t0,0
	sb $t0,reloj+2
	sb $t0,reloj+3
	sb $t0,reloj
	sb $t0,reloj+1

	# Se imprime el tiempo actual (Por Monitor):
	b imprime_monitor
	
letra_q:
	
	# Se imprime por consola el mensaje de salida:
	imprimir_t(m_fin)

imprime_salir:
	
	# Se inicializan las variables de iteracion
	# del ciclo de impresion del monitor	
	lb $t0,m_fin # $t0 contiene la primera letra de m_fin
	li $t2,0     # $t2 es el registro de iteracion

loopMonitorSalir:

	# Se carga en $t1 el registro de control del Monitor
	lw $t1, 0xFFFF0008

	# Se verifica el bit de Ready
	andi $t1,$t1,1
	beqz $t1,loopMonitorSalir

	# Se almacena en el registro de datos del Monitor
	# el caracter a imprimir:
	sw $t0,0xFFFF000C

	# Se actualizan las variables de iteracion del ciclo:
	addi $t2,$t2,1
	lb  $t0,m_fin($t2)
	bnez $t0 loopMonitorSalir

	# Finaliza la ejecucion del programa:
	finalizarPrograma()

volver: 	

	# Se limpia el registro $13 del Coprocesador 0:	
	mtc0 $zero,$13 

	# Se restauran todos los registros que se habian guardado:
	lw $a0, registros
	lw $t0, registros+4
	lw $t1, registros+8
	lw $t2, registros+12
	lw $t3, registros+16
	lw $v0, registros+20
	lw $v1, registros+24
	
	# Restauramos $at:	
	move $at, $k0

	# Se retorna de la interrupcion:
	eret
