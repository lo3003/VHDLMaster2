library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================================
-- ENTITY: score_mem (BestScore)
-- DESCRIPTION:
--   Mémorise le meilleur score atteint.
--   Sur réception de 'score_command', il compare le 'score' actuel
--   avec le meilleur score enregistré et le met à jour si nécessaire.
-- =============================================================================
entity score_mem is
    Port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        score_command : in  std_logic; -- Ordre de comparer/mettre à jour le score
        score         : in  unsigned(6 downto 0); -- Score actuel de la partie terminée
        best_o        : out unsigned(6 downto 0)  -- Meilleur score mémorisé
    );
end entity score_mem;

architecture Behavioral of score_mem is

    -- Signal interne pour mémoriser le meilleur score
    signal best_score_reg : unsigned(6 downto 0) := (others => '0');

begin

    -- =========================================================================
    -- PROCESSUS DE GESTION DU MEILLEUR SCORE
    -- =========================================================================
    best_score_process: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                best_score_reg <= (others => '0'); -- Réinitialise le meilleur score à 0
            
            -- Si on reçoit l'ordre de vérifier...
            elsif score_command = '1' then
                -- ...et si le score actuel est meilleur que celui enregistré...
                if score > best_score_reg then
                    best_score_reg <= score; -- ...on met à jour le record !
                end if;
                -- Si le score n'est pas meilleur, on ne fait rien, le record est conservé.
            end if;
        end if;
    end process best_score_process;

    -- La sortie reflète en permanence le meilleur score enregistré
    best_o <= best_score_reg;

end architecture Behavioral;
