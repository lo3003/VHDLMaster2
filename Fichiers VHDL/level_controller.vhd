
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================================
-- ENTITY: level_controller (CORRIGÉ)
-- DESCRIPTION:
--   Gère le niveau de difficulté du jeu (Facile, Moyen, Difficile).
--   Fournit les durées ON et OFF correspondantes pour le clignotement des LEDs.
-- =============================================================================
entity level_controller is
    Port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        level_command : in  std_logic; -- Impulsion d'un cycle provenant du bouton
        level         : out unsigned(1 downto 0);
        on_off_times  : out std_logic_vector(9 downto 0) -- [OFF_TIME(4 bits) & ON_TIME(5 bits)]
    );
end entity level_controller;

architecture Behavioral of level_controller is

    -- Constantes pour les durées en multiples de 100 ms (pour des compteurs 5 bits)
    -- Format : OFF (5 bits) & ON (5 bits)

    -- Niveau Facile: 500ms ON / 500ms OFF
    constant EASY_ON_TIME    : unsigned(4 downto 0) := to_unsigned(15, 5); -- 15 * 100ms
    constant EASY_OFF_TIME   : unsigned(4 downto 0) := to_unsigned(15, 5); -- 15 * 100ms

    -- Niveau Moyen: 200ms ON / 200ms OFF
    constant MEDIUM_ON_TIME  : unsigned(4 downto 0) := to_unsigned(10, 5); -- 10 * 100ms
    constant MEDIUM_OFF_TIME : unsigned(4 downto 0) := to_unsigned(10, 5); -- 10 * 100ms

    -- Niveau Difficile: 100ms ON / 100ms OFF
    constant HARD_ON_TIME    : unsigned(4 downto 0) := to_unsigned(5, 5); -- 5 * 100ms
    constant HARD_OFF_TIME   : unsigned(4 downto 0) := to_unsigned(5, 5); -- 5 * 100ms

    -- Signal interne pour mémoriser le niveau actuel
    signal level_reg : unsigned(1 downto 0) := "00"; -- "00"=Facile, "01"=Moyen, "10"=Difficile

begin

    -- PROCESSUS 1: GESTION DU NIVEAU (Logique Séquentielle)
    level_update_process: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                level_reg <= "00"; -- Niveau par défaut : Facile
            elsif level_command = '1' then
                -- Logique de cyclage : F -> M -> D -> F ...
                case level_reg is
                    when "00"   => level_reg <= "01"; -- De Facile à Moyen
                    when "01"   => level_reg <= "10"; -- De Moyen à Difficile
                    when "10"   => level_reg <= "00"; -- De Difficile à Facile
                    when others => level_reg <= "00"; -- Retour à un état sûr
                end case;
            end if;
        end if;
    end process level_update_process;

    -- PROCESSUS 2: GÉNÉRATION DES TEMPS (Logique Combinatoire)
    timing_generation_process: process(level_reg)
    begin
        case level_reg is
            when "00"   => -- Facile
                on_off_times <= std_logic_vector(EASY_OFF_TIME) & std_logic_vector(EASY_ON_TIME);
            when "01"   => -- Moyen
                on_off_times <= std_logic_vector(MEDIUM_OFF_TIME) & std_logic_vector(MEDIUM_ON_TIME);
            when "10"   => -- Difficile
                on_off_times <= std_logic_vector(HARD_OFF_TIME) & std_logic_vector(HARD_ON_TIME);
            when others => -- Défaut (Facile)
                on_off_times <= std_logic_vector(EASY_OFF_TIME) & std_logic_vector(EASY_ON_TIME);
        end case;
    end process timing_generation_process;

    -- Connexion du registre interne au port de sortie
    level <= level_reg;

end architecture Behavioral;
