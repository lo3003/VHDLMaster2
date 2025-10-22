library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_sw_seq_comparator is
end entity;

architecture Behavioral of tb_sw_seq_comparator	 is

    -- 1. Déclaration du composant
    component sw_seq_comparator
        generic ( MAX_SEQ_LENGTH : integer := 10 );
        Port (
            clk             : in  std_logic;
            reset           : in  std_logic;
            latch_command   : in  std_logic;
            index           : in  unsigned(3 downto 0);
            seq_value       : in  unsigned(3 downto 0);
            latch_valid     : out std_logic;
            compare_command : in  std_logic;
            sw_index        : in  unsigned(3 downto 0);
            compare_valid   : out std_logic;
            match_error     : out std_logic
        );
    end component;

    -- 2. Signaux du testbench
    signal clk_tb             : std_logic := '0';
    signal reset_tb           : std_logic := '0'; -- Actif HAUT dans le module
    signal latch_command_tb   : std_logic := '0';
    signal index_tb           : unsigned(3 downto 0) := (others => '0');
    signal seq_value_tb       : unsigned(3 downto 0) := (others => '0');
    signal latch_valid_tb     : std_logic;
    signal compare_command_tb : std_logic := '0';
    signal sw_index_tb        : unsigned(3 downto 0) := (others => '0');
    signal compare_valid_tb   : std_logic;
    signal match_error_tb     : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    -- 3. Instanciation du DUT
    DUT: sw_seq_comparator
        generic map ( MAX_SEQ_LENGTH => 10 )
        port map (
            clk             => clk_tb,
            reset           => reset_tb,
            latch_command   => latch_command_tb,
            index           => index_tb,
            seq_value       => seq_value_tb,
            latch_valid     => latch_valid_tb,
            compare_command => compare_command_tb,
            sw_index        => sw_index_tb,
            compare_valid   => compare_valid_tb,
            match_error     => match_error_tb
        );

    -- 4. Génération de l'horloge
    clk_process : process
    begin
        clk_tb <= '0'; wait for CLK_PERIOD/2;
        clk_tb <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- 5. Scénario de test (inchangé logiquement, 'step_tb' n'est juste plus assigné)
    stim_process : process
    begin
        report "--- Debut du testbench pour sw_seq_comparator ---";

        -- == 1. Reset ==
        report "Phase 1: Reset...";
        reset_tb <= '1'; -- Appliquer le reset (actif HAUT)
        wait for 2*CLK_PERIOD;
        reset_tb <= '0'; -- Relâcher le reset
        wait for CLK_PERIOD;
        report "Phase 1: Reset termine.";

        -- == 2. Latch de valeurs ==
        report "Phase 2: Latch des valeurs...";
        -- Latch Valeur 5 à l'index 0
        latch_command_tb <= '1';
        index_tb         <= to_unsigned(0, 4);
        seq_value_tb     <= to_unsigned(5, 4);
        wait for CLK_PERIOD;
        latch_command_tb <= '0';
        wait for CLK_PERIOD;
        assert latch_valid_tb = '1' report "ERREUR Latch 0: latch_valid n'est pas a 1." severity error;
        wait for CLK_PERIOD;
        assert latch_valid_tb = '0' report "ERREUR Latch 0: latch_valid n'est pas retombe a 0." severity error;

        -- Latch Valeur 8 à l'index 1
        latch_command_tb <= '1';
        index_tb         <= to_unsigned(1, 4); -- L'index pour les comparaisons suivantes sera 1
        seq_value_tb     <= to_unsigned(8, 4);
        wait for CLK_PERIOD;
        latch_command_tb <= '0';
        wait for CLK_PERIOD;
        assert latch_valid_tb = '1' report "ERREUR Latch 1: latch_valid n'est pas a 1." severity error;
        wait for CLK_PERIOD;

        report "Phase 2: Latch termine. Memoire = {0: 5, 1: 8, ...}. index_tb pointe maintenant sur 1.";

        -- == 3. Test de Comparaison ==
        report "Phase 3: Tests de comparaison (avec index='1' utilisé pour lire la mémoire)...";

        -- Test A: sw_index=8.
        -- Le DUT compare sw_index (8) avec seq_mem_reg[index] (seq_mem_reg[1]=8)
        -- => Attendu: SUCCES (match_error=0)
        report " Test A: sw_index=8 -> attendu: match_error=0 (compare sw=8 vs mem[1]=8)";
        compare_command_tb <= '1';
        sw_index_tb        <= to_unsigned(8, 4);
        wait for CLK_PERIOD;
        compare_command_tb <= '0';
        wait for CLK_PERIOD;
        assert compare_valid_tb = '1' report "ERREUR Test A: compare_valid n'est pas a 1." severity error;
        assert match_error_tb = '0' report "ERREUR Test A: match_error devrait etre 0." severity error;
        wait for CLK_PERIOD;

        -- Test B: sw_index=5.
        -- Le DUT compare sw_index (5) avec seq_mem_reg[index] (seq_mem_reg[1]=8)
        -- => Attendu: ECHEC (match_error=1)
         report " Test B: sw_index=5 -> attendu: match_error=1 (compare sw=5 vs mem[1]=8)";
        compare_command_tb <= '1';
        sw_index_tb        <= to_unsigned(5, 4);
        wait for CLK_PERIOD;
        compare_command_tb <= '0';
        wait for CLK_PERIOD;
        assert compare_valid_tb = '1' report "ERREUR Test B: compare_valid n'est pas a 1." severity error;
        assert match_error_tb = '1' report "ERREUR Test B: match_error devrait etre 1." severity error;
        wait for CLK_PERIOD;

         -- Test C: Changer l'index pointé et refaire une comparaison
        report " Test C: index=0, sw_index=5 -> attendu: match_error=0 (compare sw=5 vs mem[0]=5)";
        index_tb           <= to_unsigned(0, 4); -- On change l'index pointé pour la comparaison
        compare_command_tb <= '1';
        sw_index_tb        <= to_unsigned(5, 4);
        wait for CLK_PERIOD;
        compare_command_tb <= '0';
        wait for CLK_PERIOD;
        assert compare_valid_tb = '1' report "ERREUR Test C: compare_valid n'est pas a 1." severity error;
        assert match_error_tb = '0' report "ERREUR Test C: match_error devrait etre 0." severity error;
        wait for CLK_PERIOD;


        report "--- Fin du testbench (sans port 'step') ---";
        wait;
    end process;

end architecture Behavioral;
