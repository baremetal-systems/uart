library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library STD;
use STD.env.finish;

entity tb_uart_rx is
end entity tb_uart_rx;

architecture behavior of tb_uart_rx is

	component uart_rx is
		generic (
			  CLK_FREQ					: natural := 100000000
			; BAUD_RATE					: natural := 115200
			; DATA_BYTES				: natural := 8
			; PARITY_TYPE				: natural := 0
			; STOP_BITS					: natural := 1
		);
		port (
			  clk						: in std_logic
			; rst						: in std_logic
			; ser_in					: in std_logic
			; byte_recv					: out std_logic
			; data_byte					: out std_logic_vector (DATA_BYTES - 1 downto 0)
			; busy						: out std_logic
		);
	end component uart_rx;

	constant CLK_PERIOD					: time := 10 ns;

	constant TB_DATA_BYTES				: natural := 8;
	constant TB_BAUD_RATE				: natural := 115200;
	constant TB_CLK_FREQ				: natural := 100000000;
	constant TB_PARITY					: natural := 0;
	constant TB_STOP_BITS				: natural := 1;
	constant TB_BAUD_TICK_COUNT			: natural := natural(CEIL(CEIL(real(TB_CLK_FREQ) / real(TB_BAUD_RATE)) / real (TB_DATA_BYTES + TB_STOP_BITS + 1)));

	signal tb_clk						: std_logic := '1';
	signal tb_rst						: std_logic := '0';

	signal tb_ser_in					: std_logic := '1';
	signal tb_byte_recv					: std_logic;
	signal tb_busy						: std_logic;
	signal tb_data_byte					: std_logic_vector (TB_DATA_BYTES - 1 downto 0) := (others => '0');
	signal tb_test_byte					: std_logic_vector (TB_DATA_BYTES - 1 downto 0) := (others => '0');

	procedure uart_write (signal data_byte : in std_logic_vector (TB_DATA_BYTES -1 downto 0);
						  signal serial_out : out std_logic;
						  constant baud_count : in natural;
						  constant clk_per : in time;
						  constant stop_bit_count : in natural) is 

		begin
			serial_out <= '0';
			wait for baud_count* clk_per;

			for I in 0 to data_byte'length - 1 loop
					serial_out <= data_byte (I);
					wait for baud_count * clk_per;
			end loop;
			
			serial_out <= '1';
			wait for baud_count * clk_per * stop_bit_count;
	end procedure uart_write;

begin

	--
	-- CREATE CLOCK
	--
	tb_clk <= not tb_clk after CLK_PERIOD / 2;

	dut : uart_rx
		generic map (
			  CLK_FREQ => TB_CLK_FREQ 
			, BAUD_RATE => TB_BAUD_RATE
			, DATA_BYTES => TB_DATA_BYTES
			, PARITY_TYPE => TB_PARITY
			, STOP_BITS => TB_STOP_BITS
		)
		port map (
			clk => tb_clk
			, rst => tb_rst
			, ser_in => tb_ser_in
			, byte_recv => tb_byte_recv
			, data_byte => tb_data_byte
			, busy => tb_busy
		);

	--
	-- CREATE RESET PULSE
	--
    reset_process: process
    begin
        wait for CLK_PERIOD;
        tb_rst <= '1';
        wait for CLK_PERIOD * 2;
        tb_rst <= '0';
        wait;
    end process reset_process;

	process
	begin
		wait for CLK_PERIOD * 10;
		tb_test_byte <= b"0101_0101";
		wait for CLK_PERIOD * 2;
		uart_write(tb_test_byte, tb_ser_in, TB_BAUD_TICK_COUNT, CLK_PERIOD, TB_STOP_BITS);

--		wait for CLK_PERIOD * TB_DATA_BYTES * TB_BAUD_TICK_COUNT;
		wait for 1000 * CLK_PERIOD;

		assert (tb_test_byte = tb_data_byte or tb_byte_recv = '1')
				report "Wrong data byte received!" severity error;

		wait for CLK_PERIOD * 10;
		tb_test_byte <= b"1111_0000";
		wait for clk_period * 2;
		uart_write(tb_test_byte, tb_ser_in, TB_BAUD_TICK_COUNT, CLK_PERIOD, TB_STOP_BITS);
		wait for 1000 * CLK_PERIOD;

		assert (tb_test_byte = tb_data_byte or tb_byte_recv = '1')
				report "Wrong data byte received!" severity error;

		wait for CLK_PERIOD * 10;
		tb_test_byte <= b"0000_1111";
		wait for clk_period * 2;
		uart_write(tb_test_byte, tb_ser_in, TB_BAUD_TICK_COUNT, CLK_PERIOD, TB_STOP_BITS);
		wait for 1000 * CLK_PERIOD;

		assert (tb_test_byte = tb_data_byte or tb_byte_recv = '1')
				report "Wrong data byte received!" severity error;


		report "End of simulation";
		finish;
	end process;

end architecture behavior;
