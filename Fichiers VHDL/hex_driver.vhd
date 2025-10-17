library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hex_driver is
    generic (
        -- Generic to switch between fast simulation timing and slow hardware timing.
        SIMULATION_MODE : boolean := false
    );
    Port (
        -- === Control Ports ===
        clk         : in  std_logic;
        reset       : in  std_logic;
        hex_command : in  std_logic_vector(1 downto 0);

        -- === Data Input Ports ===
        level       : in  unsigned(1 downto 0);
        mode        : in  std_logic;
        score       : in  unsigned(6 downto 0);
        best_score  : in  unsigned(6 downto 0);

        -- === Physical Output Ports ===
        HEX_CATHODES : out std_logic_vector(6 downto 0);
        HEX_ANODES   : out std_logic_vector(5 downto 0);

        -- === Debug Ports for Testbench Verification ===
        DBG_LATCHED_SCORE      : out unsigned(6 downto 0);
        DBG_LATCHED_BEST_SCORE : out unsigned(6 downto 0);
        DBG_LATCHED_LEVEL      : out unsigned(1 downto 0);
        DBG_LATCHED_MODE       : out std_logic
    );
end entity hex_driver;

---
architecture Behavioral of hex_driver is

    function get_refresh_count(is_sim : boolean) return integer is
    begin
        if is_sim then
            return 10;      -- Fast value for simulation --plutot utiliser une constante 
        else
            return 61440;   -- Slow value for hardware
        end if;
    end function get_refresh_count;

    -- The constant calls the function to get its value.
    constant REFRESH_COUNT : integer := get_refresh_count(SIMULATION_MODE);

    -- BCD to 7-segment conversion function.
    function to_7seg(d : unsigned(3 downto 0)) return std_logic_vector is
    begin
        case d is
            -- Digits
            when "0000" => return "1000000"; -- 0
            when "0001" => return "1111001"; -- 1
            when "0010" => return "0100100"; -- 2
            when "0011" => return "0110000"; -- 3
            when "0100" => return "0011001"; -- 4
            when "0101" => return "0010010"; -- 5
            when "0110" => return "0000010"; -- 6
            when "0111" => return "1111000"; -- 7
            when "1000" => return "0000000"; -- 8
            when "1001" => return "0010000"; -- 9
            -- Letters
            when "1010" => return "0001000"; -- A (Facile)
            when "1011" => return "0000011"; -- b (Moyen)
            when "1100" => return "1000110"; -- C (Classique)
            when "1101" => return "0100001"; -- d (Difficile)
            when "1110" => return "0000110"; -- E (Flash)
            when others => return "1111111"; -- Blank
        end case;
    end function to_7seg;

    -- =========================================================================
    -- SECTION 2: INTERNAL SIGNALS
    -- =================================================det========================

    -- Signals for latched data (the internal "dashboard")
    signal latched_level      : unsigned(1 downto 0) := "00";
    signal latched_mode       : std_logic            := '0';
    signal latched_score      : unsigned(6 downto 0) := (others => '0');
    signal latched_best_score : unsigned(6 downto 0) := (others => '0');

    -- Internal signals for multiplexing logic
    signal refresh_counter   : integer range 0 to REFRESH_COUNT - 1 := 0;
    signal mux_sel           : unsigned(2 downto 0) := "000";
    signal data_to_display   : std_logic_vector(6 downto 0);

begin

    -- =========================================================================
    -- SECTION 3: SEQUENTIAL LOGIC (Clock-driven processes)
    -- =========================================================================

    -- Process 1: Handles selective latching of data based on the command.
    latch_data_process: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                latched_score      <= (others => '0');
                latched_best_score <= (others => '0');
                latched_level      <= (others => '0');
                latched_mode       <= '0';
            else
                case hex_command is
                    when "00"   => latched_score      <= score;
                    when "01"   => latched_level      <= level;
                    when "10"   => latched_mode       <= mode;
                    when "11"   => latched_best_score <= best_score;
                    when others => null;
                end case;
            end if;
        end if;
    end process latch_data_process;

    ----------------------------------------------------------------------------

    -- Process 2: Manages the display refresh counter for multiplexing.
    refresh_process: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                refresh_counter <= 0;
                mux_sel         <= "000";
            elsif refresh_counter = REFRESH_COUNT - 1 then
                refresh_counter <= 0;
                mux_sel         <= mux_sel + 1; -- Move to the next digit
            else
                refresh_counter <= refresh_counter + 1;
            end if;
        end if;
    end process refresh_process;

    -- =========================================================================
    -- SECTION 4: COMBINATIONAL LOGIC (Instantaneous updates)
    -- =========================================================================

    -- Process 3: Selects which latched data to display based on the active digit.
    data_mux_process: process(mux_sel, latched_score, latched_best_score, latched_level, latched_mode)
        variable bcd_val : unsigned(3 downto 0);
    begin
        case mux_sel is
            when "000" => bcd_val := resize(latched_best_score / 10, 4); -- HEX5
            when "001" => bcd_val := resize(latched_best_score mod 10, 4); -- HEX4
            when "010" =>                                                 -- HEX3 (Level)
                case latched_level is
                    when "00"   => bcd_val := "1010"; -- A
                    when "01"   => bcd_val := "1011"; -- b
                    when "10"   => bcd_val := "1101"; -- d
                    when others => bcd_val := "1111";
                end case;
            when "011" =>                                                 -- HEX2 (Mode)
                if latched_mode = '0' then bcd_val := "1100"; else bcd_val := "1110"; end if;
            when "100" => bcd_val := resize(latched_score / 10, 4);       -- HEX1
            when "101" => bcd_val := resize(latched_score mod 10, 4);       -- HEX0
            when others => bcd_val := "1111";
        end case;
        data_to_display <= to_7seg(bcd_val);
    end process data_mux_process;

    ----------------------------------------------------------------------------

    -- Process 4: Activates the correct digit anode.
    anode_decoder_process: process(mux_sel)
    begin
        case mux_sel is
            when "000"  => HEX_ANODES <= "111110"; -- Enable HEX5
            when "001"  => HEX_ANODES <= "111101"; -- Enable HEX4
            when "010"  => HEX_ANODES <= "111011"; -- Enable HEX3
            when "011"  => HEX_ANODES <= "110111"; -- Enable HEX2
            when "100"  => HEX_ANODES <= "101111"; -- Enable HEX1
            when "101"  => HEX_ANODES <= "011111"; -- Enable HEX0
            when others => HEX_ANODES <= "111111"; -- All off
        end case;
    end process anode_decoder_process;

    -- =========================================================================
    -- SECTION 5: FINAL OUTPUT ASSIGNMENTS
    -- =========================================================================

    -- Connect the selected pattern to the physical cathode outputs.
    HEX_CATHODES <= data_to_display;

    -- Connect the internal latched signals to the debug ports.
    DBG_LATCHED_SCORE      <= latched_score;
    DBG_LATCHED_BEST_SCORE <= latched_best_score;
    DBG_LATCHED_LEVEL      <= latched_level;
    DBG_LATCHED_MODE       <= latched_mode;

end architecture Behavioral;