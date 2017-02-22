# Jordan Miller 260513815

# Change the value N and filenames to test different given matrix problems
.data
N: .word 64
Afname: .asciiz "A64.bin"
Bfname: .asciiz "B64.bin"
Cfname: .asciiz "C64.bin"
Dfname: .asciiz "D64.bin"       # Use D to check your code: D = AB - C 

#################################################################
# Main function for testing assignment objectives.
# Modify this function as needed to complete your assignment.
# Note that the TA will ultimately use a different testing program.
# Finally note we will use save registers in the main function without
# saving them, but you must respect register conventions for all
# of the functions you implement!  Recall that $f20-$f31 are save 
# registers on the floating point coprocessor

bsize: .word 4

.text
main:	la   $t0, N
	lw   $s7, ($t0)		# Let $s7 be the matrix size n

	move $a0 $s7
	jal mallocMatrix	# allocate heap memory and load matrix A
	move $s0 $v0		# $s0 is a pointer to matrix A
	la $a0 Afname
	move $a1 $s7
	move $a2 $s7
	move $a3 $s0
	jal loadMatrix
	
	move $a0 $s7
	jal mallocMatrix	# allocate heap memory and load matrix B
	move $s1 $v0		# $s1 is a pointer to matrix B
	la $a0 Bfname
	move $a1 $s7
	move $a2 $s7
	move $a3 $s1
	jal loadMatrix
	
	move $a0 $s7
	jal mallocMatrix	# allocate heap memory and load matrix C
	move $s2 $v0		# $s2 is a pointer to matrix C
	la $a0 Cfname
	move $a1 $s7
	move $a2 $s7
	move $a3 $s2
	jal loadMatrix
	
	move $a0 $s7
	jal mallocMatrix	# allocate heap memory and load matrix A
	move $s3 $v0		# $s3 is a pointer to matrix D
	la $a0 Dfname
	move $a1 $s7
	move $a2 $s7
	move $a3 $s3
	jal loadMatrix		# D is the answer, i.e., D = AB+C 

	
			
	# TODO: add your testing code here
	move $a0, $s0 #stores A in a0
	move $a1, $s1 #stores B in a1
	move $a2, $s2 #stores C in a2
	move $a3, $s7 #stores N in a3
	
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal multiplyAndAddV2
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
	move $a0, $a2
	move $a1, $s3
	move $a2, $s7
	
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal check
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
	
	li $v0, 10      # load exit call code 10 into $v0
        syscall         # call operating system to exit	
        
subtract: #a0 = float* A, a1 = float* B, a2 = float* C, a3 = int n
	move $t1, $a3
	mul $a3, $a3, $a3 #n^2
	li $t0, 0
subLoop:
	beq $t0, $a3, subDone
	lwc1 $f5, ($a0) #loads floats from pointers
	lwc1 $f6, ($a1)
	sub.s $f4, $f5, $f6
	swc1 $f4, ($a2) #stores result in address at a0
	addi $a0, $a0, 4 #increments pointers and counter
	addi $a1, $a1, 4
	addi $a2, $a2, 4
	addi $t0, $t0, 1
	j subLoop
subDone: 
	li $t0, 4
	mul $t0, $t0, $a3
	sub $a0, $a0, $t0 #resets matrix pointers
	sub $a1, $a1, $t0
	sub $a2, $a2, $t0
	move $a3, $t1 #restores n
	jr $ra
	
	
	
frobeneousNorm: #a0 = float* A, a1 = int n
	move $t1, $a1
	mul $a1, $a1, $a1 #n^2
	li $t0, 0 #counter
	mtc1 $zero, $f0 #zeroes f0 in prep
frobLoop:
	beq $t0, $a1, frobDone
	lwc1 $f4, ($a0)
	mul.s $f4, $f4, $f4 #squares
	add.s $f0, $f0, $f4 #adds square of value to total
	addi $a0, $a0, 4 #increments matrix pointer
	addi $t0, $t0, 1 #increments counter
	j frobLoop
