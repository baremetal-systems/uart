library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;


entity uart_rx is
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

end entity uart_rx;

architecture rtl of uart_rx is

	function calculate_bit_sum(
						  data_bytes_count 	: natural := 0
						; parity_bit 		: natural := 0
						; stop_bits_count	: natural := 0
					) return natural is
		variable sum : natural := 0;

	begin
		if (parity_bit > 0) then
				sum := sum + 1;
		else
				sum := sum + 0;
		end if;

		if (stop_bits_count = 2) then
				sum := sum + 2;
		else
				sum := sum + 1;
		end if;

		sum := sum + data_bytes_count;

		return  sum + 1; -- start bit

	end function calculate_bit_sum;

	constant BAUD_TICK_COUNT		: natural := natural(CEIL(CEIL(real(CLK_FREQ) / real(BAUD_RATE)) / real (calculate_bit_sum(DATA_BYTES, PARITY_TYPE, STOP_BITS))));

	constant RX_TICK_COUNT			: natural := natural(CEIL(real(BAUD_TICK_COUNT) / real(2)));
	constant TICK_CNT_WIDTH			: natural := natural(CEIL(LOG2(real(BAUD_TICK_COUNT))));

	signal tick_count_reg			: std_logic_vector (TICK_CNT_WIDTH downto 0) := (others => '0');
	signal bit_count_reg			: std_logic_vector (DATA_BYTES - 1 downto 0) := (others => '0');
	signal stop_bit_count_reg		: std_logic_vector (1 downto 0) := (others => '0');

	signal byte_received_reg 		: std_logic := '0';
	signal ser_in_reg				: std_logic_vector (1 downto 0) := "11";
	signal data_byte_reg			: std_logic_vector (DATA_BYTES - 1 downto 0) := (others => '0');
	signal busy_reg					: std_logic := '0';
	signal parity_reg				: std_logic := '0';

	type state_t is (idle, start, stop, data, parity, parity_error);
	signal state 					: state_t := idle;

begin

	data_byte <= data_byte_reg;
	byte_recv <= byte_received_reg;
	busy <= busy_reg;

	baud_tick_proc: process(clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				tick_count_reg <= (others => '0');
			else
				if (unsigned(tick_count_reg) < BAUD_TICK_COUNT and state /= idle) then
					tick_count_reg <= std_logic_vector (unsigned(tick_count_reg) + 1 );
				else 
					tick_count_reg <= (others => '0');
				end if;
			end if;
		end if;
	end process baud_tick_proc;

	recv_proc: process(clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				busy_reg <= '0';
				ser_in_reg <= "11";
				state <= idle;
			else
				ser_in_reg(0) <= ser_in;
				ser_in_reg(1) <= ser_in_reg(0);

				if (state /= idle) then
					busy_reg <= '1';
				else
					busy_reg <= '0';
				end if;

				case state is
						when idle =>
							byte_received_reg <= '0';
							parity_reg <= '0';
							stop_bit_count_reg <= (others => '0');
							data_byte_reg <= (others => '0'); --data_byte_reg;
							bit_count_reg <= (others => '0'); 

							if (ser_in_reg = "00") then
								state <= start;
							else
								state <= idle;
							end if;

						when start =>
							byte_received_reg <= '0';
							parity_reg <= '0';
							stop_bit_count_reg <= (others => '0'); --stop_bit_count_reg;
							data_byte_reg <= (others => '0'); --data_byte_reg;
							bit_count_reg <= (others => '0'); --bit_count_reg;

							if (unsigned(tick_count_reg) >= BAUD_TICK_COUNT - 1) then
								state <= data;
							else
								state <= start;
							end if;

						when data =>
						    byte_received_reg <= '0';
						    stop_bit_count_reg <= (others => '0'); --stop_bit_count_reg;

						    if (unsigned(tick_count_reg) = RX_TICK_COUNT - 1) then
								data_byte_reg <= ser_in_reg(1) & data_byte_reg(DATA_BYTES - 1 downto 1);
								bit_count_reg <= bit_count_reg(DATA_BYTES - 2 downto 0) & '1';
								state <= data;
								
								if (ser_in_reg(1) = '1') then
									parity_reg <= parity_reg xor ser_in_reg(1);
								else
									parity_reg <= parity_reg;
								end if;
							elsif (unsigned(tick_count_reg) >= BAUD_TICK_COUNT -1) then
								data_byte_reg <= data_byte_reg;
								bit_count_reg <= bit_count_reg;

								if (bit_count_reg(DATA_BYTES - 1) = '1') then
									if (PARITY_TYPE > 0) then
										state <= parity;
									else
										state <= stop;
									end if;
								else
									state <= data;
								end if;
						    else 
								state <= data;
								data_byte_reg <= data_byte_reg;
								bit_count_reg <= bit_count_reg;
						    end if;

						when parity => 
								byte_received_reg <= '0';
								data_byte_reg <= data_byte_reg;
								bit_count_reg <= bit_count_reg;
								stop_bit_count_reg <= stop_bit_count_reg;

								if (unsigned(tick_count_reg) = RX_TICK_COUNT) then
									case PARITY_TYPE is
										when 2 =>
											if (not parity_reg = ser_in_reg(1)) then
												state <= parity;
											else
												state <= parity_error;
											end if;

										when 1 =>
											if (parity_reg = ser_in_reg(1)) then
												state <= parity;
											else
												state <= parity_error;
											end if;

										when 0 =>
											state <= parity_error;

										when others => 
											state <= parity_error;
									end case;
										
								elsif(unsigned(tick_count_reg) >= BAUD_TICK_COUNT - 1) then
									state <= stop;
								else
									state <= parity;
								end if;

						when stop =>
							byte_received_reg <= '1';
							data_byte_reg <= data_byte_reg;
							bit_count_reg <= bit_count_reg;

							if (unsigned(tick_count_reg) >= BAUD_TICK_COUNT - 1) then
								stop_bit_count_reg <= stop_bit_count_reg(1) & '1';

								if (unsigned(stop_bit_count_reg) >= STOP_BITS) then
									state <= idle;
								else
									state <= stop;
								end if;
							else
								state <= stop;
							end if;

						when others =>
							state <= idle;
							byte_received_reg <= '0';
							data_byte_reg <= data_byte_reg;
							bit_count_reg <= bit_count_reg;
							stop_bit_count_reg <= stop_bit_count_reg;

				end case;
			end if;
		end if;
	end process recv_proc;

end architecture rtl;
