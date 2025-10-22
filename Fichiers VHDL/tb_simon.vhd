library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_simon_complet is
end entity;

architecture test of tb_simon_complet is

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
    signal key_tb     : std_logic_vector(3 downto 0) := (others => '1');
    signal ledr_tb    : std_logic_vector(9 downto 0);
    signal hex0_tb, hex1_tb, hex2_tb, hex3_tb, hex4_tb, hex5_tb : std_logic_vector(6 downto 0);

    -- Constantes
    constant CLK_PERIOD   : time := 20 ns; -- 50 MHz
    
    -- Séquence attendue (copiée de hard_seq_generator.vhd)
    constant EXPECTED_SEQ : array (0 to 9) of integer := (0, 1, 2, 8, 9, 1, 2, 3, 7, 8);

begin

    -- 3. Instanciation du DUT
    uut: simon
        port map (
            CLOCK_50 => clk_tb, RESET_N  => reset_n_tb, SW => sw_tb, KEY => key_tb,
            LEDR => ledr_tb, HEX0 => hex0_tb, HEX1 => hex1_tb, HEX2 => hex2_tb,
            HEX3 => hex3_tb, HEX4 => hex4_tb, HEX5 => hex5_tb
        );

    -- 4. Processus d'horloge
    clk_process: process
    begin
        clk_tb <= not clk_tb;
        wait for CLK_PERIOD / 2;
    end process;

    -- 5. Processus de stimulation
    stim_proc: process
        procedure press_key(key_index : integer; duration_ms : integer := 4) is
        begin
            report "Appui sur KEY(" & integer'image(key_index) & ")";
            key_tb(key_index) <= '0';
            wait for duration_ms * 1 ms;
            key_tb(key_index) <= '1';
            wait for 1 ms;
        end procedure;

        procedure set_switch(sw_index : integer) is
            variable sw_vector : std_logic_vector(9 downto 0) := (others => '0');
        begin
             report "Activation de SW(" & integer'image(sw_index) & ")";
             if sw_index >= 0 and sw_index <= 9 then
                sw_vector(sw_index) := '1';
             end if;
            sw_tb <= sw_vector;
        end procedure;

    begin
        report "--- DEBUT DU TESTBENCH COMPLET POUR SIMON ---";
        
        -- == 1. Reset ==
        report "ETAPE 1: Reset du systeme...";
        reset_n_tb <= '0';
        sw_tb      <= (others => '0');
        key_tb     <= (others => '1');
        wait for 100 ns;
        reset_n_tb <= '1';
        wait for 1 us;
        report "ETAPE 1: Reset termine.";

        -- == 2. Démarrage du jeu ==
        report "ETAPE 2: Demarrage du jeu...";
        press_key(0); -- Appui sur KEY0 (Start)
        report "ETAPE 2: Bouton Start appuye.";
        wait for 100 ms;

        -- == 3. NIVEAU 1 (step=0) - REUSSITE ==
        report "ETAPE 3: Niveau 1 (doit reussir)...";
        report " Attente affichage LED 0...";
        wait until ledr_tb(EXPECTED_SEQ(0)) = '1'; report " LED 0 allumee.";
        wait until ledr_tb(EXPECTED_SEQ(0)) = '0'; report " LED 0 eteinte.";
        
        report " Phase Joueur...";
        set_switch(EXPECTED_SEQ(0));
        press_key(1); -- Valider
        report " Reponse Niveau 1 envoyee.";
        wait for 100 ms;

        -- == 4. NIVEAU 2 (step=1) - ECHEC ==
        report "ETAPE 4: Niveau 2 (doit echouer)...";
        -- Phase affichage
        report " Attente affichage LED 0...";
        wait until ledr_tb(EXPECTED_SEQ(0)) = '1'; report " LED 0 allumee.";
        wait until ledr_tb(EXPECTED_SEQ(0)) = '0'; report " LED 0 eteinte.";
        report " Attente affichage LED 1...";
        wait until ledr_tb(EXPECTED_SEQ(1)) = '1'; report " LED 1 allumee.";
        wait until ledr_tb(EXPECTED_SEQ(1)) = '0'; report " LED 1 eteinte.";
        
        report " Phase Joueur...";
        -- Joueur: Etape 1 (Correcte)
        set_switch(EXPECTED_SEQ(0));
        press_key(1);
        report " Reponse Niveau 2, Etape 1 (Correcte) envoyee.";
        wait for 100 ms;
        
        -- Joueur: Etape 2 (Incorrecte)
        report " Simulation Erreur Etape 2...";
        set_switch(EXPECTED_SEQ(1) + 2); -- Erreur volontaire
        press_key(1);
        report " Reponse Niveau 2, Etape 2 (Incorrecte) envoyee.";
        wait for 100 ms;

        -- == 5. Vérification Game Over ==
        report "ETAPE 5: Attente de l'animation Game Over...";
        wait for 3000 ms; -- Attendre 3 secondes pour voir l'animation
        report "ETAPE 5: Animation Game Over terminee (verification visuelle).";
        
        report "--- FIN DE LA SIMULATION ---";
        wait;
    end process stim_proc;

end architecture test;
