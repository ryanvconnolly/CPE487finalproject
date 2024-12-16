LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY runner IS
    PORT (
        v_sync    : IN STD_LOGIC;
        pixel_row : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        pixel_col : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        red       : OUT STD_LOGIC;
        green     : OUT STD_LOGIC;
        blue      : OUT STD_LOGIC;
        up        : IN STD_LOGIC;
        down      : IN STD_LOGIC;
        left      : IN STD_LOGIC;
        right     : IN STD_LOGIC;
        reset     : IN STD_LOGIC;
        seconds_bcd : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)  -- Seconds in BCD
    );
END runner;

ARCHITECTURE Behavioral OF runner IS
    -- signals and variables for SURFER
    CONSTANT size  : INTEGER := 8;
    SIGNAL runner_on : STD_LOGIC; -- indicates whether runner is over current pixel position
    SIGNAL runner_dead : STD_LOGIC := '0';
    SIGNAL game_active : STD_LOGIC := '0'; -- Indicates if the game is active
    SIGNAL runner_dead_on : STD_LOGIC;
    SIGNAL runner_deadx  : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(320 - (size/2), 11);
    SIGNAL runner_deady  : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(440 - (size * 4), 11);
    -- current runner position - initialized to center of screen
    SIGNAL runner_x  : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(320 - (size/2), 11);
    SIGNAL runner_y  : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(440 - (size * 4), 11);
    SIGNAL runner_hop : STD_LOGIC_VECTOR(10 DOWNTO 0) := "00000000100";
    SIGNAL direction  : INTEGER := 8;

    SIGNAL  train_size : INTEGER := 30;
    SIGNAL train1_on : STD_LOGIC; -- indicates whether train1 is over current pixel position

    -- current train 1 position 
    SIGNAL train1_x  : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(240 - (train_size/2), 11);
    SIGNAL train1_y  : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(0, 11);
    -- current train motion - initialized to +3 pixels/frame
    SIGNAL train1_y_motion : STD_LOGIC_VECTOR(10 DOWNTO 0) := "00000001000";

    -- train 2 -
    SIGNAL train2_on : STD_LOGIC; -- indicates whether train1 is over current pixel position
    -- current train position 
    SIGNAL train2_x  : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(320 - (train_size/2), 11);
    SIGNAL train2_y  : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(0, 11);
    -- current train motion - initialized to +4 pixels/frame
    SIGNAL train2_y_motion : STD_LOGIC_VECTOR(10 DOWNTO 0) := "00000000100";

    -- train 3 -
    SIGNAL train3_on : STD_LOGIC; -- indicates whether train1 is over current pixel position
    -- current train position 
    SIGNAL train3_x  : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(400 - (train_size/2), 11);
    SIGNAL train3_y  : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(100, 11);
    -- current train motion - initialized to +5 pixels/frame
    SIGNAL train3_y_motion : STD_LOGIC_VECTOR(10 DOWNTO 0) := "00000000110";   
    
    SIGNAL seconds : INTEGER RANGE 0 TO 59 := 0; -- Seconds counter
    SIGNAL stopwatch_active : STD_LOGIC := '0'; -- Controls the stopwatch

