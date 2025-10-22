library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================================
-- ENTITY: switch_debouncer
-- DESCRIPTION:
--   Filtre anti-rebond pour un bus de N switches.
--   Il stabilise les entrées en attendant une période de stabilité avant
--   de propager la nouvelle valeur.
-- =============================================================================
entity switch_debouncer is
    generic (
        WIDTH         : natural := 10;          -- Largeur du bus de switches (10 pour votre projet)
        CLK_FREQ_HZ   : natural := 50_000_000; -- Fréquence de l'horloge de votre carte (50 MHz)
        DEBOUNCE_MS   : natural := 10           -- Temps de stabilité souhaité en millisecondes
    );
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        sw_in      : in  std_logic_vector(WIDTH-1 downto 0); -- Entrée brute des switches
        sw_out     : out std_logic_vector(WIDTH-1 downto 0)  -- Sortie stable et "propre"
    );
end entity switch_debouncer;

architecture rtl of switch_debouncer is

    -- Calcul du nombre de cycles d'horloge nécessaires pour la temporisation
    constant COUNTER_MAX : natural := (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
    
    -- Un compteur par switch pour gérer les rebonds indépendamment
    type T_COUNTER_ARRAY is array (WIDTH-1 downto 0) of natural range 0 to COUNTER_MAX;
    signal counters : T_COUNTER_ARRAY := (others => 0);
    
    -- Registres pour une double synchronisation (prévient la métastabilité)
    signal s1, s2 : std_logic_vector(WIDTH-1 downto 0);
    
    -- Registre interne pour la sortie stable
    signal sw_out_reg : std_logic_vector(WIDTH-1 downto 0);

begin

    debounce_proc: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                s1         <= (others => '0');
                s2         <= (others => '0');
                sw_out_reg <= (others => '0');
                counters   <= (others => 0);
            else
                -- 1. Double synchronisation des entrées
                s1 <= sw_in;
                s2 <= s1;

                -- 2. Logique de "debounce" pour chaque switch du bus
                for i in 0 to WIDTH-1 loop
                    -- Si l'entrée (stabilisée) est différente de la sortie actuelle
                    if s2(i) /= sw_out_reg(i) then
                        -- L'état a changé, on lance/continue le compteur
                        if counters(i) < COUNTER_MAX then
                            counters(i) <= counters(i) + 1;
                        else
                            -- Le compteur a atteint son maximum : l'état est stable.
                            -- On met à jour la sortie et on réinitialise le compteur.
                            sw_out_reg(i) <= s2(i);
                            counters(i)   <= 0;
                        end if;
                    else
                        -- L'état n'a pas changé, on garde le compteur à zéro.
                        counters(i) <= 0;
                    end if;
                end loop;
            end if;
        end if;
    end process debounce_proc;

    -- 3. Connexion du registre interne à la sortie finale du module
    sw_out <= sw_out_reg;

end architecture rtl;
