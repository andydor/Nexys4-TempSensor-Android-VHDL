----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/03/2021 04:54:12 PM
-- Design Name: 
-- Module Name: I2C_Controller - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity I2C_Controller is
	generic(input_clk: integer := 100_000_000; --nexys4 clock speed in Hz
	        bus_clk: integer := 400_000); --scl speed in Hz
	port(clk: in std_logic;
		 reset_n: in std_logic;
		 ena: in std_logic; --request data
		 addr: in std_logic_vector(6 downto 0); --address of slave
		 rw: in std_logic; -- 0 -> write    1 -> read
		 data_wr: in std_logic_vector(7 downto 0); --write to slave
		 busy: out std_logic; --transaction in progress
		 data_rd: out std_logic_vector(7 downto 0); --read from slave
		 ack_error: buffer std_logic;
		 sda: inout std_logic;
	     scl: inout std_logic);
end I2C_Controller;

architecture Behavioral of I2C_Controller is

	constant clk_div: integer := (input_clk/bus_clk)/4; --number of clocks in 1/4 cycle of scl
	
	type fsm is (ready, start, command, slave_ack1, write, read, slave_ack2, master_ack, stop);
	
	signal state: fsm;
	signal data_clk: std_logic; --data clock for sda
	signal data_clk_prev: std_logic; --previous data clock
	signal scl_clk: std_logic; --internal scl
	signal scl_ena: std_logic := '0'; --enables internal scl to output
	signal sda_int: std_logic := '1'; --internal sda
	signal sda_ena_n: std_logic; --enables internal sda to output
	signal addr_rw: std_logic_vector(7 downto 0); --address & read/write
	signal data_tx: std_logic_vector(7 downto 0); --data to write to slave
	signal data_rx: std_logic_vector(7 downto 0); --data received from slave
	signal bit_cnt: integer range 0 to 7 := 7;
	signal stretch: std_logic := '0'; --slave stretching scl
	
begin

	--generate bus and data clock
	process (clk, reset_n)
	
	variable count: integer range 0 to clk_div * 4; --timing for clock generation
	
	begin
	
		if reset_n = '0' then --reset
			stretch <= '0';
			count := 0;
		elsif clk = '1' and clk'event then
			data_clk_prev <= data_clk; --store previous value of data clock
			if count = clk_div * 4 - 1 then --end of timing cycle
				count := 0; --reset timer
			elsif stretch = '0' then --stretching not detected
				count := count + 1; --continue clock generation
			end if;
			
			case count is
				when 0 to clk_div - 1 => --first 1/4 cycle of clocking
					scl_clk <= '0';
					data_clk <= '0';
				when clk_div to clk_div * 2 - 1 => --second 1/4 cycle of clocking
					scl_clk <= '0';
					data_clk <= '1';
				when clk_div * 2 to clk_div * 3 - 1 => --third 1/4 cycle of clocking
					scl_clk <= '1'; --release scl
					if scl = '0' then --detect if slave is stretching clock
						stretch <= '1';
					else
						stretch <= '0';
					end if;
					data_clk <= '1';
				when others => --last 1/4 cycle of clocking
					scl_clk <= '1';
					data_clk <= '0';
			end case;
		end if;
		
	end process;

	--fsm and writing to sda during scl low
	process (clk, reset_n)
		begin
		
			if reset_n = '0' then --reset
				state <= ready; --initial state
				busy <= '1';
				scl_ena <= '0'; --sets scl high impedance
				sda_int <= '1'; --sets sda high impedance
				ack_error <= '0'; --clear acknowledge flag
				bit_cnt <= 7;
				data_rd <= "00000000";
			elsif clk = '1' and clk'event then
				if data_clk = '1' and data_clk_prev = '0' then --rising edge
					case state is
						when ready => --idle
							if ena = '1' then
								busy <= '1';
								addr_rw <= addr & rw; --slave address & command
								data_tx <= data_wr; --data to write
								state <= start;
							else
								busy <= '0';
								state <= ready;
							end if;
						when start =>
							busy <= '1';
							sda_int <= addr_rw(bit_cnt); --send first address bit
							state <= command;
						when command =>
							if bit_cnt = 0 then --transmit finished
								sda_int <= '1'; --release sda for slave acknowledge
								bit_cnt <= 7;
								state <= slave_ack1;
							else
								bit_cnt <= bit_cnt - 1;
								sda_int <= addr_rw(bit_cnt - 1); --write address/command bit
								state <= command;
							end if;
						when slave_ack1 => --command ack
							if addr_rw(0) = '0' then --write
								sda_int <= data_tx(bit_cnt);
								state <= write;
							else --read
								sda_int <= '1'; --release sda from incoming data
								state <= read;
							end if;
						when write =>
							busy <= '1';
							if (bit_cnt = 0) then --transmit finished
								sda_int <= '1'; --release sda for slave acknowledge
								bit_cnt <= 7;
								state <= slave_ack2;
							else
								bit_cnt <= bit_cnt - 1;
								sda_int <= data_tx(bit_cnt - 1);
								state <= write;
							end if;
						when read =>
							busy <= '1';
							if (bit_cnt = 0) then
								if ena = '1' and addr_rw = addr & rw then --read at same address
									sda_int <= '0'; --ack
								else
									sda_int <= '1'; --no ack
								end if;
								bit_cnt <= 7;
								data_rd <= data_rx;
								state <= master_ack;
							else
								bit_cnt <= bit_cnt - 1;
								state <= read;
							end if;
						when slave_ack2 => --write ack
							if ena = '1' then --continue
								busy <= '0';
								addr_rw <= addr & rw;
								data_tx <= data_wr;
								if addr_rw = addr & rw then --another write
									sda_int <= data_wr(bit_cnt);
									state <= write;
								else --another read or new slave
									state <= start;
								end if;
							else --completed
								state <= stop;
							end if;
						when master_ack => --ack after read
							if ena = '1' then --continue
								busy <= '0';
								addr_rw <= addr & rw;
								data_tx <= data_wr;
								if addr_rw = addr & rw then --another read
									sda_int <= '1'; --release sda from incoming data
									state <= read;
								else --another write or new slave
									state <= start;
								end if; 
							else --completed
								state <= stop;
							end if;
						when stop =>
							busy <= '0';
							state <= ready;
					end case; 
				elsif data_clk = '0' and data_clk_prev = '1' then --falling edge
					case state is
						when start => 
							if scl_ena = '0' then --new transaction
								scl_ena <= '1'; --enable scl
								ack_error <= '0';
							end if;
						when slave_ack1 => --receive slave ack command
							if sda /= '0' or ack_error = '1' then --no ack
								ack_error <= '1';
							end if;
						when read =>
							data_rx(bit_cnt) <= sda;
						when slave_ack2 => --receive slave ack write
							if sda /= '0' or ack_error = '1' then --no ack
								ack_error <= '1';
							end if;
						when stop => 
							scl_ena <= '0'; --disable scl
						when others => 
							null;
					end case;
				end if;
			end if;
			
		end process; 

		--sda output
		with state select sda_ena_n <= data_clk_prev when start, --start condition
		                               not data_clk_prev when stop, --stop condition
		                               sda_int when others; --set internal sda signal 
 
		--scl and sda outputs
		scl <= '0' when (scl_ena = '1' and scl_clk = '0') else 'Z';
		sda <= '0' when sda_ena_n = '0' else 'Z';
 
end Behavioral;