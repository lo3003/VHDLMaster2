-- FSM + score
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity simon_controller is
Port (
clk, reset : in std_logic;
start_pulse : in std_logic;
valid_pulse : in std_logic;
level : in unsigned(1 downto 0);
cfg_times : in std_logic_vector(31 downto 0);
seq_value : in unsigned(2 downto 0);
match_ok : in std_logic;
timeout_flag : in std_logic;
show_enable : out std_logic;
score_o : out unsigned(7 downto 0);
game_over : out std_logic
);
end entity;