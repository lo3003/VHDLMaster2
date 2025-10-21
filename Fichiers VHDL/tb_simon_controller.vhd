library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_simon_controller is
end entity;

architecture test of tb_simon_controller is

    -- N_MAX reste élevé pour ne pas gagner par accident
    constant TB_N_MAX : integer := 10;

    -- 1. Déclaration du composant à tester (DUT)
    component simon_controller is
        generic ( N_MAX : integer := 10 );
        Port (
            clk              : in std_logic;
            reset            : in std_logic;
            start_pulse      : in std_logic;
            valid_pulse      : in std_logic;
            mode_pulse		 : in std_logic;
            level_pulse      : in std_logic;
            send_valid       : in std_logic;
            show_valid       : in std_logic;
            read_valid       : in std_logic;
            latch_valid      : in std_logic;
            compare_valid    : in std_logic;
            led_game_valid   : in std_logic;
            match_error      : in std_logic;
            mode             : in std_logic;
            level 			 : in std_logic_vector(1 downto 0);
            on_off_times 	 : in std_logic_vector(9 downto 0);
            send_command 	 : out std_logic;
            show_command     : out std_logic;
            read_command     : out std_logic;
            latch_command    : out std_logic;
            compare_command  : out std_logic;
            score_command    : out std_logic;
            level_command    : out std_logic;
            mode_command     : out std_logic;
            led_game_command : out std_logic;
            index            : out unsigned(3 downto 0);
            step             : out unsigned(3 downto 0);
            score_o          : out unsigned(6 downto 0);
            game_over_o      : out std_logic
        );
    end component;

    -- 2. Signaux pour connecter au DUT
    signal clk            : std_logic := '0';
    signal reset          : std_logic := '0';
    signal start_pulse    : std_logic := '0';
    signal valid_pulse    : std_logic := '0';
    signal mode_pulse     : std_logic := '0';
    signal level_pulse    : std_logic := '0';
    signal send_valid     : std_logic := '0';
    signal show_valid     : std_logic := '0';
    signal read_valid     : std_logic := '0';
    signal latch_valid    : std_logic := '0';
    signal compare_valid  : std_logic := '0';
    signal led_game_valid : std_logic := '0';
    signal match_error    : std_logic := '0';
    signal mode           : std_logic := '0';
    signal level          : std_logic_vector(1 downto 0) := "00";
    signal on_off_times   : std_logic_vector(9 downto 0) := (others => '0');
    signal send_command   : std_logic;
    signal show_command   : std_logic;
    signal read_command   : std_logic;
    signal latch_command  : std_logic;
    signal compare_command : std_logic;
    signal score_command  : std_logic;
    signal level_command  : std_logic;
    signal mode_command   : std_logic;
    signal led_game_command: std_logic;
    signal index          : unsigned(3 downto 0);
    signal step           : unsigned(3 downto 0);
    signal score_o        : unsigned(6 downto 0);
    signal game_over_o    : std_logic;

    -- Constantes
    constant CLK_PERIOD : time := 20 ns;

