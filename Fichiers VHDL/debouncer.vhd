library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================================
-- ENTITY: debouncer
-- DESCRIPTION:
--   Filtre les rebonds mécaniques d'un bouton poussoir.
--   Fournit une sortie stable et une impulsion d'un cycle lors d'un front descendant.
-- =============================================================================
entity debouncer is
    generic (
        CLK_FREQ_HZ   : natural := 50_000_000; -- Fréquence de l'horloge système (50 MHz)
        DEBOUNCE_MS   : natural := 20          -- Durée de l'anti-rebond en millisecondes
    );
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        btn_in     : in  std_logic; -- Entrée brute du bouton (actif bas)
        btn_stable : out std_logic; -- Sortie stable du bouton
        btn_pulse  : out std_logic  -- Impulsion d'un cycle sur le front descendant
    );
end entity debouncer;

architecture rtl of debouncer is

    -- Calcul de la valeur maximale du compteur pour atteindre le délai souhaité
    constant COUNTER_MAX : natural := (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;

    -- Type pour la machine à états interne
    type state_type is (S_IDLE, S_WAIT, S_DOWN);
    signal state, next_state : state_type;
    
    -- Compteur pour la temporisation
    signal counter : natural range 0 to COUNTER_MAX;

    -- Registres pour synchroniser l'entrée
    signal s1, s2 : std_logic;

begin

    -- =========================================================================
    -- PROCESS 1: Synchronisation de l'entrée et gestion de l'état
    -- =========================================================================
    process(clk, reset)
    begin
        if reset = '1' then
            s1    <= '1';
            s2    <= '1';
            state <= S_IDLE;
        elsif rising_edge(clk) then
            -- Double registre pour éviter la méta-stabilité
            s1    <= btn_in;
            s2    <= s1;
            state <= next_state;
        end if;
    end process;
    
    -- =========================================================================
    -- PROCESS 2: Logique de la machine à états et du compteur
    -- =========================================================================
    process(state, s2, counter)
    begin
        -- Valeurs par défaut
        next_state <= state;
        btn_pulse  <= '0';
        
        case state is
            -- Le bouton est relâché et stable
            when S_IDLE =>
                if s2 = '0' then -- Un appui est détecté !
                    next_state <= S_WAIT;
                end if;

            -- Le bouton a été pressé, on attend la fin des rebonds
            when S_WAIT =>
                if counter < COUNTER_MAX then
                    -- Le compteur tourne, on attend
                    next_state <= S_WAIT;
                else
                    -- Le temps est écoulé, on vérifie si le bouton est toujours pressé
                    if s2 = '0' then -- Oui, l'appui est valide
                        next_state <= S_DOWN;
                        btn_pulse  <= '1'; -- On génère l'impulsion !
                    else -- Non, c'était juste du bruit
                        next_state <= S_IDLE;
                    end if;
                end if;
            
            -- Le bouton est maintenu enfoncé
            when S_DOWN =>
                if s2 = '1' then -- Le joueur relâche le bouton
                    next_state <= S_IDLE;
                end if;

        end case;
    end process;

    -- =========================================================================
    -- PROCESS 3: Logique du compteur
    -- =========================================================================
    process(clk, reset)
    begin
        if reset = '1' then
            counter <= 0;
        elsif rising_edge(clk) then
            if next_state = S_WAIT then
                counter <= counter + 1;
            else
                counter <= 0;
            end if;
        end if;
    end process;

    -- Connexion de la sortie stable
    btn_stable <= '0' when state = S_DOWN else '1';

end architecture rtl;
