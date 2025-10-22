library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debouncer is
    generic (
        CLK_FREQ_HZ   : natural := 50_000_000;
        DEBOUNCE_MS   : natural := 20
    );
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        btn_in     : in  std_logic; -- Entrée brute du bouton (actif bas)
        btn_pulse  : out std_logic  -- Impulsion propre d'un cycle
    );
end entity debouncer;

architecture rtl of debouncer is
    constant COUNTER_MAX : natural := (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
    signal counter : natural range 0 to COUNTER_MAX := 0;
    signal s1, s2 : std_logic := '1'; -- Registres de synchro, initialisés à l'état relâché
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                s1 <= '1';
                s2 <= '1';
                counter <= 0;
                btn_pulse <= '0';
            else
                -- Synchronisation de l'entrée pour éviter la métastabilité
                s1 <= btn_in;
                s2 <= s1;

                -- Logique du debouncer
                if s2 = '0' then -- Si le bouton est potentiellement pressé
                    if counter < COUNTER_MAX then
                        counter <= counter + 1;
                    else -- Le compteur a atteint son max, le bouton est stablement pressé
                        -- On génère une impulsion SEULEMENT au moment où il devient stable
                        if s2'last_signal = '1' then -- Si l'état précédent était 'relâché'
                            btn_pulse <= '1';
                        else
                            btn_pulse <= '0';
                        end if;
                    end if;
                else -- Le bouton est relâché
                    counter <= 0;
                    btn_pulse <= '0';
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
