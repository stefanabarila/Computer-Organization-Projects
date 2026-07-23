.data
# Configurare flags si parametri
flag_case_insensitive:  .byte 0      # 1 daca avem -i, altfel 0
flag_skip_blanks:       .byte 0      # 1 daca avem -B, altfel 0

# Pointeri pentru fisiere
first_file_name:        .quad 0      # numele primului fisier
second_file_name:       .quad 0      # numele celui de-al doilea fisier
first_file_stream:      .quad 0      # FILE* pentru primul fisier
second_file_stream:     .quad 0      # FILE* pentru al doilea fisier

# Buffere pentru citirea liniilor
line_buffer_a:          .space 1024  # buffer pentru fisierul 1
line_buffer_b:          .space 1024  # buffer pentru fisierul 2

# Contor pentru linia curenta
current_line_counter:   .long 1      # numarul liniei curente

# siruri pentru formatarea outputului
fmt_change_line:        .string "%dc%d\n"        # afiseaza "NcN"
fmt_first_line:         .string "< %s\n"         # afiseaza "< linie"
fmt_divider:            .string "---\n"          # separator intre linii
fmt_second_line:        .string "> %s\n"         # afiseaza "> linie"
file_open_mode:         .string "r"              # mod de deschidere fisier

.text
.global main
.global diff

main:
    pushq   %rbp                 # salvam base pointer
    mov     %rsp, %rbp           # initializam noul frame
   
    call    diff                 # executa compararea fisierelor
   
    mov     %eax, %edi           # pregatim codul de iesire
    call    exit                 # terminam programul

# Functia principala diff
# Intrare: %edi = argc, %rsi = argv
# Iesire: %eax = cod de iesire (0 = succes, 1 = eroare)
diff:
    pushq   %rbp                 # salvam base pointer
    mov     %rsp, %rbp           # initializam noul frame
    pushq   %r12                 # salvam registre care trebuie pastrate
    pushq   %r13
    pushq   %r14
    pushq   %r15

    # Pastram argc si argv
    mov     %edi, %r14d          # argc in r14
    mov     %rsi, %r15           # argv in r15

    # Resetam flag-urile
    movb    $0, flag_case_insensitive
    movb    $0, flag_skip_blanks

    # Verificam daca avem suficiente argumente
    cmp     $3, %r14d            # avem cel putin 3 argumente?
    jl      exit_with_error      # daca nu, iesim cu eroare

    # Procesam argumentele comenzii
    mov     $1, %r12d            # incepem de la argv[1]
   
argument_processing_loop:
    cmp     %r12d, %r14d         # am terminat toate argumentele?
    jle     validate_filenames   # daca da, validam numele fisierelor
   
    # Obtinem argumentul curent
    mov     %r12, %rax           # indexul curent
    shl     $3, %rax             # inmultim cu 8
    add     %r15, %rax           # adaugam la baza argv
    mov     (%rax), %rdi         # incarcam argv[r12]
   
    # Verificam daca e flag (incepe cu '-')
    movb    (%rdi), %al          # primul caracter
    cmp     $45, %al             # e '-'?
    jne     store_filename       # daca nu, e nume de fisier
   
    # E un flag, il procesam
    call    process_flags        # analizam flag-urile
    inc     %r12d                # trecem la urmatorul argument
    jmp     argument_processing_loop
   
store_filename:
    # E nume de fisier, verificam unde sa-l punem
    cmp     $0, first_file_name # primul fisier e setat?
    jne     store_second_file    # daca da, setam al doilea
   
    # Setam primul fisier
    mov     %rdi, first_file_name
    inc     %r12d                # urmatorul argument
    jmp     argument_processing_loop
   
store_second_file:
    # Setam al doilea fisier
    mov     %rdi, second_file_name
    inc     %r12d                # urmatorul argument
    jmp     argument_processing_loop

validate_filenames:
    # Verificam ca am primit ambele fisiere
    cmp     $0, first_file_name # primul fisier exista?
    je      exit_with_error      # daca nu, eroare
    cmp     $0, second_file_name # al doilea fisier exista?
    je      exit_with_error      # daca nu, eroare
    jmp     open_both_files

# Functie pentru verificarea unei linii goale
# Intrare: %rdi = pointer la sir
# Iesire: %eax = 1 daca linia e goala, 0 altfel
check_if_blank:
    pushq   %rbp                 # salvam base pointer
    mov     %rsp, %rbp           # initializam stack frame
   
inspect_character:
    movb    (%rdi), %al          # citim caracterul
    cmp     $0, %al              # daca e terminator null
    je      found_blank_line     # daca da, linia e goala
   
    # Verificam caractere whitespace
    cmp     $32, %al             # spatiu?
    je      advance_position     
    cmp     $9, %al              # tab?
    je      advance_position     
    cmp     $10, %al             # newline?
    je      advance_position     
    cmp     $13, %al             # carriage return?
    je      advance_position     
   
    # Am gasit caracter non-whitespace
    mov     $0, %eax             # return 0
    jmp     finish_blank_check
   
