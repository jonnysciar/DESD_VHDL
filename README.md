# Digital Electronic System Design — Lab Project

*Course: Digital Electronics Systems Design* \
*Group members: [jonnysciar](https://github.com/jonnysciar), [gmnapo](https://github.com/gmnapo), [damianopasquini02](https://github.com/damianopasquini02),* \
*Academic year: 2025–2026*

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [System Architecture](#system-architecture)
3. [Building the Vivado Project](#building-the-vivado-project)
4. [Module Reference](#module-reference)
   - [Path 1 — UART-Controlled Audio Acquisition](#path-1--uart-controlled-audio-acquisition)
   - [Path 2 — Real-Time Audio Processing](#path-2--real-time-audio-processing)
   - [Shared Infrastructure](#shared-infrastructure)
5. [Reports](#reports)
6. [Known Bugs](#known-bugs)
7. [Grading Breakdown](#grading-breakdown)
8. [Acknowledgements](#acknowledgements)

## Project Overview

This project implements a dual-path real-time audio processing system on an FPGA, using the Digilent **Pmod I2S2** as audio source/sink and the Digilent **Pmod JSTK2** as a joystick controller. The two processing paths run concurrently on the same audio stream and share a common AXI4-Stream (AXIS) infrastructure:

- **Path 1** receives timed recording commands from a PC over UART, compresses the audio into a custom 16-bit floating-point format, and streams it back to the PC.
- **Path 2** applies real-time effects (reverb, moving-average low-pass filter, channel mixing, volume, and balance) controlled interactively by the joystick and on-board switches, and drives a VU-meter on the board's LEDs.

Both paths share the same I2S audio input. Path 1 drives the 7-segment display (countdown timer) and the UART link; Path 2 drives the I2S output, the LED level meter, and the JSTK2 RGB LED.

## System Architecture

![System Architecture](./docs/top.svg)

**Interfaces used:**

| Peripheral | Protocol | Role |
|---|---|---|
| Pmod I2S2 | I²S / AXIS | Audio input and output |
| Pmod JSTK2 | SPI / AXIS | Joystick + RGB LED control |
| PC ↔ FPGA | UART 2 Mbaud | Commands in, compressed audio out |
| 7-Segment Display | GPIO (multiplexed) | Countdown timer |
| 16 on-board LEDs | GPIO | VU-meter |

## Building the Vivado Project

### Prerequisites

- Vivado 2020.2
- Digilent board files installed (for Basys 3 support)
- A Basys3 board connected via USB-JTAG

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/<your-org>/<your-repo>.git
   cd <your-repo>
   ```
2. **Source Vivado**
   ```
   source \path\to\Vivado\settings64.sh
   ```

3. **Makefile targets**

   ```bash
   make                # synthesise, implement, and generate the bitstream (default)
   make program        # program the bitstream on the connected Basys 3 over JTAG
   make record t=10    # run the Python recording script for 10 seconds
   make clean          # remove all build artefacts
   ```

## Module Reference

### Path 1 — UART-Controlled Audio Acquisition

Path 1 lets a PC start and stop timed audio recordings. Commands arrive over UART; compressed audio is streamed back over UART.

![Path 1](./docs/path1.svg)

#### DEPACKETIZER
 
> Parses 4-byte UART packets (`HEADER=0x69 | MIN | SEC | FOOTER=0x42`) and drives the acquisition FSM, asserting `send_audio` and loading the countdown on valid commands, while silently discarding malformed or out-of-range packets.
 
---
 
#### FLOAT COMPRESSOR
 
> Compresses signed 24-bit PCM samples into a custom `[S | EXP(4) | MANTISSA(11)]` 16-bit floating-point format to reduce UART bandwidth, with configurable field widths via generics.
 
---
 
#### SEND CONTROLLER
 
> Routes the compressed AXIS stream to the UART TX when `send_audio = 1`, and silently discards all transactions otherwise, respecting `TLAST`-delimited packet boundaries.
 
---
 
#### 7SEGMENT CTRL
 
> Multiplexes the four `MM:SS` countdown digits onto the Basys 3 7-segment display by round-robin cycling through the active-low anode select (`AN[3:0]`) and segment cathode (`SEG[6:0]`) outputs fast enough for persistence of vision.
 
---


### Path 2 — Real-Time Audio Processing

Path 2 is the live effects chain. Audio flows left to right through the modules below:

![Path 2](./docs/path2.svg)

ontrols:
 
| Control | Source |
|---|---|
| Enable moving average | SW0 |
| Enable reverb | SW1 |
| REVERB alpha / REVERB delay | JSTK X/Y when TRIG=1 |
| BALANCE / VOLUME | JSTK X/Y when TRIG=0 |
| Cycle OUTPUT SELECTOR mode | Rising edge of JSTK BTN |
 
---

#### DIGILENT JSTK2

Interfaces with the Pmod JSTK2 over SPI via an AXI4-Stream SPI master.

#### EFFECT SELECTOR

Demultiplexes the joystick axes based on the trigger button state.

#### REVERB

Implements feedback delay (echo) independently on left and right channels.

---

#### MOVING AVERAGE

Low-pass filter of fixed order 32. When `enable_filter = 0`, samples pass through unmodified.

---

#### OUTPUT SELECTOR

Cycles through 8 channel-mixing modes on each rising edge of `btn_jstk`. The active mode is reflected on the JSTK2 RGB LED.

---

#### VOLUME 

Applies an exponential gain to the audio, so perceived loudness scales linearly with the joystick position. The amplification factor doubles every `2^N` joystick units (generic `N`, default 6), centred at the joystick midpoint. Output saturates (clips) instead of wrapping.

### Shared Infrastructure

#### AXI4-STREAM
> All modules communicate over the standard AXI4-Stream protocol (`TDATA`, `TVALID`, `TREADY`, `TLAST`). An FSM-based handshake pattern is used throughout to ensure compliance without requiring one transaction per clock cycle.

## Reports

Power and timing reports

## Known Bugs

List any incomplete features, timing closure issues, or edge-case glitches here. (e.g., "Occasional UART packet drops at baud rates higher than 2M," or "Minor popping noise during aggressive volume saturation").

## Acknowledgments

We would like to thank the professors and teaching assistants of the **Digital Electronic System Design** course at Politecnico di Milano for designing this project track and for their guidance throughout the semester.

---
 


