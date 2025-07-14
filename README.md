# Atari Breakout on FPGA

This project implements a fully playable version of the classic **Atari Breakout** game on the **Intel DE1-SoC FPGA** using **SystemVerilog**, real-time **VGA graphics**, and **hardware FSM design**.

Players control a paddle to bounce a ball that breaks a 7x4 brick array. The game tracks lives, displays win/lose graphics, and showcases modular hardware design across display, game physics, and collision handling subsystems.

## Key Features

- Real-Time Graphics: 640x480 VGA display with paddle, ball, bricks, and dynamic game-end screens.
- Collision Engine: Accurate paddle, brick, and wall collision using VGA scan-aware logic.
- FSM-Driven Logic: Ball and display behavior modeled via finite state machines.
- Score & Lives: Lives displayed using HEX displays. Game ends after 3 missed balls or when all bricks are cleared.
- Memory-Mapped Graphics: "YOU WIN" and "GAME OVER" screens rendered from hand-crafted MIF-based ROMs.

## Controls

| Action        | Control Input  |
|---------------|----------------|
| Move Left     | N8 Left Button |
| Move Right    | N8 Right Button|
| Launch Ball   | N8 Up Button   |

## Architecture Overview

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

## Design Highlights

### Ball Physics with FSM

The ball operates in two states:
- `REST`: Ball moves with paddle, awaiting launch.
- `MOVING`: Ball moves autonomously with dx/dy vectors, bouncing off walls, paddle, and bricks.

Position is updated per VGA refresh using `x_reg`, `y_reg`, and future-state vectors `next_x`, `next_y`. Direction reverses on impact, simulating physics.

### Brick Array with Register Storage

Bricks are stored as an unpacked register array. Unlike RAM-based approaches, this allows combinational access and single-cycle deletion. Each brick stores presence state and color.

### VGA-Aware Collision Detection

Instead of bounding-box math, we exploit the VGA's active pixel scan to flag potential horizontal/vertical collisions. This simplifies logic and ensures real-time updates without ghost pixels.

### End-Game Graphics via ROM

"YOU WIN" and "GAME OVER" screens use hand-crafted bitmaps in `.mif` files, displayed using scaled pixel ROMs and a dedicated FSM for timed rendering. Scaling logic expands 32x16 bitmaps to readable 256x128 overlays.

## Testing and Debugging

Modules were testbenched in simulation and validated on LabsLand FPGA access. The ball and paddle systems were verified in isolation before full integration.

We avoided many timing pitfalls by:
- Prioritizing combinational logic for brick memory
- Using FSMs with predictable transitions
- Minimizing overlap computation

## Screenshots

### Game Start
![Game Start](assets/game_start.png)  
*Figure 1: Initial screen with paddle and ball ready. The player presses UP to launch the ball.*

### Game Play
![Game Play](assets/game_play.png)  
*Figure 2: Ball in motion, bouncing off walls and paddle. Bricks change state as they're hit.*

### Game Over
![Game Over](assets/game_over.png)  
*Figure 3: "GAME OVER" screen displayed after 3 missed balls. Rendered from ROM bitmap.*

### You Win
![You Win](assets/you_win.png)  
*Figure 4: "YOU WIN" screen displayed after all bricks are destroyed.*


## File Structure

```
├── paddle.sv
├── ball.sv
├── brick_array.sv
├── victory_display.sv
├── game_over_display.sv
├── vga_controller.sv
├── top_level.sv
└── assets/
    └── *.mif (bitmap graphics)
```

## Tools Used

- SystemVerilog for all hardware logic
- Quartus Prime for synthesis and MIF generation
- LabsLand for FPGA deployment and testing
- Intel DE1-SoC development board

## Author

Built by [Hemil Patel](https://github.com/hemzp)
