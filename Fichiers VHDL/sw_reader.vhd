library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================================
-- ENTITY: sw_reader (MODIFIÉ)
-- DESCRIPTION:
--   Ce module attend qu'un seul switch soit activé, mémorise sa valeur,
--   attend que TOUS les switches soient relâchés, puis envoie la valeur
--   mémorisée avec une impulsion de validation.
-- =============================================================================
entity sw_reader is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        read_command : in  std_logic;
        sw_i         : in  std_logic_vector(9 downto 0);
        read_valid   : out std_logic;
        sw_index     : out unsigned(3 downto 0)
    );
end entity sw_reader;

architecture Behavioral of sw_reader is

    type state_type is (S_IDLE, S_DETECTED);
    signal state         : state_type := S_IDLE;
    signal stored_index  : unsigned(3 downto 0);
    
begin

    -- Processus principal gérant la lecture et la validation
    main_fsm: process(clk)
        variable current_index : unsigned(3 downto 0);
        variable is_valid_input : boolean;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= S_IDLE;
                read_valid <= '0';
                sw_index <= (others => '0');
            else
                -- L'impulsion de validation est à '0' par défaut
                read_valid <= '0';

                -- Encodeur combinatoire interne au processus
                case sw_i is
                    when "0000000001" => current_index := to_unsigned(0, 4); is_valid_input := true;
                    when "0000000010" => current_index := to_unsigned(1, 4); is_valid_input := true;
                    when "0000000100" => current_index := to_unsigned(2, 4); is_valid_input := true;
                    when "0000001000" => current_index := to_unsigned(3, 4); is_valid_input := true;
                    when "0000010000" => current_index := to_unsigned(4, 4); is_valid_input := true;
                    when "0000100000" => current_index := to_unsigned(5, 4); is_valid_input := true;
                    when "0001000000" => current_index := to_unsigned(6, 4); is_valid_input := true;
                    when "0010000000" => current_index := to_unsigned(7, 4); is_valid_input := true;
                    when "0100000000" => current_index := to_unsigned(8, 4); is_valid_input := true;
                    when "1000000000" => current_index := to_unsigned(9, 4); is_valid_input := true;
                    when others       => is_valid_input := false;
                end case;

                -- Machine à états pour la logique de lecture et de relâchement
                case state is
                    -- ETAT 1: Attente d'une commande et d'un switch valide
                    when S_IDLE =>
                        if read_command = '1' and is_valid_input then
                            state <= S_DETECTED;
                            stored_index <= current_index; -- On mémorise la valeur
                        end if;

                    -- ETAT 2: Un switch a été détecté, on attend qu'il soit relâché
                    when S_DETECTED =>
                        if sw_i = "0000000000" then
                            state <= S_IDLE;       -- Retour à l'état initial
                            sw_index <= stored_index;  -- On sort la valeur mémorisée
                            read_valid <= '1';     -- On envoie l'impulsion !
                        end if;
                end case;
                
                -- Si la commande de lecture est coupée, on revient à l'état initial
                if read_command = '0' then
                    state <= S_IDLE;
                end if;
            end if;
        end if;
    end process main_fsm;

end architecture Behavioral;
