library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_hard_seq_generator is
end tb_hard_seq_generator;

architecture behavior of tb_hard_seq_generator is

    -- Component Declaration for the Unit Under Test (UUT)
    component hard_seq_generator is
        generic ( N_MAX : integer := 10 );
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            send_command : in  std_logic;
            index        : in  unsigned(3 downto 0);
            send_valid   : out std_logic;
            value_o      : out unsigned(3 downto 0)
        );
    end component;

    -- Séquence attendue pour la vérification (miroir de celle du UUT)
    type seq_array is array (0 to 9) of unsigned(3 downto 0);
    constant expected_sequence : seq_array := (
        to_unsigned(0, 4),  
        to_unsigned(1, 4),  
        to_unsigned(2, 4),
        to_unsigned(8, 4),
        to_unsigned(9, 4),
		  to_unsigned(1, 4),  
        to_unsigned(2, 4),  
        to_unsigned(3, 4),
        to_unsigned(7, 4),
        to_unsigned(8, 4)
    );

    -- Inputs
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    signal index        : unsigned(3 downto 0) := (others => '0');
    signal send_command : std_logic := '0';

    -- Outputs
    signal send_valid   : std_logic;
    signal value_o      : unsigned(3 downto 0);

    -- Clock period definition
    constant CLK_PERIOD : time := 20 ns; -- Horloge de 50 MHz

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: hard_seq_generator
    generic map ( N_MAX => 10 )
    port map (
        clk          => clk,
        reset        => reset,
        send_command => send_command,
        index        => index,
        send_valid   => send_valid, 
        value_o      => value_o
    );

    -- Clock process
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulus process
    process
    begin
        -- 1. Appliquer le reset (actif bas)
        reset <= '1';
        wait for 100 ns;
        
        -- 2. Sortir du reset
        reset <= '0';
        wait for CLK_PERIOD;

        -- 3. Tester chaque index valide
        report "Début du test des index valides...";
        for i in 0 to 9 loop
            -- Positionner l'index à lire
            index <= to_unsigned(i, 4);
            
            -- Envoyer la commande de lecture pour un cycle d'horloge
            send_command <= '1';
            wait for CLK_PERIOD;
            send_command <= '0';
            
            -- Attendre un cycle pour que la sortie soit stable
            wait for CLK_PERIOD;

            -- Vérifier la sortie
            assert value_o = expected_sequence(to_integer(index))
                report "Erreur à l'index " & integer'image(to_integer(index)) & 
							  ": attendu " & integer'image(to_integer(expected_sequence(to_integer(index)))) & 
							  ", obtenu " & integer'image(to_integer(value_o))
                severity error;
        end loop;
        
        report "Fin du test des index valides.";
        
        -- 4. Tester un index hors limite
        report "Début du test des index hors limites...";
        index <= to_unsigned(10, 4); -- Index 5 > N_MAX-1
        send_command <= '1';
        wait for CLK_PERIOD;
        send_command <= '0';
        wait for CLK_PERIOD;
        
        -- Le signal `send_valid` ne devrait pas passer à '1'
        assert send_valid = '0' 
            report "Erreur : send_valid est passé à '1' pour un index hors limite."
            severity error;

        report "Test terminé.";
        
        -- Arrêter la simulation
        wait;
    end process;

end architecture;
