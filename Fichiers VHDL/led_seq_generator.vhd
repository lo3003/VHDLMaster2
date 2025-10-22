library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================================
-- ENTITY: led_seq_generator
-- DESCRIPTION: Version finale et robuste. Gère le clignotement d'une LED
--              (un cycle ON puis OFF) en utilisant une méthode de comptage
--              fiable pour la synthèse matérielle.
-- =============================================================================
entity led_seq_generator is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        show_command : in  std_logic;
        seq_value    : in  unsigned(3 downto 0);
        on_off_times : in  std_logic_vector(9 downto 0);
        show_valid   : out std_logic;
        led_o        : out std_logic_vector(9 downto 0)
    );
end entity;

architecture rtl of led_seq_generator is

    -- États de la machine pour gérer le cycle de clignotement
    type state_type is (S_IDLE, S_ON, S_OFF);
    signal state : state_type := S_IDLE;

    -- Compteur rapide (prescaler) pour générer un "tick" toutes les 100ms
    constant TICKS_100MS : natural := 5_000_000; -- 50MHz / 10
    signal prescaler_cnt : natural range 0 to TICKS_100MS - 1;

    -- Compteur lent qui compte les "ticks" de 100ms
    signal tick_cnt : unsigned(4 downto 0);

begin

    main_proc: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state         <= S_IDLE;
                prescaler_cnt <= 0;
                tick_cnt      <= (others => '0');
                led_o         <= (others => '0');
                show_valid    <= '0';
            else
                -- La sortie 'show_valid' est une impulsion, on la remet à '0' par défaut
                show_valid <= '0';

                case state is
                    
                    -- ETAT 1: Attend la commande de démarrage
                    when S_IDLE =>
                        led_o <= (others => '0');
                        if show_command = '1' then
                            state         <= S_ON;
                            prescaler_cnt <= 0;
                            tick_cnt      <= (others => '0');
                            -- Allumer la LED immédiatement
                            if to_integer(seq_value) < 10 then
                                led_o(to_integer(seq_value)) <= '1';
                            end if;
                        end if;

                    -- ETAT 2: Période ON (LED allumée)
                    when S_ON =>
                        if prescaler_cnt = TICKS_100MS - 1 then
                            prescaler_cnt <= 0;
                            if tick_cnt = unsigned(on_off_times(4 downto 0)) - 1 then
                                -- Fin de la période ON
                                state    <= S_OFF;
                                tick_cnt <= (others => '0');
                                led_o    <= (others => '0'); -- Eteindre la LED
                            else
                                tick_cnt <= tick_cnt + 1;
                            end if;
                        else
                            prescaler_cnt <= prescaler_cnt + 1;
                        end if;
                        
                    -- ETAT 3: Période OFF (LED éteinte)
                    when S_OFF =>
                        if prescaler_cnt = TICKS_100MS - 1 then
                            prescaler_cnt <= 0;
                            if tick_cnt = unsigned(on_off_times(9 downto 5)) - 1 then
                                -- Fin de la période OFF, cycle terminé
                                state      <= S_IDLE;
                                show_valid <= '1'; -- Envoyer l'impulsion de validation !
                            else
                                tick_cnt <= tick_cnt + 1;
                            end if;
                        else
                            prescaler_cnt <= prescaler_cnt + 1;
                        end if;

                end case;
            end if;
        end if;
    end process main_proc;

end architecture rtl;
