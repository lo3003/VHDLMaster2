library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================================
-- ENTITY: simon (Top-Level)
-- DESCRIPTION: Module principal pour le jeu Simon sur la carte DE0-CV.
--              Interconnecte tous les sous-modules.
-- =============================================================================
entity simon is
    Port (
        -- Horloge et Reset
        CLOCK_50 : in  std_logic;                                          -- Horloge 50 MHz
        RESET_N  : in  std_logic;                                          -- Reset global actif bas (KEY4 ou autre source)

        -- Entrées utilisateur
        SW       : in  std_logic_vector(9 downto 0);                       -- Interrupteurs
        KEY      : in  std_logic_vector(3 downto 0);                       -- Boutons poussoirs

        -- Sorties
        LEDR     : out std_logic_vector(9 downto 0);                       -- LEDs rouges 
        HEX0     : out std_logic_vector(6 downto 0);                       -- Afficheur 7-seg 0 (Score unités) 
        HEX1     : out std_logic_vector(6 downto 0);                       -- Afficheur 7-seg 1 (Score dizaines) 
        HEX2     : out std_logic_vector(6 downto 0);                       -- Afficheur 7-seg 2 (Mode) 
        HEX3     : out std_logic_vector(6 downto 0);                       -- Afficheur 7-seg 3 (Niveau) 
        HEX4     : out std_logic_vector(6 downto 0);                       -- Afficheur 7-seg 4 (Best score unités) 
        HEX5     : out std_logic_vector(6 downto 0)                        -- Afficheur 7-seg 5 (Best score dizaines) 
    );
end entity simon;

