library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_sw_reader is
end entity tb_sw_reader;

architecture Behavioral of tb_sw_reader is

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
    -- SCÉNARIO DE TEST COMPLET
    -- =========================================================================
    stim_proc: process
    begin
        report "--- Debut du testbench complet pour sw_reader ---";
        
        -- Test 1: Reset.
        report "Test 1: Verification du reset.";
        reset_tb <= '1'; wait for 100 ns; reset_tb <= '0'; wait for 20 ns;
        assert sw_index_tb = "0000" and read_valid_tb = '0' report "ERREUR Test 1" severity error;
        report "Test 1: OK.";

        -- Test 2: Lecture de SW2 (cas valide).
        report "Test 2: Lecture de SW2.";
        sw_i_tb <= "0000000100";
        wait for CLK_PERIOD;
        read_command_tb <= '1'; wait for CLK_PERIOD; read_command_tb <= '0';
        wait for CLK_PERIOD;
        assert sw_index_tb = "0010" and read_valid_tb = '1' report "ERREUR Test 2" severity error;
        wait for CLK_PERIOD;
        assert read_valid_tb = '0' report "ERREUR Test 2: read_valid n'est pas une impulsion." severity error;
        report "Test 2: OK.";

        -- Test 3: Lecture de SW9 (cas valide).
        report "Test 3: Lecture de SW9.";
        sw_i_tb <= "1000000000";
        wait for CLK_PERIOD;
        read_command_tb <= '1'; wait for CLK_PERIOD; read_command_tb <= '0';
        wait for CLK_PERIOD;
        assert sw_index_tb = "1001" and read_valid_tb = '1' report "ERREUR Test 3" severity error;
        report "Test 3: OK.";
        
        -- Test 4: Pas de commande. La sortie ne doit pas changer.
        report "Test 4: Changement de SW sans commande.";
        sw_i_tb <= "0000000001";
        wait for 100 ns;
        assert sw_index_tb = "1001" report "ERREUR Test 4: L'index a change sans commande." severity error;
        report "Test 4: OK.";

        -- Test 5: Commande avec entrée invalide (aucun switch).
        report "Test 5: Commande avec entree invalide (aucun switch).";
        sw_i_tb <= "0000000000";
        wait for CLK_PERIOD;
        read_command_tb <= '1'; wait for CLK_PERIOD; read_command_tb <= '0';
        wait for CLK_PERIOD;
        assert read_valid_tb = '0' report "ERREUR Test 5" severity error;
        report "Test 5: OK.";

        -- *** NOUVEAU TEST AJOUTÉ ***
        -- Test 6: Commande avec entrée invalide (plusieurs switches -> "1111").
        report "Test 6: Commande avec entree invalide (plusieurs switches).";
        sw_i_tb <= "0000001100"; -- SW2 et SW3 activés -> cas 'others'
        wait for CLK_PERIOD;
        
        read_command_tb <= '1';
        wait for CLK_PERIOD;
        read_command_tb <= '0';
        wait for CLK_PERIOD;

        -- On vérifie que read_valid est bien resté à '0' car index_comb était "1111"
        assert read_valid_tb = '0'
            report "ERREUR Test 6: read_valid est passe a '1' pour une entree multiple." severity error;
        report "Test 6: OK.";

        report "--- TOUS LES TESTS ONT REUSSI ---" severity note;
        wait;
    end process;

end architecture Behavioral;
