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
	
	.data

soy_t:	.asciiz "Presionaste una t \n"
soy_r:	.asciiz "Presionaste una r \n"
soy_q:	.asciiz "Presionaste una q \n" 



.macro finalizarPrograma()
	li $v0, 10
	syscall
.end_macro


	.text


loop:
	lw $10,0xFFFF0000
	and $10,$10,1
	beqz $10,loop

	lw $11,0xFFFF0004

	# Se verifica si es "t"

	beq $11,116,letraT

	# Se verifica si es "q"

	beq $11,113,letraQ

	# Se verifixa si es "r"
	
	beq $11,114,letraR

	b loop

letraT:
	li $v0,4
	la $a0,soy_t
	syscall
	b loopm

letraQ:
	li $v0,4
	la $a0,soy_q
	syscall
	finalizarPrograma()

letraR:
	li $v0,4
	la $a0,soy_r
	syscall
	b loopm


loopm:
	lw $10,0xFFFF0008
	andi $10,$10,1
	beqz $10,loopm
	sw $11,0xFFFF000C
	b loop


	
