library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================================
-- ENTITY: level_controller
-- DESCRIPTION:
--   Gère le niveau de difficulté du jeu (Facile, Moyen, Difficile).
--   Il cycle à travers les niveaux à chaque impulsion sur 'level_pulse'.
--   Il fournit le niveau actuel ainsi que la durée correspondante en
--   cycles d'horloge pour l'affichage des LEDs.
-- =============================================================================
entity level_controller is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        level_command : in  std_logic; -- Impulsion d'un cycle provenant du bouton
        level       : out unsigned(1 downto 0);
        on_off_times   : out std_logic_vector(9 downto 0)
    );
end entity level_controller;

architecture Behavioral of level_controller is

    -- Constantes pour les durées en cycles d'horloge (basé sur une clk de 50 MHz)
    -- Facile: 0.5s = 25,000,000 cycles
    constant EASY_TIME   : natural := 10;
    -- Moyen: 0.25s = 12,500,000 cycles
    constant MEDIUM_TIME : natural := 5;
    -- Difficile: 0.1s = 5,000,000 cycles
    constant HARD_TIME   : natural := 2;

    -- Signal interne pour mémoriser le niveau actuel
    signal level_reg : unsigned(1 downto 0) := "00"; -- "00"=Facile, "01"=Moyen, "10"=Difficile

begin

    -- =========================================================================
    -- PROCESSUS 1: GESTION DU NIVEAU (Logique Séquentielle)
    -- =========================================================================
    -- Ce processus met à jour le niveau uniquement sur une impulsion.
    level_update_process: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                level_reg <= "00"; -- Niveau par défaut : Facile
            elsif level_pulse = '1' then
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

    -- =========================================================================
    -- PROCESSUS 2: GÉNÉRATION DES TEMPS (Logique Combinatoire)
    -- =========================================================================
    -- Ce processus traduit le niveau actuel en une valeur de temps.
    -- Il s'exécute instantanément dès que `level_reg` change.
    timing_generation_process: process(level_reg)
    begin
        case level_reg is
            when "00"   => on_off_times <= std_logic_vector(to_unsigned(EASY_TIME, 10));
            when "01"   => on_off_times <= std_logic_vector(to_unsigned(MEDIUM_TIME, 10));
            when "10"   => on_off_times <= std_logic_vector(to_unsigned(HARD_TIME, 10));
            when others => on_off_times <= std_logic_vector(to_unsigned(EASY_TIME, 10));
        end case;
    end process timing_generation_process;

    -- Connexion du registre interne au port de sortie
    level <= level_reg;

end architecture Behavioral;
