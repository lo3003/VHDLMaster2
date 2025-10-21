library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity level_controller_tb is
end entity level_controller_tb;

architecture Behavioral of level_controller_tb is

    -- === Composant à tester (DUT) ===
    component level_controller
        Port (
            clk           : in  std_logic;
            reset         : in  std_logic;
            level_command : in  std_logic;
            level         : out unsigned(1 downto 0);
            on_off_times  : out std_logic_vector(9 downto 0)
        );
    end component;

    -- === Signaux du testbench ===
    signal clk_tb         : std_logic := '0';
    signal reset_tb       : std_logic := '0';
    signal level_cmd_tb   : std_logic := '0';
    signal level_tb       : unsigned(1 downto 0);
    signal on_off_times_tb: std_logic_vector(9 downto 0);

    -- Constantes pour la simulation
    constant CLK_PERIOD : time := 20 ns;

    -- Constantes pour les valeurs de temps attendues
    constant EASY_TIME_VEC   : std_logic_vector(9 downto 0) := "00101" & "00101"; -- 5 & 5
    constant MEDIUM_TIME_VEC : std_logic_vector(9 downto 0) := "00010" & "00010"; -- 2 & 2
    constant HARD_TIME_VEC   : std_logic_vector(9 downto 0) := "00001" & "00001"; -- 1 & 1

begin
    -- === Instanciation du DUT ===
    uut: level_controller
        port map (
            clk           => clk_tb,
            reset         => reset_tb,
            level_command => level_cmd_tb,
            level         => level_tb,
            on_off_times  => on_off_times_tb
        );

    -- === Génération de l'horloge ===
    clk_process: process
    begin
        clk_tb <= not clk_tb;
        wait for CLK_PERIOD / 2;
    end process;

    -- === Scénario de test ===
    stim_proc: process
    begin
        report "--- Debut du testbench pour level_controller (corrigé) ---";

        -- Test 1: Reset initial -> Niveau Facile
        report "Test 1: Verification du reset. Niveau attendu: Facile (00).";
        reset_tb <= '1';
        wait for CLK_PERIOD * 5;
        reset_tb <= '0';
        wait for CLK_PERIOD;
        assert level_tb = "00" and on_off_times_tb = EASY_TIME_VEC
            report "ERREUR Test 1: Le reset n'a pas initialisé le niveau à Facile." severity error;
        report "Test 1: OK.";

        -- Test 2: Première impulsion -> passage à Moyen
        report "Test 2: Envoi d'une impulsion. Niveau attendu: Moyen (01).";
        level_cmd_tb <= '1';
        wait for CLK_PERIOD;
        level_cmd_tb <= '0';
        wait for CLK_PERIOD;
        assert level_tb = "01" and on_off_times_tb = MEDIUM_TIME_VEC
            report "ERREUR Test 2: Le niveau n'est pas passé à Moyen." severity error;
        report "Test 2: OK.";

        -- Test 3: Deuxième impulsion -> passage à Difficile
        report "Test 3: Envoi d'une impulsion. Niveau attendu: Difficile (10).";
        level_cmd_tb <= '1';
        wait for CLK_PERIOD;
        level_cmd_tb <= '0';
        wait for CLK_PERIOD;
        assert level_tb = "10" and on_off_times_tb = HARD_TIME_VEC
            report "ERREUR Test 3: Le niveau n'est pas passé à Difficile." severity error;
        report "Test 3: OK.";

        -- Test 4: Troisième impulsion -> retour à Facile
        report "Test 4: Envoi d'une impulsion. Niveau attendu: Facile (00).";
        level_cmd_tb <= '1';
        wait for CLK_PERIOD;
        level_cmd_tb <= '0';
        wait for CLK_PERIOD;
        assert level_tb = "00" and on_off_times_tb = EASY_TIME_VEC
            report "ERREUR Test 4: Le niveau n'est pas retourné à Facile." severity error;
        report "Test 4: OK.";

        report "--- TOUS LES TESTS ONT REUSSI ---" severity note;
        wait;
    end process;

end architecture Behavioral;
