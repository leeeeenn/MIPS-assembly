#Objectives: Bin Packing Problem Solution Using MIPS Assembly..
# Input: From File, Output: To a file and on the screen...
# Student: Leen Ahmad 1212028
#section 1, Mr Aziz Qaroush
.data
input_file_name: .asciiz "\n[+] Enter The name of Input File, Please: "
input_file: .space 100
file_data: .space 1024
error_msg: .asciiz "\n[-] Error: File could not be opened.\n"
debug_msg: .asciiz "\n[+] DEBUG: File name entered: "
float_msg: .asciiz "\n[+] Parsed float: "
bin_msg: .asciiz " | Bin Count: "
float_str: .space 32
newline: .asciiz "\n"
too_big_msg: .asciiz "\n[-] Error: Item value greater than or equal to 1.0 is invalid!\n"
one_float: .float 1.0
bins: .space 400      # 100 bins max × 4 bytes (float)
bin_count: .word 0
item_values: .space 400      # 100 floats × 4 bytes
item_bins:   .space 400      # 100 words = bin indices
item_count:  .word 0
item_msg:    .asciiz "  - Item: "
bin_title:   .asciiz "\nBin["
end_bracket: .asciiz "]:"
space_left:  .asciiz "  > Remaining space: "
float_1_point_1: .float 1.1
invalid_char_msg: .asciiz "\n[-] Error: Invalid character found in input file!\n"
                     #menu partt
float_100: .float 100.0

menu_prompt:    .asciiz "\n[MENU] Choose: [R]ead File | [F]irst [F]it | [B]est [F]it | [W]rite Output | [Q]uit : "
read_msg:       .asciiz "\n[+] Reading from file...\n"
ff_msg:         .asciiz "\n[+] Running First Fit...\n"
bf_msg:         .asciiz "\n[+] Running Best Fit...\n"
write_msg:      .asciiz "\n[+] Writing output ..\n"
quit_msg:       .asciiz "\n[+] Exiting  LEEEEN'S Bin Tracking Program. Goodbye!\n"
invalid_opt:    .asciiz "\n[-] Invalid option. Try again!\n"
welcome_msg:    .asciiz "\n[+] Welcome  To LEEEEN'S Bin Tracking Program. I hope you like it! \n"

output_file: .space 100
output_file_prompt: .asciiz "\n[+] Enter output file name: "

int_str: .space 12
temp_storage_2: .asciiz "" 
dot_char: .asciiz "."
zero_char: .asciiz "0"

.align 2
integer_buffer: .space 30 # buffer to save integers
.align 2
float_buffer: .space 30  # buffer to save float numbers
.align 2
temp_buffer: .space 30 

.text
.globl main

main:
# Welcome Message...
li $v0, 4
la $a0, welcome_msg
syscall
menu_loop:
    li $v0, 4
    la $a0, menu_prompt
    syscall

    li $v0, 12           # Read a character
    syscall
    move $t0, $v0        # Save input character

    # Check for 'f' or 'F' (start of "ff")
    li $t1, 102        # 'f'
    li $t2, 70         # 'F'
    beq $t0, $t1, check_second_f
    beq $t0, $t2, check_second_f
    
    #check for b or B
    li $t1, 66
    li $t2, 98
    beq $t0, $t1, check_f
    beq $t0, $t2, check_f
    

continue_check:
    # Check for other single-letter options (r, w, q)
    li $t1, 113          # ASCII 'q'
    beq $t0, $t1, quit
    li $t1, 81           # ASCII 'Q'
    beq $t0, $t1, quit

    li $t1, 114          # ASCII 'r'
    beq $t0, $t1, read_file
    li $t1, 82           # ASCII 'R'
    beq $t0, $t1, read_file

    li $t1, 119          # ASCII 'w'
    beq $t0, $t1, write_output
    li $t1, 87           # ASCII 'W'
    beq $t0, $t1, write_output

    # Invalid input
    li $v0, 4
    la $a0, invalid_opt
    syscall
    j menu_loop
