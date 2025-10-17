library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity level_controller_tb is
end entity level_controller_tb;

architecture Behavioral of level_controller_tb is

    -- === Composant à tester (DUT) ===
    component level_controller
        Port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            level_pulse : in  std_logic;
            level       : out unsigned(1 downto 0);
            cfg_times   : out std_logic_vector(31 downto 0)
        );
    end component;

    -- === Signaux du testbench ===
    signal clk_tb         : std_logic := '0';
    signal reset_tb       : std_logic := '0';
    signal level_pulse_tb : std_logic := '0';
    signal level_tb       : unsigned(1 downto 0);
    signal cfg_times_tb   : std_logic_vector(31 downto 0);

    -- Constantes pour la simulation
    constant CLK_PERIOD : time := 20 ns;

    -- Constantes pour les valeurs de temps attendues (pour les asserts)
    constant EASY_TIME_VEC   : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(25000000, 32));
    constant MEDIUM_TIME_VEC : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(12500000, 32));
    constant HARD_TIME_VEC   : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(5000000, 32));

begin
    -- === Instanciation du DUT ===
    uut: level_controller
        port map (
            clk         => clk_tb,
            reset       => reset_tb,
            level_pulse => level_pulse_tb,
            level       => level_tb,
            cfg_times   => cfg_times_tb
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
        report "--- Debut du testbench pour level_controller ---";
        
        -- Test 1: Reset initial
        report "Test 1: Verification du reset. Niveau attendu: Facile (00).";
        reset_tb <= '1';
        wait for CLK_PERIOD * 5;
        reset_tb <= '0';
        wait for CLK_PERIOD; -- Laisser un cycle pour que la sortie combinatoire se stabilise

        assert level_tb = "00" and cfg_times_tb = EASY_TIME_VEC
            report "ERREUR Test 1: Le reset n'a pas initialise le niveau a Facile." severity error;
        report "Test 1: OK.";

        -- Test 2: Première impulsion -> passage à Moyen
        report "Test 2: Envoi d'une impulsion. Niveau attendu: Moyen (01).";
        level_pulse_tb <= '1';
        wait for CLK_PERIOD;
        level_pulse_tb <= '0';
        wait for CLK_PERIOD;

        assert level_tb = "01" and cfg_times_tb = MEDIUM_TIME_VEC
            report "ERREUR Test 2: Le niveau n'est pas passe a Moyen." severity error;
        report "Test 2: OK.";

        -- Test 3: Deuxième impulsion -> passage à Difficile
        report "Test 3: Envoi d'une impulsion. Niveau attendu: Difficile (10).";
        level_pulse_tb <= '1';
        wait for CLK_PERIOD;
        level_pulse_tb <= '0';
        wait for CLK_PERIOD;

        assert level_tb = "10" and cfg_times_tb = HARD_TIME_VEC
            report "ERREUR Test 3: Le niveau n'est pas passe a Difficile." severity error;
        report "Test 3: OK.";

        -- Test 4: Troisième impulsion -> retour à Facile
        report "Test 4: Envoi d'une impulsion. Niveau attendu: Facile (00).";
        level_pulse_tb <= '1';
        wait for CLK_PERIOD;
        level_pulse_tb <= '0';
        wait for CLK_PERIOD;

        assert level_tb = "00" and cfg_times_tb = EASY_TIME_VEC
            report "ERREUR Test 4: Le niveau n'est pas retourne a Facile." severity error;
        report "Test 4: OK.";
        
        -- Test 5: Vérification de la mémorisation (pas d'impulsion)
        report "Test 5: Attente sans impulsion. Le niveau ne doit pas changer.";
        wait for CLK_PERIOD * 10;
        
        assert level_tb = "00"
            report "ERREUR Test 5: Le niveau a change sans impulsion !" severity error;
        report "Test 5: OK.";

        report "--- TOUS LES TESTS ONT REUSSI ---" severity note;
        wait;
    end process;

end architecture Behavioral;