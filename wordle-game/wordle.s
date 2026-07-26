# Wordle Game (AT&T syntax, Linux x86-64)
# Alexandru Daria & Barila Stefana


.section .data
    .equ WORD_LENGTH, 5
    .equ MAX_TRIES,   6
    .equ TIME_LIMIT, 120            # seconds

    color_reset:   .string "\033[0m"
    color_green:   .string "\033[42m\033[30m"
    color_yellow:  .string "\033[43m\033[30m"
    color_gray:    .string "\033[100m\033[37m"
    color_clear:   .string "\033[2J\033[H"

    msg_title:     .string "\n=== WORDLE GAME ===\n"
    msg_rules:     .string "Guess the 5-letter word in 6 tries!\n\n"
    msg_prompt:    .string "Enter your guess (5 letters): "
    msg_invalid:   .string "\nInvalid word! Try again.\n"
    msg_win:       .string "\n Congratulations! You won!\n"
    msg_lose:      .string "\n Game Over! The word was: "
    msg_timeout:   .string "\n Time's up! The word was: "
    msg_nl:        .string "\n"
    msg_sp:        .string " "
    msg_tries:     .string "Tries used: "
    msg_score:     .string "\n=== SCOREBOARD ===\n"
    msg_div:       .string "---------------\n"

    # Small demo dictionary 
    word0:  .string "apple"
    word1:  .string "brave"
    word2:  .string "chair"
    word3:  .string "dance"
    word4:  .string "earth"
    word5:  .string "flame"
    word6:  .string "grace"
    word7:  .string "heart"
    word8:  .string "image"
    word9:  .string "joker"
    word10: .string "knife"
    word11: .string "light"
    word12: .string "music"
    word13: .string "night"
    word14: .string "ocean"
    word15: .string "peace"
    word16: .string "queen"
    word17: .string "robot"
    word18: .string "smile"
    word19: .string "train"

    dictionary:
        .quad word0, word1, word2, word3, word4
        .quad word5, word6, word7, word8, word9
        .quad word10, word11, word12, word13, word14
        .quad word15, word16, word17, word18, word19

    dict_count: .quad 20

.section .bss
    .lcomm secret_word, 8   
    .lcomm current_guess, 8
    .lcomm feedback, 48        
    .lcomm guesses, 384              
    .lcomm tries_count, 8
    .lcomm input_buffer, 128
    .lcomm start_time, 8
    .lcomm letter_counts, 32        

.section .text
.globl main

main:
    pushq %rbp
    movq %rsp, %rbp

    # init tries
    movq $0, tries_count

    # choose random secret
    call select_random_word

    # record start time
    call record_start_time

    # show initial empty grid
    call display_grid

game_loop:
    # timeout check
    call check_timeout
    testq %rax, %rax
    jnz game_over_timeout

    # prompt and read guess
    call get_user_guess

    # validate (letters + dictionary)
    call validate_guess
    testq %rax, %rax
    jz invalid_guess

    # store guess
    call save_guess

    # compute feedback for this row
    call process_guess

    # this guess is now "played"
    incq tries_count

    # draw grid (now shows this row)
    call display_grid

    # win
    call check_win
    cmpq $1, %rax
    je game_over_win

    # out of tries
    movq tries_count, %rax
    cmpq $MAX_TRIES, %rax
    jl game_loop

    # lose
    jmp game_over_lose

invalid_guess:
    leaq msg_invalid, %rdi
    call print_str
    jmp game_loop

game_over_win:
    leaq msg_win, %rdi
    call print_str
    call show_scoreboard
    jmp exit_ok

game_over_lose:
    leaq msg_lose, %rdi
    call print_str
    leaq secret_word, %rdi
    call print_str
    leaq msg_nl, %rdi
    call print_str
    call show_scoreboard
    jmp exit_ok

game_over_timeout:
    leaq msg_timeout, %rdi
    call print_str
    leaq secret_word, %rdi
    call print_str
    leaq msg_nl, %rdi
    call print_str
    call show_scoreboard

exit_ok:
    xorq %rax, %rax
    leave
    ret

clear_screen:
    pushq %rbp
    movq %rsp, %rbp
    leaq color_clear, %rdi
    call print_str
    leave
    ret

display_grid:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13

    call clear_screen
    leaq msg_title, %rdi
    call print_str
    leaq msg_rules, %rdi
    call print_str
    leaq msg_nl, %rdi
    call print_str

    movq $0, %r12                 # row = 0..5
row_loop:
    cmpq $MAX_TRIES, %r12
    jge done

    # if row >= tries_count ⇒ empty row
    movq tries_count, %rax
    cmpq %r12, %rax
    jle empty_row

    # played row 
    movq $0, %r13                 # col = 0..4
