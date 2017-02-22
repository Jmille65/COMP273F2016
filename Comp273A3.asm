# Jordan Miller 260513815
.data
bitmapDisplay: .space 0x80000 # enough memory for a 512x256 bitmap display
resolution: .word  512 256    # width and height of the bitmap display

windowlrbt: 
#.float -2.5 2.5 -1.25 1.25  					# good window for viewing Julia sets
#.float -3 2 -1.25 1.25  					# good window for viewing full Mandelbrot set
.float -0.807298 -0.799298 -0.179996 -0.175996 		# double spiral
#.float -1.019741354 -1.013877846  -0.325120847 -0.322189093 	# baby Mandelbrot
 
bound: .float 100	# bound for testing for unbounded growth during iteration
maxIter: .word 128	# maximum iteration count to be used by drawJulia and drawMandelbrot
scale: .word 16		# scale parameter used by computeColour

# Julia constants for testing, or likewise for more examples see
# https://en.wikipedia.org/wiki/Julia_set#Quadratic_polynomials  
JuliaC0:  .float 0    0    # should give you a circle, a good test, though boring!
JuliaC1:  .float 0.25 0.5 
JuliaC2:  .float 0    0.7 
JuliaC3:  .float 0    0.8 

# a demo starting point for iteration tests
z0: .float  0 0

# TODO: define various constants you need in your .data segment here
plusString: .asciiz " + "
iString: .asciiz " i"
newLineString: .asciiz "\n"
xString: .asciiz "x"
yString: .asciiz " + y"
iEqualString: .asciiz " i = "

########################################################################################
.text
	
	# TODO: Write your function testing code here
	la $t1, JuliaC1
	l.s $f12, ($t1)
	l.s $f13, 4($t1)
	jal printComplex
	mov.s $f14, $f12
	mov.s $f15, $f13
	jal multComplex
	mov.s $f12, $f0
	mov.s $f13, $f1
	jal printComplex
	la $t1, JuliaC1
	l.s $f12, ($t1)
	l.s $f13, 4($t1)
	addi $a0, $0, 10 #sets n for iterateVerbose
	la $t1, z0
	l.s $f14, 0($t1)
	l.s $f15, 4($t1)
	jal iterateVerbose
	
	#testing 5
	li $a0, 0
	li $a1, 0
	jal pixel2ComplexInWindow
	mov.s $f12, $f0
	mov.s $f13, $f1
	jal printComplex
	
	li $a0, 256
	li $a1, 128
	jal pixel2ComplexInWindow
	mov.s $f12, $f0
	mov.s $f13, $f1
	jal printComplex

	li $a0, 512
	li $a1, 256
	jal pixel2ComplexInWindow
	mov.s $f12, $f0
	mov.s $f13, $f1
	jal printComplex
	
	#testing 6
	#la $t1, JuliaC1
	#l.s $f12, ($t1)
	#l.s $f13, 4($t1)
	#jal drawJulia
	
	#testing 7
	jal drawMandelbrot
	
	li $v0 10 # exit
	syscall

# TODO: Write your functions to implement various assignment objectives here
drawMandelbrot: #takes f12, f13 as complex constant
	
	addi $t7, $0, 0 #initial column
	addi $t8, $0, 0 #initial row
	la $s2, bitmapDisplay
	
	
mandeLoop:
	la $t3, z0 #zeroes out starting point for iterations
	l.s $f14, ($t3)
	l.s $f15, 4($t3)
	la $t3, resolution
	lw $t9, ($t3) #maxCol
	lw $t6, 4($t3) #maxRow
	la $t0, maxIter
	lw $t0, ($t0) #maxIter
	add $a0, $0, $t7 #puts column into arg position
	add $a1, $0, $t8 #puts row into arg position
	
	addi $sp, $sp, -4 #determines starting position
	sw $ra, 0($sp)
	jal pixel2ComplexInWindow
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	

	
	
	add $a0, $t0, $0 #moves maxIter to arg spot for iterate
	mov.s $f12, $f0 #moves results of pixel2Complex... to proper arg spot for iterate
	mov.s $f13, $f1 
	addi $sp, $sp, -4 #iterates, storing completed iterations in v0
	sw $ra, 0($sp)
	jal iterate
	sw $ra, 0($sp)
	addi $sp, $sp, -4 
	
	beq $t0, $v0, mandelSetBlack
	addi $a0, $v0, 0 #stores iteration count in a0 for computeColour
	blt $v0, $t0, mandelComputeColourCaller #function to call computeColour
