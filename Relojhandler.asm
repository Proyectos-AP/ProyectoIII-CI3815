#
# Relojhandler.asm
#
# Descripcion:
#
# Nombres:
#	Alejandra Cordero / Carnet: 12-10645
#	Pablo Maldonado   / Carnet: 12-10561
#
# Ultima modificacion: 22/02/2015
#

##############################################################
#                    SECCION DE DATOS                        #
##############################################################

	.kdata

c1_minutos:	.word		0
c2_minutos:	.word		0	
c1_segundos:	.word		0
c2_segundos:	.word		0
registros:	.word		0,1,2,3,4,5,6
m_tiempo:		.asciiz		"Time: "
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

.macro imprimir_i(%etiqueta)
	li $v0,1
	lw $a0,%etiqueta
	syscall
.end_macro

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

	# Because we are running in the kernel, we can use $k0/$k1 without
	# saving their old values.

	# Se realiza el manejo de la interrupcion:
	
	# Se revisa la tecla que se marco	
	lb $t0, 0xffff0004	
	beq $t0,116,letra_t
	beq $t0,114,letra_r
	beq $t0,113,letra_q
	b volver
	
letra_t:
		
	# Se obtiene el tiempo actual:
	lw $t1,c1_segundos

	# Se verifica si es necesario aumentar una decima a 
	# los segundos:
	beq $t1,9,s_agregarDecimas

	# Aumenta el tiempo en 1 segundo:
	addi $t1,$t1,1
		
	# En caso de que no sea necesario aumentar una decima
	# a los segundos:
	sw $t1,c1_segundos
	b imprime_tiempo

s_agregarDecimas:
	
	sw $zero,c1_segundos		
	lw $t2,c2_segundos
	beq $t2,5,m_agregarUnidad

	addi $t2,$t2,1
	sw $t2,c2_segundos
	b imprime_tiempo
	
m_agregarUnidad:

	# Se obtiene el tiempo actual:
	lw $t1,c1_minutos

	# Se verifica si la hora es de la forma X3:XX
	beq $t1,3,verificar_reset

	# Se verifica si es necesario aumentar una decima a 
	# los segundos:
	beq $t1,9,m_agregarDecimas

	# Aumenta el tiempo en 1 minuto:
	addi $t1,$t1,1
		
	# En caso de que no sea necesario aumentar una decima
	# a los segundos:
	sw $t1,c1_minutos
	sw $zero c2_segundos
	b imprime_tiempo

m_agregarDecimas:
	
	sw $zero,c1_minutos	
	lw $t2,c2_minutos

	beq $t2,2,verificar_reset

	addi $t2,$t2,1
	sw $t2,c2_minutos
	b imprime_tiempo
	

verificar_reset:

	lw $t0,c2_minutos
	lw $t1,c2_segundos
	lw $t2,c1_segundos
	
	add $t2,$t2,$t0
	add $t2,$t2,$t1
	beq $t0,2,letra_r
	
	lw $t2,c1_minutos
	addi $t2,$t2,1
	sw $t2,c1_minutos

	sw $zero,c2_segundos
		

imprime_tiempo:

	# Se imprime el tiempo actual: (por consola)
	imprimir_t(m_tiempo)
	imprimir_i(c2_minutos)	
	imprimir_i(c1_minutos)
	imprimir_t(dos_puntos)
	imprimir_i(c2_segundos)
	imprimir_i(c1_segundos)	
	imprimir_t(salto_linea)

imprime_monitor:

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

loopMonitorMinuto2:

	# Se imprime el minuto actual (Monitor)
	lw $t0,c2_minutos
	addi $t0,$t0,48
	lw $t1, 0xFFFF0008
	andi $t1,$t1,1
	beqz $t1,loopMonitorMinuto2
	sw $t0,0xFFFF000C

loopMonitorMinuto1:

	# Se imprime el minuto actual (Monitor)
	lw $t0,c1_minutos
	addi $t0,$t0,48
	lw $t1, 0xFFFF0008
	andi $t1,$t1,1
	beqz $t1,loopMonitorMinuto1
	sw $t0,0xFFFF000C

loopDosPuntos:

	# Se imprimen dos puntos ":" (Monitor)
	li $t0,58
	lw $t1, 0xFFFF0008
	andi $t1,$t1,1
	beqz $t1,loopDosPuntos
	sw $t0,0xFFFF000C

loopMonitorSegundo2:

	# Se imprime el minuto actual (Monitor)
	lw $t0,c2_segundos
	addi $t0,$t0,48
	lw $t1, 0xFFFF0008
	andi $t1,$t1,1
	beqz $t1,loopMonitorSegundo2
	sw $t0,0xFFFF000C


loopMonitorSegundo1:

	# Se imprime el minuto actual (Monitor)
	lw $t0,c1_segundos
	addi $t0,$t0,48
	lw $t1, 0xFFFF0008
	andi $t1,$t1,1
	beqz $t1,loopMonitorSegundo1
	sw $t0,0xFFFF000C

loopSaltoLinea:

	# Se imprimen dos puntos ":" (Monitor)
	li $t0,10
	lw $t1, 0xFFFF0008
	andi $t1,$t1,1
	beqz $t1,loopSaltoLinea
	sw $t0,0xFFFF000C

 	b volver

letra_r:
	# Se resetea el reloj:	
	li $t0,0
	sw $t0,c1_minutos
	sw $t0,c2_minutos
	sw $t0,c1_segundos
	sw $t0,c2_segundos

	# Se imprime el tiempo actual (Por consola):
	imprimir_t(m_tiempo)
	imprimir_i(c2_minutos)
	imprimir_i(c1_minutos)	
	imprimir_t(dos_puntos)
	imprimir_i(c2_segundos)
	imprimir_i(c1_segundos)
	imprimir_t(salto_linea)

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
