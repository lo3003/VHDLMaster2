library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hex_driver_tb is
end entity hex_driver_tb;

architecture Behavioral of hex_driver_tb is
    -- === Component Under Test (DUT) ===
    component hex_driver
        generic (
            SIMULATION_MODE : boolean := false
        );
        Port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            hex_command : in  std_logic_vector(1 downto 0);
            level       : in  unsigned(1 downto 0);
            mode        : in  std_logic;
            score       : in  unsigned(6 downto 0);
            best_score  : in  unsigned(6 downto 0);
            HEX_CATHODES: out std_logic_vector(6 downto 0);
            HEX_ANODES  : out std_logic_vector(5 downto 0);
            DBG_LATCHED_SCORE      : out unsigned(6 downto 0);
            DBG_LATCHED_BEST_SCORE : out unsigned(6 downto 0);
            DBG_LATCHED_LEVEL      : out unsigned(1 downto 0);
            DBG_LATCHED_MODE       : out std_logic
        );
    end component;

    -- === Testbench Signals ===
    signal clk_tb         : std_logic := '0';
    signal reset_tb       : std_logic := '0';
    signal hex_command_tb : std_logic_vector(1 downto 0) := "00";
    signal level_tb       : unsigned(1 downto 0)         := "00";
    signal mode_tb        : std_logic                    := '0';
    signal score_tb       : unsigned(6 downto 0)         := (others => '0');
    signal best_score_tb  : unsigned(6 downto 0)         := (others => '0');
    signal HEX_CATHODES_tb: std_logic_vector(6 downto 0);
    signal HEX_ANODES_tb  : std_logic_vector(5 downto 0);
    signal dbg_score_tb      : unsigned(6 downto 0);
    signal dbg_best_score_tb : unsigned(6 downto 0);
    signal dbg_level_tb      : unsigned(1 downto 0);
    signal dbg_mode_tb       : std_logic;

    constant CLK_PERIOD : time := 20 ns;

begin
    -- === DUT Instantiation ===
    -- We enable SIMULATION_MODE to speed up the multiplexing refresh rate.
    uut: hex_driver
        generic map (
            SIMULATION_MODE => true
        )
        port map (
            clk           => clk_tb,
            reset         => reset_tb,
            hex_command   => hex_command_tb,
            level         => level_tb,
            mode          => mode_tb,
            score         => score_tb,
            best_score    => best_score_tb,
            HEX_CATHODES  => HEX_CATHODES_tb,
            HEX_ANODES    => HEX_ANODES_tb,
            DBG_LATCHED_SCORE      => dbg_score_tb,
            DBG_LATCHED_BEST_SCORE => dbg_best_score_tb,
            DBG_LATCHED_LEVEL      => dbg_level_tb,
            DBG_LATCHED_MODE       => dbg_mode_tb
        );

    -- === Clock Generation ===
    clk_process: process
    begin
        clk_tb <= not clk_tb;
        wait for CLK_PERIOD / 2;
    end process;

    -- =========================================================================
    -- SCENARIO DE TEST AVEC LONGUES PAUSES POUR OBSERVATION
    -- =========================================================================
    stim_proc: process
    begin
        report "--- Debut du testbench avec longues pauses pour observation ---";
        
        -- === Test 1: Reset Initial ===
        report "Test 1: Verification du reset. L'affichage doit montrer 00 A C 00.";
        reset_tb <= '1';
        wait for 100 ns; -- Short wait for reset
        reset_tb <= '0';
        
        assert dbg_score_tb = 0 report "ERREUR Test 1" severity error;
        report "Test 1: OK. Reset effectue. Observation de l'affichage a zero...";
        wait for 5 ms; -- << LONGUE PAUSE POUR OBSERVER L'AFFICHAGE "00 A C 00"

        -- === Test 2: Mise à jour du score à 42 ===
        report "Test 2: Mise a jour score a 42. Affichage attendu: 00 A C 42";
        score_tb <= to_unsigned(42, 7);
        hex_command_tb <= "00"; -- Send score update command
        wait for CLK_PERIOD;    -- Hold command for 1 cycle
        hex_command_tb <= "00"; -- Deactivate command
        
        wait for CLK_PERIOD; -- Allow one cycle for the latch to update
        assert dbg_score_tb = 42 report "ERREUR Test 2" severity error;
        report "Test 2: OK. Score mis a 42. Observation de l'affichage...";
        wait for 5 ms; -- << LONGUE PAUSE POUR OBSERVER L'AFFICHAGE "00 A C 42"

        -- === Test 3: Mise à jour du niveau à 'Difficile' ===
        report "Test 3: Mise a jour niveau a 'D'. Affichage attendu: 00 d C 42";
        level_tb <= "10";
        hex_command_tb <= "01"; -- Send level update command
        wait for CLK_PERIOD;
        hex_command_tb <= "00";
        
        wait for CLK_PERIOD;
        assert dbg_level_tb = "10" and dbg_score_tb = 42 report "ERREUR Test 3" severity error;
        report "Test 3: OK. Niveau mis a 'D'. Observation de l'affichage...";
        wait for 5 ms; -- << LONGUE PAUSE POUR OBSERVER L'AFFICHAGE "00 d C 42"

        -- === Test 4: Mise à jour du mode à 'Flash' ===
        report "Test 4: Mise a jour mode a 'F'. Affichage attendu: 00 d E 42";
        mode_tb <= '1';
        hex_command_tb <= "10"; -- Send mode update command
        wait for CLK_PERIOD;
        hex_command_tb <= "00";

        wait for CLK_PERIOD;
        assert dbg_mode_tb = '1' report "ERREUR Test 4" severity error;
        report "Test 4: OK. Mode mis a 'F'. Observation de l'affichage...";
        wait for 5 ms;
            
        -- === Test 5: Mise à jour du Meilleur Score à 99 ===
        report "Test 5: Mise a jour best_score a 99. Affichage attendu: 99 d E 42";
        best_score_tb <= to_unsigned(99, 7);
        hex_command_tb <= "11"; -- Send best_score update command
        wait for CLK_PERIOD;
        hex_command_tb <= "00";
        
        wait for CLK_PERIOD;
        assert dbg_best_score_tb = 99 report "ERREUR Test 5" severity error;
        report "Test 5: OK. Best_score mis a 99. Observation de l'affichage final...";
        wait for 5 ms; -- << LONGUE PAUSE POUR OBSERVER L'AFFICHAGE "99 d E 42"
        
        report "--- FIN DES TESTS ---" severity note;
        wait;
    end process;
end architecture Behavioral;