mandeLoopContinued:
	
	sw $s1, ($s2) #stores colour into bitmap
	addi $s2, $s2, 4 #increments s2 by a word
	addi $t7, $t7, 1 #increments column
	bge $t7, $t9, mandelNextColumn #branches to increment column if row is full
	j mandeLoop
mandelNextColumn:
	addi $t8, $t8, 1 #increments row
	addi $t7, $0, 0 #resets column
	
	bge $t8, $t6, doneMandel
	
	j mandeLoop
doneMandel:
	addi $s1, $0, 0 #re-zeroes s1
	addi $s2, $0, 0 #same thing
	
	li $v0 10 # exit
	syscall
	jr $ra
mandelSetBlack: 
	addi $s1, $0, 0 #stores black in s1
	j mandeLoopContinued
mandelComputeColourCaller:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal computeColour
	lw $ra, ($sp)
	addi $sp, $sp, 4
	addi $s1, $v0, 0 #temporarily stores colour in s1
	j mandeLoopContinued



drawJulia: #takes f12, f13 as complex constant
	
	addi $t7, $0, 0 #initial column
	addi $t8, $0, 0 #initial row
	la $s2, bitmapDisplay
	
loop:
	la $t3, resolution
	lw $t9, ($t3) #maxCol
	lw $t6, 4($t3) #maxRow
	la $t0, maxIter
	lw $t0, ($t0) #maxIter
	add $a0, $0, $t7 #puts column into arg position
	add $a1, $0, $t8 #puts row into arg position
	
	addi $sp, $sp, -4 #determines starting position
	sw $ra, 0($sp)
	jal pixel2ComplexInWindow
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	add $a0, $t0, $0 #moves maxIter to arg spot for iterate
	mov.s $f14, $f0 #moves results of pixel2Complex... to proper arg spot for iterate
	mov.s $f15, $f1 
	addi $sp, $sp, -4 #iterates, storing completed iterations in v0
	sw $ra, 0($sp)
	jal iterate
	sw $ra, 0($sp)
	addi $sp, $sp, -4 
	
	beq $t0, $v0, setBlack
	addi $a0, $v0, 0 #stores iteration count in a0 for computeColour
	blt $v0, $t0, computeColourCaller #function to call computeColour
loopContinued:
	
	sw $s1, ($s2) #stores colour into bitmap
	addi $s2, $s2, 4 #increments s2 by a word
	addi $t7, $t7, 1 #increments column
	bge $t7, $t9, nextColumn #branches to increment column if row is full
	j loop
nextColumn:
	addi $t8, $t8, 1 #increments row
	addi $t7, $0, 0 #resets column
	
	bge $t8, $t6, doneJulia
	
	j loop
doneJulia:
	addi $s1, $0, 0 #re-zeroes s1
	addi $s2, $0, 0 #same thing
	
	li $v0 10 # exit
	syscall
	jr $ra
setBlack: 
	addi $s1, $0, 0 #stores black in s1
	j loopContinued
computeColourCaller:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal computeColour
	lw $ra, ($sp)
	addi $sp, $sp, 4
	addi $s1, $v0, 0 #temporarily stores colour in s1
	j loopContinued

pixel2ComplexInWindow: #col in a0, row in a1
#real component:
	mtc1 $a0, $f9 #stores col in f9
	cvt.s.w $f9, $f9 #converts it to a double
	la $t3, resolution
	lw $t5, ($t3)
	mtc1 $t5, $f10 #puts w in f10
	cvt.s.w $f10, $f10
	div.s $f9, $f9, $f10 #divides col by w, stores in f9
	la $t4, windowlrbt
	l.s $f10, ($t4) #stores l in f10
	l.s $f11, 4($t4) #stores r in f11
	sub.s $f11, $f11, $f10 #subtracts l from r
	mul.s $f9, $f9, $f11 #multiplies col/w by r-l
	add.s $f0, $f9, $f10 #adds result of previous with l
	
