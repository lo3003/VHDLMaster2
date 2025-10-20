library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hard_seq_generator is
    generic ( N_MAX : integer := 5 );
    Port (
        clk				: in  std_logic;
		  reset			: in  std_logic;
		  send_command	: in  std_logic;
        index 			: in  unsigned(3 downto 0);
		  send_valid	: out std_logic;
        value_o		: out unsigned(3 downto 0)
    );
end entity;

architecture rtl of hard_seq_generator is
    -- Type du tableau pour la séquence
    type seq_array is array (0 to N_MAX-1) of unsigned(3 downto 0);
	 signal valid : std_logic;
    
    -- Séquence fixe codée en dur
    constant sequence : seq_array := (
        to_unsigned(0, 4),  
        to_unsigned(1, 4),  
        to_unsigned(2, 4),
        to_unsigned(8, 4),
        to_unsigned(9, 4)
    );
    
begin
    -- Process synchrone pour lire la ROM
	process(clk, reset)
	begin
		 if reset = '0' then
			  -- Initialise les sorties à un état connu
			  value_o <= (others => '0');
			  send_valid <= '0';
			  valid <= '0';
		 elsif rising_edge(clk) then
			  -- Si une commande est reçue et que l'index est valide
			  if send_command = '1' and to_integer(index) < N_MAX then
					value_o <= sequence(to_integer(index));
					valid <= '1';
					
				-- Valid retourne à 0 après un cycle
			  elsif valid = '1' then
					valid <= '0';
			  end if;
		 end if;
	end process;
	
	send_valid <= valid;
end architecture;