check_f:
    li $v0, 12         # read second char
    syscall
    move $t3, $v0
    li $t1, 102        # 'f'
    li $t2, 70         # 'F'
    beq $t3, $t1, best_fit   # second char is 'f'
    beq $t3, $t2, best_fit   # second char is 'F'
    j menu_loop  

check_second_f:
    li $v0, 12         # read second char
    syscall
    move $t3, $v0
    li $t1, 102        # 'f'
    li $t2, 70         # 'F'
    beq $t3, $t1, first_fit   # second char is 'f'
    beq $t3, $t2, first_fit   # second char is 'F'
    j menu_loop        # invalid second char

read_file:
    li $v0, 4
    la $a0, read_msg
    syscall

    jal read_file_only
    j menu_loop

first_fit:
    li $v0, 4
    la $a0, ff_msg
    syscall

    lw $t0, item_count
    beqz $t0, read_and_then_ff
best_fit:
    li $v0, 4
    la $a0, ff_msg
    syscall

    lw $t0, item_count
    beqz $t0, read_and_then_bf

do_first_fit:
    jal parse_and_ff
    j menu_loop

read_and_then_ff:
    jal read_file_only
    j do_first_fit
read_and_then_bf:
    jal read_file_only_bf
    j do_best_fit
do_best_fit:
    jal parse_and_bf
    j menu_loop

write_output:
    li $v0, 4
    la $a0, write_msg
    syscall
    jal write_output_file

    j menu_loop

quit:
    li $v0, 4
    la $a0, quit_msg
    syscall
    li $v0, 10
    syscall


parse_loop:
    lb $t0, 0($s1)
    beqz $t0, check_final_float
    beq $t0, 0x0A, parse_float
    beq $t0, 0x0D, parse_float  # carriage return
    
        # Validate character before storing in float_str
    li $t3, 0x30         # ASCII '0'
    li $t4, 0x39         # ASCII '9'
    blt $t0, $t3, check_special
    bgt $t0, $t4, check_special
    j valid_char

check_special:
    li $t3, 0x2E         # '.'
    beq $t0, $t3, valid_char
    li $t3, 0x20         # space
    beq $t0, $t3, valid_char
    li $t3, 0x0A         # newline
    beq $t0, $t3, valid_char
    li $t3, 0x0D         # carriage return
    beq $t0, $t3, valid_char

    # Invalid character found
    li $v0, 4
    la $a0, invalid_char_msg
    syscall
    #li $v0, 10           # Exit
    #syscall
    j menu_loop

valid_char:
    sb $t0, 0($s2)


    sb $t0, 0($s2)
    addiu $s1, $s1, 1
    addiu $s2, $s2, 1
    j parse_loop

parse_float:
    sb $zero, 0($s2)
    la $s2, float_str
    addiu $s1, $s1, 1

    # Check minimum format
    la $t9, float_str
    lb $t0, 0($t9)
    beqz $t0, skip_line
    lb $t1, 1($t9)
    beqz $t1, skip_line
    lb $t2, 2($t9)
    beqz $t2, skip_line

    # Find decimal point
    la $t5, float_str
find_decimal:
    lb $t6, 0($t5)
    beqz $t6, skip_line
    li $t7, 46
    beq $t6, $t7, found_decimal
    addiu $t5, $t5, 1
    j find_decimal

found_decimal:
    addiu $t5, $t5, 1
    li $t8, 0
    li $t4, 0

collect_digits:
    lb $t6, 0($t5)
    beqz $t6, done_digits
    li $t7, 10
    beq $t6, $t7, done_digits
    li $t7, 13
    beq $t6, $t7, done_digits
    li $t7, 32
    beq $t6, $t7, done_digits
    li $t3, 48
    blt $t6, $t3, done_digits
    li $t7, 57
    bgt $t6, $t7, done_digits

    subu $t2, $t6, $t3
    mul $t4, $t4, 10
    add $t4, $t4, $t2
    addiu $t5, $t5, 1
    addiu $t8, $t8, 1
    j collect_digits