#imaginary component:
	mtc1 $a1, $f9 #stores col in f9
	cvt.s.w $f9, $f9 #converts it to a double
	la $t3, resolution
	lw $t5, 4($t3)
	mtc1 $t5, $f10 #puts h in f10
	cvt.s.w $f10, $f10 #converts h to float
	div.s $f9, $f9, $f10 #divides col by w, stores in f9
	la $t4, windowlrbt
	l.s $f10, 8($t4) #stores b in f10
	l.s $f11, 12($t4) #stores t in f11
	sub.s $f11, $f11, $f10 #subtracts b from t
	mul.s $f9, $f9, $f11 #multiplies row/h by t-b
	add.s $f1, $f9, $f10 #adds result of previous with l
	
	jr $ra

iterateVerbose: #a0 = n, f12 = a, f13 = b, f14 = x0, f15 = y0
	add $s0, $a0, $0 #will need a0 for other things
	la $t2, bound
	l.s $f6, ($t2) #stores bound in f6
	add $t1, $0, $0 #zeroes t1 (counter)
verboseRecurse:
	#Completeness testing:
	#Note: when the bound is exceeded this gives an iteration count 1 higher than the 2nd example in the assignment outline, which I believe is incorrect
	beq $t1, $s0, done #if iterations complete, go to done
	mul.s $f7, $f14, $f14 #x^2
	mul.s $f8, $f15, $f15 #y^2
	add.s $f7, $f7, $f8 #sum of previous two lines
	c.lt.s $f6, $f7 #if f6 < f7, set coprocessor condition bit to 1
	bc1t done #if f6 < f7, go to done, else:
	
	#String building
	
	li $v0, 4 #sets to string print
	la $a0, xString
	syscall
	li $v0, 1 #sets to int print
	add $a0, $t1, $0 #prepares to print iteration #
	syscall
	la $a0, yString
	li $v0, 4
	syscall
	li $v0, 1 #sets to int print
	add $a0, $t1, $0 #prepares to print iteration #
	syscall
	la $a0, iEqualString #prints other filler material
	li $v0, 4
	syscall
	
	#new values
	mov.s $f7, $f12 #temporary storage
	mov.s $f8, $f13
	mov.s $f12, $f14 #duplicates x and y for squaring using multComplex function
	mov.s $f13, $f15
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal printComplex #prints complex number and new line
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal multComplex # creates new complex number, real portion in f0, imaginary in f1
	lw $ra, 0($sp)
	addi $sp, $sp, 4 #this and line above deal with stack pointer
	add.s $f12, $f0, $f7 #these add c to z^2 for next iteration
	add.s $f13, $f1, $f8
	
	#cleanup:
	mov.s $f14, $f12
	mov.s $f15, $f13
	mov.s $f12, $f7
	mov.s $f13, $f8
	
	addi $t1, $t1, 1
	j verboseRecurse
done:
	li $v0, 1 #syscall code 1 for int print
	add $a0, $t1, $0 #puts number of completed iterations in a0
	syscall
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal printNewLine
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	add $v0, $t1, $0
	jr $ra

iterate: #a0 = n, f12 = a, f13 = b, f14 = x0, f15 = y0
	add $s0, $a0, $0 #will need a0 for other things
	la $t2, bound
	l.s $f6, ($t2) #stores bound in f6
	add $t1, $0, $0 #zeroes t1 (counter)
