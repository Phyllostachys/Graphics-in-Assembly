# Jacob Shaffer
# CMPEN 351 Final Project
# Experiment 4: Rotate a Pyramid(Actually a tetrahedron) in the 3D plain about its y axis
#	Use Bitmap Display
# Unit Width in Pixels		1
# Unit Height in Pixels		1
# Display Width in Pixels	256
# Display Height in Pixels	256
# Base address for display	0x10040000 (heap)

	.data
stack_begin:
	.word	0:100
stack_end:
PyramidCorners:
	.word	128,85,0	# A offset 0	4	8
	.word	195,200,40	# B offset 12	16	20
	.word	60,200,40	# C offset 24	28	32
	.word	128,190,-40	# D offset 36	40	44
rnd_val:
	.float	0.5
cos:
	.float	0.984807753
cos_sqr:
	.float	0.969846310
sin:
	.float	0.173648178
sin_sqr:
	.float	0.030153689


	.text
Main:
	la	$sp,stack_end
	la	$s7,PyramidCorners

Loop:
	# adjust z
	move	$a0,$s7
	jal	AdjustPyramidZ

	# calculate midpoint between b and d
	lw	$a0,12($s7)
	lw	$a1,16($s7)
	lw	$a2,36($s7)
	lw	$a3,40($s7)
	jal	CalcMidpoint
	move	$s0,$v0
	move	$s1,$v1
	
	# calculate midpoint between a and c
	lw	$a0,0($s7)
	lw	$a1,4($s7)
	lw	$a2,24($s7)
	lw	$a3,28($s7)
	jal	CalcMidpoint
	move	$s2,$v0
	move	$s3,$v1
	
	# calculate midpoint between last two values
	move	$a0,$s0
	move	$a1,$s1
	move	$a2,$s2
	move	$a3,$s3
	jal	CalcMidpoint

	# center pyramid on screen
	move	$a0,$v0
	move	$a1,$v1
	jal	CenterPyramid

	# clear the screen
	lui	$a0,0x1004
	lui	$a1,0x1008
	jal	ClearScreen
	
	# draw pyramid
	move	$a0,$s7
	jal	DrawPyramid

	# rotate octahedron
	move	$a0,$s7
	jal	RotatePyramid

	j	Loop
Exit:
	li	$v0,10
	syscall

# CalcMidpoint: calculates the integer midpoint between two points
# Input:
#	a0 = x1
#	a1 = y1
#	a2 = x2
#	a3 = y2
# Return:
#	v0 = abs(x1-x2)/2
#	v1 = abs(y1-y2)/2
CalcMidpoint:
	move	$t0,$a0
	move	$t1,$a1
	move	$t2,$a2
	move	$t3,$a3

	addu	$t0,$t0,$t2
	abs	$t0,$t0
	srl	$v0,$t0,1

	addu	$t1,$t1,$t3
	abs	$t1,$t1
	srl	$v1,$t1,1

	jr	$ra

