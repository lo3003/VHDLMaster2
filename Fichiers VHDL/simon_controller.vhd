library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simon_controller is
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
end entity;

architecture rtl of simon_controller is
    -- Définition des états de la machine
	type state_type is (
        S_IDLE,
        S_SEND_CMD, S_SEND_WAIT, S_SHOW_LATCH_CMD, S_SHOW_LATCH_WAIT,
        S_READ_SW_CMD, S_READ_SW_WAIT,
        S_COMPARE_CMD, S_COMPARE_WAIT,
        S_GAME_OVER_CMD, S_GAME_OVER_WAIT
    );
	signal state, next_state : state_type;

    -- Signaux internes pour gérer l'état du jeu
    signal current_step  : unsigned(3 downto 0);
	signal current_index : unsigned(3 downto 0);
    signal current_score : unsigned(6 downto 0);
	signal game_over_sig : std_logic;
	
	-- Signaux "next" pour les registres
    signal next_current_step  : unsigned(3 downto 0);
	signal next_current_index : unsigned(3 downto 0);
    signal next_current_score : unsigned(6 downto 0);
	signal next_game_over_sig : std_logic;

begin
    -- Connexion des signaux internes aux ports de sortie
    index       <= current_index;
    step        <= current_step;
    score_o     <= current_score;
    game_over_o <= game_over_sig;

    -- =========================================================================
    -- PROCESS 1: PROCESSUS SÉQUENTIEL (Registres / Mémoire)
    -- =========================================================================
    process(clk, reset)
    begin
        if reset = '0' then
            state         <= S_IDLE;
            current_step  <= (others => '0');
            current_index <= (others => '0');
            current_score <= (others => '0');
            game_over_sig <= '0';
        elsif rising_edge(clk) then
            state         <= next_state;
            current_step  <= next_current_step;
            current_index <= next_current_index;
            current_score <= next_current_score;
            game_over_sig <= next_game_over_sig;
        end if;
    end process;

    -- =========================================================================
    -- PROCESS 2: PROCESSUS COMBINATOIRE (Logique / Cerveau)
    -- =========================================================================
    process(state, start_pulse, mode_pulse, level_pulse, send_valid, show_valid, 
        read_valid, latch_valid, compare_valid, led_game_valid, match_error, 
        current_step, current_index, current_score, game_over_sig)
    begin
        -- Valeurs par défaut pour éviter les latches
        next_state         <= state;
        next_current_step  <= current_step;
        next_current_index <= current_index;
        next_current_score <= current_score; -- On garde le score par défaut
        next_game_over_sig <= game_over_sig;
        
        send_command     <= '0';
        show_command     <= '0';
        read_command     <= '0';
        latch_command    <= '0';
        compare_command  <= '0';
        score_command    <= '0';
        level_command    <= '0';
        mode_command     <= '0';
		led_game_command <= '0';
        
        -- Logique de la machine à états
        case state is
            when S_IDLE =>
                if start_pulse = '1' then
                    next_state         <= S_SEND_CMD;
                    next_current_step  <= to_unsigned(0, 4); -- Niveau 1 (longueur 0+1)
                    next_current_index <= to_unsigned(0, 4);
                    next_game_over_sig <= '0'; -- On part sur une nouvelle partie
                    
                    -- LOGIQUE SCORE: Reset si la partie précédente était un "Game Over"
                    if game_over_sig = '1' then 
                        next_current_score <= to_unsigned(0, 7);
                    end if;
                elsif mode_pulse = '1' then 
                    mode_command <= '1'; 
                elsif level_pulse = '1' then 
                    level_command <= '1';
                end if;

            when S_SEND_CMD =>
                send_command <= '1';
                next_state   <= S_SEND_WAIT;
            when S_SEND_WAIT =>
                if send_valid = '1' then 
                    next_state <= S_SHOW_LATCH_CMD;
                end if;
				
            when S_SHOW_LATCH_CMD =>
                show_command  <= '1';
                latch_command <= '1';
                next_state    <= S_SHOW_LATCH_WAIT;
            when S_SHOW_LATCH_WAIT =>
                if show_valid = '1' and latch_valid = '1' then
                    if current_index < current_step then
                        next_state         <= S_SEND_CMD;
                        next_current_index <= current_index + 1;
                    else
                        next_state         <= S_READ_SW_CMD;
                        next_current_index <= to_unsigned(0, 4);
                    end if;
                end if;
				
            when S_READ_SW_CMD =>
                read_command <= '1';
                next_state   <= S_READ_SW_WAIT;
            when S_READ_SW_WAIT =>
                if read_valid = '1' then 
                    next_state <= S_COMPARE_CMD;
                end if;
				
            when S_COMPARE_CMD =>
                compare_command <= '1';
                next_state      <= S_COMPARE_WAIT;
            when S_COMPARE_WAIT =>
                if compare_valid = '1' then 
                    if match_error = '1' then 
                        -- PARTIE PERDUE
                        next_state         <= S_GAME_OVER_CMD;
                        next_game_over_sig <= '1'; -- '1' = Perdu
                        next_current_step  <= to_unsigned(0, 4);
                        next_current_index <= to_unsigned(0, 4);
                    elsif current_index < current_step then 
                        -- Étape suivante du niveau
                        next_state         <= S_READ_SW_CMD;
                        next_current_index <= current_index + 1;
                    else 
                        -- NIVEAU RÉUSSI
                        next_current_index <= to_unsigned(0, 4);
                        if to_integer(current_step) < N_MAX-1 then 
                            -- On passe au niveau suivant
                            next_current_step <= current_step + 1;
                            next_state        <= S_SEND_CMD;
                        else 
                            -- PARTIE GAGNÉE
                            next_state         <= S_GAME_OVER_CMD;
                            next_game_over_sig <= '0'; -- '0' = Gagné
                            next_current_score <= current_score + 1; -- On incrémente le score
                            next_current_step  <= to_unsigned(0, 4);
                        end if;
                    end if;
                end if;
				
            when S_GAME_OVER_CMD => 
                led_game_command <= '1';
                score_command    <= '1';
                next_state       <= S_GAME_OVER_WAIT;
				
            when S_GAME_OVER_WAIT => 
                if led_game_valid = '1' then 
                    next_state <= S_IDLE; 
                end if;
        end case;
    end process;
	 
end architecture;