advance_position:
    inc     %rdi                 # mergi la urmatorul caracter
    jmp     inspect_character    
   
found_blank_line:
    mov     $1, %eax             # return 1
   
finish_blank_check:
    popq    %rbp                 # restauram base pointer
    ret                          # return

# Functie pentru eliminarea newline-ului din sir
# Intrare: %rdi = sir de caractere
strip_newline:
    pushq   %rbp
    mov     %rsp, %rbp
   
search_for_end:
    movb    (%rdi), %al          # citim caracterul
    cmp     $0, %al              # null terminator?
    je      newline_stripped     # daca da, terminam
    cmp     $10, %al             # newline?
    je      remove_it            # daca da, il eliminam
    inc     %rdi                 # urmatorul caracter
    jmp     search_for_end       # continuam cautarea

remove_it:
    movb    $0, (%rdi)           # inlocuim cu null

newline_stripped:
    popq    %rbp
    ret

# Functie pentru procesarea flag-urilor (ex: "-i", "-B", "-iB", "-Bi")
# Intrare: %rdi = sir cu flag-uri (incepe cu '-')
# Modifica: flag_case_insensitive, flag_skip_blanks
process_flags:
    pushq   %rbp
    mov     %rsp, %rbp
   
    inc     %rdi                 # sarim peste '-'
   
examine_flag_character:
    movb    (%rdi), %al          # caracterul curent
    cmp     $0, %al              # terminat sirul?
    je      flags_processed      
   
    # Verificam pentru 'i'
    cmp     $105, %al            # e 'i'?
    je      activate_case_flag   # activam ignore case
   
    # Verificam pentru 'B'
    cmp     $66, %al             # e 'B'?
    je      activate_blank_flag  # activam ignore blank
   
    # Flag necunoscut - ignoram
    inc     %rdi                 # urmatorul caracter
    jmp     examine_flag_character
   
activate_case_flag:
    movb    $1, flag_case_insensitive # setam flag-ul -i
    inc     %rdi                 # urmatorul caracter
    jmp     examine_flag_character
   
activate_blank_flag:
    movb    $1, flag_skip_blanks # setam flag-ul -B
    inc     %rdi                 # urmatorul caracter
    jmp     examine_flag_character
   
flags_processed:
    popq    %rbp
    ret

# Functie pentru citirea urmatoarei linii din fisierul 2
# Iesire: %r13 = 1 daca am citit linie, 0 daca EOF; linia in line_buffer_b
read_next_from_file2:
    pushq   %rbp
    mov     %rsp, %rbp

attempt_read_file2:
    # Citim o linie din fisierul 2
    mov     $line_buffer_b, %rdi # buffer-ul
    mov     $1023, %esi          # dimensiunea
    mov     second_file_stream, %rdx # handle-ul fisierului
    call    fgets                # citim linia
   
    cmp     $0, %rax             # EOF?
    je      reached_eof_file2    # daca da, returnam 0
   
    # Curatam newline-ul
    mov     $line_buffer_b, %rdi 
    call    strip_newline        # eliminam newline
   
    # Daca -B e activ, verificam daca linia e goala
    cmpb    $1, flag_skip_blanks # flag-ul -B e setat?
    jne     valid_line_file2     # daca nu, pastram linia
   
    # Verificam daca linia e goala
    mov     $line_buffer_b, %rdi # verificam linia
    call    check_if_blank       # e goala?
    cmp     $1, %eax             # rezultat?
    je      attempt_read_file2   # daca e goala, citim urmatoarea
   
valid_line_file2:
    mov     $1, %r13             # succes - am citit o linie
    jmp     done_reading_file2

reached_eof_file2:
    mov     $0, %r13             # EOF - nu mai sunt linii
   
done_reading_file2:
    popq    %rbp
    ret

# Functie pentru citirea urmatoarei linii din fisierul 1
# Iesire: %r12 = 1 daca am citit linie, 0 daca EOF; linia in line_buffer_a
read_next_from_file1:
    pushq   %rbp
    mov     %rsp, %rbp

attempt_read_file1:
    # Citim o linie din fisierul 1
    mov     $line_buffer_a, %rdi # buffer-ul
    mov     $1023, %esi          # dimensiunea
    mov     first_file_stream, %rdx # handle-ul fisierului
    call    fgets                # citim linia
   
    cmp     $0, %rax             # EOF?
    je      reached_eof_file1    # daca da, returnam 0
   
    # Curatam newline-ul
    mov     $line_buffer_a, %rdi # sterge newline din buffer
    call    strip_newline        # eliminam trailing newline
   
    # Daca -B e activ, verificam daca linia e goala
    cmpb    $1, flag_skip_blanks # flag-ul -B e setat?
    jne     valid_line_file1     # daca nu, pastram linia
   
    # Verificam daca linia e goala
    mov     $line_buffer_a, %rdi # verificam linia
    call    check_if_blank       # e goala?
    cmp     $1, %eax             # rezultat?
    je      attempt_read_file1   # daca e goala, citim urmatoarea
   
valid_line_file1:
    mov     $1, %r12             # succes - am citit o linie
    jmp     done_reading_file1