# DrawPyramid: draw a 3d looking pyramid
# Inputs:
#	a0 = memory address with 6 points each with and x and y
# Return: none
DrawPyramid:
	addiu   $sp, $sp, -40	# allocate stack frame
	sw      $s0, 0($sp)	# save s0-s7
	sw      $s1, 4($sp)
	sw      $s2, 8($sp)
	sw      $s3, 12($sp)
	sw      $s4, 16($sp)
	sw      $s5, 20($sp)
	sw      $s6, 24($sp)
	sw      $s7, 28($sp)
	sw      $ra, 32($sp)	# save ra

	move	$s0,$a0

	# Draw A-B
	lw	$a0,0($s0)
	lw	$a1,4($s0)
	lw	$a2,12($s0)
	lw	$a3,16($s0)
	jal	DrawLine
	
	# Draw A-C
	lw	$a0,0($s0)
	lw	$a1,4($s0)
	lw	$a2,24($s0)
	lw	$a3,28($s0)
	jal	DrawLine

	# Draw A-D
	lw	$a0,0($s0)
	lw	$a1,4($s0)
	lw	$a2,36($s0)
	lw	$a3,40($s0)
	jal	DrawLine

	# Draw B-C
	lw	$a0,12($s0)
	lw	$a1,16($s0)
	lw	$a2,24($s0)
	lw	$a3,28($s0)
	jal	DrawLine

	# Draw B-D
	lw	$a0,12($s0)
	lw	$a1,16($s0)
	lw	$a2,36($s0)
	lw	$a3,40($s0)
	jal	DrawLine

	# Draw C-D
	lw	$a0,24($s0)
	lw	$a1,28($s0)
	lw	$a2,36($s0)
	lw	$a3,40($s0)
	jal	DrawLine

	lw      $s0, 0($sp)
	lw      $s1, 4($sp)
	lw      $s2, 8($sp)
	lw      $s3, 12($sp)
	lw      $s4, 16($sp)
	lw      $s5, 20($sp)
	lw      $s6, 24($sp)
	lw      $s7, 28($sp)	# restore s0-27
	lw      $ra, 32($sp)	# restore ra
	addiu   $sp, $sp, 40	# deallocate stack frame
	jr	$ra

# CenterPyramid: center the pyramid on the screen
# Input:
#	a0 = x value of midpoint
#	a1 = y value of midpoint
# Return: none
CenterPyramid:
	addiu   $sp, $sp, -40	# allocate stack frame
	sw      $s0, 0($sp)	# save s0-s7
	sw      $s1, 4($sp)
	sw      $s2, 8($sp)
	sw      $s3, 12($sp)
	sw      $s4, 16($sp)
	sw      $s5, 20($sp)
	sw      $s6, 24($sp)
	sw      $s7, 28($sp)
	sw      $ra, 32($sp)	# save ra

	# initialize center value and point counter
	li	$t0,128
	li	$t1,4

	# adjust x points to centered
	sub	$a0,$a0,$t0	# find difference between midpoint and center
	neg	$a0,$a0		# negate so that it can be added to x value
	move	$t2,$s7		# store pyramid address in t2
_COloop1:
	lw	$t9,0($t2)	# load x value
	add	$t9,$t9,$a0	# adjust x value
	sw	$t9,0($t2)	# store x value
	addiu	$t1,$t1,-1	# dec point count
	addiu	$t2,$t2,12	# goto next x point
	bne	$t1,$zero,_COloop1

	# reinitialize point counter
	li	$t1,4

	# adjust y points to centered
	sub	$a1,$a1,$t0	# find difference between midpoint and center
	neg	$a1,$a1		# negate so that it can be added to y value
	move	$t2,$s7		# store pyramid address in t2
	addiu	$t2,$t2,4	# point to first y value
_COloop2:
	lw	$t9,0($t2)	# load y value
	add	$t9,$t9,$a1	# adjust y value
	sw	$t9,0($t2)	# store y value
	addiu	$t1,$t1,-1	# dec point count
	addiu	$t2,$t2,12	# goto next y point
	bne	$t1,$zero,_COloop2

	lw      $s0, 0($sp)
	lw      $s1, 4($sp)
	lw      $s2, 8($sp)
	lw      $s3, 12($sp)
	lw      $s4, 16($sp)
	lw      $s5, 20($sp)
	lw      $s6, 24($sp)
	lw      $s7, 28($sp)	# restore s0-27
	lw      $ra, 32($sp)	# restore ra
	addiu   $sp, $sp, 40	# deallocate stack frame
	jr	$ra

# AdjustPyramidZ: find lowest z value and shift all points so that lowest is zero
# Input:
#	a0 = address of pyramid points
# Return: none
AdjustPyramidZ:
	addiu   $sp, $sp, -40	# allocate stack frame
	sw      $s0, 0($sp)	# save s0-s7
	sw      $s1, 4($sp)
	sw      $s2, 8($sp)
	sw      $s3, 12($sp)
	sw      $s4, 16($sp)
	sw      $s5, 20($sp)
	sw      $s6, 24($sp)
	sw      $s7, 28($sp)
	sw      $ra, 32($sp)	# save ra

	move	$s0,$a0
	lw	$t0,8($s0)
	li	$t3,3

