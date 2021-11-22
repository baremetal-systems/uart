library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity uart_top is
	generic (
		  CLK_FREQ						: natural := 100000000
		; BAUD_RATE						: natural := 115200
		; DATA_BYTES					: natural := 8
		; PARITY_TYPE					: natural := 0
		; STOP_BITS						: natural := 1
	);
	port (
		  clk							: in std_logic
		; rst							: in std_logic
		; rx							: in std_logic
		; tx							: out std_logic
		; data_byte_rx					: out std_logic_vector (DATA_BYTES - 1 downto 0)
		; data_byte_tx 					: in std_logic_vector (DATA_BYTES - 1 downto 0)
		; rx_busy						: out std_logic
		; tx_busy						: out std_logic
		; rx_recv_flag					: out std_logic
		; tx_trans_flag					: in std_logic
		; tx_sent_flag					: out std_logic
	);
end entity uart_top;

architecture rtl of uart_top is

	component uart_tx is
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
			; send_byte					: in std_logic
			; byte_in					: in std_logic_vector (7 downto 0)
			; ser_out					: out std_logic
			; byte_sent					: out std_logic
			; busy						: out std_logic
		);
	end component uart_tx;

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

begin
		
		transmit: uart_tx
			generic map (
				  CLK_FREQ => CLK_FREQ
				, BAUD_RATE => BAUD_RATE
				, DATA_BYTES => DATA_BYTES
				, PARITY_TYPE => PARITY_TYPE
				, STOP_BITS => STOP_BITS
			)
			port map (
				  clk => clk
				, rst => rst
				, send_byte => tx_trans_flag
				, byte_in => data_byte_tx
				, ser_out => tx
				, byte_sent => tx_sent_flag
				, busy => tx_busy
			);

		transmit: uart_rx
			generic map (
				  CLK_FREQ => CLK_FREQ
				, BAUD_RATE => BAUD_RATE
				, DATA_BYTES => DATA_BYTES
				, PARITY_TYPE => PARITY_TYPE
				, STOP_BITS => STOP_BITS
			)
			port map (
				  clk => clk
				, rst => rst
				, ser_in => rx
				, byte_recv => rx_recv_flag
				, data_byte => data_byte_rx
				, busy => rx_busy
			);

end architecture rtl;
