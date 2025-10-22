library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sw_seq_comparator is
    generic (
        MAX_SEQ_LENGTH : integer := 10
    );
    Port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        latch_command   : in  std_logic;
        index           : in  unsigned(3 downto 0);
        seq_value       : in  unsigned(3 downto 0);
        latch_valid     : out std_logic;
        compare_command : in  std_logic;
        sw_index        : in  unsigned(3 downto 0);
        compare_valid   : out std_logic;
        match_error     : out std_logic
    );
end entity sw_seq_comparator;

architecture Behavioral of sw_seq_comparator is

    type T_SEQ_MEMORY is array (0 to MAX_SEQ_LENGTH - 1) of unsigned(3 downto 0);
    signal seq_mem_reg      : T_SEQ_MEMORY;
    
begin

    main_process: process(clk, reset)
    begin
        if reset = '1' then
            seq_mem_reg   <= (others => (others => '0'));
            latch_valid   <= '0';
            compare_valid <= '0';
            match_error   <= '0';
        elsif rising_edge(clk) then
            -- Logique pour LATCH (mémorisation)
            if latch_command = '1' then
                if to_integer(index) < MAX_SEQ_LENGTH then
                    seq_mem_reg(to_integer(index)) <= seq_value;
                end if;
                latch_valid <= '1';
            else
                latch_valid <= '0';
            end if;
            
            -- Logique pour COMPARE (comparaison)
            if compare_command = '1' then
                if to_integer(index) < MAX_SEQ_LENGTH and sw_index /= seq_mem_reg(to_integer(index)) then
                    match_error <= '1'; -- Erreur détectée
                else
                    match_error <= '0'; -- Pas d'erreur
                end if;
                compare_valid <= '1';
            else
                compare_valid <= '0';
                -- Si pas de commande, on ne change pas l'état de match_error pour éviter un latch
                -- La valeur est mémorisée par le registre implicite du signal de sortie 'match_error'
            end if;

            -- Si aucune commande n'est active, on s'assure que les valid sont bas.
            if compare_command = '0' and latch_command = '0' then
                 -- On ne touche pas à match_error pour qu'il conserve sa valeur
            end if;

        end if;
    end process main_process;
    
end architecture Behavioral;
