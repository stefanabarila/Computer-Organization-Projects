# Alternative printf implementation in x86-64 assembly
# Supports %d, %u, %s, %% format specifiers using direct system calls

.section .data
    # String conversion workspace - 40 bytes for safety
    digit_workspace: .space 40
    
.section .text
.globl main
.globl my_printf

# Linux system call constants
.equ WRITE_SYSCALL, 1
.equ EXIT_SYSCALL, 60
.equ TERMINAL_FD, 1

main:
    pushq %rbp
    movq %rsp, %rbp
    
    # COMPREHENSIVE TEST: Space adventure story with multiple arguments
    # Tests 7 arguments: format + 6 variable arguments
    # First 6 var args go in registers, any beyond would use stack
    
    # Setup all arguments for space adventure story
    movq $space_story, %rdi        # Format string: space adventure
    movq $astronaut_name, %rsi     # Astronaut name: "Nova"
    movq $2157, %rdx               # Year: 2157
    movq $5, %rcx                  # Number of planets visited
    movq $847, %r8                 # Alien artifacts collected
    movq $captain_motto, %r9       # Captain's motto string
    pushq $42
    pushq $420
    
    call my_printf
    
    # BOUNDARY TESTS: Check special cases
    movq $boundary_tests, %rdi
    movq $0, %rsi                  # Test value: zero
    movq $18446744073709551615, %rdx  # Large unsigned: 2^64-1
    call my_printf
    
    # NEGATIVE VALUE TESTS: Verify signed integer handling  
    movq $signed_tests, %rdi
    movq $-789, %rsi               # Negative test value
    movq $-2147483648, %rdx        # Smallest negative 32-bit int
    call my_printf
    
    # Terminate program
    movq $EXIT_SYSCALL, %rax
    movq $0, %rdi
    syscall

# Custom printf implementation
# Input: %rdi=format_string, %rsi-%r9=arguments, stack=additional_args
my_printf:
    pushq %rbp
    movq %rsp, %rbp
    
    # Preserve all argument registers for later retrieval
    pushq %rdi    # format string saved at      -8(%rbp)
    pushq %rsi    # argument 1 saved at         -16(%rbp)
    pushq %rdx    # argument 2 saved at         -24(%rbp)
    pushq %rcx    # argument 3 saved at         -32(%rbp)
    pushq %r8     # argument 4 saved at         -40(%rbp)
    pushq %r9     # argument 5 saved at         -48(%rbp)
    
    # Allocate space for function state variables
    subq $32, %rsp
    # -56(%rbp) = argument_counter (which argument we're processing)
    # -64(%rbp) = format_pointer (current position in format string)
    # -72(%rbp) = temp storage
    # -80(%rbp) = additional temp storage
    
    # Initialize state variables
    movq $0, -56(%rbp)         # Start with first argument
    movq %rdi, -64(%rbp)       # Begin at start of format string
    
string_scanner:
    # Fetch current character from format string
    movq -64(%rbp), %rax
    movb (%rax), %cl
    
    # Test for string termination
    testb %cl, %cl
    jz function_exit
    
    # Check if current character starts a format sequence
    cmpb $'%', %cl
    je format_handler
    
    # Normal character processing - output directly
    movq -64(%rbp), %rsi       # Character location
    movq $1, %rdx              # Single character length
    call output_text
    
    # Advance to next character
    incq -64(%rbp)
    jmp string_scanner

format_handler:
    # Move past the '%' symbol
    incq -64(%rbp)
    
    # Get the format specification character
    movq -64(%rbp), %rax
    movb (%rax), %cl
    
    # Verify we haven't reached end of string
    testb %cl, %cl
    jz function_exit
    
    # Determine format type and branch accordingly
    cmpb $'d', %cl             # Signed decimal format
    je process_signed
    cmpb $'u', %cl             # Unsigned decimal format  
    je process_unsigned
    cmpb $'s', %cl             # String format
    je process_string
    cmpb $'%', %cl             # Literal percent symbol
    je process_literal_percent
    
    # Unrecognized format - output literally
    movq $percent_symbol, %rsi
    movq $1, %rdx
    call output_text           # Output '%'
    
    movq -64(%rbp), %rsi       # Output the unknown character
    movq $1, %rdx
    call output_text
    
    incq -64(%rbp)
    jmp string_scanner

process_signed:
    call fetch_argument
    call output_signed_number
    incq -64(%rbp)
    jmp string_scanner

process_unsigned:
    call fetch_argument
    call output_unsigned_number
    incq -64(%rbp)  
    jmp string_scanner

process_string:
    call fetch_argument
    movq %rax, %rsi
    call output_string
    incq -64(%rbp)
    jmp string_scanner

process_literal_percent:
    movq $percent_symbol, %rsi
    movq $1, %rdx
    call output_text
    incq -64(%rbp)
    jmp string_scanner

