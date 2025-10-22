library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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
    
    -- *** CORRECTION : Ajout d'un registre de sortie pour garantir la stabilité ***
    signal sw_index_reg  : unsigned(3 downto 0);

begin

    main_fsm: process(clk, reset)
        variable current_index : unsigned(3 downto 0);
        variable is_valid_input : boolean;
    begin
        if reset = '1' then
            state <= S_IDLE;
            read_valid <= '0';
            sw_index_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- read_valid est une impulsion, donc '0' par défaut
            read_valid <= '0';

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

            case state is
                when S_IDLE =>
                    if read_command = '1' and is_valid_input then
                        state <= S_DETECTED;
                        stored_index <= current_index;
                    end if;
                    
                when S_DETECTED =>
                    if sw_i = "0000000000" then
                        state <= S_IDLE;
                        -- On met à jour le registre de sortie au moment de la validation
                        sw_index_reg <= stored_index;
                        read_valid <= '1';
                    end if;
            end case;
            
            if read_command = '0' then
                state <= S_IDLE;
            end if;
        end if;
    end process main_fsm;

    -- La sortie est maintenant connectée au registre stable
    sw_index <= sw_index_reg;

end architecture Behavioral;
