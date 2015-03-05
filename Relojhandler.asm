#
# Relojhandler.asm
#
# Descripcion:
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
dos_puntos:	.asciiz		":"
salto_linea:	.asciiz		"\n"
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

#.macro imprimir_i(%posicion+%valor)
#	li $v0,1
#	lb $a0,%posicion+%valor
#	syscall
#.end_macro

##############################################################
#              MANEJADOR DE LA INTERRUPCION                  #
##############################################################

	# Direccion donde se almacenan los manejadores de instrucciones:

	.ktext 0x80000180
	
	# Planificador de registros:
	
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

	mfc0 $k0 $13		# Cause register
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	
	beq $a0,8,verificar_scall
	beq $a0,0,interrup_reloj


verificar_scall:
	
	beq $v0,100,scall_100
	bne $v0,100,noScall_100
	
noScall_100:
	
	# Se actualiza el EPC antes de volver: 
	mfc0,$t0,$14
	addi $t0,$t0,4
	mtc0 $t0,$14
	b volver

scall_100:

	# Se habilitan las interrupciones por software

	mfc0 $k0 $12			# Set Status register
	ori  $k0 0x0301		# Interrupts enabled
	mtc0 $k0 $12

	li      $t0, 0xffff0000     # Receiver control register (Teclado)
	li      $t1, 0x00000002     # Interrupt enable bit
	sw      $t1, ($t0)

	li      $t0, 0xffff0008     # Receiver control register (Monitor)
	li      $t1, 0x00000002     # Interrupt enable bit
	sw      $t1, ($t0)

	# Se resetea el reloj:

	sb $zero,reloj+3
	sb $zero,reloj+2
	sb $zero,reloj+1
	sb $zero,reloj

	# Se limpia el registro $13 del Coprocesador 0:	
	mtc0 $zero,$13 

	# Se actualiza el EPC antes de volver: 
	mfc0,$t0,$14
	addi $t0,$t0,4
	mtc0 $t0,$14

	b volver


interrup_reloj:

	# Se revisa la tecla que se marco	
	lb  $t0, 0xffff0004	
	beq $t0,116,letra_t
	beq $t0,114,letra_r
	beq $t0,113,letra_q
	b volver
	
letra_t:
		
	# Se obtiene el tiempo actual:
	lb $t1,reloj

	# Se verifica si es necesario aumentar una decima a 
	# los segundos:
	beq $t1,9,s_agregarDecimas

	# Aumenta el tiempo en 1 segundo:
	addi $t1,$t1,1
		
	# En caso de que no sea necesario aumentar una decima
	# a los segundos:
	sb $t1,reloj
	b imprime_tiempo

s_agregarDecimas:
	
	sb $zero,reloj		
	lb $t2,reloj+1
	beq $t2,5,m_agregarUnidad

	addi $t2,$t2,1
	sb $t2,reloj+1
	b imprime_tiempo
	
m_agregarUnidad:

	# Se obtiene el tiempo actual:
	lb $t1,reloj+2

	# Se verifica si la hora es de la forma X9:XX
	#beq $t1,9,verificar_reset

	# Se verifica si es necesario aumentar una decima a 
	# los segundos:
	beq $t1,9,m_agregarDecimas

	# Aumenta el tiempo en 1 minuto:
	addi $t1,$t1,1
		
	# En caso de que no sea necesario aumentar una decima
	# a los segundos:
	sb $t1,reloj+2
	sb $zero reloj+1
	b imprime_tiempo

m_agregarDecimas:

	sb $zero,reloj+2	
	lb $t2,reloj+3

	beq $t2,5,letra_r

	addi $t2,$t2,1
	sb $t2,reloj+3
	b imprime_tiempo
	

verificar_reset:

	lb $t0,reloj+3
	lb $t1,reloj+1
	lb $t2,reloj
	
	add $t2,$t2,$t0
	add $t2,$t2,$t1
	beq $t0,2,letra_r
	
	lb $t2,reloj+2
	addi $t2,$t2,1
	sb $t2,reloj+2

	sb $zero,reloj+1
		

imprime_tiempo:

	# Se imprime el tiempo actual: (por consola)
	

	#li $v0,1
	#lb $a0,reloj+3 
	#syscall

	#li $v0,1
	#lb $a0,reloj+2
	#syscall

	#imprimir_t(dos_puntos)
		
	#li $v0,1
	#lb $a0,reloj+1
	#syscall

	#imprimir_i(reloj+1)
	#imprimir_i(reloj)	

	#li $v0,1
	#lb $a0,reloj
	#syscall

	#imprimir_t(salto_linea)

