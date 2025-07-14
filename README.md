# Atari Breakout on FPGA

This project implements a fully playable version of the classic **Atari Breakout** game on the **Intel DE1-SoC FPGA** using **SystemVerilog**, real-time **VGA graphics**, and **hardware FSM design**.

Players control a paddle to bounce a ball that breaks a 7x4 brick array. The game tracks lives, displays win/lose graphics, and showcases modular hardware design across display, game physics, and collision handling subsystems.

---

## 🧠 Key Features

- **Real-Time Graphics**: 640x480 VGA display with paddle, ball, bricks, and dynamic game-end screens.
- **Collision Engine**: Accurate paddle, brick, and wall collision using VGA scan-aware logic.
- **FSM-Driven Logic**: Ball and display behavior modeled via finite state machines.
- **Score & Lives**: Lives displayed using HEX displays. Game ends after 3 missed balls or when all bricks are cleared.
- **Memory-Mapped Graphics**: "YOU WIN" and "GAME OVER" screens rendered from hand-crafted MIF-based ROMs.

---

## 🎮 Controls

| Action        | Control Input  |
|---------------|----------------|
| Move Left     | N8 Left Button |
| Move Right    | N8 Right Button|
| Launch Ball   | N8 Up Button   |

---

## 🧩 Architecture Overview

The system consists of the following top-level modules:

| Module                 | Description                                                 |
|------------------------|-------------------------------------------------------------|
| `paddle.sv`            | Handles paddle movement and boundary clamping               |
| `ball.sv`              | Ball FSM controlling motion, boundary physics, and collision|
| `brick_array.sv`       | 7x4 brick register array with row-based color encoding      |
| `game_over_display.sv` | FSM-based ROM display for game over graphic                 |
| `victory_display.sv`   | FSM-based ROM display for victory graphic                   |
| `vga_controller.sv`    | VGA signal generation and pixel tracking                    |
| `top_level.sv`         | Instantiates all modules and connects inputs/outputs        |

---

## 📐 Design Highlights

### Ball Physics with FSM

The ball operates in two states:
- `REST`: Ball moves with paddle, awaiting launch.
- `MOVING`: Ball moves autonomously with dx/dy vectors, bouncing off walls, paddle, and bricks.

Position is updated per VGA refresh using `x_reg`, `y_reg`, and future-state vectors `next_x`, `next_y`. Direction reverses on impact, simulating physics.

---

### Brick Array with Register Storage

Bricks are stored as an unpacked register array. Unlike RAM-based approaches, this allows combinational access and single-cycle deletion. Each brick stores presence state and color.

---

### VGA-Aware Collision Detection

Instead of bounding-box math, we exploit the VGA's active pixel scan to flag potential horizontal/vertical collisions. This simplifies logic and ensures real-time updates without ghost pixels.

---

### End-Game Graphics via ROM

"YOU WIN" and "GAME OVER" screens use hand-crafted bitmaps in `.mif` files, displayed using scaled pixel ROMs and a dedicated FSM for timed rendering. Scaling logic expands 32x16 bitmaps to readable 256x128 overlays.

---

## 🧪 Testing and Debugging

Modules were testbenched in simulation and validated on LabsLand FPGA access. The ball and paddle systems were verified in isolation before full integration.

We avoided many timing pitfalls by:
- Prioritizing combinational logic for brick memory
- Using FSMs with predictable transitions
- Minimizing overlap computation

---

## 📷 Screenshots

> _Consider uploading images like ball bouncing, paddle movement, and win/lose screens here_

---

## 📁 File Structure

