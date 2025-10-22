library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_seq_generator is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        show_command : in  std_logic;
        seq_value    : in  unsigned(3 downto 0);
        on_off_times : in  std_logic_vector(9 downto 0);
        show_valid   : out std_logic;
        led_o        : out std_logic_vector(9 downto 0)
    );
end entity;

architecture rtl of led_seq_generator is
    type state_type is (S_IDLE, S_ON, S_OFF, S_DONE);
    signal state : state_type := S_IDLE;

    constant TICKS_100MS : natural := 5_000_000;
    signal prescaler_cnt : natural range 0 to TICKS_100MS - 1;
    signal tick_cnt      : unsigned(4 downto 0);
    
begin
    main_proc: process(clk, reset)
        variable temp_led_o : std_logic_vector(9 downto 0);
    begin
        if reset = '1' then
            state         <= S_IDLE;
            prescaler_cnt <= 0;
            tick_cnt      <= (others => '0');
            led_o         <= (others => '0');
            show_valid    <= '0';
        elsif rising_edge(clk) then
            
            case state is
                when S_IDLE =>
                    led_o      <= (others => '0');
                    show_valid <= '0';
                    if show_command = '1' then
                        state         <= S_ON;
                        prescaler_cnt <= 0;
                        tick_cnt      <= (others => '0');
                        temp_led_o    := (others => '0');
                        if to_integer(seq_value) < 10 then
                           temp_led_o(to_integer(seq_value)) := '1';
                        end if;
                        led_o <= temp_led_o;
                    end if;

                when S_ON =>
                    if prescaler_cnt = TICKS_100MS - 1 then
                        prescaler_cnt <= 0;
                        if tick_cnt = unsigned(on_off_times(4 downto 0)) - 1 then
                            state    <= S_OFF;
                            tick_cnt <= (others => '0');
                            led_o    <= (others => '0');
                        else
                            tick_cnt <= tick_cnt + 1;
                        end if;
                    else
                        prescaler_cnt <= prescaler_cnt + 1;
                    end if;
                    
                when S_OFF =>
                    if prescaler_cnt = TICKS_100MS - 1 then
                        prescaler_cnt <= 0;
                        if tick_cnt = unsigned(on_off_times(9 downto 5)) - 1 then
                            state      <= S_DONE;
                            show_valid <= '1';
                        else
                            tick_cnt <= tick_cnt + 1;
                        end if;
                    else
                        prescaler_cnt <= prescaler_cnt + 1;
                    end if;

                when S_DONE =>
                    show_valid <= '1';
                    if show_command = '0' then
                        state      <= S_IDLE;
                        show_valid <= '0';
                    end if;
            end case;
        end if;
    end process main_proc;
end architecture rtl;
