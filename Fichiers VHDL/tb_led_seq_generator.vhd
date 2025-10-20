library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_seq_generator_tb is
end entity;

architecture test of led_seq_generator_tb is

    -- 1. Déclaration du composant à tester (DUT) mise à jour
    component led_seq_generator is
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            show_command : in  std_logic;
            seq_value    : in  unsigned(3 downto 0);
            on_off_times : in  std_logic_vector(9 downto 0);
            show_valid   : out std_logic;
            led_o        : out std_logic_vector(9 downto 0)
        );
    end component;

    -- 2. Signaux pour connecter au DUT (mis à jour)
    signal tb_clk          : std_logic := '0';
    signal tb_reset        : std_logic := '0';
    signal tb_show_command : std_logic := '0';
    signal tb_seq_value    : unsigned(3 downto 0) := (others => '0');
    signal tb_on_off_times : std_logic_vector(9 downto 0) := (others => '0');
    signal tb_show_valid   : std_logic;
    signal tb_led_o        : std_logic_vector(9 downto 0);

    -- Constantes pour la simulation
    constant CLK_PERIOD : time := 20 ns; -- Période pour 50 MHz

begin

    -- 3. Instanciation du DUT (mise à jour)
    uut: led_seq_generator
        port map (
            clk          => tb_clk,
            reset        => tb_reset,
            show_command => tb_show_command,
            seq_value    => tb_seq_value,
            on_off_times => tb_on_off_times,
            show_valid   => tb_show_valid,
            led_o        => tb_led_o
        );

    -- 4. Processus de génération de l'horloge
    clk_process: process
    begin
        tb_clk <= '0';
        wait for CLK_PERIOD / 2;
        tb_clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- 5. Processus de stimulation
    stimulus_process: process
    begin
        report "Début de la simulation du led_seq_generator." severity note;

        -- **SCENARIO 1: Reset et état initial**
        report "TEST 1: Reset et module désactivé." severity note;
        tb_reset <= '0';
        tb_show_command <= '0';
        wait for 100 ns; -- Maintenir le reset actif
        tb_reset <= '1';
        wait for CLK_PERIOD;
        
        -- On vérifie que les LEDs sont bien éteintes après le reset
        assert tb_led_o = "0000000000" report "ERREUR TEST 1: Les LEDs ne sont pas éteintes après le reset." severity error;

        -- **SCENARIO 2: Allumage simple (300ms ON / 200ms OFF)**
        report "TEST 2: Allumage de la LED 5 (300ms ON / 200ms OFF)." severity note;
        
        -- Configuration:
        -- Temps ON = 1 (1 * 100ms), Temps OFF = 1 (1 * 100ms)
        tb_on_off_times <= std_logic_vector(to_unsigned(2, 5)) & -- on_off_times(9 downto 5) = OFF
                           std_logic_vector(to_unsigned(2, 5)); -- on_off_times(4 downto 0) = ON
        tb_seq_value    <= to_unsigned(5, 4); -- LED à allumer
        
        -- On active le module
        tb_show_command <= '1';
        wait for CLK_PERIOD; -- Laisser le temps à la commande d'être prise en compte

        -- Vérification de l'allumage
        wait for 50 ms; -- On attend un peu pour être sûr d'être dans l'état ON
        assert tb_led_o = "0000100000" report "ERREUR TEST 2: La LED 5 ne s'est pas allumée." severity error;

        -- Attendre la fin de la période ON et vérifier l'extinction
        wait for 50 ms; -- On complète les 300 ms
        wait for CLK_PERIOD;
        assert tb_led_o = "0000000000" report "ERREUR TEST 2: La LED 5 ne s'est pas éteinte." severity error;
        
        -- Attendre la fin de la période OFF et vérifier le ré-allumage
        wait for 100 ms; -- On attend les 200 ms
        wait for CLK_PERIOD;
        assert tb_led_o = "0000100000" report "ERREUR TEST 2: La LED 5 ne s'est pas rallumée." severity error;
        
        report "Fin de la simulation." severity note;
        wait; -- Stoppe la simulation
    end process;
end architecture;