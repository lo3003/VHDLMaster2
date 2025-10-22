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

    -- *** MODIFIÉ : Constantes en type unsigned ***
    constant BLINK_DURATION   : unsigned(23 downto 0) := to_unsigned(12_500_000, 24);
    constant CHENILLARD_SPEED : unsigned(23 downto 0) := to_unsigned(2_500_000, 24);

    -- *** MODIFIÉ : Signaux en type unsigned ***
    signal is_active_reg  : std_logic := '0';
    signal win_loss_reg   : std_logic := '0';
    signal timer_reg      : unsigned(23 downto 0);
    signal repetition_reg : unsigned(2 downto 0);
    signal position_reg   : unsigned(3 downto 0);
    signal leds_on_reg    : std_logic := '0';

begin

    -- Processus unique pour gérer toute la logique
    animation_process: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                is_active_reg  <= '0';
                timer_reg      <= (others => '0');
                led_game_valid <= '0';
                leds_on_reg    <= '0';
                position_reg   <= (others => '0');

            -- Déclenchement de l'animation
            elsif led_game_command = '1' and is_active_reg = '0' then
                is_active_reg <= '1';
                win_loss_reg  <= game_over;
                timer_reg     <= (others => '0');
                
                if game_over = '1' then -- Défaite
                    repetition_reg <= to_unsigned(6, 3);
                    leds_on_reg    <= '1';
                else -- Victoire
                    repetition_reg <= to_unsigned(2, 3);
                    position_reg   <= (others => '0');
                end if;
            
            -- Déroulement de l'animation en cours
            elsif is_active_reg = '1' then
                led_game_valid <= '0';

                if (win_loss_reg = '1' and timer_reg = BLINK_DURATION - 1) or 
                   (win_loss_reg = '0' and timer_reg = CHENILLARD_SPEED - 1) then
                    
                    timer_reg <= (others => '0');
                    
                    if win_loss_reg = '1' then -- Défaite
                        leds_on_reg    <= not leds_on_reg;
                        repetition_reg <= repetition_reg - 1;
                    else -- Victoire
                        if position_reg = 9 then
                            position_reg   <= (others => '0');
                            repetition_reg <= repetition_reg - 1;
                        else
                            position_reg <= position_reg + 1;
                        end if;
                    end if;

                    -- Condition de fin
                    if repetition_reg = 1 then
                        is_active_reg  <= '0';
                        led_game_valid <= '1';
                    end if;
                
                else
                    timer_reg <= timer_reg + 1;
                end if;
            
            else
                led_game_valid <= '0';
            end if;
        end if;
    end process animation_process;

    -- =========================================================================
    -- LOGIQUE DE SORTIE
    -- =========================================================================
    output_logic: process(is_active_reg, win_loss_reg, leds_on_reg, position_reg)
        variable led_chenillard : std_logic_vector(9 downto 0);
    begin
        if is_active_reg = '0' then
            led_o <= (others => '0');
        else
            if win_loss_reg = '1' then -- Défaite (clignotement)
                if leds_on_reg = '1' then
                    led_o <= (others => '1');
                else
                    led_o <= (others => '0');
                end if;
            else -- Victoire (chenillard)
                led_chenillard := (others => '0');
                -- On a besoin de convertir 'position_reg' en entier pour l'utiliser comme index
                led_chenillard(to_integer(position_reg)) := '1';
                led_o <= led_chenillard;
            end if;
        end if;
    end process output_logic;

end architecture Behavioral;
