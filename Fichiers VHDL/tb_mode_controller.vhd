library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mode_controller_tb is
end entity mode_controller_tb;

architecture Behavioral of mode_controller_tb is

    -- === Composant à tester (DUT) ===
    component mode_controller
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            mode_command : in  std_logic;
            mode         : out std_logic
        );
    end component;

    -- === Signaux du testbench ===
    signal clk_tb          : std_logic := '0';
    signal reset_tb        : std_logic := '0';
    signal mode_command_tb : std_logic := '0';
    signal mode_tb         : std_logic;

    constant CLK_PERIOD : time := 20 ns;

begin
    -- === Instanciation du DUT ===
    uut: mode_controller
        port map (
            clk          => clk_tb,
            reset        => reset_tb,
            mode_command => mode_command_tb,
            mode         => mode_tb
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
        report "--- Debut du testbench pour mode_controller ---";
        
        -- Test 1: Reset initial -> Mode Classique
        report "Test 1: Verification du reset. Mode attendu: Classique ('0').";
        reset_tb <= '1';
        wait for CLK_PERIOD * 5;
        reset_tb <= '0';
        wait for CLK_PERIOD;

        assert mode_tb = '0'
            report "ERREUR Test 1: Le reset n'a pas initialise le mode a Classique." severity error;
        report "Test 1: OK.";

        -- Test 2: Première impulsion -> passage à Flash
        report "Test 2: Envoi d'une impulsion. Mode attendu: Flash ('1').";
        mode_command_tb <= '1';
        wait for CLK_PERIOD;
        mode_command_tb <= '0';
        wait for CLK_PERIOD;

        assert mode_tb = '1'
            report "ERREUR Test 2: Le mode n'est pas passe a Flash." severity error;
        report "Test 2: OK.";

        -- Test 3: Deuxième impulsion -> retour à Classique
        report "Test 3: Envoi d'une impulsion. Mode attendu: Classique ('0').";
        mode_command_tb <= '1';
        wait for CLK_PERIOD;
        mode_command_tb <= '0';
        wait for CLK_PERIOD;

        assert mode_tb = '0'
            report "ERREUR Test 3: Le mode n'est pas retourne a Classique." severity error;
        report "Test 3: OK.";
        
        -- Test 4: Vérification de la mémorisation
        report "Test 4: Attente sans impulsion. Le mode ne doit pas changer.";
        wait for CLK_PERIOD * 10;
        
        assert mode_tb = '0'
            report "ERREUR Test 4: Le mode a change sans impulsion !" severity error;
        report "Test 4: OK.";

        report "--- TOUS LES TESTS ONT REUSSI ---" severity note;
        wait;
    end process;

end architecture Behavioral;