architecture structural of simon is

    -- =========================================================================
    -- Déclarations des Composants (Basées sur les fichiers VHDL fournis)
    -- =========================================================================

    component hard_seq_generator is
        generic ( N_MAX : integer := 10 );
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic; -- Actif HAUT
            send_command : in  std_logic;
            index        : in  unsigned(3 downto 0);
            send_valid   : out std_logic;
            value_o      : out unsigned(3 downto 0)
        );
    end component;

    component led_seq_generator is
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic; -- Actif HAUT
            show_command : in  std_logic;
            seq_value    : in  unsigned(3 downto 0);
            on_off_times : in  std_logic_vector(9 downto 0); -- !! Important !!
            show_valid   : out std_logic;
            led_o        : out std_logic_vector(9 downto 0)
        );
    end component;

    component sw_reader is
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic; -- Actif HAUT
            read_command : in  std_logic;
            sw_i         : in  std_logic_vector(9 downto 0);
            read_valid   : out std_logic;
            sw_index     : out unsigned(3 downto 0)
        );
    end component;

    component sw_seq_comparator is
        generic ( MAX_SEQ_LENGTH : integer := 10 );
        Port (
            clk             : in  std_logic;
            reset           : in  std_logic; -- Actif HAUT
            latch_command   : in  std_logic;
            index           : in  unsigned(3 downto 0);
            seq_value       : in  unsigned(3 downto 0);
            latch_valid     : out std_logic;
            compare_command : in  std_logic;
            step            : in  unsigned(3 downto 0);
            sw_index        : in  unsigned(3 downto 0);
            compare_valid   : out std_logic;
            match_error     : out std_logic
        );
    end component;

    component simon_controller is
        generic ( N_MAX : integer := 10 );
        Port (
            clk              : in std_logic;
            reset            : in std_logic; -- Actif HAUT
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
            on_off_times 	 : in std_logic_vector(9 downto 0); -- Vers led_seq_gen si mode FLASH
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

    component hex_driver is
        Port (
            score       : in  unsigned(6 downto 0);
            best_score  : in  unsigned(6 downto 0);
            level       : in  unsigned(1 downto 0);
            mode        : in  std_logic;
            HEX5, HEX4  : out std_logic_vector(6 downto 0);
            HEX3        : out std_logic_vector(6 downto 0);
            HEX2        : out std_logic_vector(6 downto 0);
            HEX1, HEX0  : out std_logic_vector(6 downto 0)
        );
    end component;

    component score_mem is
        Port (
            clk           : in  std_logic;
            reset         : in  std_logic; -- Actif HAUT
            score_command : in  std_logic;
            score         : in  unsigned(6 downto 0);
            best_o        : out unsigned(6 downto 0)
        );
    end component;

    -- !! Composant mis à jour !!
    component level_controller is
        Port (
            clk           : in  std_logic;
            reset         : in  std_logic;       -- Actif HAUT
            level_command : in  std_logic;       -- Changement de nom
            level         : out unsigned(1 downto 0);
            on_off_times  : out std_logic_vector(9 downto 0) -- Changement de type/nom
        );
    end component;

    component mode_controller is
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic; -- Actif HAUT
            mode_command : in  std_logic; -- Changement de nom
            mode         : out std_logic
        );
    end component;

     component led_game_state is
        Port (
            clk              : in  std_logic;
            reset            : in  std_logic; -- Actif HAUT
            led_game_command : in  std_logic;
            game_over        : in  std_logic;
            led_o            : out std_logic_vector(9 downto 0);
            led_game_valid   : out std_logic
        );
    end component;

    -- =========================================================================
    -- Signaux Internes d'Interconnexion
    -- =========================================================================

    -- Reset interne (actif HAUT)
    signal reset_int       : std_logic;

    -- Signaux du contrôleur principal (sorties)
    signal send_command    : std_logic;
    signal show_command    : std_logic;
    signal read_command    : std_logic;
    signal latch_command   : std_logic;
    signal compare_command : std_logic;
    signal score_command   : std_logic;
    signal level_command   : std_logic; -- -> vers level_controller
    signal mode_command    : std_logic;  -- -> vers mode_controller
    signal led_game_command: std_logic; -- -> vers led_game_state
    signal index_ctrl      : unsigned(3 downto 0);
    signal step_ctrl       : unsigned(3 downto 0);
    signal score_ctrl      : unsigned(6 downto 0);
    signal game_over_ctrl  : std_logic;

    -- Signaux des modules périphériques vers le contrôleur (entrées)
    signal send_valid      : std_logic;
    signal show_valid      : std_logic;
    signal read_valid      : std_logic;
    signal latch_valid     : std_logic;
    signal compare_valid   : std_logic;
    signal led_game_valid  : std_logic;
    signal match_error     : std_logic;

    -- Signaux entre modules
    signal seq_value       : unsigned(3 downto 0); -- Sortie hard_seq -> Entrée led_seq & comparator
    signal sw_index        : unsigned(3 downto 0); -- Sortie sw_reader -> Entrée comparator
    signal current_level   : unsigned(1 downto 0); -- Sortie level_ctrl -> Entrée controller & hex_driver
    signal current_mode    : std_logic;            -- Sortie mode_ctrl -> Entrée controller & hex_driver
    signal best_score      : unsigned(6 downto 0); -- Sortie score_mem -> Entrée hex_driver
    signal level_on_off_times : std_logic_vector(9 downto 0); -- !! Nouveau signal !! Sortie level_ctrl -> Entrée led_seq_gen

    -- Signaux de sortie LED
    signal led_o_seq       : std_logic_vector(9 downto 0); -- Sortie du led_seq_generator
    signal led_o_game      : std_logic_vector(9 downto 0); -- Sortie du led_game_state
    signal animation_active: std_logic := '0';             -- Signal pour gérer la priorité LED

	 -- Signaux pour les impulsions des boutons (synchronisation simple)
    signal start_pulse_sync : std_logic;
    signal valid_pulse_sync : std_logic;
    signal level_pulse_sync : std_logic;
    signal mode_pulse_sync  : std_logic;