_APZ_loop1:
	lw	$t1,20($s0)
	ble	$t1,$t0,_APZ_inc
	move	$t0,$t1
_APZ_inc:
	addiu	$s0,$s0,12
	addiu	$t3,$t3,-1
	bnez	$t3,_APZ_loop1

	li	$t3,4
	neg	$t0,$t0
_APZ_loop2:
	lw	$t2,8($a0)
	add	$t2,$t2,$t0
	sw	$t2,8($a0)
	addiu	$a0,$a0,12
	addiu	$t3,$t3,-1
	bnez	$t3,_APZ_loop2

	lw      $s0, 0($sp)
	lw      $s1, 4($sp)
	lw      $s2, 8($sp)
	lw      $s3, 12($sp)
	lw      $s4, 16($sp)
	lw      $s5, 20($sp)
	lw      $s6, 24($sp)
	lw      $s7, 28($sp)	# restore s0-27
	lw      $ra, 32($sp)	# restore ra
	addiu   $sp, $sp, 40	# deallocate stack frame
	jr	$ra

# RotatePyramid: rotate the pyramid points using
#	RotatePoint function on every point
# Input:
#	a0 = address in memory of the octahedron
# Return: all points rotated about origin
RotatePyramid:
	addiu   $sp, $sp, -40	# allocate stack frame
	sw      $s0, 0($sp)	# save s0-s7
	sw      $s1, 4($sp)
	sw      $s2, 8($sp)
	sw      $s3, 12($sp)
	sw      $s4, 16($sp)
	sw      $s5, 20($sp)
	sw      $s6, 24($sp)
	sw      $s7, 28($sp)
	sw      $ra, 32($sp)	# save ra

	li	$s1,4		# setup point counter
	move	$s0,$a0
_RPloop:
	lw	$a0,0($s0)
	lw	$a1,4($s0)
	lw	$a2,8($s0)
	jal	RotatePointY
	sw	$v0,0($s0)
	sw	$v1,4($s0)
	sw	$a0,8($s0)
	addiu	$s0,$s0,12
	addiu	$s1,$s1,-1
	bne	$zero,$s1,_RPloop

	lw      $s0, 0($sp)
	lw      $s1, 4($sp)
	lw      $s2, 8($sp)
	lw      $s3, 12($sp)
	lw      $s4, 16($sp)
	lw      $s5, 20($sp)
	lw      $s6, 24($sp)
	lw      $s7, 28($sp)	# restore s0-27
	lw      $ra, 32($sp)	# restore ra
	addiu   $sp, $sp, 40	# deallocate stack frame
	jr	$ra

# CalcAddress: calculate address of pixel on bitmap
# Input:
#	$a0 = x coordinate (0-255)
#	$a1 = y coordinate (0-255)
# Return:
#	$v0 = memory address
CalcAddress:
	li	$v0,0x10040000
	sll	$a0,$a0,2	# a0 = a0 * 4
	sll	$a1,$a1,10	# a1 = a1 * 256 * 4	
	addu	$v0,$v0,$a0	# v0 = 0x10040000 + a0
	addu	$v0,$v0,$a1	# v0 = v0 + a1
	jr	$ra