col_loop:
    cmpq $5, %r13
    jge row_end

    # feedback[row][col]
    movq %r12, %rax
    imulq $8, %rax
    addq %r13, %rax
    leaq feedback, %rbx
    movb (%rbx,%rax,1), %cl

    # color
    cmpb $'G', %cl
    je tile_green
    cmpb $'Y', %cl
    je tile_yellow
    leaq color_gray, %rdi
    jmp tile_after_color
tile_green:
    leaq color_green, %rdi
    jmp tile_after_color
tile_yellow:
    leaq color_yellow, %rdi
tile_after_color:
    call print_str

    # letter from guesses[row][col]
    movq %r12, %rax
    imulq $64, %rax
    addq %r13, %rax
    leaq guesses, %rbx
    movzbl (%rbx,%rax,1), %eax      # AL = letter

    # to uppercase if a-z
    cmpb $'a', %al
    jb no_up
    cmpb $'z', %al
    ja no_up
    subb $32, %al
no_up:
    movzbq %al, %rdi
    call print_char

    # reset + space
    leaq color_reset, %rdi
    call print_str
    leaq msg_sp, %rdi
    call print_str

    incq %r13
    jmp col_loop

    # empty row
empty_row:
    movq $0, %r13
empty_col:
    cmpq $5, %r13
    jge row_end
    leaq color_gray, %rdi
    call print_str
    movq $'_', %rdi
    call print_char
    leaq color_reset, %rdi
    call print_str
    leaq msg_sp, %rdi
    call print_str
    incq %r13
    jmp empty_col

row_end:
    leaq msg_nl, %rdi
    call print_str
    incq %r12
    jmp row_loop

done:
    leaq msg_nl, %rdi
    call print_str

    popq %r13
    popq %r12
    popq %rbx
    leave
    ret

get_user_guess:
    pushq %rbp
    movq %rsp, %rbp

    leaq msg_prompt, %rdi
    call print_str

    # read up to 128 bytes
    movq $0, %rax                # sys_read
    movq $0, %rdi                # stdin
    leaq input_buffer, %rsi
    movq $128, %rdx
    syscall

    # copy first 5 chars to current_guess, lowercasing
    leaq input_buffer, %rsi
    leaq current_guess, %rdi
    movq $5, %rcx
copy:
    movb (%rsi), %al
    cmpb $'A', %al
    jb no_low
    cmpb $'Z', %al
    ja no_low
    addb $32, %al     # makes lowercase
no_low:
    movb %al, (%rdi)
    incq %rsi
    incq %rdi
    loop copy
    movb $0, (%rdi)
    leave
    ret

save_guess:
    pushq %rbp
    movq %rsp, %rbp
    # offset = tries_count * 64 (tries_count not yet inc when called)
    movq tries_count, %rax
    imulq $64, %rax
    leaq guesses, %rdi
    addq %rax, %rdi
    leaq current_guess, %rsi
    movq $6, %rcx
    rep movsb
    leave
    ret

validate_guess:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12

    # letters only
    leaq current_guess, %rsi
    movq $5, %rcx
chk:
    movb (%rsi), %al
    cmpb $'a', %al
    jb bad
    cmpb $'z', %al
    ja bad
    incq %rsi
    loop chk

    # dict membership
    leaq dictionary, %rbx
    movq dict_count, %r12
loop_dict:
    cmpq $0, %r12
    je bad
    movq (%rbx), %rdi           # word*
    leaq current_guess, %rsi
    movq $5, %rcx
cmp5:
    movb (%rsi), %al
    cmpb (%rdi), %al
    jne next
    incq %rsi
    incq %rdi
    loop cmp5
    movq $1, %rax               # found
    jmp ok_end
next:
    addq $8, %rbx
    decq %r12
    jmp loop_dict

bad:
    movq $0, %rax
ok_end:
    popq %r12
    popq %rbx
    leave
    ret

process_guess:
    pushq %rbp
    movq  %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    # row index = current tries_count (before increment)
    movq tries_count, %r15

    # base ptr for feedback[row]
    movq %r15, %rax
    imulq $8, %rax
    leaq feedback, %rbx
    addq %rax, %rbx             # RBX = &feedback[row][0]

    # init feedback to 'N'
    movq $5, %rcx
    movq %rbx, %rdi
initN:
    movb $'N', (%rdi)
    incq %rdi
    loop initN

    # zero counts[26]
    leaq letter_counts, %rdi
    movq $26, %rcx
    xorq %rax, %rax
zeroC:
    movb %al, (%rdi)
    incq %rdi
    loop zeroC

    # build counts from secret
    movq $0, %r12
count_loop:
    cmpq $5, %r12
    jge first_pass
    leaq secret_word, %rdi
    movzbl (%rdi,%r12,1), %eax     # eax = secret[i]
    subl $'a', %eax
    # guard (0..25)
    cmpl $25, %eax
    ja inc_i1
    leaq letter_counts, %rsi
    addq %rax, %rsi
    movzbl (%rsi), %edx
    incl %edx
    movb %dl, (%rsi)