BEGIN
    -- THIS IS WHERE THE COLORS WERE DONE FOR DRAWING 
    -- Default background is white
    red <= train1_on OR runner_on;  -- Red for Train 1 and Runner (as black is all colors combined)
    green <= train2_on OR runner_on; -- Green for Train 2 and Runner
    blue <= train3_on OR runner_on;  -- Blue for Train 3 and Runner
    
    stopwatch : PROCESS (v_sync)
        VARIABLE frame_counter : INTEGER := 0; -- Counts frames for 1-second intervals
    BEGIN
        IF rising_edge(v_sync) THEN
        -- Handle reset
        IF reset = '1' THEN
            frame_counter := 0; -- Reset frame counter
            seconds <= 0;       -- Reset seconds counter
            seconds_bcd <= CONV_STD_LOGIC_VECTOR(0, 8); -- Reset BCD output
        -- Only update stopwatch if active
        ELSIF stopwatch_active = '1' THEN
            -- Increment frame counter (assume 60Hz frame rate)
            frame_counter := frame_counter + 1;

            -- Every 60 frames (1 second at 60Hz), increment the seconds
            IF frame_counter = 60 THEN
                frame_counter := 0; -- Reset frame counter
                seconds <= seconds + 1;

                -- Reset seconds if it exceeds 99 (for two-digit display)
                IF seconds = 100 THEN
                    seconds <= 0;
                END IF;

                -- Update BCD output
                seconds_bcd <= CONV_STD_LOGIC_VECTOR((seconds MOD 10) + (seconds / 10) * 16, 8);
                END IF;
            END IF;
    END IF;
    END PROCESS;

    fdraw : PROCESS (runner_x, runner_y, pixel_row, pixel_col, runner_dead) IS
    BEGIN
        IF NOT (runner_dead = '1') THEN
            IF (pixel_col >= runner_x - size) AND
               (pixel_col <= runner_x + size) AND
               (pixel_row >= runner_y - size) AND
               (pixel_row <= runner_y + size) THEN
                runner_on <= '1';
            ELSE
                runner_on <= '0';
            END IF;
         ELSIF runner_dead = '1' THEN
            IF (pixel_col >= runner_deadx - size) AND
              (pixel_col <= runner_deadx + size) AND
               (pixel_row >= runner_deady - size) AND
               (pixel_row <= runner_deady + size) THEN
                runner_dead_on <= '1';
                runner_on <= '0';
        END IF;
         END IF;
        END PROCESS;

    -- process to move runner once every frame (i.e. once every vsync pulse)
    mrunner : PROCESS
    BEGIN
       WAIT UNTIL rising_edge(v_sync);
       IF reset = '1' THEN
        -- Reset the game
        runner_x <= CONV_STD_LOGIC_VECTOR(320 - (size/2), 11);
        runner_y <= CONV_STD_LOGIC_VECTOR(440 - (size * 4), 11);
        runner_dead <= '0';
        game_active <= '1';
        stopwatch_active <= '1'; -- Start stopwatch
        ELSE
        -- Handle other game states
        -- Only allow horizontal movement
        IF left = '1' THEN
            direction <= 3; -- Move left
        ELSIF right = '1' THEN
            direction <= 4; -- Move right
        ELSIF reset = '1' THEN
            direction <= 5; -- Reset the game
        ELSE
            direction <= 0; -- No movement
        END IF;

        IF direction = 3 THEN
            runner_x <= runner_x - runner_hop; -- Move left
        ELSIF direction = 4 THEN
            runner_x <= runner_x + runner_hop; -- Move right
        ELSIF direction = 5 THEN
        -- Reset the game
        runner_x <= CONV_STD_LOGIC_VECTOR(320 - (size/2), 11);
        runner_y <= CONV_STD_LOGIC_VECTOR(440 - (size * 4), 11);
        runner_dead <= '0';
        game_active <= '1';
        stopwatch_active <= '1'; -- Start stopwatch

    ELSIF runner_dead = '1' THEN
        game_active <= '0'; -- Stop the game
        stopwatch_active <= '0'; -- Stop stopwatch
    END IF;
    END IF;
          --- collision detection for train1, 2 and 3
        -- Check for collision between runner and any train
        IF ((runner_x >= train1_x - train_size AND runner_x <= train1_x + train_size) 
        AND (runner_y >= train1_y - train_size AND runner_y <= train1_y + train_size)) OR 
            ((runner_x >= train2_x - train_size AND runner_x <= train2_x + train_size) 
        AND (runner_y >= train2_y - train_size AND runner_y <= train2_y + train_size)) OR
            ((runner_x >= train3_x - train_size AND runner_x <= train3_x + train_size) 
        AND (runner_y >= train3_y - train_size AND runner_y <= train3_y + train_size))
        THEN
    -- Mark the runner as dead and save its position
    runner_dead <= '1';
    game_active <= '0'; -- Stop game when runner dies
    runner_deadx <= runner_x;
    runner_deady <= runner_y;
