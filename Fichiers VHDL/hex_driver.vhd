library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hex_driver is
    Port (
        -- === Données en entrée ===
        score       : in  unsigned(6 downto 0);
        best_score  : in  unsigned(6 downto 0);
        level       : in  unsigned(1 downto 0);
        mode        : in  std_logic;

        -- === Sorties directes pour chaque afficheur ===
        HEX5, HEX4  : out std_logic_vector(6 downto 0); -- Afficheurs pour le meilleur score
        HEX3        : out std_logic_vector(6 downto 0); -- Afficheur pour le niveau
        HEX2        : out std_logic_vector(6 downto 0); -- Afficheur pour le mode
        HEX1, HEX0  : out std_logic_vector(6 downto 0)  -- Afficheurs pour le score actuel
    );
end entity hex_driver;

architecture Behavioral of hex_driver is

    -- La fonction de conversion reste utile pour les chiffres
    function to_7seg(d : unsigned(3 downto 0)) return std_logic_vector is
    begin
        case d is
            when "0000"=>return"1000000"; when "0001"=>return"1111001";
            when "0010"=>return"0100100"; when "0011"=>return"0110000";
            when "0100"=>return"0011001"; when "0101"=>return"0010010";
            when "0110"=>return"0000010"; when "0111"=>return"1111000";
            when "1000"=>return"0000000"; when "1001"=>return"0010000";
            when "1010"=>return"0001000"; when "1011"=>return"0000011";
            when "1100"=>return"1000110"; when "1101"=>return"0100001";
            when "1110"=>return"0000110"; when others=>return"1111111";
        end case;
    end function to_7seg;

begin

    -- =========================================================================
    -- LOGIQUE DE TRADUCTION (Assignations concurrentes)
    -- =========================================================================

    -- Afficheurs pour le SCORE ACTUEL (HEX1 et HEX0)
    HEX5 <= to_7seg(resize(score / 10, 4)); -- Dizaines
    HEX4 <= to_7seg(resize(score mod 10, 4)); -- Unités

    -- Afficheurs pour le MEILLEUR SCORE (HEX5 et HEX4)
    HEX1 <= to_7seg(resize(best_score / 10, 4)); -- Dizaines
    HEX0 <= to_7seg(resize(best_score mod 10, 4)); -- Unités

    -- **MODIFIÉ** : Afficheur pour le NIVEAU (HEX3)
    HEX2 <= "0000110" when level = "00" else  -- 'E' (Easy)
            "1000111" when level = "01" else  -- 'L' (Medium)
            "0011000" when level = "10" else  -- 'H' (Hard)
            "1111111";                        -- Blank

    -- **MODIFIÉ** : Afficheur pour le MODE (HEX2)
    HEX3 <= to_7seg("1100") when mode = '0' else  -- 'C' (Classique)
            "0001110";                          -- 'F' (Flash)

end architecture Behavioral;
