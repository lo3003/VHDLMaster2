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
    signal match_error_reg  : std_logic;
    
begin

    -- =========================================================================
    -- PROCESSUS UNIQUE ET ROBUSTE
    -- =========================================================================
    main_process: process(clk)
    begin
        if rising_edge(clk) then
            -- === Priorité n°1 : Le Reset ===
            if reset = '1' then
                seq_mem_reg   <= (others => (others => '0'));
                match_error_reg <= '0';
                latch_valid   <= '0';
                compare_valid <= '0';
            else
                -- === Actions par défaut à chaque cycle ===
                -- Les confirmations sont des impulsions, donc on les remet à '0' par défaut.
                latch_valid   <= '0';
                compare_valid <= '0';
                
                -- === Priorité n°2 : Commande de mémorisation (latch) ===
                if latch_command = '1' then
                    seq_mem_reg(to_integer(index)) <= seq_value;
                    latch_valid <= '1'; -- On active la confirmation pour le prochain cycle
                end if;
                
                -- === Priorité n°3 : Commande de comparaison ===
                if compare_command = '1' then
                    -- La comparaison se fait ici, de manière synchrone et sûre
                    if sw_index /= seq_mem_reg(to_integer(index)) then
                        match_error_reg <= '1';
                    else
                        match_error_reg <= '0';
                    end if;
                    compare_valid <= '1'; -- On active la confirmation pour le prochain cycle
                end if;
            end if;
        end if;
    end process main_process;

    -- La sortie 'match_error' est maintenant directement connectée au registre interne.
    -- Cela garantit que la valeur reste stable jusqu'à la prochaine comparaison.
    match_error <= match_error_reg;
    
end architecture Behavioral;
