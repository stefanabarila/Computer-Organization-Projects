.section .data
    # Hidden payload to embed
    payload: .asciz "The quick brown fox jumps over the lazy dog"
   
    # Prefix sequence before the payload
    # 8xC, 4xS, 2xE, 4x1, 4x4, 8x0
    prefix: .asciz "CCCCCCCCSSSSEE11114444000000000"
   
    # Suffix sequence after the payload (mirrors prefix)
    suffix: .asciz "CCCCCCCCSSSSEE11114444000000000"
   
    # Bitmap file signature and metadata (14 bytes total)
    bitmap_sig:
        .byte 'B', 'M'           # Magic number for BMP
        .Long 3126               # Complete file size in bytes
        .Long 0                  # Reserved field (unused)
        .Long 54                 # Offset to pixel array
   
    # Bitmap information header (40 bytes total)
    bitmap_info:
        .Long 40                 # Header size
        .Long 32                 # Width in pixels
        .Long 32                 # Height in pixels
        .word 1                  # Color planes (always 1)
        .word 24                 # Bits per pixel (RGB)
        .Long 0                  # Compression method (none)
        .Long 3072               # Image size (32*32*3)
        .Long 2835               # Horizontal resolution (pixels/meter)
        .Long 2835               # Vertical resolution (pixels/meter)
        .Long 0                  # Colors in palette
        .Long 0                  # Important colors
   
    output_file: .asciz "stego.bmp"

.section .bss
    # Storage for combined prefix + payload + suffix
    .Lcomm combined_data, 200
   
    # Storage for run-length encoded data
    .Lcomm compressed_data, 400
   
    # Storage for visual pattern (32x32 pixels * 3 bytes RGB)
    .Lcomm pattern_grid, 3072
   
    # Storage for final encoded bitmap
    .Lcomm encoded_bitmap, 3072
   
    # Buffers for decoding process
    .Lcomm recovered_bitmap, 3072
    .Lcomm decompressed_data, 400
    .Lcomm extracted_payload, 200

.section .text
    .globl main
    .globl encrypt
    .globl decrypt

main:
    pushq %rbp
    movq %rsp, %rbp
   
    # Phase 1: Merge prefix + payload + suffix
    call merge_components
   
    # Phase 2: Apply run-length encoding compression
    call apply_rle_encoding
   
    # Phase 3: Generate visual pattern grid
    call generate_pattern
   
    # Phase 4: Encode data using XOR cipher
    call encrypt
   
    # Phase 5: Export as bitmap file
    call export_bitmap

    # Phase 6: Decode and verify
    call decrypt
   
    # Display recovered payload
    movq $1, %rax                # write syscall
    movq $1, %rdi                # stdout
    movq $extracted_payload, %rsi
    movq $100, %rdx
    syscall
   
    # Clean exit
    movq $60, %rax               # exit syscall
    xorq %rdi, %rdi              # status 0
    syscall
   
    movq %rbp, %rsp
    popq %rbp
    ret

merge_components:
    # Concatenates prefix, payload, and suffix into combined_data
   
    pushq %rsi
    pushq %rdi
   
    movq $combined_data, %rdi    # Destination pointer
   
    # Append prefix
    movq $prefix, %rsi
    call copy_string
   
    # Append payload
    movq $payload, %rsi
    call copy_string
   
    # Append suffix
    movq $suffix, %rsi
    call copy_string
   
    movb $0, (%rdi)              # Null terminator
   
    popq %rdi
    popq %rsi
    ret

copy_string:
    # Helper: copies null-terminated string
    # Input: rsi=source, rdi=destination
    # Output: rdi advanced to next position
   
    pushq %rax
   
Lcopy_next:
    movb (%rsi), %al
    cmpb $0, %al
    je Lcopy_end
   
    movb %al, (%rdi)
    incq %rsi
    incq %rdi
    jmp Lcopy_next
   
Lcopy_end:
    popq %rax
    ret

apply_rle_encoding:
    # Compresses combined_data using Run-Length Encoding
    # Output format: byte pairs [count][char]
   
    pushq %rsi
    pushq %rdi
    pushq %rax
    pushq %rbx
    pushq %rcx
   
    movq $combined_data, %rsi
    movq $compressed_data, %rdi
   
Lrle_next:
    movb (%rsi), %al
    cmpb $0, %al
    je Lrle_complete
   
    movb %al, %bl                # Store current char
    movq $1, %rcx                # Start count
    incq %rsi
   
