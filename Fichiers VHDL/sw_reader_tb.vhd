library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sw_reader_tb is
end entity sw_reader_tb;

architecture Behavioral of sw_reader_tb is

    component sw_reader
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            read_command : in  std_logic;
            sw_i         : in  std_logic_vector(9 downto 0);
            read_valid   : out std_logic;
            sw_index     : out unsigned(3 downto 0)
        );
    end component;

    signal clk_tb          : std_logic := '0';
    signal reset_tb        : std_logic := '0';
    signal read_command_tb : std_logic := '0';
    signal sw_i_tb         : std_logic_vector(9 downto 0) := (others => '0');
    signal read_valid_tb   : std_logic;
    signal sw_index_tb     : unsigned(3 downto 0);

    constant CLK_PERIOD : time := 20 ns;

begin
    uut: sw_reader
        port map (
            clk => clk_tb, reset => reset_tb, read_command => read_command_tb,
            sw_i => sw_i_tb, read_valid => read_valid_tb, sw_index => sw_index_tb
        );

    clk_process: process begin clk_tb <= not clk_tb; wait for CLK_PERIOD / 2; end process;

    -- =========================================================================
    -- SCÉNARIO DE TEST CORRIGÉ
    -- =========================================================================
    stim_proc: process
    begin
        report "--- Debut du testbench corrige pour sw_reader ---";
        
        -- Test 1: Reset.
        report "Test 1: Verification du reset.";
        reset_tb <= '1'; wait for 100 ns; reset_tb <= '0'; wait for 20 ns;
        assert sw_index_tb = "0000" and read_valid_tb = '0' report "ERREUR Test 1" severity error;
        report "Test 1: OK.";

        -- Test 2: Lecture de SW2. Index attendu: 2 ("0010").
        report "Test 2: Lecture de SW2.";
        sw_i_tb <= "0000000100"; -- 1. On prépare l'entrée
        wait for CLK_PERIOD;    -- 2. On attend 1 cycle pour que le DUT voie le changement
        
        read_command_tb <= '1'; -- 3. On envoie la commande
        wait for CLK_PERIOD;
        read_command_tb <= '0';
        
        wait for CLK_PERIOD;
        assert sw_index_tb = "0010" and read_valid_tb = '1' 
            report "ERREUR Test 2: L'index pour SW2 est incorrect." severity error;
        
        wait for CLK_PERIOD;
        assert read_valid_tb = '0' 
            report "ERREUR Test 2: read_valid n'est pas une impulsion." severity error;
        report "Test 2: OK.";

        -- Test 3: Lecture de SW9. Index attendu: 9 ("1001").
        report "Test 3: Lecture de SW9.";
        sw_i_tb <= "1000000000"; -- 1. On prépare l'entrée
        wait for CLK_PERIOD;    -- 2. On attend
        
        read_command_tb <= '1'; -- 3. On envoie la commande
        wait for CLK_PERIOD;
        read_command_tb <= '0';
        wait for CLK_PERIOD;
        
        assert sw_index_tb = "1001" and read_valid_tb = '1' 
            report "ERREUR Test 3: L'index pour SW9 est incorrect." severity error;
        report "Test 3: OK.";
        
        -- Test 4: Pas de commande. La sortie ne doit pas changer.
        report "Test 4: Changement de SW sans commande.";
        sw_i_tb <= "0000000001";
        wait for 100 ns;
        
        assert sw_index_tb = "1001" 
            report "ERREUR Test 4: L'index a change sans commande." severity error;
        report "Test 4: OK.";

        report "--- TOUS LES TESTS ONT REUSSI ---" severity note;
        wait;
    end process;

end architecture Behavioral;