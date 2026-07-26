# Interactive Terminal Wordle

A fully playable, terminal-based clone of the popular game Wordle, implemented in x86-64 Assembly for Linux. 

**Academic Context:** Engineered collaboratively in a team of 2 for the Computer Organization course at Delft University of Technology.

## ⚙️ System Architecture & Features

This application runs a continuous interactive game loop, processing raw user input and dynamically rendering a color-coded terminal UI.

* **Direct I/O & Terminal Rendering:** Bypasses standard C wrappers for input/output, utilizing Linux system calls (`sys_read`, `sys_write`) to process keyboard input and render the UI grid via ANSI Escape Codes.
* **Algorithmic State Management:** Maintains multi-pass evaluation arrays to accurately calculate Green, Yellow, and Gray letter feedback without duplicating letter counts.
* **Dictionary Validation:** Implements memory-efficient string comparison loops to validate user input against a hardcoded data segment dictionary before accepting a guess.
* **Time-Restricted Execution:** Integrates `libc` time functions (`time@PLT`) to enforce a strict 120-second timeout condition on the game loop.

## 📜 Game Rules & Dictionary

**The Rules:**
1. You have exactly **6 attempts** to guess the secret 5-letter word.
2. You must guess the word within a strict **120-second time limit**.
3. Every guess you enter must be a valid 5-letter word from the game's internal dictionary.
4. After each guess, the terminal will color-code your letters to provide feedback:
   * 🟩 **Green:** The letter is in the word and in the exact correct position.
   * 🟨 **Yellow:** The letter is in the word but in the wrong position.
   * ⬜ **Gray:** The letter is not in the secret word at all.

**The Internal Dictionary:**
To accommodate the Assembly data segment constraints, the game randomly selects the secret word from (and validates guesses against) this curated 20-word dictionary:
> `apple`, `brave`, `chair`, `dance`, `earth`, `flame`, `grace`, `heart`, `image`, `joker`, `knife`, `light`, `music`, `night`, `ocean`, `peace`, `queen`, `robot`, `smile`, `train`

## 🚀 Compilation & Execution

This application is designed for Linux environments (or WSL) and compiled via the GNU C Compiler (GCC) to link the standard time libraries.

```bash
# Compile the assembly source code
gcc -no-pie wordle.s -o wordle

# Execute the binary
./wordle
```
## ✅ Expected Output
Here is an example of what the terminal UI looks like during a winning game session (the colours are actually in the background of the letters):
```bash
=== WORDLE GAME ===
Guess the 5-letter word in 6 tries!


_ _ _ _ _ 
_ _ _ _ _ 
_ _ _ _ _ 
_ _ _ _ _ 
_ _ _ _ _ 
_ _ _ _ _ 

Enter your guess (5 letters): image

=== WORDLE GAME ===
Guess the 5-letter word in 6 tries!

⬜⬜⬜⬜🟨 I M A G E
_ _ _ _ _ 
_ _ _ _ _ 
_ _ _ _ _ 
_ _ _ _ _ 
_ _ _ _ _ 

Enter your guess (5 letters): ocean

=== WORDLE GAME ===
Guess the 5-letter word in 6 tries!

⬜⬜⬜⬜🟨 I M A G E
⬜⬜🟩⬜🟩 O C E A N
_ _ _ _ _ 
_ _ _ _ _ 
_ _ _ _ _ 
_ _ _ _ _ 

Enter your guess (5 letters): queen

=== WORDLE GAME ===
Guess the 5-letter word in 6 tries!

⬜⬜⬜⬜🟨 I M A G E
⬜⬜🟩⬜🟩 O C E A N
🟩🟩🟩🟩🟩 Q U E E N
_ _ _ _ _ 
_ _ _ _ _ 
_ _ _ _ _ 


 Congratulations! You won!

=== SCOREBOARD ===
---------------
Tries used: 3
```