Lrle_count:
    movb (%rsi), %al
    cmpb $0, %al
    je Lrle_emit
   
    cmpb %bl, %al
    jne Lrle_emit
   
    incq %rcx
    incq %rsi
   
    cmpq $255, %rcx              # Max count limit
    jl Lrle_count
   
Lrle_emit:
    movb %cl, (%rdi)             # Emit count
    incq %rdi
   
    movb %bl, (%rdi)             # Emit character
    incq %rdi
   
    jmp Lrle_next
   
Lrle_complete:
    movb $0, (%rdi)              # End marker
   
    popq %rcx
    popq %rbx
    popq %rax
    popq %rdi
    popq %rsi
    ret

generate_pattern:
    # Creates 32x32 RGB pattern grid
    # Stripe pattern: 8W + 8B + 4W + 4B + 2W + 3B + 2W + 1R
    # W=white(255,255,255), B=black(0,0,0), R=red(0,0,255)
   
    pushq %rdi
    pushq %rcx
    pushq %rax
   
    movq $pattern_grid, %rdi
    movq $32, %rax               # Row counter
   
Lpattern_row:
    pushq %rax
   
    # 8 white pixels
    movq $8, %rcx
    call draw_white
   
    # 8 black pixels
    movq $8, %rcx
    call draw_black
   
    # 4 white pixels
    movq $4, %rcx
    call draw_white
   
    # 4 black pixels
    movq $4, %rcx
    call draw_black
   
    # 2 white pixels
    movq $2, %rcx
    call draw_white
   
    # 3 black pixels
    movq $3, %rcx
    call draw_black
   
    # 2 white pixel
    movq $2, %rcx
    call draw_white
   
    # 1 red pixel (marker)
    movb $0, (%rdi)              # Blue
    movb $0, 1(%rdi)           # Green
    movb $255, 2(%rdi)             # Red
    addq $3, %rdi
   
    popq %rax
    decq %rax
    jnz Lpattern_row
   
    popq %rax
    popq %rcx
    popq %rdi
    ret

draw_white:
    # Renders rcx white pixels (RGB: 255,255,255)
   
    pushq %rcx
   
white_loop:
    movb $255, (%rdi)
    movb $255, 1(%rdi)
    movb $255, 2(%rdi)
    addq $3, %rdi
    loop white_loop
   
    popq %rcx
    ret

draw_black:
    # Renders rcx black pixels (RGB: 0,0,0)
   
    pushq %rcx
   
black_loop:
    movb $0, (%rdi)
    movb $0, 1(%rdi)
    movb $0, 2(%rdi)
    addq $3, %rdi
    loop black_loop
   
    popq %rcx
    ret

encrypt:
    # XOR encryption: pattern_grid XOR compressed_data
    # Output stored in encoded_bitmap
   
    pushq %rsi
    pushq %rdi
    pushq %rax
    pushq %rcx
   
    # Copy pattern to output first
    movq $pattern_grid, %rsi
    movq $encoded_bitmap, %rdi
    movq $3072, %rcx
    rep movsb
   
    # XOR compressed data into the bitmap
    movq $compressed_data, %rsi
    movq $encoded_bitmap, %rdi
   
Lencode_loop:
    movb (%rsi), %al
    cmpb $0, %al
    je Lencode_finish
   
    xorb %al, (%rdi)
   
    incq %rsi
    incq %rdi
    jmp Lencode_loop
   
Lencode_finish:
    popq %rcx
    popq %rax
    popq %rdi
    popq %rsi
    ret

export_bitmap:
    # Writes encoded_bitmap to stego.bmp file
   
    pushq %rbx
    pushq %rcx
    pushq %rdx
   
    # Create file
    movq $2, %rax                # open syscall
    movq $output_file, %rdi
    movq $577, %rsi              # O_CREAT|O_WRONLY|O_TRUNC
    movq $0644, %rdx
    syscall
   
    cmpq $0, %rax
    jl Lexport_error
   
    movq %rax, %rbx              # Save file descriptor
   
    # Write BMP signature
    movq $1, %rax                # write syscall
    movq %rbx, %rdi
    movq $bitmap_sig, %rsi
    movq $14, %rdx
    syscall
   
    # Write BMP info header
    movq $1, %rax
    movq %rbx, %rdi
    movq $bitmap_info, %rsi
    movq $40, %rdx
    syscall
   
    # Write pixel data
    movq $1, %rax
    movq %rbx, %rdi
    movq $encoded_bitmap, %rsi
    movq $3072, %rdx
    syscall
   
    # Close file
    movq $3, %rax                # close syscall
    movq %rbx, %rdi
    syscall
   