# Retrieve next argument based on current argument counter
# Output: argument value in %rax
fetch_argument:
    movq -56(%rbp), %rcx       # Load current argument index
    
    # Select argument source based on index
    cmpq $0, %rcx
    je fetch_arg_0
    cmpq $1, %rcx
    je fetch_arg_1  
    cmpq $2, %rcx
    je fetch_arg_2
    cmpq $3, %rcx
    je fetch_arg_3
    cmpq $4, %rcx
    je fetch_arg_4
    
    # Arguments beyond register capacity are on stack
    # Calculate stack position: base_offset + (index-5)*8
    subq $5, %rcx              
    imulq $8, %rcx             
    addq $16, %rcx             # Account for return address and saved rbp
    movq (%rbp, %rcx), %rax
    jmp fetch_complete

fetch_arg_0:
    movq -16(%rbp), %rax       # Retrieve saved %rsi
    jmp fetch_complete
fetch_arg_1:
    movq -24(%rbp), %rax       # Retrieve saved %rdx
    jmp fetch_complete
fetch_arg_2:
    movq -32(%rbp), %rax       # Retrieve saved %rcx
    jmp fetch_complete
fetch_arg_3:
    movq -40(%rbp), %rax       # Retrieve saved %r8
    jmp fetch_complete
fetch_arg_4:
    movq -48(%rbp), %rax       # Retrieve saved %r9
    jmp fetch_complete

fetch_complete:
    incq -56(%rbp)             # Increment argument counter
    ret

# Handle signed integer printing (supports negative values)
output_signed_number:
    pushq %rbp
    movq %rsp, %rbp
    
    # Check number sign
    testq %rax, %rax
    jns handle_positive
    
    # Negative number processing
    pushq %rax                 # Save negative value
    movq $minus_symbol, %rsi
    movq $1, %rdx
    call output_text           # Print minus sign
    popq %rax
    negq %rax                  # Convert to positive
    
handle_positive:
    call output_unsigned_number
    
    movq %rbp, %rsp
    popq %rbp
    ret

# Convert and output unsigned integer
output_unsigned_number:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %rcx
    pushq %rdx
    pushq %rsi
    
    # Handle zero as special case
    testq %rax, %rax
    jnz number_conversion
    
    movq $zero_symbol, %rsi
    movq $1, %rdx
    call output_text
    jmp number_output_done
    
number_conversion:
    # Convert number to string using division algorithm
    # Build digits in reverse order
    movq $digit_workspace + 39, %rdi  # Start at end of workspace
    movb $0, (%rdi)                   # Null terminate
    decq %rdi
    
    movq $10, %rbx                    # Division base
    
digit_extraction:
    movq $0, %rdx                     # Clear upper bits
    divq %rbx                         # Divide: quotient in %rax, remainder in %rdx
    
    addb $'0', %dl                    # Convert digit to ASCII
    movb %dl, (%rdi)                  # Store digit character
    decq %rdi
    
    testq %rax, %rax                  # Check for more digits
    jnz digit_extraction
    
    # Output the converted number
    incq %rdi                         # Point to first digit
    movq %rdi, %rsi
    call calculate_length             # Get string length
    movq %rax, %rdx
    call output_text
    
number_output_done:
    popq %rsi
    popq %rdx
    popq %rcx
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret

# Output null-terminated string
output_string:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rax
    pushq %rdx
    
    call calculate_length             # Determine string length
    movq %rax, %rdx
    call output_text
    
    popq %rdx
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    ret

# Calculate string length for null-terminated string
# Input: %rsi = string address
# Output: %rax = length
calculate_length:
    pushq %rcx
    movq $0, %rax                     # Initialize counter
    
length_loop:
    cmpb $0, (%rsi, %rax)             # Check for null terminator
    je length_complete
    incq %rax
    jmp length_loop
    
length_complete:
    popq %rcx
    ret

# System call interface for text output
# Input: %rsi = text address, %rdx = text length
output_text:
    pushq %rax
    pushq %rdi
    
    # Configure write system call
    movq $WRITE_SYSCALL, %rax
    movq $TERMINAL_FD, %rdi
    syscall
    
    popq %rdi
    popq %rax
    ret

function_exit:
    # Cleanup and return to caller
    addq $32, %rsp                    # Remove local variables
    
    # Restore all saved registers
    popq %r9
    popq %r8
    popq %rcx
    popq %rdx
    popq %rsi
    popq %rdi
    
    movq %rbp, %rsp
    popq %rbp
    ret

.section .rodata

# Space adventure story format
space_story: .asciz "Captain %s embarked on a mission in year %u.\nShe explored %u distant planets and discovered %u ancient artifacts.\nHer ship's motto: '%s'. Unknown format %%z detected! Mission success: %u%%! %u\n\n"

# Character elements
astronaut_name: .asciz "Nova"
captain_motto: .asciz "Explore beyond the stars"

# Test format strings
boundary_tests: .asciz "Boundary testing: Zero=%u, Maximum=%u, Format %%y unsupported!\n\n"
signed_tests: .asciz "Sign tests: Negative %d, Minimum %d verified!\n\n"

# Character constants
percent_symbol: .asciz "%"
minus_symbol: .asciz "-"
zero_symbol: .asciz "0"