done_digits:
    mtc1 $t4, $f2
    cvt.s.w $f2, $f2

    li $t6, 1
    li $t7, 0
pow10_loop:
    beq $t7, $t8, pow10_done
    mul $t6, $t6, 10
    addiu $t7, $t7, 1
    j pow10_loop

pow10_done:
    mtc1 $t6, $f4
    cvt.s.w $f4, $f4
    div.s $f0, $f2, $f4
    l.s $f6, one_float
    c.lt.s $f0, $f6
    bc1f value_too_large

    # Print parsed float
    li $v0, 4
    la $a0, float_msg
    syscall
    li $v0, 2
    mov.s $f12, $f0
    syscall

    # === First Fit ===
    la $t0, bins
    lw $t1, bin_count
    li $t2, 0

ff_loop:
    bge $t2, $t1, ff_no_fit
    mul $t5, $t2, 4
    add $t6, $t0, $t5
    l.s $f8, 0($t6)
    mov.s $f2, $f8
    c.le.s $f0, $f2
    bc1f ff_next_bin

    sub.s $f10, $f8, $f0
    s.s $f10, 0($t6)
    j ff_done

ff_next_bin:
    addiu $t2, $t2, 1
    j ff_loop

ff_no_fit:
    l.s $f6, one_float
    sub.s $f10, $f6, $f0
    mul $t5, $t1, 4
    add $t6, $t0, $t5
    s.s $f10, 0($t6)
    addiu $t1, $t1, 1
    sw $t1, bin_count

ff_done:
    # Store item value in item_values[item_count]
    lw $t3, item_count
    mul $t4, $t3, 4
    la $t5, item_values
    add $t5, $t5, $t4
    s.s $f0, 0($t5)

    # Store bin index in item_bins[item_count]
    la $t6, item_bins
    add $t6, $t6, $t4
    sw $t2, 0($t6)   # $t2 holds bin index used

    # Increment item_count
    addiu $t3, $t3, 1
    sw $t3, item_count


skip_line:
    la $s2, float_str
    j parse_loop

value_too_large:
    li $v0, 4
    la $a0, too_big_msg
    syscall
    j skip_line

check_final_float:
    la $t9, float_str
    lb $t8, 0($t9)
    beqz $t8, done_parsing
    lb $t8, 1($t9)
    beqz $t8, done_parsing
    j parse_float

done_parsing:
    li $v0, 4
    la $a0, newline
    syscall

    li $v0, 4
    la $a0, bin_msg
    syscall

    li $v0, 1
    lw $a0, bin_count
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    # For each bin
    li $t2, 0                   # bin index
    lw $t1, bin_count
    la $t0, bins
    la $s5, item_bins
    la $s6, item_values
    lw $s7, item_count

print_bins_loop:
    bge $t2, $t1, finish_program

    # Print Bin[i]:
    li $v0, 4
    la $a0, bin_title
    syscall

    li $v0, 1
    move $a0, $t2
    syscall

    li $v0, 4
    la $a0, end_bracket
    syscall

    # Loop over all items and print items in this bin
    li $t8, 0  # item index

print_items_in_bin:
    bge $t8, $s7, print_bin_remaining

    mul $t9, $t8, 4
    add $t4, $s5, $t9       # item_bins[i]
    lw $t3, 0($t4)
    bne $t3, $t2, skip_item

    # Print item value
    li $v0, 4
    la $a0, item_msg
    syscall

    add $t6, $s6, $t9       # item_values[i]
    l.s $f12, 0($t6)

    li $v0, 2
    syscall

    li $v0, 4
    la $a0, newline
    syscall

skip_item:
    addiu $t8, $t8, 1
    j print_items_in_bin

print_bin_remaining:
    # Print remaining space in bin
    li $v0, 4
    la $a0, space_left
    syscall

    mul $t5, $t2, 4
    add $t6, $t0, $t5
    l.s $f12, 0($t6)

    li $v0, 2
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    addiu $t2, $t2, 1
    j print_bins_loop


# === BEGIN: Best Fit Packing ===



