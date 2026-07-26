# Computer-Organization-Projects

A collection of system tools and applications written entirely in x86-64 Assembly for Linux. These projects were developed in a team of 2 as part of the Computer Science and Engineering BSc curriculum at Delft University of Technology (Bonus Assignments for the Computer Organization course).

This repository demonstrates a deep understanding of computer architecture, memory management, and direct kernel interaction without reliance on high-level abstractions.

## 🛠️ Core Technical Competencies Demonstrated

*   **Instruction Set Architecture:** Proficient in x86-64 Assembly (AT&T Syntax).
*   **System Architecture:** Direct execution of Linux kernel system calls (`sys_read`, `sys_write`, `sys_open`).
*   **Hardware Compliance:** Strict adherence to System V AMD64 ABI calling conventions.
*   **Memory Management:** Manual stack frame construction, heap allocation bypassing, and exact byte-level buffer processing.
*   **Algorithm Translation:** Implementing complex algorithms (RLE Compression, XOR Ciphers, String Parsing) directly at the hardware level.

## 📂 Project Directory

### 1. [Custom `printf` Implementation](./custom-printf)
A custom, streamlined implementation of the C standard library's `printf` function. 
*   **Highlight:** Parses variadic arguments across hardware registers and stack memory to format integers and strings on the fly, outputting directly via `sys_write`.

### 2. [BMP Steganography & Data Compression](./bmp-steganography)
A data processing suite that encodes, compresses, and obfuscates text payloads inside a dynamically generated 24-bit RGB bitmap image.
*   **Highlight:** Implements a custom Run-Length Encoding (RLE-8) algorithm and XOR cipher, while manually constructing valid BMP file headers byte-by-byte in memory.

### 3. [File Comparison Utility (diff)](./file-diff-utility)
An Assembly implementation of the classic Unix `diff` utility that compares two files line by line.
*   **Highlight:** Features a robust command-line argument parser for dynamic functional flags (`-i` for case-insensitive, `-B` to ignore blank lines) and memory-safe buffer management.

### 4. [Interactive Terminal Wordle](./wordle-game)
A fully playable, terminal-based clone of Wordle featuring dictionary validation, color-coded ANSI rendering, and strict execution timeouts.
*   **Highlight:** Manages complex internal game states and multi-pass array evaluations dynamically within a continuous, time-restricted execution loop.

---

### 👤 Author
**Stefana Barila**  
*BSc Computer Science & Engineering @ Delft University of Technology*

**Collaborator:** Daria Alexandru