Lexport_error:
    popq %rdx
    popq %rcx
    popq %rbx
    ret

decrypt:
    # Reverses encoding process
    # Steps: Load BMP → XOR decode → RLE decompress → Extract payload
   
    pushq %rbp
    movq %rsp, %rbp
   
    call load_bitmap
    call xor_decode
    call decompress_rle
    call extract_original
   
    movq $extracted_payload, %rax
   
    movq %rbp, %rsp
    popq %rbp
    ret

load_bitmap:
    # Reads stego.bmp into recovered_bitmap
   
    pushq %rbx
    pushq %rcx
    pushq %rdx
   
    # Open file
    movq $2, %rax                # open syscall
    movq $output_file, %rdi
    movq $0, %rsi                # O_RDONLY
    syscall
   
    cmpq $0, %rax
    jl Lload_error
   
    movq %rax, %rbx
   
    # Skip to pixel data (offset 54)
    movq $8, %rax                # lseek syscall
    movq %rbx, %rdi
    movq $54, %rsi
    movq $0, %rdx                # SEEK_SET
    syscall
   
    # Read pixel data
    movq $0, %rax                # read syscall
    movq %rbx, %rdi
    movq $recovered_bitmap, %rsi
    movq $3072, %rdx
    syscall
   
    # Close file
    movq $3, %rax
    movq %rbx, %rdi
    syscall
   
Lload_error:
    popq %rdx
    popq %rcx
    popq %rbx
    ret

xor_decode:
    # XOR recovered_bitmap with pattern_grid to get compressed_data
   
    pushq %rsi
    pushq %rdi
    pushq %rax
    pushq %rcx
   
    movq $recovered_bitmap, %rsi
    movq $pattern_grid, %rdi
    movq $decompressed_data, %rcx
   
    xorq %rax, %rax
   
Lxor_decode_loop:
    movb (%rsi), %al
    xorb (%rdi), %al
    movb %al, (%rcx)
   
    incq %rsi
    incq %rdi
    incq %rcx
   
    cmpb $0, %al
    je Lxor_decode_done
   
    movq %rcx, %rax
    subq $decompressed_data, %rax
    cmpq $400, %rax
    jge Lxor_decode_done
   
    jmp Lxor_decode_loop
   
Lxor_decode_done:
    popq %rcx
    popq %rax
    popq %rdi
    popq %rsi
    ret

decompress_rle:
    # Expands RLE data from decompressed_data to combined_data
   
    pushq %rsi
    pushq %rdi
    pushq %rax
    pushq %rbx
    pushq %rcx
   
    movq $decompressed_data, %rsi
    movq $combined_data, %rdi
   
Lrle_decode_loop:
    movb (%rsi), %cl
    cmpb $0, %cl
    je Lrle_decode_done
   
    incq %rsi
    movb (%rsi), %bl
    incq %rsi
   
Lrle_expand:
    movb %bl, (%rdi)
    incq %rdi
    decb %cl
    jnz Lrle_expand
   
    jmp Lrle_decode_loop
   
Lrle_decode_done:
    movb $0, (%rdi)
   
    popq %rcx
    popq %rbx
    popq %rax
    popq %rdi
    popq %rsi
    ret

extract_original:
    # Removes prefix (31 chars) and suffix (31 chars)
    # Extracts original payload to extracted_payload
   
    pushq %rsi
    pushq %rdi
    pushq %rcx
    pushq %rbx
   
    movq $combined_data, %rsi
    addq $31, %rsi               # Skip prefix
   
    movq $extracted_payload, %rdi
   
    # Calculate message length
    movq $combined_data, %rax
    xorq %rcx, %rcx
   
Lcount_len:
    movb (%rax), %bl
    cmpb $0, %bl
    je Lgot_len
    incq %rax
    incq %rcx
    jmp Lcount_len
   
Lgot_len:
    subq $62, %rcx               # Remove prefix+suffix length
   
Lextract_loop:
    cmpq $0, %rcx
    jle Lextract_done
   
    movb (%rsi), %al
    movb %al, (%rdi)
    incq %rsi
    incq %rdi
    decq %rcx
    jmp Lextract_loop
   
Lextract_done:
    movb $0, (%rdi)
   
    popq %rbx
    popq %rcx
    popq %rdi
    popq %rsi
    ret
