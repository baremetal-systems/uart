library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library STD;
use STD.env.finish;

entity tb_uart_tx is
end entity tb_uart_tx;

architecture behavior of tb_uart_tx is

	component uart_tx is
		generic (
			  CLK_FREQ				: natural := 100000000
			; BAUD_RATE				: natural := 115200
			; DATA_BYTES			: natural := 8
			; PARITY_TYPE			: natural := 0
			; STOP_BITS				: natural := 1
		);
		port (
			  clk					: in std_logic
			; rst					: in std_logic
			; send_byte				: in std_logic
			; byte_in				: in std_logic_vector (7 downto 0)
			; ser_out				: out std_logic
			; byte_sent				: out std_logic
			; busy					: out std_logic
		);
	end component uart_tx;

	constant CLK_PERIOD					: time := 10 ns;

	constant TB_DATA_BYTES				: natural := 8;
	constant TB_BAUD_RATE				: natural := 115200;
	constant TB_CLK_FREQ				: natural := 100000000;
	constant TB_PARITY					: natural := 0;
	constant TB_STOP_BITS				: natural := 1;
	constant TB_BAUD_TICK_COUNT			: natural := natural(CEIL(CEIL(real(TB_CLK_FREQ) / real(TB_BAUD_RATE)) / real (TB_DATA_BYTES + TB_STOP_BITS + 1)));

	signal tb_clk						: std_logic := '1';
	signal tb_rst						: std_logic := '0';

	signal tb_write_byte				: std_logic := '0';
	signal tb_ser_out					: std_logic;
	signal tb_byte_sent					: std_logic;
	signal tb_busy						: std_logic;
	signal tb_data_byte					: std_logic_vector (TB_DATA_BYTES - 1 downto 0) := (others => '0');
	signal tb_test_byte					: std_logic_vector (TB_DATA_BYTES - 1 downto 0) := (others => '0');

	procedure uart_receive (signal byte_rec			: inout std_logic_vector (TB_DATA_BYTES - 1 downto 0)
						  ; signal ser_in 			: in std_logic
						  ; constant clk_per		: in time
						  ; constant baud_count 	: in natural
					      ; constant stop_bit_count : in natural) is	

	begin
		wait until ser_in = '0';
		wait for baud_count * clk_per;
		for I in 0 to byte_rec'length - 1 loop
			wait for (natural(CEIL(real(baud_count) / real(2))) - 1) * clk_per;
			byte_rec <= ser_in & byte_rec(byte_rec'length - 1 downto 1);
			wait for (natural(CEIL(real(baud_count) / real(2))) - 1) * clk_per;
		end loop;
		wait for baud_count * clk_per * stop_bit_count;
		
	end procedure uart_receive;


begin

	--
	-- CREATE CLOCK
	--
	tb_clk <= not tb_clk after CLK_PERIOD / 2;

	dut : uart_tx
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
			, ser_out => tb_ser_out
			, send_byte => tb_write_byte
			, byte_in => tb_data_byte
			, busy => tb_busy
			, byte_sent => tb_byte_sent
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
		tb_data_byte <= b"0101_0101";
		tb_write_byte <= '1';
		wait for 1 * clk_period;
		tb_write_byte <= '0';

		uart_receive(tb_test_byte, tb_ser_out, CLK_PERIOD, TB_BAUD_TICK_COUNT, TB_STOP_BITS);
		wait until tb_busy = '0';

		assert (tb_test_byte = tb_data_byte)
				report ("Wrong byte received") severity error;


		tb_data_byte <= b"0000_1111";
		tb_write_byte <= '1';
		wait for 1 * clk_period;
		tb_write_byte <= '0';

		uart_receive(tb_test_byte, tb_ser_out, CLK_PERIOD, TB_BAUD_TICK_COUNT, TB_STOP_BITS);
		wait until tb_busy = '0';
		
		assert (tb_test_byte = tb_data_byte)
				report ("Wrong byte received") severity error;

		tb_data_byte <= b"1111_0000";
		tb_write_byte <= '1';
		wait for 1 * clk_period;
		tb_write_byte <= '0';

		uart_receive(tb_test_byte, tb_ser_out, CLK_PERIOD, TB_BAUD_TICK_COUNT, TB_STOP_BITS);
		wait until tb_busy = '0';
		
		assert (tb_test_byte = tb_data_byte)
				report ("Wrong byte received") severity error;


		report "End of simulation";
		finish;

	end process;


end architecture behavior;