recurseNonVerbose:
	#Completeness testing:
	#Note: when the bound is exceeded this gives an iteration count 1 higher than the 2nd example in the assignment outline, which I believe is incorrect
	addi $t1, $t1, 1 #incrementing increment count
	beq $t1, $s0, doneNonVerbose #if iterations complete, go to done
	mul.s $f7, $f14, $f14 #x^2
	mul.s $f8, $f15, $f15 #y^2
	add.s $f7, $f7, $f8 #sum of previous two lines
	c.lt.s $f6, $f7 #if f6 < f7, set coprocessor condition bit to 1
	bc1t doneNonVerbose #if f6 < f7, go to done, else:
	
	#new values
	mov.s $f7, $f12 #temporary storage
	mov.s $f8, $f13
	mov.s $f12, $f14 #duplicates x and y for squaring using multComplex function
	mov.s $f13, $f15
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal multComplex # creates new complex number, real portion in f0, imaginary in f1
	lw $ra, 0($sp)
	addi $sp, $sp, 4 #this and line above deal with stack pointer
	add.s $f12, $f0, $f7 #these add c to z^2 for next iteration
	add.s $f13, $f1, $f8
	
	#cleanup:
	mov.s $f14, $f12
	mov.s $f15, $f13
	mov.s $f12, $f7
	mov.s $f13, $f8
	

	j recurseNonVerbose
doneNonVerbose:
	add $v0, $t1, $0
	jr $ra


printComplex:
	addi $v0, $0, 2 #sets syscall to float print
	syscall
	mov.s $f4, $f12 #stores arg1 temporarily in order to not disturb variables
	mov.s $f12, $f13 #moves arg2 into printing position
	la $a0, plusString
	addi $v0, $0, 4 #sets syscall to string print
	syscall
	addi $v0, $0, 2 #sets syscall to float print
	syscall
	la $a0, iString
	addi $v0, $0, 4 #sets syscall to string print
	syscall #prints the i... printNewLine would make more sense if I could include this in it, but such are the instructions
	mov.s $f13, $f12 #moves arg2 back to arg2 position
	mov.s $f12, $f4 #moves arg1 back to arg1 position
	addi $sp, $sp, -4 #stack pointer nonsense, don't worry i got dis
	sw $ra, 0($sp) 
	jal printNewLine
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

printNewLine:
	add $t0, $v0, $0 #stores previous syscall code to not disturb program flow
	addi $v0, $0, 4 #sets syscall to print string
	la $a0, newLineString #loads address of newLineString into a0
	syscall #prints new line
	add $v0, $t0, $0 #restores previous syscall code
	jr $ra

multComplex: #f12 = a, f13 = b, f14 = c, f15 = d
	mul.s $f4, $f12, $f14 #f4 contains ac
	mul.s $f5, $f13, $f15 #f5 contains bd
	sub.s $f0, $f4, $f5 #f0 contains real portion
	mul.s $f4, $f12, $f15 #f4 contains ad
	mul.s $f5, $f13, $f14 #f5 contains bc
	add.s $f1, $f4, $f5 #f1 contains imaginary portion
	jr $ra


########################################################################################
# Computes a colour corresponding to a given iteration count in $a0
# The colours cycle smoothly through green blue and red, with a speed adjustable 
# by a scale parametre defined in the static .data segment
computeColour:
	la $t0 scale
	lw $t0 ($t0)
	mult $a0 $t0
	mflo $a0
ccLoop:
	slti $t0 $a0 256
	beq $t0 $0 ccSkip1
	li $t1 255
	sub $t1 $t1 $a0
	sll $t1 $t1 8
	add $v0 $t1 $a0
	jr $ra
ccSkip1:
  	slti $t0 $a0 512
	beq $t0 $0 ccSkip2
	addi $v0 $a0 -256
	li $t1 255
	sub $t1 $t1 $v0
	sll $v0 $v0 16
	or $v0 $v0 $t1
	jr $ra
ccSkip2:
	slti $t0 $a0 768
	beq $t0 $0 ccSkip3
	addi $v0 $a0 -512
	li $t1 255
	sub $t1 $t1 $v0
	sll $t1 $t1 16
	sll $v0 $v0 8
	or $v0 $v0 $t1
	jr $ra
ccSkip3:
 	addi $a0 $a0 -768
 	j ccLoop
