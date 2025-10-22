library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity led_game_state is
    Port (
        clk              : in  std_logic;
        reset            : in  std_logic;
        led_game_command : in  std_logic;
        game_over        : in  std_logic;
        led_o            : out std_logic_vector(9 downto 0);
        led_game_valid   : out std_logic
    );
end entity led_game_state;

architecture Behavioral of led_game_state is

    -- Type pour la machine à états
    type state_type is (S_IDLE, S_ANIMATING, S_DONE);
    signal state : state_type := S_IDLE;

    -- Constantes pour les temporisations
    constant BLINK_DURATION   : natural := 12_500_000; -- ~250ms à 50MHz
    constant CHENILLARD_SPEED : natural := 2_500_000;  -- ~50ms à 50MHz

    -- Signaux internes pour la logique de l'animation
    signal win_loss_reg   : std_logic := '0';
    signal timer_reg      : natural range 0 to BLINK_DURATION;
    signal repetition_reg : unsigned(2 downto 0);
    signal position_reg   : unsigned(3 downto 0);
    signal leds_on_reg    : std_logic := '0';
    
    -- *** CORRECTION : Signal interne pour piloter les LEDs ***
    signal led_o_reg      : std_logic_vector(9 downto 0);

begin

    -- =========================================================================
    -- PROCESSUS UNIQUE POUR TOUTE LA LOGIQUE SÉQUENTIELLE
    -- =========================================================================
    main_process: process(clk, reset)
        variable led_chenillard : std_logic_vector(9 downto 0);
    begin
        if reset = '1' then
            state          <= S_IDLE;
            timer_reg      <= 0;
            led_game_valid <= '0';
            leds_on_reg    <= '0';
            position_reg   <= (others => '0');
            led_o_reg      <= (others => '0'); -- On pilote le signal interne

        elsif rising_edge(clk) then
            
            case state is
                when S_IDLE =>
                    led_game_valid <= '0';
                    led_o_reg      <= (others => '0');
                    if led_game_command = '1' then
                        state         <= S_ANIMATING;
                        win_loss_reg  <= game_over;
                        timer_reg     <= 0;
                        if game_over = '1' then -- Défaite
                            repetition_reg <= to_unsigned(6, 3);
                            leds_on_reg    <= '1';
                            led_o_reg      <= (others => '1'); -- Allume les LEDs
                        else -- Victoire
                            repetition_reg <= to_unsigned(2, 3);
                            position_reg   <= (others => '0');
                            led_chenillard := (others => '0');
                            led_chenillard(0) := '1';
                            led_o_reg      <= led_chenillard; -- Allume la première LED
                        end if;
                    end if;

                when S_ANIMATING =>
                    if (win_loss_reg = '1' and timer_reg = BLINK_DURATION - 1) or 
                       (win_loss_reg = '0' and timer_reg = CHENILLARD_SPEED - 1) then
                        
                        timer_reg <= 0;
                        if win_loss_reg = '1' then -- Logique de défaite (clignotement)
                            leds_on_reg    <= not leds_on_reg;
                            repetition_reg <= repetition_reg - 1;
                            if leds_on_reg = '1' then led_o_reg <= (others => '0');
                            else led_o_reg <= (others => '1'); end if;
                        else -- Logique de victoire (chenillard)
                            if position_reg = 9 then
                                position_reg   <= (others => '0');
                                repetition_reg <= repetition_reg - 1;
                            else
                                position_reg <= position_reg + 1;
                            end if;
                            
                            led_chenillard := (others => '0');
                            if position_reg < 9 then
                                led_chenillard(to_integer(position_reg + 1)) := '1';
                            else 
                                led_chenillard(0) := '1';
                            end if;
                            led_o_reg <= led_chenillard;
                        end if;

                        if repetition_reg = 1 then
                            state          <= S_DONE;
                            led_game_valid <= '1';
                        end if;
                    else
                        timer_reg <= timer_reg + 1;
                    end if;
                
                when S_DONE =>
                    led_game_valid <= '1';
                    if led_game_command = '0' then
                        state          <= S_IDLE;
                        led_game_valid <= '0';
                    end if;
            end case;
        end if;
    end process main_process;

    -- Affectation concurrente finale vers le port de sortie
    led_o <= led_o_reg;

end architecture Behavioral;