# DrawPixel: draw a dot at the specified coordinates
# Input:
#	$a0 = x coordinate (0-255)
#	$a1 = y coordinate (0-255)
# Return: none
DrawPixel:
	addiu   $sp, $sp, -40	# allocate stack frame
	sw      $s0, 0($sp)	# save s0-s7
	sw      $s1, 4($sp)
	sw      $s2, 8($sp)
	sw      $s3, 12($sp)
	sw      $s4, 16($sp)
	sw      $s5, 20($sp)
	sw      $s6, 24($sp)
	sw      $s7, 28($sp)
	sw      $ra, 32($sp)	# save ra

	li	$t0,0x00FFFFFF
	jal	CalcAddress
	sw	$t0, 0($v0)

	lw      $s0, 0($sp)
	lw      $s1, 4($sp)
	lw      $s2, 8($sp)
	lw      $s3, 12($sp)
	lw      $s4, 16($sp)
	lw      $s5, 20($sp)
	lw      $s6, 24($sp)
	lw      $s7, 28($sp)	# restore s0-27
	lw      $ra, 32($sp)	# restore ra
	addiu   $sp, $sp, 40	# deallocate stack frame
	jr	$ra

# DrawLine: Draw a line between two sets of x,y coordinates
# Input:
#	$a0 = starting x coordinate
#	$a1 = starting y coordinate
#	$a2 = ending x coordinate
#	$a3 = ending y coordinate
# Return: none
DrawLine:
	addiu   $sp, $sp, -40
	sw      $s0, 0($sp)		# save s0-s7
	sw      $s1, 4($sp)
	sw      $s2, 8($sp)
	sw      $s3, 12($sp)
	sw      $s4, 16($sp)
	sw      $s5, 20($sp)
	sw      $s6, 24($sp)
	sw      $s7, 28($sp)
	sw      $ra, 32($sp)

        move    $s0, $a0                # copy a0-a3 to s0-s3
        move    $s1, $a1
        move    $s2, $a2
        move    $s3, $a3

        subu    $s6, $s2, $s0           # delta-x
        lui     $t0, 0x8000
        and     $t0, $t0, $s6           # check for negative
        beq     $t0, $zero, _next1
        subu    $s6, $zero, $s6
_next1:
        subu    $s7, $s3, $s1           # delta-y
        lui     $t0, 0x8000
        and     $t0, $t0, $s7           # check for negative
        beq     $t0, $zero, _next2
        subu    $s7, $zero, $s7
_next2:
        bgeu    $s6, $s7, _next4        # which is greater delta x or y?
# y has the greater delta
        bgeu    $s3, $s1, _next3
        move    $s4, $s0                # swap starting/ending
        move    $s0, $s2
        move    $s2, $s4

        move    $s4, $s1
        move    $s1, $s3
        move    $s3, $s4
_next3:
        subu    $s6, $s2, $s0           # delta-x
        subu    $s7, $s3, $s1           # delta-y

        li      $s4, 1
        sw      $s4, 36($sp)
        lui     $t0, 0x8000
        and     $t0, $t0, $s6           # check for negative
        beq     $t0, $zero, _line2
        li      $s4, -1
        sw      $s4, 36($sp)
        subu    $s6, $zero, $s6
        j       _line2
# x has the greater delta
_next4:
        bgeu    $s2, $s0, _line1
        move    $s4, $s0                # swap starting/ending
        move    $s0, $s2
        move    $s2, $s4

        move    $s4, $s1
        move    $s1, $s3
        move    $s3, $s4
_line1:
        subu    $s6, $s2, $s0           # delta-x
        subu    $s7, $s3, $s1           # delta-y

        li      $s4, 1
        sw      $s4, 36($sp)
        lui     $t0, 0x8000
        and     $t0, $t0, $s7           # check for negative
        beq     $t0, $zero, _line2
        li      $s4, -1
        sw      $s4, 36($sp)
        subu    $s7, $zero, $s7
_line2:

        bltu    $s6, $s7, _line5
        sll     $s4, $s7, 1
        subu    $s4, $s4, $s6

        move    $s5, $s6
_line3:
        beq     $s5, $zero, _line8
        move    $a0, $s0
        move    $a1, $s1
        jal     DrawPixel
        addiu   $s0, $s0, 1
        addu    $s4, $s4, $s7
        addu    $s4, $s4, $s7
        lui     $t0, 0x8000
        and     $t0, $t0, $s4
        bne     $t0, $zero, _line4
        lw      $t0, 36($sp)
        addu    $s1, $s1, $t0
        subu    $s4, $s4, $s6
        subu    $s4, $s4, $s6
