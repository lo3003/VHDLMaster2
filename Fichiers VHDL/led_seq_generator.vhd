-- Génération LEDs
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity led_seq_generator is
Port (
clk : in std_logic;
seq_value : in unsigned(2 downto 0);
show_enable : in std_logic;
cfg_times : in std_logic_vector(31 downto 0);
led_o : out std_logic_vector(7 downto 0)
);
end entity;