library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- =============================================================================
-- ENTITY: mode_controller
-- DESCRIPTION:
--   Gère le mode de jeu (Classique/Flash).
--   Il bascule entre les deux modes à chaque impulsion reçue sur 'mode_command'.
-- =============================================================================
entity mode_controller is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        mode_command : in  std_logic; -- Impulsion d'un cycle provenant du bouton
        mode         : out std_logic  -- '0' = Classique, '1' = Flash
    );
end entity mode_controller;

architecture Behavioral of mode_controller is

    -- Signal interne pour mémoriser le mode actuel
    signal mode_reg : std_logic := '0'; -- Mode par défaut : Classique

begin

    -- =========================================================================
    -- PROCESSUS DE MISE À JOUR DU MODE (Logique Séquentielle)
    -- =========================================================================
    mode_update_process: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mode_reg <= '0'; -- Au reset, on revient toujours en mode Classique
            elsif mode_command = '1' then
                -- À chaque impulsion, on inverse la valeur du mode
                mode_reg <= not mode_reg;
            end if;
            -- Si aucune commande n'est reçue, mode_reg conserve sa valeur (mémorisation)
        end if;
    end process mode_update_process;

    -- Connexion du registre interne au port de sortie
    mode <= mode_reg;

end architecture Behavioral;