END IF;
       END PROCESS;

    --process to draw train1, train2, train3
    t1draw : PROCESS (train1_x, train1_y, pixel_row, pixel_col, train_size) IS
    BEGIN
        IF (pixel_col >= train1_x - train_size) AND
         (pixel_col <= train1_x + train_size) AND
             (pixel_row >= train1_y - train_size) AND
             (pixel_row <= train1_y + train_size) THEN
                train1_on <= '1';
        ELSE
            train1_on <= '0';
        END IF;
        END PROCESS;
        -- process to move train1 once every frame (i.e. once every vsync pulse)
        -- Process to move train1 once every frame (i.e. once every vsync pulse)
mtrain1 : PROCESS
BEGIN
    WAIT UNTIL rising_edge(v_sync);
    -- Check if train1 reaches the bottom of the screen
    IF game_active = '1' THEN
        IF train1_y + train_size >= 800 THEN
            train1_y <= CONV_STD_LOGIC_VECTOR(0, 11); -- Reset train1 to top
        ELSIF reset = '1' THEN
            train1_y <= CONV_STD_LOGIC_VECTOR(0, 11); -- Reset train1 to top
        ELSE
            train1_y <= train1_y + train1_y_motion; -- Move train1 down
        END IF;
    END IF;
END PROCESS;

t2draw : PROCESS (train2_x, train2_y, pixel_row, pixel_col, train_size) IS
BEGIN
    IF (pixel_col >= train2_x - train_size) AND
       (pixel_col <= train2_x + train_size) AND
       (pixel_row >= train2_y - train_size) AND
       (pixel_row <= train2_y + train_size) THEN
        train2_on <= '1';
    ELSE
        train2_on <= '0';
    END IF;
END PROCESS;

-- Process to move train2 once every frame (i.e. once every vsync pulse)
mtrain2 : PROCESS
BEGIN
    WAIT UNTIL rising_edge(v_sync);
    -- Check if train2 reaches the bottom of the screen
    IF game_active = '1' THEN
        IF train2_y + train_size >= 800 THEN
            train2_y <= CONV_STD_LOGIC_VECTOR(0, 11); -- Reset train2 to top
        ELSIF reset = '1' THEN
            train2_y <= CONV_STD_LOGIC_VECTOR(0, 11); -- Reset train2 to top
        ELSE
            train2_y <= train2_y + train2_y_motion; -- Move train2 down
        END IF;
    END IF;
END PROCESS;

t3draw : PROCESS (train3_x, train3_y, pixel_row, pixel_col, train_size) IS
BEGIN
    IF (pixel_col >= train3_x - train_size) AND
       (pixel_col <= train3_x + train_size) AND
       (pixel_row >= train3_y - train_size) AND
       (pixel_row <= train3_y + train_size) THEN
        train3_on <= '1';
    ELSE
        train3_on <= '0';
    END IF;
END PROCESS;

-- Process to move train3 once every frame (i.e. once every vsync pulse)
mtrain3 : PROCESS
BEGIN
    WAIT UNTIL rising_edge(v_sync);
    -- Check if train3 reaches the bottom of the screen
    IF game_active = '1' THEN
        IF train3_y + train_size >= 800 THEN
            train3_y <= CONV_STD_LOGIC_VECTOR(0, 11); -- Reset train3 to top
        ELSIF reset = '1' THEN
            train3_y <= CONV_STD_LOGIC_VECTOR(0, 11); -- Reset train3 to top
        ELSE
            train3_y <= train3_y + train3_y_motion; -- Move train3 down
        END IF;
    END IF;
END PROCESS;
END BEHAVIORAL;