reached_eof_file1:
    mov     $0, %r12             # EOF - nu mai sunt linii
   
done_reading_file1:
    popq    %rbp
    ret

open_both_files:
    # Deschidem primul fisier
    mov     first_file_name, %rdi # numele fisierului
    mov     $file_open_mode, %rsi # modul "r"
    call    fopen                # deschidem fisierul
    mov     %rax, first_file_stream # salvam handle-ul

    # Verificam daca s-a deschis cu succes
    cmp     $0, %rax             # NULL?
    je      exit_with_error      # eroare la deschidere

    # Deschidem al doilea fisier
    mov     second_file_name, %rdi # numele fisierului
    mov     $file_open_mode, %rsi # modul "r"
    call    fopen                # deschidem fisierul
    mov     %rax, second_file_stream # salvam handle-ul

    # Verificam daca s-a deschis cu succes
    cmp     $0, %rax             # NULL?
    je      close_first_only     # inchidem primul si iesim cu eroare

    # Bucla principala de comparare
main_comparison_loop:
    # Citim urmatoarea linie din primul fisier
    call    read_next_from_file1 # rezultat in %r12
   
    # Citim urmatoarea linie din al doilea fisier
    call    read_next_from_file2 # rezultat in %r13

    # Verificam daca ambele fisiere au ajuns la sfarsit
    cmp     $0, %r12             # primul fisier s-a terminat?
    je      verify_second_eof    # verificam si al doilea

    # Verificam daca doar al doilea fisier s-a terminat
    cmp     $0, %r13             # al doilea fisier s-a terminat?
    je      exit_successfully    # daca da, gata

    # Ambele fisiere au linii - comparam
    # Verificam flag-ul -i
    cmpb    $1, flag_case_insensitive # ignoram case?
    je      do_case_insensitive  # daca da, comparatie case-insensitive
   
    # Comparatie normala (case-sensitive)
    jmp     do_case_sensitive

do_case_insensitive:
    # Comparatie case-insensitive
    mov     $line_buffer_a, %rdi # prima linie
    mov     $line_buffer_b, %rsi # a doua linie
    call    strcasecmp           # comparam fara case
    cmp     $0, %eax             # sunt egale?
    je      lines_are_same       # daca da, continuam
    jmp     lines_differ         # daca nu, afisam diferenta

do_case_sensitive:
    # Comparatie case-sensitive
    mov     $line_buffer_a, %rdi # prima linie
    mov     $line_buffer_b, %rsi # a doua linie
    call    strcmp               # comparam
    cmp     $0, %eax             # sunt egale?
    je      lines_are_same       # daca da, continuam
    jmp     lines_differ         # daca nu, afisam diferenta

lines_are_same:
    # Liniile sunt identice
    incl    current_line_counter # incrementam contorul
    jmp     main_comparison_loop # continuam cu urmatoarea linie

verify_second_eof:
    # Primul fisier s-a terminat, verificam al doilea
    cmp     $0, %r13             # si al doilea s-a terminat?
    je      exit_successfully    # daca da, totul e ok
    jmp     exit_successfully    # oricum iesim cu succes

lines_differ:
    # Afisam diferenta in format diff
    # Afisam "NcN"
    mov     $fmt_change_line, %rdi # formatul
    mov     current_line_counter, %esi # numarul liniei
    mov     current_line_counter, %edx # acelasi numar
    xor     %eax, %eax           # fara argumente float
    call    printf               # afisam

    # Afisam "< linie din fisierul 1"
    mov     $fmt_first_line, %rdi # formatul cu "<"
    mov     $line_buffer_a, %rsi # linia din primul fisier
    xor     %eax, %eax           # fara argumente float
    call    printf               # afisam

    # Afisam separatorul "---"
    mov     $fmt_divider, %rdi   # separatorul
    xor     %eax, %eax           # fara argumente float
    call    printf               # afisam

    # Afisam "> linie din fisierul 2"
    mov     $fmt_second_line, %rdi # formatul cu ">"
    mov     $line_buffer_b, %rsi # linia din al doilea fisier
    xor     %eax, %eax           # fara argumente float
    call    printf               # afisam

    # Continuam cu urmatoarea linie
    incl    current_line_counter # incrementam contorul
    jmp     main_comparison_loop # continuam comparatia

# Iesire cu succes - inchidem fisierele si returnam 0
exit_successfully:
    # inchidem ambele fisiere
    mov     first_file_stream, %rdi # primul handle
    call    fclose               # inchidem
    mov     second_file_stream, %rdi # al doilea handle
    call    fclose               # inchidem
    mov     $0, %eax             # cod de succes
    jmp     cleanup_and_return

# Iesire cu eroare - inchidem primul fisier si returnam 1
close_first_only:
    mov     first_file_stream, %rdi # primul handle
    call    fclose               # inchidem

exit_with_error:
    mov     $1, %eax             # cod de eroare

cleanup_and_return:
    popq    %r15                 # restauram registrele
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbp                 # restauram base pointer
    ret                          # ne intoarcem
