# BMP Steganography & Data Compression

A complete data processing and steganography suite written entirely in raw x86-64 Assembly. This application encodes, compresses, and obfuscates text payloads inside a dynamically generated 24-bit RGB bitmap image, and successfully reverses the pipeline to extract the hidden data.

**Academic Context:** Engineered collaboratively in a team of 2 for the Computer Organization course at Delft University of Technology. 

## ⚙️ System Architecture & Hardware Compliance

This project was built from scratch without the use of the standard C library or external abstractions. 
* **Direct Kernel Interaction:** Utilizes raw Linux system calls (`sys_open`, `sys_read`, `sys_write`, `sys_lseek`, `sys_close`) for all file I/O and memory operations.
* **Calling Conventions:** Strictly adheres to the System V AMD64 ABI calling convention. All subroutines manage custom stack frames (`pushq %rbp; movq %rsp, %rbp`) to ensure proper execution context and memory safety.
* **Binary File Manipulation:** Manually constructs the 14-byte BMP Magic Number signature and 40-byte DIB header byte-by-byte in memory prior to disk export.

## 🧠 Algorithmic Implementation

The codebase follows a rigorous, formally specified design pipeline to ensure algorithmic correctness:
1. **Data Compression:** Implements a custom Run-Length Encoding (RLE-8) algorithm to compress the combined string payload.
2. **Encryption:** Applies an XOR cipher, combining the compressed payload with a dynamically generated 32x32 pixel RGB canvas.
3. **Decryption & Verification:** Reads the `stego.bmp` file directly from the disk, reverses the XOR cipher, expands the RLE string, and extracts the original payload to standard output.

## 🏗️ Core Subroutine Architecture

* `merge_components`: Concatenates the 31-byte prefix, target payload, and 31-byte suffix into a contiguous memory buffer.
* `apply_rle_encoding`: Iterates through the payload to compress contiguous byte sequences into `[count][char]` byte pairs.
* `generate_pattern`: Renders a 32x32 RGB stripe pattern (White, Black, Red) directly into a `.bss` memory allocation.
* `encrypt`: Executes the XOR cipher between the RLE-compressed data buffer and the RGB pattern grid.
* `export_bitmap`: Formats the headers and flushes the encoded pixel array to disk as a valid `.bmp` file.
* `decrypt`: Reverses the encoding pipeline (File Load → XOR Decode → RLE Decompress → Payload Extraction).

## 🚀 Compilation & Execution

Designed for Linux environments (or WSL) and compiled via the GNU C Compiler (GCC).

```bash
# Compile the assembly source code (disabling Position Independent Executables for absolute addressing)
gcc -no-pie bitmap.s -o stego_suite

# Execute the binary pipeline
./stego_suite
