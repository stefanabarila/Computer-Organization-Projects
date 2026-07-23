# File Comparison Utility (diff)

An x86-64 Assembly implementation of the classic Unix `diff` utility. This program compares two files line by line and outputs all detected differences to the standard output. 

**Academic Context:** Engineered collaboratively in a team of 2 for the Computer Organization course at Delft University of Technology.

## ⚙️ System Architecture & Execution Flow

This utility is designed around a robust command-line argument parser and relies on the C standard library (`libc`) for buffered file I/O.

* **Argument Parsing & State Management:** Manually iterates through `argc` and `argv` registers to isolate file names and dynamically toggle functional flags.
* **Calling Conventions:** Strictly adheres to the System V AMD64 ABI. Core subroutines maintain custom stack frames (`pushq %rbp; movq %rsp, %rbp`) and safely preserve callee-saved registers (`%r12`-`%r15`).
* **Stream Processing:** Utilizes `fopen` and `fgets` to read files sequentially into 1024-byte `.space` buffers, ensuring memory-safe line-by-line evaluation without loading entire files into RAM simultaneously.

## 🧠 Core Features & Algorithmic Logic

The program implements a custom `diff` subroutine that acts as the primary evaluation engine. It features two distinct operational flags:

1. **`-i` (Case-Insensitive):** When toggled, the program redirects the evaluation flow from standard `strcmp` to `strcasecmp`, masking character case differences during comparison.
2. **`-B` (Ignore Blank Lines):** When toggled, the program executes a custom `check_if_blank` subroutine. This parser iterates through the buffer byte-by-byte to detect and skip lines containing only whitespace (Spaces, Tabs, Carriage Returns, and Newlines) before the comparison occurs.

## 🚀 Compilation & Execution

This utility is designed for Linux environments and compiled via the GNU C Compiler (GCC), linking against the standard C library.

```bash
# Compile the assembly source code
gcc -no-pie diff.s -o my_diff

# Execute the binary with flags
./my_diff -i -B file1.txt file2.txt
```
## ✅ Expected Output Format

When a discrepancy is found, the program accurately recreates the standard diff output formatting to highlight the changed lines:
```bash
Hi, this is a testfile.
Testfile 1 to be precise.
```

```bash
Hi, this is a testfile.
Testfile 2 to be precise.
```

```bash
2c2
< Testfile 1 to be precise.
---
> Testfile 2 to be precise.
```