inc_i1:
    incq %r12
    jmp count_loop

    # first pass: greens
first_pass:
    movq $0, %r12
g1:
    cmpq $5, %r12
    jge second_pass
    leaq current_guess, %rdi
    leaq secret_word, %rsi
    movzbl (%rdi,%r12,1), %eax
    movzbl (%rsi,%r12,1), %edx
    cmpl %edx, %eax
    jne g1_next

    # mark G
    movb $'G', (%rbx,%r12,1)
    # decrement count for that letter
    subl $'a', %eax
    cmpl $25, %eax
    ja g1_next
    leaq letter_counts, %rdi
    addq %rax, %rdi
    movzbl (%rdi), %ecx
    testl %ecx, %ecx
    jz g1_next
    decl %ecx
    movb %cl, (%rdi)
g1_next:
    incq %r12
    jmp g1

    # second pass: yellows if remaining count > 0 (and not green)
second_pass:
    movq $0, %r12
g2:
    cmpq $5, %r12
    jge done_proc

    # skip already green
    movb (%rbx,%r12,1), %al
    cmpb $'G', %al
    je g2_next

    # take guess letter
    leaq current_guess, %rdi
    movzbl (%rdi,%r12,1), %eax
    subl $'a', %eax
    cmpl $25, %eax
    ja g2_next

    leaq letter_counts, %rsi
    addq %rax, %rsi
    movzbl (%rsi), %ecx
    testl %ecx, %ecx
    jz g2_next
    # mark Y and decrement
    movb $'Y', (%rbx,%r12,1)
    decl %ecx
    movb %cl, (%rsi)

g2_next:
    incq %r12
    jmp g2

done_proc:
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    leave
    ret

check_win:
    pushq %rbp
    movq %rsp, %rbp
    leaq current_guess, %rsi
    leaq secret_word, %rdi
    movq $5, %rcx
loopW:
    movb (%rsi), %al
    cmpb (%rdi), %al
    jne no
    incq %rsi
    incq %rdi
    loop loopW
    movq $1, %rax
    leave
    ret
no:
    xorq %rax, %rax
    leave
    ret

select_random_word:
    pushq %rbp
    movq %rsp, %rbp

    xorq %rdi, %rdi          # time(NULL)
    call time@PLT           

    movq dict_count, %rcx
    xorq %rdx, %rdx
    divq %rcx                # RDX = time % dict_count
    movq %rdx, %rax          # index

    leaq dictionary, %rsi
    movq (%rsi,%rax,8), %rsi # word* → RSI

    leaq secret_word, %rdi
    movq $5, %rcx
cp:
    movb (%rsi), %al
    movb %al, (%rdi)
    incq %rsi
    incq %rdi
    loop cp
    movb $0, (%rdi)

    leave
    ret

record_start_time:
    pushq %rbp
    movq %rsp, %rbp
    xorq %rdi, %rdi
    call time@PLT
    movq %rax, start_time
    leave
    ret

check_timeout:
    pushq %rbp
    movq %rsp, %rbp
    xorq %rdi, %rdi
    call time@PLT
    subq start_time, %rax
    cmpq $TIME_LIMIT, %rax
    movq $0, %rax
    jl ok
    movq $1, %rax
ok:
    leave
    ret

show_scoreboard:
    pushq %rbp
    movq %rsp, %rbp

    leaq msg_score, %rdi
    call print_str
    leaq msg_div, %rdi
    call print_str

    leaq msg_tries, %rdi
    call print_str

    movq tries_count, %rax
    call print_num
    leaq msg_nl, %rdi
    call print_str

    leave
    ret

print_str:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    movq %rdi, %rbx
    movq %rdi, %rsi
    call str_len
    movq %rax, %rdx
    movq $1, %rax            # write
    movq $1, %rdi            # fd=1
    movq %rbx, %rsi
    syscall
    popq %rbx
    leave
    ret

print_char:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    movb %dil, -1(%rbp)
    movq $1, %rax
    movq $1, %rdi
    leaq -1(%rbp), %rsi
    movq $1, %rdx
    syscall
    leave
    ret

# prints unsigned in %rax
print_num:
    pushq %rbp
    movq %rsp, %rbp
    subq $32, %rsp
    movq %rax, %r8           # save input
    leaq -1(%rbp), %rdi
    movb $0, (%rdi)
    movq %r8, %rax
    movq $10, %rcx
pn_loop:
    xorq %rdx, %rdx
    divq %rcx
    addb $'0', %dl
    decq %rdi
    movb %dl, (%rdi)
    testq %rax, %rax
    jnz pn_loop
    movq %rdi, %rdi
    call print_str
    leave
    ret

str_len:
    pushq %rbp
    movq %rsp, %rbp
    movq %rsi, %rax
sl:
    cmpb $0, (%rax)
    je sd
    incq %rax
    jmp sl
sd:
    subq %rsi, %rax
    leave
    ret


.section .note.GNU-stack,"",@progbits