_line4:
        addiu   $s5, $s5, -1
        j       _line3

_line5:
        sll     $s4, $s6, 1
        subu    $s4, $s4, $s7

        move    $s5, $s7
_line6:
        beq     $s5, $zero, _line8
        move    $a0, $s0
        move    $a1, $s1
        jal     DrawPixel
        addiu   $s1, $s1, 1
        addu    $s4, $s4, $s6
        addu    $s4, $s4, $s6
        lui     $t0, 0x8000
        and     $t0, $t0, $s4
        bne     $t0, $zero, _line7
        lw      $t0, 36($sp)
        addu    $s0, $s0, $t0
        subu    $s4, $s4, $s7
        subu    $s4, $s4, $s7
_line7:
        addiu   $s5, $s5, -1
        j       _line6
_line8:
        move    $a0, $s2
        move    $a1, $s3
        jal     DrawPixel

	lw      $s0, 0($sp)
	lw      $s1, 4($sp)
	lw      $s2, 8($sp)
	lw      $s3, 12($sp)
	lw      $s4, 16($sp)
	lw      $s5, 20($sp)
	lw      $s6, 24($sp)
	lw      $s7, 28($sp)
	lw      $ra, 32($sp)
	addiu   $sp, $sp, 40
	jr      $ra	

# RotatePointY: rotate a given x,y,z point theta degrees
#	counterclockwise around the y axis
# Input:
# 	a0 = x value of point
#	a1 = y value of point
#	a2 = z value of point
# Return:
#	v0 = new x value of point
#	v1 = new y value of point
#	a0 = new z value of point
RotatePointY:
	# load floats to coproc1
	la	$t0,rnd_val
	la	$t1,cos
	la	$t2,sin
	la	$t3,cos_sqr
	la	$t4,sin_sqr
	l.s	$f4,0($t0)	# rnd val
	l.s	$f5,0($t1)	# cos(10)
	l.s	$f6,0($t2)	# sin(10)
	l.s	$f7,0($t3)	# cos^2(10)
	l.s	$f8,0($t4)	# sin^2(10)

	# convert x,y,z to floats
	mtc1	$a0,$f17
	cvt.s.w	$f17,$f17	# f17 = x
	mtc1	$a2,$f18
	cvt.s.w	$f18,$f18	# f18 = z

	# first row matrix multiplication
	mul.s	$f10,$f17,$f5	# f10 = x * cos(10)
	mul.s	$f11,$f18,$f6	# f11 = z * sin(10)

	# add together first row
	add.s	$f0,$f10,$f11	# f0 = [x * cos(10)] + [z * sin(10)]

	# second row matrix multiplication
	mul.s	$f10,$f18,$f5	# f10 = z * cos(10)
	mul.s	$f11,$f17,$f6	# f11 = x * sin(10)

	# add together second row
	sub.s	$f1,$f10,$f11	# f1 = [z * cos(10)] - [x * sin(10)]

	# convert to integer x,y
	add.s	$f0,$f0,$f4	# $f0 = f0 + 0.5
	cvt.w.s	$f0,$f0
	mfc1	$v0,$f0

	# y value does not change in this rotation
	move	$v1,$a1

	add.s	$f1,$f1,$f4	# $f1 = f1 + 0.5
	cvt.w.s	$f1,$f1
	mfc1	$a0,$f1
	
	jr	$ra

# ClearBuffer: clear a buffer by zeroing it out
# Input:
#	a0 = starting address of buffer
#	a1 = ending address of buffer
# Return: none
ClearScreen:
	sw	$zero,0($a0)
	sw	$zero,4($a0)
	sw	$zero,8($a0)
	sw	$zero,12($a0)
	sw	$zero,16($a0)
	sw	$zero,20($a0)
	sw	$zero,24($a0)
	sw	$zero,28($a0)
	addiu	$a0,$a0,32
	bne	$a0,$a1,ClearScreen
_CSRet:
	jr	$ra
