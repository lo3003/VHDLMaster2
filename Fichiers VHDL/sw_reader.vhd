library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================================
-- ENTITY: sw_reader (Capture_SW)
-- DESCRIPTION:
--   Sur commande, ce module lit les 10 interrupteurs, identifie lequel
--   est activé, et convertit sa position en un index binaire de 4 bits.
--   Il émet une impulsion 'read_valid' pour signaler que l'index est prêt.
-- =============================================================================
entity sw_reader is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        read_command : in  std_logic; -- Ordre de lecture
        sw_i         : in  std_logic_vector(9 downto 0); -- Entrée des 10 switchs
        read_valid   : out std_logic; -- Confirmation de lecture (impulsion)
        sw_index     : out unsigned(3 downto 0)  -- Index du switch détecté
    );
end entity sw_reader;

architecture Behavioral of sw_reader is

    -- Signal interne pour le résultat de la conversion combinatoire
    signal index_comb : unsigned(3 downto 0);

begin

    -- =========================================================================
    -- PROCESSUS 1: ENCODEUR (Logique Combinatoire)
    -- =========================================================================
    -- Ce processus traduit en permanence l'état des switchs en un index.
    -- Un 'case' est la manière la plus propre et efficace de décrire cet encodeur.
    encoder_process: process(sw_i)
    begin
        case sw_i is
            when "0000000001" => index_comb <= "0000"; -- SW0 -> index 0
            when "0000000010" => index_comb <= "0001"; -- SW1 -> index 1
            when "0000000100" => index_comb <= "0010"; -- SW2 -> index 2
            when "0000001000" => index_comb <= "0011"; -- SW3 -> index 3
            when "0000010000" => index_comb <= "0100"; -- SW4 -> index 4
            when "0000100000" => index_comb <= "0101"; -- SW5 -> index 5
            when "0001000000" => index_comb <= "0110"; -- SW6 -> index 6
            when "0010000000" => index_comb <= "0111"; -- SW7 -> index 7
            when "0100000000" => index_comb <= "1000"; -- SW8 -> index 8
            when "1000000000" => index_comb <= "1001"; -- SW9 -> index 9
            
            -- Si aucun switch n'est activé, ou si plusieurs le sont,
            -- on sort une valeur par défaut qui peut être interprétée comme une erreur.
            when others       => index_comb <= "1111";
        end case;
    end process encoder_process;

    -- =========================================================================
    -- PROCESSUS 2: SYNCHRONISATION DE LA SORTIE (Logique Séquentielle)
    -- =========================================================================
    -- Ce processus met à jour les sorties sur un front d'horloge.
    output_reg_process: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                sw_index   <= (others => '0');
                read_valid <= '0';
            else
                -- Si on reçoit la commande, on met à jour les sorties
                if read_command = '1' and index_comb /= "1111" then
                    sw_index   <= index_comb; -- On enregistre l'index calculé
                    read_valid <= '1';        -- On active la validation
                else
                    -- S'il n'y a pas de commande, on désactive la validation.
                    -- sw_index conserve sa valeur précédente.
                    read_valid <= '0';
                end if;
            end if;
        end if;
    end process output_reg_process;

end architecture Behavioral;
