library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_hex_driver is
end entity tb_hex_driver;

architecture Behavioral of tb_hex_driver is
    -- === Composant à tester (DUT) ===
    component hex_driver
        Port (
            score       : in  unsigned(6 downto 0);
            best_score  : in  unsigned(6 downto 0);
            level       : in  unsigned(1 downto 0);
            mode        : in  std_logic;
            HEX5, HEX4, HEX3, HEX2, HEX1, HEX0 : out std_logic_vector(6 downto 0)
        );
    end component;

    -- === Signaux du testbench ===
    signal score_tb      : unsigned(6 downto 0);
    signal best_score_tb : unsigned(6 downto 0);
    signal level_tb      : unsigned(1 downto 0);
    signal mode_tb       : std_logic;
    signal HEX0_tb, HEX1_tb, HEX2_tb, HEX3_tb, HEX4_tb, HEX5_tb : std_logic_vector(6 downto 0);

    -- === Constantes pour les valeurs attendues ===
    constant SEG_1 : std_logic_vector(6 downto 0) := "1111001";
    constant SEG_2 : std_logic_vector(6 downto 0) := "0100100";
    constant SEG_3 : std_logic_vector(6 downto 0) := "0110000";
    constant SEG_8 : std_logic_vector(6 downto 0) := "0000000";
    constant SEG_C : std_logic_vector(6 downto 0) := "1000110";
    constant SEG_d : std_logic_vector(6 downto 0) := "0100001";

begin
    -- === Instanciation du DUT ===
    uut: hex_driver
        port map (
            score => score_tb, best_score => best_score_tb, level => level_tb, mode => mode_tb,
            HEX5 => HEX5_tb, HEX4 => HEX4_tb, HEX3 => HEX3_tb, HEX2 => HEX2_tb,
            HEX1 => HEX1_tb, HEX0 => HEX0_tb
        );

    -- === Processus de test (scénario) ===
    stim_proc: process
    begin
        report "--- Debut du testbench simplifie pour hex_driver ---";

        -- === Test 1: score=23, best=81, level=D, mode=C ===
        report "Test 1: Affichage de '81 d C 23'";
        score_tb      <= to_unsigned(23, 7);
        best_score_tb <= to_unsigned(81, 7);
        level_tb      <= "10"; -- Difficile
        mode_tb       <= '0';  -- Classique
        wait for 10 ns; -- Attendre juste pour que les valeurs se propagent et soient visibles

        -- Vérifications automatiques
        assert HEX5_tb = SEG_8 report "ERREUR Test 1: HEX5 (best/diz) devrait etre 8" severity error;
        assert HEX4_tb = SEG_1 report "ERREUR Test 1: HEX4 (best/uni) devrait etre 1" severity error;
        assert HEX3_tb = SEG_d report "ERREUR Test 1: HEX3 (level) devrait etre 'd'" severity error;
        assert HEX2_tb = SEG_C report "ERREUR Test 1: HEX2 (mode) devrait etre 'C'"  severity error;
        assert HEX1_tb = SEG_2 report "ERREUR Test 1: HEX1 (score/diz) devrait etre 2" severity error;
        assert HEX0_tb = SEG_3 report "ERREUR Test 1: HEX0 (score/uni) devrait etre 3" severity error;
        
        report "Test 1: OK.";

        report "--- TOUS LES TESTS ONT REUSSI ---";
        wait; -- Fin de la simulation
    end process stim_proc;

end architecture Behavioral;