parse_loop_bf:
    lb $t0, 0($s1)           # Load current char from file_data buffer
    beqz $t0, check_final_float_bf   # If null terminator → done

    # Check if it's newline or carriage return → time to parse float
    li $t1, 0x0A             # '\n'
    beq $t0, $t1, parse_float_bf
    li $t1, 0x0D             # '\r'
    beq $t0, $t1, parse_float_bf

    # Check if character is digit
    li $t3, 0x30             # ASCII '0'
    li $t4, 0x39             # ASCII '9'
    blt $t0, $t3, check_special_bf
    bgt $t0, $t4, check_special_bf
    j valid_char_bf

parse_float_bf:
    sb $zero, 0($s2)
    la $s2, float_str
    addiu $s1, $s1, 1

    la $t9, float_str
    lb $t0, 0($t9)
    beqz $t0, skip_line_bf
    lb $t1, 1($t9)
    beqz $t1, skip_line_bf
    lb $t2, 2($t9)
    beqz $t2, skip_line_bf

    la $t5, float_str
check_special_bf:
    li $t1, 0x2E             # ASCII '.' (dot)
    beq $t0, $t1, valid_char_bf
    li $t1, 0x20             # ASCII space
    beq $t0, $t1, skip_and_continue
    li $t1, 0x0A             # newline
    beq $t0, $t1, skip_and_continue
    li $t1, 0x0D             # carriage return
    beq $t0, $t1, skip_and_continue

    # If it's none of the above, it's invalid
    li $v0, 4
    la $a0, invalid_char_msg
    syscall
    j menu_loop

skip_and_continue:
    addiu $s1, $s1, 1        # skip the character
    j parse_loop_bf

valid_char_bf:
    sb $t0, 0($s2)           # store char in float_str
    addiu $s2, $s2, 1
    addiu $s1, $s1, 1        # advance file buffer
    j parse_loop_bf

# ==== START BEST FIT ====
start_bf:
    lw $t3, item_count
    li $t4, 0

bf_item_loop:
    bge $t4, $t3, bf_done

    mul $t5, $t4, 4
    la $t6, item_values
    add $t6, $t6, $t5
    l.s $f0, 0($t6)

    lw $t7, bin_count
    la $t8, bins
    li $t9, -1
    l.s $f10, float_1_point_1

    li $s0, 0
bf_bin_loop:
    bge $s0, $t7, bf_check_result
    mul $s1, $s0, 4
    add $s2, $t8, $s1
    l.s $f2, 0($s2)
    c.le.s $f0, $f2
    bc1f bf_next_bin

    sub.s $f4, $f2, $f0
    c.lt.s $f4, $f10
    bc1f bf_next_bin

    mov.s $f10, $f4
    move $t9, $s0

bf_next_bin:
    addiu $s0, $s0, 1
    j bf_bin_loop

bf_check_result:
    bgez $t9, bf_use_existing

    l.s $f6, one_float
    sub.s $f8, $f6, $f0
    mul $t2, $t7, 4
    la $t3, bins
    add $t3, $t3, $t2
    s.s $f8, 0($t3)
    move $t9, $t7
    addiu $t7, $t7, 1
    sw $t7, bin_count
    j bf_store

bf_use_existing:
    mul $t2, $t9, 4
    la $t3, bins
    add $t3, $t3, $t2
    l.s $f6, 0($t3)
    sub.s $f6, $f6, $f0
    s.s $f6, 0($t3)

bf_store:
    mul $t6, $t4, 4
    la $t7, item_bins
    add $t7, $t7, $t6
    sw $t9, 0($t7)

    addiu $t4, $t4, 1
    j bf_item_loop

bf_done:
    jr $ra
done_parsing_bf:
  j menu_loop
skip_line_bf:
    la $s2, float_str
    j parse_loop_bf

