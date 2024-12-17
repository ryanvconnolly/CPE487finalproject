# CPE 487 Final Project: Subway Surfers
<img title="subway surfers" alt="Alt text" src="subway surfers.jpg" width="500" height="600">

## Expected Behavior
<img title="subway surfers" alt="Alt text" src="subway surfers gif.GIF">

* Our goal in making this project is to mimic the Subway Surfers video game and have the basic mechanics:
  - Runner starts at the bottom of the screen in the center
  - Runner runs continuously, avoiding trains
  - 3 trains running at different speeds, with a staggered or random release to ensure there is always a way for the runner to survive
  - Trains loop continuously from the top
  - Runner can only move horizontally to dodge the trains
  - Runner “dies” as soon as it collides with one of the trains.
  - Stopwatch timer points system to see how long the player stays alive. 

## Necessary Hardware
1. Nexys A7-100T FPGA Board
2. Computer with Vivado installed
3. Micro-USB Cable
4. VGA Cable
5. Monitor/TV with VGA input or VGA adapter

## Vivado Instructions
1. On your Nexys A7 board, connect the VGA port to your monitor, the USB port to your computer, and ensure that the power switch is set to "on". Adapters may be needed depending on your specific hardware.
2. Download all projects from the GitHub repository.
3. Create a new project in Vivado, making sure to import the proper source files and constraint files.
4. Run Synthesis, Implementation, write bit stream, and then program the board. 
ENJOY THE GAME!!!!


## Game Play Instructions

1. When the bitstream is initially uploaded to the FPGA board, the player will be able see their runner and blue train 3.
2. Press BTNC to start the game.
3. The trains will begin to move down the screen. The player will have to dodge the trains by using the BTNL and BTNR to move the runner left and right, respectively.
4. If the runner collides with any of the trains, the runner "dies." To restart a new game, simply press BTNC.
5. Player can view their game duration by looking at the 7-segment decoder on the Nexys A7 Board.

