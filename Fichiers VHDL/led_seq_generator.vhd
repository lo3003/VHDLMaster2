library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_seq_generator is
    Port (
        clk       	: in  std_logic;
		  reset			: in  std_logic;
        show_command : in  std_logic;
        seq_value 	: in  unsigned(3 downto 0);
        on_off_times : in  std_logic_vector(9 downto 0);
		  show_valid 	: out  std_logic;
        led_o     	: out std_logic_vector(9 downto 0)
    );
end entity;

architecture rtl of led_seq_generator is
    type state_type is (st_off, st_on);
    signal state : state_type;

    signal prescaler : unsigned(22 downto 0);  -- Compteur pour 100 ms (0 à 4999999)
    signal tick : std_logic := '0';

    signal timer : unsigned(4 downto 0);  -- Compteur par pas de 100 ms pour ON/OFF
	 
	 signal valid : std_logic := '0';
	 
	 signal st_counter : unsigned(1 downto 0);

    constant CLK_FREQ : positive := 50000000;  -- 50 MHz
    constant MS_DIV : positive := CLK_FREQ / 10;  -- 5000000 pour 100 ms

begin
    process(clk,reset)
    begin
		  if reset = '1' or show_command = '0' then
				state <= st_off;
            timer <= (others => '0');
				prescaler <= to_unsigned(4999999,23); -- Compteur initialisé à 4999999 afin de trigger immédiatement un tick
				valid <= '0';
				st_counter <= to_unsigned(0,2);
            led_o <= (others => '0');
        elsif rising_edge(clk) and show_command = '1' then
            -- Prescaler pour générer un tick toutes les 100 ms
            if prescaler = MS_DIV - 1 then
                prescaler <= (others => '0');
                tick <= '1';
            else
                prescaler <= prescaler + 1;
                tick <= '0';
            end if;

            -- Gestion de l'état et du clignotement
				if tick = '1' then
					 if timer = 0 then
						case state is
							 when st_on =>
								   state <= st_off;
								   timer <= unsigned(on_off_times(9 downto 5)) - 1;  -- Chargement OFF_0.1s
								   led_o <= (others => '0');
							 when st_off =>
								   state <= st_on;
									st_counter <= to_unsigned(1,2);
								   timer <= unsigned(on_off_times(4 downto 0)) - 1;  -- Chargement ON_0.1s
								   led_o <= (others => '0');
									if st_counter = to_unsigned(1,2) then
										valid <= '1';
										st_counter <= to_unsigned(0,2);
								   elsif to_integer(seq_value) < 10 then  -- Sécurité
										led_o(to_integer(seq_value)) <= '1';
									end if;
					   end case;
					 else
						timer <= timer - 1;
					 end if;
			   end if;
		  end if;
    end process;
	 
	 show_valid <= valid;
	 
end architecture;