value_too_large_bf:
    li $v0, 4
    la $a0, too_big_msg
    syscall
    j skip_line_bf
 check_final_float_bf:
    la $t9, float_str
    lb $t8, 0($t9)        # Check first byte
    beqz $t8, done_parsing_bf  # If empty string → done

    lb $t8, 1($t9)        # Check second byte
    beqz $t8, done_parsing_bf  # If only one char → treat as junk

    j parse_float_bf 
    

finish_program:
    li $v0, 4
    la $a0, newline
    syscall

    j menu_loop   # GO BACK TO MENU instead of exiting



# ==== Ask for file ====
ask_for_file:
    la $a0, input_file_name
    li $v0, 4
    syscall
    la $a0, input_file
    li $a1, 100
    li $v0, 8
    syscall

    # Clean newline
    la $t0, input_file
remove_newline:
    lb $t1, 0($t0)
    beqz $t1, done_remove
    li $t2, 10
    beq $t1, $t2, replace_null
    addiu $t0, $t0, 1
    j remove_newline

replace_null:
    sb $zero, 0($t0)
done_remove:
    jr $ra

file_open_fail:
    li $v0, 4
    la $a0, error_msg
    syscall
    j menu_loop

parse_and_ff:
    jal read_file_only

    # Check if items exist
    lw $t0, item_count
    beqz $t0, return_to_menu

    # Now First Fit is already handled in parse_loop per item, so just return
    li $v0, 0
    jr $ra

parse_and_bf:
     jal read_file_only

    # Check if items exist
    lw $t0, item_count
    beqz $t0, return_to_menu

    # Now First Fit is already handled in parse_loop per item, so just return
    li $v0, 0
    jr $ra


return_to_menu:
    li $v0, 4
    la $a0, error_msg
    syscall
    jr $ra  # return to caller (menu)


read_file_only:
 jal ask_for_file 

    # Open file
    li $v0, 13
    la $a0, input_file
    li $a1, 0
    li $a2, 0
    syscall
    move $s0, $v0
    blt $s0, 0, return_to_menu   # if file fails, return

    # Debug print after success only
    li $v0, 4
    la $a0, debug_msg
    syscall
    li $v0, 4
    la $a0, input_file
    syscall

    # Read content
    li $v0, 14
    move $a0, $s0
    la $a1, file_data
    li $a2, 1024
    syscall

    # Close file
    li $v0, 16
    move $a0, $s0
    syscall


    # Start parsing
    la $s1, file_data
    la $s2, float_str
    j parse_loop


read_file_only_bf:
 jal ask_for_file 

    # Open file
    li $v0, 13
    la $a0, input_file
    li $a1, 0
    li $a2, 0
    syscall
    move $s0, $v0
    blt $s0, 0, return_to_menu   # if file fails, return

    # Debug print after success only
    li $v0, 4
    la $a0, debug_msg
    syscall
    li $v0, 4
    la $a0, input_file
    syscall

    # Read content
    li $v0, 14
    move $a0, $s0
    la $a1, file_data
    li $a2, 1024
    syscall

    # Close file
    li $v0, 16
    move $a0, $s0
    syscall


    # Start parsing
    la $s1, file_data
    la $s2, float_str
    j parse_loop

write_output_file:
    # Prompt for output file name
    li $v0, 4
    la $a0, output_file_prompt
    syscall

    la $a0, output_file
    li $a1, 100
    li $v0, 8
    syscall

    # Remove newline
    la $t0, output_file
remove_newline_out:
    lb $t1, 0($t0)
    beqz $t1, done_remove_out
    li $t2, 10
    beq $t1, $t2, replace_null_out
    addiu $t0, $t0, 1
    j remove_newline_out

replace_null_out:
    sb $zero, 0($t0)
done_remove_out:

    # Open file for writing
    li $v0, 13
    la $a0, output_file
    li $a1, 1           # write-only
    li $a2, 0
    syscall
    move $s7, $v0       # ✅ Store file descriptor in $s7
    blt $s7, 0, return_to_menu

    # Write " | Bin Count: "
    li $v0, 15
    move $a0, $s7
    la $a1, bin_msg
    li $a2, 14
    syscall

    lw $a0, bin_count
    jal print_int_to_file

    li $v0, 15
    move $a0, $s7
    la $a1, newline
    li $a2, 1
    syscall

    # Prepare pointers and counters
    li $t2, 0                      # bin index
    lw $t1, bin_count
    la $t0, bins
    la $s5, item_bins
    la $s6, item_values
    lw $t7, item_count            # ✅ item count in $t7 (not $s7!)

