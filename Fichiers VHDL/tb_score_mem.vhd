library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_score_mem is
end entity;

architecture Behavioral of tb_score_mem is

    -- === Composant à tester (DUT) ===
    component score_mem
        Port (
            clk           : in  std_logic;
            reset         : in  std_logic;
            score_command : in  std_logic;
            score         : in  unsigned(6 downto 0);
            best_o        : out unsigned(6 downto 0)
        );
    end component;

    -- === Signaux du testbench ===
    signal clk_tb           : std_logic := '0';
    signal reset_tb         : std_logic := '0';
    signal score_command_tb : std_logic := '0';
    signal score_tb         : unsigned(6 downto 0) := (others => '0');
    signal best_o_tb        : unsigned(6 downto 0);

    constant CLK_PERIOD : time := 20 ns;

begin
    -- === Instanciation du DUT ===
    uut: score_mem
        port map (
            clk           => clk_tb,
            reset         => reset_tb,
            score_command => score_command_tb,
            score         => score_tb,
            best_o        => best_o_tb
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
        report "--- Debut du testbench pour score_mem ---";
        
        -- Test 1: Reset initial -> best_score = 0
        report "Test 1: Verification du reset. Meilleur score attendu: 0.";
        reset_tb <= '1'; wait for 100 ns; reset_tb <= '0'; wait for 20 ns;

        assert best_o_tb = 0 report "ERREUR Test 1: Le reset n'a pas initialise le score a 0." severity error;
        report "Test 1: OK.";

        -- Test 2: Premier record -> best_score = 15
        report "Test 2: Enregistrement d'un premier score de 15.";
        score_tb <= to_unsigned(15, 7);
        score_command_tb <= '1'; wait for CLK_PERIOD; score_command_tb <= '0'; wait for 20 ns;

        assert best_o_tb = 15 report "ERREUR Test 2: Le premier score n'a pas ete enregistre." severity error;
        report "Test 2: OK.";

        -- Test 3: Score plus faible -> best_score reste à 15
        report "Test 3: Tentative avec un score plus faible (8). Le record doit rester 15.";
        score_tb <= to_unsigned(8, 7);
        score_command_tb <= '1'; wait for CLK_PERIOD; score_command_tb <= '0'; wait for 20 ns;

        assert best_o_tb = 15 report "ERREUR Test 3: Le record a ete ecrase par un score plus faible." severity error;
        report "Test 3: OK.";
        
        -- Test 4: Nouveau record -> best_score = 22
        report "Test 4: Enregistrement d'un nouveau record (22).";
        score_tb <= to_unsigned(22, 7);
        score_command_tb <= '1'; wait for CLK_PERIOD; score_command_tb <= '0'; wait for 20 ns;

        assert best_o_tb = 22 report "ERREUR Test 4: Le nouveau record n'a pas ete mis a jour." severity error;
        report "Test 4: OK.";
        
        -- Test 5: Pas de commande -> best_score reste à 22
        report "Test 5: Changement du score sans commande. Le record doit rester 22.";
        score_tb <= to_unsigned(50, 7); -- Score potentiellement plus élevé
        wait for 100 ns; -- On attend sans envoyer de commande
        
        assert best_o_tb = 22 report "ERREUR Test 5: Le record a change sans commande." severity error;
        report "Test 5: OK.";

        report "--- TOUS LES TESTS ONT REUSSI ---" severity note;
        wait;
    end process;

end architecture Behavioral;