6. If you get confused, watch this video: [Video Demo](https://youtube.com/shorts/e7A8Uj5hRyc?si=8Utbdiid0STbItb7)
7. Have fun!


## Module Overview
#### 1. The [vga_top.vhd](https://github.com/ryanvconnolly/CPE487finalproject/blob/main/vga_top.vhd "vga_top.vhd") module acts as the top-level module that connects all other sub-modules and controls overall functionality.
- Instantiates the vga_sync, runner, leddec, and clk_wiz_0 modules.
- Handles button inputs (`left`, `right`, `reset`) for controlling the runner movement.
- Passes VGA signals (pixel position, RGB data) to the vga_sync module.
- Outputs the `seconds_bcd` counter from the runner module to the leddec module for display.

    ##### Connections:
    - `Clock`: Uses the clk_wiz_0 module to generate the correct VGA clock.
    - `Runner`: Controls movement and game logic (runner position and collisions).
    - `Display`: Uses leddec for time multiplexing the 7-segment display.

#### 2. The [vga_sync.vhd](https://github.com/ryanvconnolly/CPE487finalproject/blob/main/vga_sync.vhd "vga_sync.vhd") module generates the VGA timing signals and pixel location data.
- Drives horizontal (`h_cnt`) and vertical (`v_cnt`) counters to determine pixel positions.
- Generates the vsync and hsync signals for the VGA monitor.
- Provides the pixel_row and pixel_col coordinates for the current pixel being displayed.
- Gating RGB video signals using the video_on signal to blank the screen during sync periods.
  
    ##### Inputs:
    - Pixel clock (`pixel_clk`) from clk_wiz_0.
    - Red, green, and blue data.

    ##### Outputs:
    - Horizontal and vertical sync signals (`hsync`, `vsync`).
    - Current pixel coordinates (`pixel_row`, `pixel_col`).

#### 3. The [runner.vhd](https://github.com/ryanvconnolly/CPE487finalproject/blob/main/runner.vhd "runner.vhd") module controls the movement, position, and collision detection for the "runner" and trains.
- Updates the position of the runner based on input signals (left, right, reset).
- Moves the trains (`train1`, `train2`, `train3`) vertically down the screen and resets their positions.
- Implements collision detection between the runner and trains.
- Controls the stopwatch logic to count seconds while the game is active.
  
    ##### Main Signals:
    - `runner_x` / `runner_y`: Position of the runner.
    - `train1_x` / `train1_y`, etc.: Positions of the trains.
    - `seconds`: Tracks the elapsed time (converted to BCD for display).

    ##### Outputs:
    - RGB data (`red`, `green`, `blue`) for VGA display.
    - Seconds counter in BCD format (`seconds_bcd`).

#### 4. The [leddec.vhd](https://github.com/ryanvconnolly/CPE487finalproject/blob/main/leddec.vhd "leddec") module drives the 7-segment displays using time multiplexing to show the seconds counter.
- Uses the dig input as a multiplexing clock to control which 7-segment display is active.
- Decodes the seconds_bcd input to drive the cathode lines (CA to CG).
- Cycles through the four digits of the 7-segment display rapidly to give the appearance of continuous illumination.
  
    ##### Inputs:
    - `dig`: 2-bit input that selects the active digit.
    - `f_data`: 16-bit input data containing the BCD digits to display.

    ##### Outputs:
    - `anode`: Activates the appropriate display (AN0–AN3).
    - `seg`: Drives the cathode lines to display the correct digits.

#### 5. The [runner.xdc](https://github.com/ryanvconnolly/CPE487finalproject/blob/main/runner.xdc "runner.xdc") module specifies the physical constraints for the design, such as pin mappings for buttons, clocks, and outputs.
- Maps board buttons (`BTNL`, `BTNR`, `BTNC`, `BTND`, `BTNU`) to their respective ports in hardware.
- Configures the clock source for the clk_wiz_0 module (e.g., 100 MHz input clock).
- Maps VGA output signals (`hsync`, `vsync`, `red`, `green`, `blue`) to the appropriate physical pins on the FPGA.

#### 6. The [clk_wiz_0.vhd](https://github.com/ryanvconnolly/CPE487finalproject/blob/main/clk_wiz_0.vhd "clk_wiz_0.vhd") module generates the correct clock signals for the system (unmodified).
- Takes the FPGA’s input clock (e.g., 100 MHz) and generates a 25 MHz clock for the VGA sync module.
- Outputs additional clocks if needed for other components.
- Uses the Xilinx Clocking Wizard to customize the clock frequencies.

#### 7. The [clk_wiz_0_clk_wiz.vhd](https://github.com/ryanvconnolly/CPE487finalproject/blob/main/clk_wiz_0.vhd "clk_wiz_0_clk_wiz") module is supporting module for clk_wiz_0 that contains the actual clock generation logic.
- Configures clock dividers and multipliers to produce the desired clock frequencies.


## Modifications
We used a previous project (Crossy Road) as a starting point which used lab 3 as a basis, it shared the same logic throughout:
#### 1. vga_top.vhd
- Changed the frog component to runner in the instantiation.
- Removed vertical runner motion signals
- Updated components to support changes made in runner.vhd
- Connected seconds_bcd from runner to the leddec module for 7-segment display.

#### 2. vga_sync.vhd
- Adjusted horizontal and vertical timing to match 800x525 for a 600x480 resolution for TV compatibility with VGA display.

#### 3. runner.vhd
- Changed the entity name from frog to runner.
- Removed all point counter signals and added `game_active` signal.
- Updated all instances of:
  - `frog` → `runner`
  (e.g., `frog_x` → `runner_x`, `frog_dead` → `runner_dead`, `frog_on` → `runner_on`).
  - `car` → `train`
  (e.g., `car1_x` → `train1_x`, `car2_on` → `train2_on`).

- Set the starting position of the runner to the center-bottom of the screen:
     ```
     runner_x <= CONV_STD_LOGIC_VECTOR(320 - (size/2), 11);
     runner_y <= CONV_STD_LOGIC_VECTOR(440 - (size * 4), 11);
     ```
- Each train (`train1`, `train2`, `train3`) is initialized at specific positions on the screen:
  - **`train1`** starts at `(240, 0)` (near the left side).
  - **`train2`** starts at `(320, 0)` (centered horizontally).
  - **`train3`** starts at `(400, 100)` (near the right side, slightly lower).
  - Example:
    ```
    SIGNAL train1_x : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(240 - (train_size/2), 11);
    SIGNAL train1_y : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(0, 11);
    ```

  
- Allowed horizontal movement only:
     ```
     IF left = '1' THEN
         runner_x <= runner_x - runner_hop; -- Move left
     ELSIF right = '1' THEN
         runner_x <= runner_x + runner_hop; -- Move right
     ```
- Updated the collision detection to check for intersections between the runner and the trains:
   ```
   IF ((runner_x >= train1_x - train_size AND runner_x <= train1_x + train_size) 
    AND (runner_y >= train1_y - train_size AND runner_y <= train1_y + train_size)) OR 
       ((runner_x >= train2_x - train_size AND runner_x <= train2_x + train_size) 
    AND (runner_y >= train2_y - train_size AND runner_y <= train2_y + train_size)) OR
       ((runner_x >= train3_x - train_size AND runner_x <= train3_x + train_size) 
    AND (runner_y >= train3_y - train_size AND runner_y <= train3_y + train_size))
   THEN
       runner_dead <= '1';
       game_active <= '0';
   ```
- Reset trains to the top of the screen when they reach the bottom:
  ```
  IF train1_y + train_size >= 800 THEN
    train1_y <= CONV_STD_LOGIC_VECTOR(0, 11); -- Reset train1 to top
  ELSIF reset = '1' THEN
    train1_y <= CONV_STD_LOGIC_VECTOR(0, 11); -- Reset train1 on reset
  ELSE
    train1_y <= train1_y + train1_y_motion; -- Move train1 down
  END IF;
  ```

  ---

  ##### * Stopwatch Integration:
    - Added stopwatch process and seconds signal
    - Added a frame counter to track 60 frames (1 second)
      ```
      frame_counter := frame_counter + 1;
      IF frame_counter = 60 THEN
          frame_counter := 0; -- Reset frame counter
          seconds <= seconds + 1;
      ```
      
    - Reset frame_counter and seconds when the game resets
      ```
      IF reset = '1' THEN
        frame_counter := 0;
        seconds <= 0;
        seconds_bcd <= CONV_STD_LOGIC_VECTOR(0, 8);
      END IF;
      ```

      - Converted seconds to Binary-Coded Decimal (BCD) for display:
        ```
        seconds_bcd <= CONV_STD_LOGIC_VECTOR((seconds MOD 10) + (seconds / 10) * 16, 8);
        ```
--- 
#### 4. runner.xdc
- Modified the pins assigned to each anode to ensure the display would print the stop watch correctly.

#### 5. clk_wiz_0_clk_wiz.vhd
- Adjusted MMCM PRIMITIVE instatiations to be compatible with TV

## Summary
##### Yash
  - Train positioning / Logic 
  - Runner positioning 
##### Ryan 
  - Major Debugging
  - Runner logic
  - Score/Stopwatch logic and implementation

##### Timeline
- This project was completed in a weeks time (Dec 10 - Dec 16).

##### Difficulties
1. Initial runner placement:
   -  had trouble figuring out the initial location of the runner so it was visible to the player and we could constrain the runner to horizontal movement only.
   -  guess and checked until it was where we wanted it.
2. Adjusting resolution:
   - the original specs were not compatible with the TV used
   - had to change the values in vga_sync and clk_wiz_0_clk_wiz
3. Starting train motion:
   - trains starting moving automatically and kill the runner before the player was ready
   - updated train reset logic
4. Resetting trains:
   - trains would bounce off the bottom and come back up -- we needed them to only come from the top and go down
   - constrained their motion (seen in mtrain1 process)
5. Collision detection:
   - was not as accurate as we wanted -- trains would only kill runner if it was hit head on
   - updated collision logic (see in mrunner process)
6.  Stopwatch backwards:
    - stopwatch printed digits backwards (can be seen at the end of the video demo)
    - reassigned the pins in runner.xdc 



   