frobDone:
	sqrt.s $f0, $f0 #sqrt of sums
	li $t0, 4
	mul $t0, $t0, $t1
	sub $a0, $a0, $t0 #resets matrix pointer
	move $a1, $t1 #restores n
	jr $ra
	
check: #a0 = float* A, a1 = float* B, a2 = int n
	move $a3, $a2 #copies n to a3
	add $a2, $a0, $zero #duplicates a0 and stores in a2
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal subtract #subtracts B from A and stores in A
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
	move $a1, $a3
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal frobeneousNorm #calculates frobeneousNorm on matrix pointed to by a0
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
	mtc1 $zero, $f12
	add.s $f12, $f12, $f0 #sets for print float
	li $v0, 2
	syscall
	jr $ra
	
multiplyAndAddV1: #a0 = float* A, a1 = float* B, a2 = float* C, a3 = int N
	add $t0, $zero, $zero #zeroes count registers
	add $t1, $zero, $zero
	add $t2, $zero, $zero
	li $t7, 4
	mul $t7, $a3, $t7 #stores # of bits in matrix
	iLoop: #(t = 0; t0 < a3; t0++)
	beq $t7, $t0, multV1Done 
		jLoop: #(t1 = 0; t1 < a3; t1++)
		beq $t7, $t1, jLoopDone
			kLoop: #(t2 = 0; t2 < a3; t2++)
			beq $t7, $t2, kLoopDone
				#address of C_ij is C* + (n*i + j)
				mul $t3, $a3, $t0 #n*i
				add $t3, $t3, $t1
				add $t3, $a2, $t3 #t3 has address of C_ij
				lwc1 $f4, ($t3) #loads C_ij into f4
				
				#address of A_ik is A* + (n*i + k)
				mul $t4, $a3, $t0
				add $t4, $t4, $t2
				add $t4, $a0, $t4 #t4 has address of A_ik
				lwc1 $f5, ($t4) #loads A_ik into f5
				
				#address of B_kj is B* + (k*n + j)
				mul $t5, $a3, $t2
				add $t5, $t5, $t1
				add $t5, $a1, $t5 #t5 has address of B_kj
				lwc1 $f6, ($t5) #loads B_kj into f6
				
				mul.s $f5, $f5, $f6 #multiplies A_ik and B_kj
				add.s $f4, $f4, $f5 #adds to C_ij
				swc1 $f4 ($t3) #stores as C_ij
			addi $t2, $t2, 4
			j kLoop
			kLoopDone:
			li $t2, 0
		addi $t1, $t1, 4
		j jLoop
		jLoopDone:
		li $t1, 0
	addi $t0, $t0, 4
	j iLoop

multV1Done:
	jr $ra
	
	
