-- Comparateur
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity sw_seq_comparator is
Port (
sw_latched : in std_logic_vector(7 downto 0);
seq_value : in unsigned(2 downto 0);
match_ok : out std_logic
);
end entity;