imprime_monitor:

	lb $t0,reloj+3
	addi $t0,$t0,48
	lb $t1,reloj+2
	addi $t1,$t1,48
	lb $t2,reloj+1
	addi $t2,$t2,48
	lb $t3,reloj
	addi $t3,$t3,48

	sb $t0,m_tiempo+6
	sb $t1,m_tiempo+7
	sb $t2,m_tiempo+9
	sb $t3,m_tiempo+10
	
	lb $t0,m_tiempo
	li $t2,0

loopMonitorTime:
	lw $t1, 0xFFFF0008
	andi $t1,$t1,1
	beqz $t1,loopMonitorTime
	sw $t0,0xFFFF000C
	addi $t2,$t2,1
	lb  $t0,m_tiempo($t2)
	bnez $t0 loopMonitorTime

	imprimir_t(m_tiempo)

#loopMonitorMinuto2:

	# Se imprime el minuto actual (Monitor)
#	lb $t0,reloj+3
#	addi $t0,$t0,48
#	lw $t1, 0xFFFF0008
#	andi $t1,$t1,1
#	beqz $t1,loopMonitorMinuto2
#	sw $t0,0xFFFF000C

#loopMonitorMinuto1:

	# Se imprime el minuto actual (Monitor)
#	lb $t0,reloj+2
#	addi $t0,$t0,48
#	lw $t1, 0xFFFF0008
#	andi $t1,$t1,1
#	beqz $t1,loopMonitorMinuto1
#	sw $t0,0xFFFF000C

#loopDosPuntos:

	# Se imprimen dos puntos ":" (Monitor)
#	li $t0,58
#	lw $t1, 0xFFFF0008
#	andi $t1,$t1,1
#	beqz $t1,loopDosPuntos
#	sw $t0,0xFFFF000C

#loopMonitorSegundo2:

	# Se imprime el minuto actual (Monitor)
#	lb $t0,reloj+1
#	addi $t0,$t0,48
#	lw $t1, 0xFFFF0008
#	andi $t1,$t1,1
#	beqz $t1,loopMonitorSegundo2
#	sw $t0,0xFFFF000C


#loopMonitorSegundo1:

	# Se imprime el minuto actual (Monitor)
#	lb $t0,reloj
#	addi $t0,$t0,48
#	lw $t1, 0xFFFF0008
#	andi $t1,$t1,1
#	beqz $t1,loopMonitorSegundo1
#	sw $t0,0xFFFF000C

#loopSaltoLinea:

	# Se imprimen dos puntos ":" (Monitor)
#	li $t0,10
#	lw $t1, 0xFFFF0008
#	andi $t1,$t1,1
#	beqz $t1,loopSaltoLinea
#	sw $t0,0xFFFF000C

 	b volver

letra_r:
	# Se resetea el reloj:	
	li $t0,0
	sb $t0,reloj+2
	sb $t0,reloj+3
	sb $t0,reloj
	sb $t0,reloj+1

	# Se imprime el tiempo actual (Por consola):

	# Se imprime el tiempo actual: (por consola)
	imprimir_t(m_tiempo)

	#li $v0,1
	#lb $a0,reloj+3
	#syscall

	#li $v0,1
	#lb $a0,reloj+2
	#syscall

	#imprimir_t(dos_puntos)
		
	#li $v0,1
	#lb $a0,reloj+1
	#syscall

	#imprimir_i(reloj+1)
	#imprimir_i(reloj)	
	
	#li $v0,1
	#lb $a0,reloj
	#syscall

	#imprimir_t(salto_linea)



	#imprimir_t(m_tiempo)
	#imprimir_i(c2_minutos)
	#imprimir_i(c1_minutos)	
	#imprimir_t(dos_puntos)
	#imprimir_i(reloj+1)
	#imprimir_i(reloj)
	#imprimir_t(salto_linea)

	# Se imprime el tiempo actual (Por Monitor):
	b imprime_monitor
	
letra_q:
	# Finaliza la ejecucion del programa:
	imprimir_t(m_fin)

imprime_salir:

	lb $t0,m_fin
	li $t2,0

loopMonitorSalir:
	lw $t1, 0xFFFF0008
	andi $t1,$t1,1
	beqz $t1,loopMonitorSalir
	sw $t0,0xFFFF000C
	addi $t2,$t2,1
	lb  $t0,m_fin($t2)
	bnez $t0 loopMonitorSalir

	finalizarPrograma()

	
volver: 	
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
