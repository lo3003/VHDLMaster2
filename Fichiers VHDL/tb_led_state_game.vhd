library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================================
-- ENTITY: led_game_state_tb
-- DESCRIPTION:
--   Testbench for the led_game_state module. It verifies the reset,
--   the defeat animation (blinking), and the victory animation (scrolling).
-- =============================================================================
entity tb_led_game_state is
end entity tb_led_game_state;

architecture Behavioral of tb_led_game_state is

    -- === Component Under Test (DUT) ===
    component led_game_state
        Port (
            clk              : in  std_logic;
            reset            : in  std_logic;
            led_game_command : in  std_logic;
            game_over        : in  std_logic;
            led_o            : out std_logic_vector(9 downto 0);
            led_game_valid   : out std_logic
        );
    end component;

    -- === Testbench Signals ===
    signal clk_tb              : std_logic := '0';
    signal reset_tb            : std_logic := '0';
    signal led_game_command_tb : std_logic := '0';
    signal game_over_tb        : std_logic := '0';
    signal led_o_tb            : std_logic_vector(9 downto 0);
    signal led_game_valid_tb   : std_logic;

    -- Clock period for a 50 MHz clock
    constant CLK_PERIOD : time := 20 ns;

begin
    -- === DUT Instantiation ===
    uut: led_game_state
        port map (
            clk              => clk_tb,
            reset            => reset_tb,
            led_game_command => led_game_command_tb,
            game_over        => game_over_tb,
            led_o            => led_o_tb,
            led_game_valid   => led_game_valid_tb
        );

    -- === Clock Generation Process ===
    clk_process: process
    begin
        clk_tb <= not clk_tb;
        wait for CLK_PERIOD / 2;
    end process;

    -- =========================================================================
    -- SCENARIO DE TEST
    -- =========================================================================
    stim_proc: process
    begin
        report "--- Debut du testbench pour led_game_state ---";
        
        -- 1. Apply reset to ensure a clean start
        reset_tb <= '1';
        wait for 100 ns;
        reset_tb <= '0';
        wait for 20 ns;
        report "Test 1: Reset termine. Le module est en attente (IDLE).";

        -- 2. Trigger the DEFEAT animation (blinking 3 times)
        report "Test 2: Declenchement de l'animation de defaite (game_over='0').";
        game_over_tb        <= '0';
        led_game_command_tb <= '1'; -- Send a one-cycle pulse to start the animation
        wait for CLK_PERIOD;
        led_game_command_tb <= '0';
        
        -- Wait for the animation to complete.
        -- This will take approximately 1.5 seconds in simulation (3 * 2 * 250ms).
        report "--> Observation de l'animation de clignotement (3 fois)...";
        wait until led_game_valid_tb = '1';
        report "Test 2: Animation de defaite terminee.";
        wait for 1 us; -- Small pause between tests

        -- 3. Trigger the VICTORY animation (scrolling twice)
        report "Test 3: Declenchement de l'animation de victoire (game_over='1').";
        game_over_tb        <= '1';
        led_game_command_tb <= '1'; -- Send a pulse to start
        wait for CLK_PERIOD;
        led_game_command_tb <= '0';
        
        -- Wait for the animation to complete.
        -- This will take approximately 1 second in simulation (2 * 10 * 50ms).
        report "--> Observation de l'animation du chenillard (2 fois)...";
        wait until led_game_valid_tb = '1';
        report "Test 3: Animation de victoire terminee.";
        
        report "--- FIN DES TESTS ---";
        wait;
    end process stim_proc;

end architecture Behavioral;