begin

    -- 3. Instanciation du DUT
    uut: simon_controller
        generic map ( N_MAX => TB_N_MAX )
        port map (
            clk              => clk,
            reset            => reset,
            start_pulse      => start_pulse,
            valid_pulse      => valid_pulse,
            mode_pulse       => mode_pulse,
            level_pulse      => level_pulse,
            send_valid       => send_valid,
            show_valid       => show_valid,
            read_valid       => read_valid,
            latch_valid      => latch_valid,
            compare_valid    => compare_valid,
            led_game_valid   => led_game_valid,
            match_error      => match_error,
            mode             => mode,
            level            => level,
            on_off_times     => on_off_times,
            send_command     => send_command,
            show_command     => show_command,
            read_command     => read_command,
            latch_command    => latch_command,
            compare_command  => compare_command,
            score_command    => score_command,
            level_command    => level_command,
            mode_command     => mode_command,
            led_game_command => led_game_command,
            index            => index,
            step             => step,
            score_o          => score_o,
            game_over_o      => game_over_o
        );

    -- 4. Processus d'horloge
    clk_process: process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    -- 5. Processus de stimulation (le scénario de test)
    stim_proc: process
        -- Procédure pour simuler une impulsion sur un signal
        procedure pulse(signal s : out std_logic) is
        begin
            s <= '1';
            wait for CLK_PERIOD;
            s <= '0';
        end procedure;

        -- Procédure pour attendre une commande (plus robuste)
        procedure wait_for_cmd(signal cmd : in std_logic) is
        begin
            -- CORRECTION: Suppression de 'cmd'name pour compatibilité
            report "Attente de commande...";
            wait until cmd = '1';
            wait for CLK_PERIOD; -- Se resynchronise sur le cycle suivant
            report "Commande recue.";
        end procedure;
    begin
        -- CORRECTION: Suppression des accents
        report "Debut du testbench (Test de Defaite Seul)." severity note;
        
        -- 1. Reset
        reset <= '0'; wait for 100 ns;
        reset <= '1'; wait for CLK_PERIOD;

        -- ===================================
        -- PARTIE 1 : TEST DE DÉFAITE AU NIVEAU 2
        -- ===================================
        report "TEST: Demarrage PARTIE (Test de Defaite)." severity note;
        pulse(start_pulse);
        
        -- ===================================
        -- NIVEAU 1 (step=0) - RÉUSSITE
        -- ===================================
        report "Simulation Niveau 1 (Reussite)..." severity note;
        
        -- Phase affichage (index 0)
        wait_for_cmd(send_command);
        wait_for_cmd(show_command);
        
        -- Phase joueur (index 0)
        wait_for_cmd(read_command);
        pulse(valid_pulse);
        match_error <= '0'; -- Correct
        wait_for_cmd(compare_command);

        wait for CLK_PERIOD*5; -- Laisser la FSM passer au niveau suivant
        assert score_o = 0 report "Score (Niv 1) devrait etre 0." severity warning;

        -- ===================================
        -- NIVEAU 2 (step=1) - ÉCHEC
        -- ===================================
        report "Simulation Niveau 2 (Echec)..." severity note;
        
        -- Phase affichage (index 0)
        wait_for_cmd(send_command);
        wait_for_cmd(show_command);
        -- Phase affichage (index 1)
        wait_for_cmd(send_command);
        wait_for_cmd(show_command);
        
        -- Phase joueur (index 0 - OK)
        wait_for_cmd(read_command);
        pulse(valid_pulse);
        match_error <= '0'; -- Correct
        wait_for_cmd(compare_command);

        -- Phase joueur (index 1 - ÉCHEC)
        wait_for_cmd(read_command);
        pulse(valid_pulse);
        match_error <= '1'; -- <<<<<<<<<<<<<<< ERREUR
        wait_for_cmd(compare_command);

        -- ===================================
        -- VÉRIFICATION GAME OVER
        -- ===================================
        report "TEST: Verification Defaite." severity note;
        wait_for_cmd(led_game_command);
        
        -- Vérifications finales
        assert game_over_o = '1' report "ERREUR: game_over_o devrait etre '1' (Defaite)" severity error;
        assert score_o = 0 report "ERREUR: Score (Defaite) devrait etre 0 (non incremente)" severity error;
        
        report "Test de defaite termine." severity note;
        
        -- On vérifie que le score se remet à zéro au prochain start
        pulse(start_pulse);
        wait for CLK_PERIOD * 5;
        assert score_o = 0 report "ERREUR: Score (Jeu 2) devrait etre 0 (reset)" severity error;

        report "Fin du testbench." severity note;
        wait;
    end process;
    
    -- ========================================================
    -- Processus de simulation des modules externes (Handshakes)
    -- ========================================================

    -- Simule hard_seq_generator
    send_proc: process(clk)
    begin
        if rising_edge(clk) then
            if send_command = '1' then
                send_valid <= '1';
            else
                send_valid <= '0';
            end if;
        end if;
    end process;
    
    -- Simule led_seq_generator ET sw_seq_comparator
    show_latch_proc: process(clk)
    begin
        if rising_edge(clk) then
            if show_command = '1' then
                show_valid <= '1';
            else
                show_valid <= '0';
            end if;
            
            if latch_command = '1' then
                latch_valid <= '1';
            else
                latch_valid <= '0';
            end if;
        end if;
    end process;

    -- Simule sw_reader
    read_proc: process(clk)
    begin
        if rising_edge(clk) then
            if read_command = '1' then
                read_valid <= '1';
            else
                read_valid <= '0';
            end if;
        end if;
    end process;

    -- Simule sw_seq_comparator
    compare_proc: process(clk)
    begin
        if rising_edge(clk) then
            if compare_command = '1' then
                compare_valid <= '1';
            else
                compare_valid <= '0';
            end if;
        end if;
    end process;

    -- Simule les modules de fin de partie (affichage score, etc.)
    game_over_proc: process(clk)
    begin
        if rising_edge(clk) then
            if led_game_command = '1' or score_command = '1' then
                led_game_valid <= '1';
            else
                led_game_valid <= '0';
            end if;
        end if;
    end process;

end architecture;