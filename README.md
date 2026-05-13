# single-cycle-processor
EEE 333 Lab 5
A single-cycle processor built in SystemVerilog. Fetches an instruction, decodes it, runs it through the ALU, and writes the result back to the register file in four states (IF, FD, EX, RWB).

## What's in it
- Register File - 16 8-bit registers, two read ports, and one write port.
- ALU - 8-bit, has functions of add, subtract, AND, OR, XOR, shift, and pass-through.
- Mux16to1 - built hierarchically from four Mux4to1s, used for register select.
- Controller - 2-bit state machine cycling IF → FD → EX → RWB.
- DReg - parameterized D flip-flop register used throughout.

## Files
Lab5.sv — all modules + testbench
Lab5.csv — instruction memory contents

## How to simulate
Open in ModelSim, compile Lab5.sv, then run Lab5_TB. Testbench loads instructions from Lab5.csv and prints PC, OPCODE, ALU output, and the working register each cycle to the waveform shown below. Do not change and leave Lab5.csv as is.

## Waveform
<img width="935" height="561" alt="image" src="https://github.com/user-attachments/assets/4d4e9e07-8541-4796-8fd9-af488c60eed9" />