write_bins_loop:
    bge $t2, $t1, close_output_file

    # Write "Bin[i]:"
    li $v0, 15
    move $a0, $s7
    la $a1, bin_title
    li $a2, 5
    syscall

    move $a0, $t2
    jal print_int_to_file

    li $v0, 15
    move $a0, $s7
    la $a1, end_bracket
    li $a2, 2
    syscall

    li $t8, 0
write_items_in_bin:
    bge $t8, $t7, write_remaining

    mul $t9, $t8, 4
    add $t4, $s5, $t9
    lw $t3, 0($t4)
    bne $t3, $t2, skip_item_out

    li $v0, 15
    move $a0, $s7
    la $a1, item_msg
    li $a2, 10
    syscall

    add $t6, $s6, $t9
    l.s $f12, 0($t6)
    jal print_float_to_file

    li $v0, 15
    move $a0, $s7
    la $a1, newline
    li $a2, 1
    syscall

skip_item_out:
    addiu $t8, $t8, 1
    j write_items_in_bin

write_remaining:
    li $v0, 15
    move $a0, $s7
    la $a1, space_left
    li $a2, 24
    syscall

    mul $t5, $t2, 4
    add $t9, $t0, $t5
    l.s $f12, 0($t9)
    jal print_float_to_file

    li $v0, 15
    move $a0, $s7
    la $a1, newline
    li $a2, 1
    syscall

    addiu $t2, $t2, 1
    j write_bins_loop

close_output_file:
    li $v0, 16
    move $a0, $s7
    syscall
    jr $ra
print_int_to_file:
    move $t0, $a0
    la $t1, int_str
    li $t2, 0
    li $t4, 10

int_convert_loop:
    divu $t0, $t4
    mfhi $t5
    mflo $t0
    addi $t5, $t5, 48
    sb $t5, 0($t1)
    addi $t1, $t1, 1
    addi $t2, $t2, 1
    bnez $t0, int_convert_loop

    sb $zero, 0($t1)
    la $t3, int_str
    sub $t1, $t1, 1

reverse_int_str:
    blt $t3, $t1, swap_int_chars
    j write_int_final

swap_int_chars:
    lb $t4, 0($t3)
    lb $t5, 0($t1)
    sb $t5, 0($t3)
    sb $t4, 0($t1)
    addi $t3, $t3, 1
    addi $t1, $t1, -1
    j reverse_int_str

write_int_final:
    li $v0, 15
    move $a0, $s7
    la $a1, int_str
    move $a2, $t2
    syscall
    jr $ra

print_float_to_file:

    # Convert float in $f12 to integer part
    mov.s $f0, $f12
    trunc.w.s $f0, $f0
    mfc1 $a0, $f0
    jal print_int_to_file

    # Write the dot '.'
    li $v0, 15
    move $a0, $s7
    la $a1, dot_char
    li $a2, 1
    syscall

    # Compute fractional part
    cvt.s.w $f2, $f0         # f2 = int(float)
    sub.s $f12, $f12, $f2    # f12 = original - int part

    l.s $f4, float_100       # f4 = 100.0
    mul.s $f12, $f12, $f4    # f12 = frac * 100

    trunc.w.s $f12, $f12
    mfc1 $a0, $f12
    jal print_int_padded     # ensure two digits

    jr $ra

print_int_padded:
    # Pads left with zero if < 10 (i.e. 01, 02...)
    li $t0, 10
    blt $a0, $t0, print_leading_zero
    j print_int_to_file

print_leading_zero:
    li $v0, 15
    move $a0, $s7
    la $a1, zero_char
    li $a2, 1
    syscall
    j print_int_to_file


