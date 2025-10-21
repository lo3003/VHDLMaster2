library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_sw_seq_comparator is
end entity;

architecture Behavioral of tb_sw_seq_comparator is

    component sw_seq_comparator
        generic (
            MAX_SEQ_LENGTH : integer := 10
        );
        Port (
            clk             : in  std_logic;
            reset           : in  std_logic;
            latch_command   : in  std_logic;
            index           : in  unsigned(3 downto 0);
            seq_value       : in  unsigned(3 downto 0);
            latch_valid     : out std_logic;
            compare_command : in  std_logic;
            step            : in  unsigned(3 downto 0);
            sw_index        : in  unsigned(3 downto 0);
            compare_valid   : out std_logic;
            match_error     : out std_logic
        );
    end component;

    signal clk             : std_logic := '0';
    signal reset           : std_logic := '0';
    signal latch_command   : std_logic := '0';
    signal index           : unsigned(3 downto 0) := (others => '0');
    signal seq_value       : unsigned(3 downto 0) := (others => '0');
    signal latch_valid     : std_logic;
    signal compare_command : std_logic := '0';
    signal step            : unsigned(3 downto 0) := (others => '0');
    signal sw_index        : unsigned(3 downto 0) := (others => '0');
    signal compare_valid   : std_logic;
    signal match_error     : std_logic;

    constant CLK_PERIOD : time := 10 ns;

    signal test_passed   : boolean := true;
    signal total_tests   : integer := 0;
    signal passed_tests  : integer := 0;

begin

    DUT: sw_seq_comparator
        generic map (
            MAX_SEQ_LENGTH => 10
        )
        port map (
            clk             => clk,
            reset           => reset,
            latch_command   => latch_command,
            index           => index,
            seq_value       => seq_value,
            latch_valid     => latch_valid,
            compare_command => compare_command,
            step            => step,
            sw_index        => sw_index,
            compare_valid   => compare_valid,
            match_error     => match_error
        );

    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Test sequence
    stim_process : process
    begin
        report "=== START OF SIMULATION ===";

        -- Reset
        reset <= '1';
        wait for 2*CLK_PERIOD;
        reset <= '0';
        wait for CLK_PERIOD;
        report "Reset done.";

        -- Latch phase
        report "=== LATCH PHASE ===";
        latch_command <= '1';
        index <= "0000";
        seq_value <= "0101"; -- 5
        wait for CLK_PERIOD;
        latch_command <= '0';
        wait for CLK_PERIOD;

        latch_command <= '1';
        index <= "0001";
        seq_value <= "1010"; -- 10
        wait for CLK_PERIOD;
        latch_command <= '0';
        wait for CLK_PERIOD;

        report "Latch done, memory loaded.";

        -- Test 1: Correct comparison
        total_tests <= total_tests + 1;
        report "=== Test #1: expected correct comparison ===";
        compare_command <= '1';
        step <= "0000";
        sw_index <= "0101";
        wait for CLK_PERIOD;
        compare_command <= '0';
        wait for CLK_PERIOD;

        if match_error = '0' then
            report "Test #1 OK: no error detected (expected).";
            passed_tests <= passed_tests + 1;
        else
            report "Test #1 FAILED: unexpected error detected." severity error;
            test_passed <= false;
        end if;

        -- Test 2: Wrong comparison
        total_tests <= total_tests + 1;
        report "=== Test #2: expected mismatch ===";
        compare_command <= '1';
        step <= "0001";
        sw_index <= "0111";
        wait for CLK_PERIOD;
        compare_command <= '0';
        wait for CLK_PERIOD;

        if match_error = '1' then
            report "Test #2 OK: mismatch correctly detected.";
            passed_tests <= passed_tests + 1;
        else
            report "Test #2 FAILED: mismatch not detected." severity error;
            test_passed <= false;
        end if;

        -- Summary
        wait for 20 ns;
        report "=== TEST SUMMARY ===";
        report "Passed tests: " & integer'image(passed_tests) & " / " & integer'image(total_tests);

        if test_passed = true then
            report "All tests passed successfully.";
        else
            report "Some tests failed." severity warning;
        end if;

        report "=== END OF SIMULATION ===";
        wait;
    end process;

end architecture Behavioral;
