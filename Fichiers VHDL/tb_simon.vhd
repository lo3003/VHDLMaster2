library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_simon is
end entity;

architecture test of tb_simon is

    -- 1. Déclaration du composant à tester (DUT)
    component simon is
        Port (
            CLOCK_50 : in  std_logic;
            RESET_N  : in  std_logic;
            SW       : in  std_logic_vector(9 downto 0);
            KEY      : in  std_logic_vector(3 downto 0);
            LEDR     : out std_logic_vector(9 downto 0);
            HEX0     : out std_logic_vector(6 downto 0);
            HEX1     : out std_logic_vector(6 downto 0);
            HEX2     : out std_logic_vector(6 downto 0);
            HEX3     : out std_logic_vector(6 downto 0);
            HEX4     : out std_logic_vector(6 downto 0);
            HEX5     : out std_logic_vector(6 downto 0)
        );
    end component;

    -- 2. Signaux pour connecter au DUT
    signal clk_tb     : std_logic := '0';
    signal reset_n_tb : std_logic := '1'; -- Actif bas
    signal sw_tb      : std_logic_vector(9 downto 0) := (others => '0');
    signal key_tb     : std_logic_vector(3 downto 0) := (others => '1'); -- Boutons relâchés (haut)
    signal ledr_tb    : std_logic_vector(9 downto 0);
    signal hex0_tb    : std_logic_vector(6 downto 0);
    signal hex1_tb    : std_logic_vector(6 downto 0);
    signal hex2_tb    : std_logic_vector(6 downto 0);
    signal hex3_tb    : std_logic_vector(6 downto 0);
    signal hex4_tb    : std_logic_vector(6 downto 0);
    signal hex5_tb    : std_logic_vector(6 downto 0);

    -- Constantes
    constant CLK_PERIOD      : time := 20 ns; -- 50 MHz
    constant DISPLAY_TIME    : time := 500 ms;
    constant PLAYER_WAIT_TIME: time := 100 ms;

    -- ** CORRECTION : Définition du type AVANT utilisation **
    subtype index_range is integer range 0 to 9;
    type integer_vector is array (index_range range <>) of integer;

    -- Séquence attendue (basée sur hard_seq_generator)
    constant EXPECTED_SEQ : integer_vector(0 to 9) := (0, 1, 2, 8, 9, 1, 2, 3, 7, 8);

begin

    -- 3. Instanciation du DUT
    uut: simon
        port map (
            CLOCK_50 => clk_tb,
            RESET_N  => reset_n_tb,
            SW       => sw_tb,
            KEY      => key_tb,
            LEDR     => ledr_tb,
            HEX0     => hex0_tb,
            HEX1     => hex1_tb,
            HEX2     => hex2_tb,
            HEX3     => hex3_tb,
            HEX4     => hex4_tb,
            HEX5     => hex5_tb
        );

    -- 4. Processus d'horloge
    clk_process: process
    begin
        clk_tb <= '0'; wait for CLK_PERIOD / 2;
        clk_tb <= '1'; wait for CLK_PERIOD / 2;
    end process;

    -- 5. Processus de stimulation
    stim_proc: process

        procedure press_key(key_index : integer) is
        begin
            report "Appui KEY(" & integer'image(key_index) & ")";
            key_tb(key_index) <= '0';
            wait for CLK_PERIOD * 2;
            key_tb(key_index) <= '1';
            wait for CLK_PERIOD;
        end procedure;

        procedure set_switch(sw_index : integer) is
            variable sw_vector : std_logic_vector(9 downto 0) := (others => '0');
        begin
             report "Activation SW(" & integer'image(sw_index) & ")";
            if sw_index >= 0 and sw_index <= 9 then
                sw_vector(sw_index) := '1';
            end if;
            sw_tb <= sw_vector;
            wait for CLK_PERIOD;
        end procedure;

        procedure wait_cycles(cycles : integer) is
        begin
            wait for CLK_PERIOD * cycles;
        end procedure;

    begin
        report "--- Debut du testbench SIMPLIFIE pour simon ---";

        -- == 1. Reset ==
        report "Phase 1: Reset...";
        reset_n_tb <= '0';
        sw_tb      <= (others => '0');
        key_tb     <= (others => '1');
        wait for 100 ns;
        reset_n_tb <= '1';
        wait_cycles(5);
        report "Phase 1: Reset termine.";

        -- == 2. Démarrage du jeu ==
        report "Phase 2: Demarrage du jeu...";
        press_key(0); -- Appui sur KEY0 (Start)
        report "Phase 2: Bouton Start appuye.";
        wait_cycles(10);

        -- == 3. Niveau 1 (step=0) ==
        report "Phase 3: Niveau 1...";
        report " Attente affichage LED...";
        wait until ledr_tb /= "0000000000"; report " LED allumee. Attente extinction...";
        wait until ledr_tb = "0000000000";  report " LED eteinte. Attente fin periode OFF...";
        -- ** Note: Les attentes basées sur des temps absolus peuvent être fragiles.
        --   Une attente basée sur les signaux de valid serait plus robuste si possible.
        wait for 300 ms; -- Attendre la fin de la période OFF + marge
        report " Fin periode OFF. Phase Joueur...";

        set_switch(EXPECTED_SEQ(0));
        press_key(1); -- Valider
        report " Reponse Niveau 1 envoyee.";
        wait_cycles(10);

        -- == 4. Niveau 2 (step=1) - ERREUR ==
        report "Phase 4: Niveau 2...";
        report " Attente affichage LED 1/2...";
        wait until ledr_tb /= "0000000000"; report " LED 1/2 allumee.";
        wait until ledr_tb = "0000000000";  report " LED 1/2 eteinte.";
        wait for 300 ms; report " Fin OFF 1/2.";

        report " Attente affichage LED 2/2...";
        wait until ledr_tb /= "0000000000"; report " LED 2/2 allumee.";
        wait until ledr_tb = "0000000000";  report " LED 2/2 eteinte.";
        wait for 300 ms; report " Fin OFF 2/2. Phase Joueur...";

        -- Joueur: Etape 1 (Correct)
        set_switch(EXPECTED_SEQ(0));
        press_key(1);
        report " Reponse Niveau 2, Etape 1 (Correcte) envoyee.";
        wait_cycles(10);

        -- Joueur: Etape 2 (Incorrect)
        report " Simulation Erreur Etape 2...";
        -- ** CORRECTION : Logique OK car EXPECTED_SEQ est maintenant bien défini **
        if EXPECTED_SEQ(1) < 9 then
             set_switch(EXPECTED_SEQ(1) + 1); -- ERREUR
        else
             set_switch(EXPECTED_SEQ(1) - 1); -- ERREUR
        end if;
        press_key(1);
        report " Reponse Niveau 2, Etape 2 (Incorrecte) envoyee.";
        wait_cycles(10);

        -- == 5. Vérification Game Over ==
        report "Phase 5: Attente de l'animation Game Over...";
        -- ** CORRECTION : Utilisation de 'ms' ou 'ns' **
        wait for 3000 ms; -- Attendre 3 secondes
        report "Phase 5: Verification visuelle de l'animation Game Over terminee.";

        report "--- Fin du testbench SIMPLIFIE ---";
        wait;
    end process stim_proc;


end architecture test;