begin

    -- Inversion du reset actif bas de la carte en reset actif haut pour les modules
    reset_int <= not RESET_N;

	 -- Connexion directe des KEYs (suppose absence de rebonds ou gestion interne)
    start_pulse_sync <= not KEY(0); -- KEY0 -> start 
    valid_pulse_sync <= not KEY(1); -- KEY1 -> valid 
    level_pulse_sync <= not KEY(2); -- KEY2 -> level 
    mode_pulse_sync  <= not KEY(3); -- KEY3 -> mode

    -- =========================================================================
    -- Instanciation des Composants
    -- =========================================================================

    -- Contrôleur Principal
    controller_inst : simon_controller
        generic map ( N_MAX => 10 ) -- Assurez-vous que N_MAX est cohérent partout
        port map (
            clk              => CLOCK_50,
            reset            => reset_int,
            start_pulse      => start_pulse_sync,
            valid_pulse      => valid_pulse_sync,
            mode_pulse		 => mode_pulse_sync,  -- Connecté
            level_pulse      => level_pulse_sync, -- Connecté
            send_valid       => send_valid,
            show_valid       => show_valid,
            read_valid       => read_valid,
            latch_valid      => latch_valid,
            compare_valid    => compare_valid,
            led_game_valid   => led_game_valid,
            match_error      => match_error,
            mode             => current_mode,
            level 			 => std_logic_vector(current_level),
            on_off_times 	 => level_on_off_times,-- Reçoit les temps du level_controller (pour mode Flash éventuel)
            send_command 	 => send_command,
            show_command     => show_command,
            read_command     => read_command,
            latch_command    => latch_command,
            compare_command  => compare_command,
            score_command    => score_command,
            level_command    => level_command,    -- Commande vers level_controller
            mode_command     => mode_command,     -- Commande vers mode_controller
            led_game_command => led_game_command, -- Commande vers led_game_state
            index            => index_ctrl,
            step             => step_ctrl,
            score_o          => score_ctrl,
            game_over_o      => game_over_ctrl
        );

    -- Générateur de séquence (ROM)
    hard_seq_inst : hard_seq_generator
        generic map ( N_MAX => 10 )
        port map (
            clk          => CLOCK_50,
            reset        => reset_int,
            send_command => send_command,
            index        => index_ctrl,
            send_valid   => send_valid,
            value_o      => seq_value
        );

    -- Afficheur de séquence LED
    led_driver_inst : led_seq_generator
        port map (
            clk          => CLOCK_50,
            reset        => reset_int,
            show_command => show_command,
            seq_value    => seq_value,
            on_off_times => level_on_off_times, -- !! Connecté à la sortie du level_controller !!
            show_valid   => show_valid,
            led_o        => led_o_seq
        );

    -- Lecteur de Switches
    sw_reader_inst : sw_reader
        port map (
            clk          => CLOCK_50,
            reset        => reset_int,
            read_command => read_command,
            sw_i         => SW, -- Connecté aux entrées SW de la carte
            read_valid   => read_valid,
            sw_index     => sw_index
        );

    -- Comparateur
    comparator_inst : sw_seq_comparator
        generic map ( MAX_SEQ_LENGTH => 10 )
        port map (
            clk             => CLOCK_50,
            reset           => reset_int,
            latch_command   => latch_command,
            index           => index_ctrl,
            seq_value       => seq_value,
            latch_valid     => latch_valid,
            compare_command => compare_command,
            step            => step_ctrl,
            sw_index        => sw_index,
            compare_valid   => compare_valid,
            match_error     => match_error
        );

    -- Gestion du niveau (!! Mis à jour !!)
    level_ctrl_inst : level_controller
        port map (
            clk           => CLOCK_50,
            reset         => reset_int,
            level_command => level_command, -- Renommé pour correspondre
            level         => current_level,
            on_off_times  => level_on_off_times -- Nouvelle sortie
        );

    -- Gestion du mode (!! Mis à jour !!)
    mode_ctrl_inst : mode_controller
        port map (
            clk          => CLOCK_50,
            reset        => reset_int,
            mode_command => mode_command, -- Renommé pour correspondre
            mode         => current_mode
        );

    -- Mémoire du meilleur score
    score_mem_inst : score_mem
        port map (
            clk           => CLOCK_50,
            reset         => reset_int,
            score_command => score_command,
            score         => score_ctrl,
            best_o        => best_score
        );

    -- Afficheur 7-Segments
    hex_driver_inst : hex_driver
        port map (
            score       => score_ctrl,
            best_score  => best_score,
            level       => current_level,
            mode        => current_mode,
            HEX5        => HEX5, -- Connecté aux sorties de la carte
            HEX4        => HEX4, -- Connecté aux sorties de la carte
            HEX3        => HEX3, -- Connecté aux sorties de la carte
            HEX2        => HEX2, -- Connecté aux sorties de la carte
            HEX1        => HEX1, -- Connecté aux sorties de la carte
            HEX0        => HEX0  -- Connecté aux sorties de la carte
        );

     -- Animation LED fin de partie
    led_game_inst : led_game_state
        port map (
            clk              => CLOCK_50,
            reset            => reset_int,
            led_game_command => led_game_command,
            game_over        => game_over_ctrl,
            led_o            => led_o_game,
            led_game_valid   => led_game_valid
        );

    -- =========================================================================
    -- Logique de sortie LED (multiplexage)
    -- =========================================================================
    -- Processus pour déterminer si l'animation de fin de partie est active
    animation_fsm_process: process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if reset_int = '1' then
                 animation_active <= '0';
            elsif led_game_command = '1' then
                 animation_active <= '1';
            elsif led_game_valid = '1' then -- L'animation se termine quand le valid arrive
                 animation_active <= '0';
            end if;
            -- Si aucune condition n'est remplie, animation_active garde sa valeur.
        end if;
    end process;

    -- Multiplexeur pour la sortie LEDR
    LEDR <= led_o_game when animation_active = '1' else led_o_seq;

end architecture structural;