multiplyAndAddV2: #a0 = float* A, a1 = float* B, a2 = float* C, a3 = int n
	li $t0, 0 #jj
	li $t1, 0 #kk
	li $t2, 0 #i
	li $t3, 0 #j
	li $t4, 0 #k
	la $t5, bsize
	lw $t5, ($t5) #bsize
	
	jjLoop:
	slt $t6, $t0, $a3 #sets t6 to 1 if jj < n
	beq $t6, $zero, jjLoopDone
		kkLoop: 
		slt $t6, $t1, $a3 #sets t6 to 1 if kk < n
		beq $t6, $zero, kkLoopDone
			iLoopV2:
			beq $t2, $a3, iLoopDoneV2
				move $t3, $t0 #sets j to be value of jj
				jLoopV2:
				add $t6, $t0, $t5 #jj + bsize
				slt $t7, $t3, $t6 #sets t7 to 1 if j < jj+bsize
				beq $t7, $zero, jLoopDoneV2
				slt $t7, $t3, $a3 #sets t7 to 1 if j < n
				beq $t7, $zero, jLoopDoneV2 #if j < n or bsize + jj, jump to jLoopDoneV2
				
					mtc1  $zero, $f4 #sum initialized to 0.0 in f4
					
					move $t4, $t1 #sets k to be value of kk
					kLoopV2:
					add $t6, $t1, $t5 #kk + bsize
					slt $t7, $t4, $t6 #sets t7 to 1 if k < kk + bsize
					beq $t7, $zero, kLoopDoneV2
					slt $t7, $t4, $a3 #sets t7 to 1 if k < n
					beq $t7, $zero, kLoopDoneV2 #if k < n or bsize + kk, jump to kLoopDoneV2
						li $t6, 4
						mul $t7, $t2, $a3 #i*n
						add $t7, $t7, $t4 # + k
						mul $t7, $t7, $t6 #changes to words for offset
						add $t7, $t7, $a0 #address of A_ik
						lwc1 $f5, ($t7) #f5 = A_ik
						
						mul $t7, $t4, $a3 #k*n
						add $t7, $t7, $t3 # + j
						mul $t7, $t7, $t6 #changes to words for offset
						add $t7, $t7, $a1 #address of B_kj
						lwc1 $f6, ($t7) #f6 = B_kj
						
						mul.s $f5, $f5, $f6
						add.s $f4, $f4, $f5 #sum += A_ik * B_kj
						
					addi $t4, $t4, 1
					j kLoopV2
					kLoopDoneV2:
					li $t4, 0 #resets k
					
					li $t6, 4
					mul $t7, $t2, $a3 #i*n
					add $t7, $t7, $t3 # + j
					mul $t7, $t7, $t6 #changes to words for offset
					add $t7, $t7, $a2 #address of C_ij
					lwc1 $f5, ($t7) #f5 = C_ij
					
					add.s $f5, $f5, $f4 #C_ij += sum
					swc1 $f5, ($t7) #stores back into memory
					
				addi $t3, $t3, 1 #increments j
				j jLoopV2
				jLoopDoneV2:
				li $t3, 0 #resets j
			addi $t2, $t2, 1 #increments i
			j iLoopV2
			iLoopDoneV2:
			li $t2, 0 #resets i
		add $t1, $t1, $t5 # kk += bsize
		j kkLoop
		kkLoopDone:
		li $t1, 0 #resets kk
	add $t0, $t0, $t5 # jj += bsize
	j jjLoop
	jjLoopDone:
	jr $ra
	

		
###############################################################
# mallocMatrix( int N )
# Allocates memory for an N by N matrix of floats
# The pointer to the memory is returned in $v0	
mallocMatrix: 	mul  $a0, $a0, $a0	# Let $s5 be n squared
		sll  $a0, $a0, 2	# Let $s4 be 4 n^2 bytes
		li   $v0, 9		
		syscall			# malloc A
		jr $ra
	
###############################################################
# loadMatrix( char* filename, int width, int height, float* buffer )
.data
errorMessage: .asciiz "FILE NOT FOUND" 
.text
loadMatrix:	mul $t0, $a1, $a2 # words to read (width x height) in a2
		sll $t0, $t0, 2	  # multiply by 4 to get bytes to read
		li $a1, 0     # flags (0: read, 1: write)
		li $a2, 0     # mode (unused)
		li $v0, 13    # open file, $a0 is null-terminated string of file name
		syscall
		slti $t1 $v0 0
		beq $t1 $0 fileFound
		la $a0 errorMessage
		li $v0 4
		syscall		  # print error message
		li $v0 10         # and then exit
		syscall		
fileFound:	move $a0, $v0     # file descriptor (negative if error) as argument for read
  		move $a1, $a3     # address of buffer in which to write
		move $a2, $t0	  # number of bytes to read
		li  $v0, 14       # system call for read from file
		syscall           # read from file
		# $v0 contains number of characters read (0 if end-of-file, negative if error).
                # We'll assume that we do not need to be checking for errors!
		
		# Note, the bitmap display doesn't update properly on load, 
		# so let's go touch each memory address to refresh it!
		move $t0, $a3	   # start address
		add $t1, $a3, $a2  # end address
loadloop:	lw $t2, ($t0)
		sw $t2, ($t0)
		addi $t0, $t0, 4
		bne $t0, $t1, loadloop
		jr $ra	
