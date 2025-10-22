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
        CLOCK_50 : in  std_logic;
        RESET_N  : in  std_logic;

        -- Entrées utilisateur
        SW       : in  std_logic_vector(9 downto 0);
        KEY      : in  std_logic_vector(3 downto 0);

        -- Sorties
        LEDR     : out std_logic_vector(9 downto 0);
        HEX0     : out std_logic_vector(6 downto 0);
        HEX1     : out std_logic_vector(6 downto 0);
        HEX2     : out std_logic_vector(6 downto 0);
        HEX3     : out std_logic_vector(6 downto 0);
        HEX4     : out std_logic_vector(6 downto 0);
        HEX5     : out std_logic_vector(6 downto 0)
    );
end entity simon;

architecture structural of simon is

    -- =========================================================================
    -- Déclarations des Composants
    -- =========================================================================

    -- *** AJOUT DE LA DÉCLARATION DU DEBOUNCER ***
    component debouncer is
        generic (
            CLK_FREQ_HZ   : natural := 50_000_000;
            DEBOUNCE_MS   : natural := 20
        );
        Port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            btn_in     : in  std_logic;
            btn_pulse  : out std_logic
        );
    end component;

    component hard_seq_generator is
        generic ( N_MAX : integer := 10 );
        Port (
            clk          : in  std_logic; reset        : in  std_logic;
            send_command : in  std_logic; index        : in  unsigned(3 downto 0);
            send_valid   : out std_logic; value_o      : out unsigned(3 downto 0)
        );
    end component;

    component led_seq_generator is
        Port (
            clk          : in  std_logic; reset        : in  std_logic;
            show_command : in  std_logic; seq_value    : in  unsigned(3 downto 0);
            on_off_times : in  std_logic_vector(9 downto 0);
            show_valid   : out std_logic; led_o        : out std_logic_vector(9 downto 0)
        );
    end component;

    component sw_reader is
        Port (
            clk          : in  std_logic; reset        : in  std_logic;
            read_command : in  std_logic; sw_i         : in  std_logic_vector(9 downto 0);
            read_valid   : out std_logic; sw_index     : out unsigned(3 downto 0)
        );
    end component;

    component sw_seq_comparator is
        generic ( MAX_SEQ_LENGTH : integer := 10 );
        Port (
            clk             : in  std_logic; reset           : in  std_logic;
            latch_command   : in  std_logic; index           : in  unsigned(3 downto 0);
            seq_value       : in  unsigned(3 downto 0); latch_valid     : out std_logic;
            compare_command : in  std_logic; sw_index        : in  unsigned(3 downto 0);
            compare_valid   : out std_logic; match_error     : out std_logic
        );
    end component;

    component simon_controller is
        generic ( N_MAX : integer := 10 );
        Port (
            clk : in std_logic; reset : in std_logic; start_pulse : in std_logic;
            valid_pulse : in std_logic; mode_pulse : in std_logic; level_pulse : in std_logic;
            send_valid : in std_logic; show_valid : in std_logic; read_valid : in std_logic;
            latch_valid : in std_logic; compare_valid : in std_logic; led_game_valid : in std_logic;
            match_error : in std_logic; mode : in std_logic; level : in std_logic_vector(1 downto 0);
            on_off_times : in std_logic_vector(9 downto 0); send_command : out std_logic;
            show_command : out std_logic; read_command : out std_logic; latch_command : out std_logic;
            compare_command : out std_logic; score_command : out std_logic; level_command : out std_logic;
            mode_command : out std_logic; led_game_command : out std_logic;
            index : out unsigned(3 downto 0); step : out unsigned(3 downto 0);
            score_o : out unsigned(6 downto 0); game_over_o : out std_logic
        );
    end component;

    component hex_driver is
        Port (
            score : in unsigned(6 downto 0); best_score : in unsigned(6 downto 0);
            level : in unsigned(1 downto 0); mode : in std_logic;
            HEX5, HEX4 : out std_logic_vector(6 downto 0);
            HEX3 : out std_logic_vector(6 downto 0); HEX2 : out std_logic_vector(6 downto 0);
            HEX1, HEX0 : out std_logic_vector(6 downto 0)
        );
    end component;

    component score_mem is
        Port (
            clk : in std_logic; reset : in std_logic;
            score_command : in std_logic; score : in unsigned(6 downto 0);
            best_o : out unsigned(6 downto 0)
        );
    end component;

    component level_controller is
        Port (
            clk : in std_logic; reset : in std_logic;
            level_command : in std_logic; level : out unsigned(1 downto 0);
            on_off_times : out std_logic_vector(9 downto 0)
        );
    end component;

    component mode_controller is
        Port (
            clk : in std_logic; reset : in std_logic;
            mode_command : in std_logic; mode : out std_logic
        );
    end component;

    component led_game_state is
        Port (
            clk : in std_logic; reset : in std_logic;
            led_game_command : in std_logic; game_over : in std_logic;
            led_o : out std_logic_vector(9 downto 0);
            led_game_valid : out std_logic
        );
    end component;

    -- (Signaux Internes d'Interconnexion inchangés)
    signal reset_int, start_pulse_sync, valid_pulse_sync, level_pulse_sync, mode_pulse_sync : std_logic;
    signal send_command, show_command, read_command, latch_command, compare_command, score_command, level_command, mode_command, led_game_command : std_logic;
    signal index_ctrl, step_ctrl : unsigned(3 downto 0);
    signal score_ctrl : unsigned(6 downto 0);
    signal game_over_ctrl : std_logic;
    signal send_valid, show_valid, read_valid, latch_valid, compare_valid, led_game_valid, match_error : std_logic;
    signal seq_value, sw_index : unsigned(3 downto 0);
    signal current_level : unsigned(1 downto 0);
    signal current_mode : std_logic;
    signal best_score : unsigned(6 downto 0);
    signal level_on_off_times : std_logic_vector(9 downto 0);
    signal led_o_seq, led_o_game : std_logic_vector(9 downto 0);
    signal animation_active : std_logic := '0';

begin

    reset_int <= not RESET_N;
    
    -- *** MODIFIÉ : Connexions directes remplacées par des debouncers ***
    debounce_start_inst : debouncer
        port map ( clk => CLOCK_50, reset => reset_int, btn_in => KEY(0), btn_pulse => start_pulse_sync );

    debounce_valid_inst : debouncer
        port map ( clk => CLOCK_50, reset => reset_int, btn_in => KEY(1), btn_pulse => valid_pulse_sync );

    debounce_level_inst : debouncer
        port map ( clk => CLOCK_50, reset => reset_int, btn_in => KEY(2), btn_pulse => level_pulse_sync );

    debounce_mode_inst : debouncer
        port map ( clk => CLOCK_50, reset => reset_int, btn_in => KEY(3), btn_pulse => mode_pulse_sync );

    -- (Le reste des instanciations est inchangé)
    controller_inst : simon_controller
        port map (
            clk => CLOCK_50, reset => reset_int, start_pulse => start_pulse_sync, valid_pulse => valid_pulse_sync,
            mode_pulse => mode_pulse_sync, level_pulse => level_pulse_sync, send_valid => send_valid,
            show_valid => show_valid, read_valid => read_valid, latch_valid => latch_valid, compare_valid => compare_valid,
            led_game_valid => led_game_valid, match_error => match_error, mode => current_mode, level => std_logic_vector(current_level),
            on_off_times => level_on_off_times, send_command => send_command, show_command => show_command,
            read_command => read_command, latch_command => latch_command, compare_command => compare_command,
            score_command => score_command, level_command => level_command, mode_command => mode_command,
            led_game_command => led_game_command, index => index_ctrl, step => step_ctrl,
            score_o => score_ctrl, game_over_o => game_over_ctrl
        );

    hard_seq_inst : hard_seq_generator
        port map (
            clk => CLOCK_50, reset => reset_int, send_command => send_command,
            index => index_ctrl, send_valid => send_valid, value_o => seq_value
        );

    led_driver_inst : led_seq_generator
        port map (
            clk => CLOCK_50, reset => reset_int, show_command => show_command,
            seq_value => seq_value, on_off_times => level_on_off_times,
            show_valid => show_valid, led_o => led_o_seq
        );

    sw_reader_inst : sw_reader
        port map (
            clk => CLOCK_50, reset => reset_int, read_command => read_command,
            sw_i => SW, read_valid => read_valid, sw_index => sw_index
        );

    comparator_inst : sw_seq_comparator
        port map (
            clk => CLOCK_50, reset => reset_int, latch_command => latch_command,
            index => index_ctrl, seq_value => seq_value, latch_valid => latch_valid,
            compare_command => compare_command, sw_index => sw_index,
            compare_valid => compare_valid, match_error => match_error
        );

    level_ctrl_inst : level_controller
        port map (
            clk => CLOCK_50, reset => reset_int, level_command => level_command,
            level => current_level, on_off_times => level_on_off_times
        );

    mode_ctrl_inst : mode_controller
        port map (
            clk => CLOCK_50, reset => reset_int, mode_command => mode_command,
            mode => current_mode
        );

    score_mem_inst : score_mem
        port map (
            clk => CLOCK_50, reset => reset_int, score_command => score_command,
            score => score_ctrl, best_o => best_score
        );

    hex_driver_inst : hex_driver
        port map (
            score => score_ctrl, best_score => best_score, level => current_level,
            mode => current_mode, HEX5 => HEX5, HEX4 => HEX4, HEX3 => HEX3,
            HEX2 => HEX2, HEX1 => HEX1, HEX0 => HEX0
        );

    led_game_inst : led_game_state
        port map (
            clk => CLOCK_50, reset => reset_int, led_game_command => led_game_command,
            game_over => game_over_ctrl, led_o => led_o_game, led_game_valid => led_game_valid
        );

    -- Logique de sortie LED (multiplexage)
    animation_fsm_process: process(CLOCK_50, reset_int)
    begin
        if reset_int = '1' then
             animation_active <= '0';
        elsif rising_edge(CLOCK_50) then
            if led_game_command = '1' then
                 animation_active <= '1';
            elsif led_game_valid = '1' then
                 animation_active <= '0';
            end if;
        end if;
    end process;

    LEDR <= led_o_game when animation_active = '1' else led_o_seq;

end architecture structural;
