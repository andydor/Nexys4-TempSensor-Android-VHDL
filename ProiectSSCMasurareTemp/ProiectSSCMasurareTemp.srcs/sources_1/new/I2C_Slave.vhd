----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/03/2021 04:59:29 PM
-- Design Name: 
-- Module Name: I2C_Slave - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity I2C_Slave is
	generic(sys_clk_freq: integer := 100_000_000; ----nexys4 clock speed in Hz
		    resolution: integer := 13; --desired resolution of temperature data in bits -> 13 or 16 bits
	        temp_sensor_addr: std_logic_vector(6 downto 0) := "1001011"); --I2C address of the temp sensor
	port(clk: in std_logic;
		 reset_n: in std_logic;
		 scl: inout std_logic;
		 sda: inout std_logic;
		 i2c_ack_err: buffer std_logic;
	     temperature: out std_logic_vector(resolution - 1 downto 0));
end I2C_Slave;

architecture Behavioral of I2C_Slave is

	type fsm is (start, set_resolution, read_msb, read_lsb, output_result);
	
	signal state: fsm; --state machine
	signal config: std_logic_vector(7 downto 0); --value to write in Sensor Configuration Register
	signal i2c_ena: std_logic; --i2c enable
	signal i2c_addr: std_logic_vector(6 downto 0);
	signal i2c_rw: std_logic; --read/write command
	signal i2c_data_wr: std_logic_vector(7 downto 0);
	signal i2c_data_rd: std_logic_vector(7 downto 0);
	signal i2c_busy: std_logic;
	signal busy_prev: std_logic;
	signal temp_data: std_logic_vector(15 downto 0);

begin

	i2c_controller: entity work.I2C_Controller
			generic map(input_clk => sys_clk_freq, 
			            bus_clk => 400_000)
			port map(clk => clk, 
				     reset_n => reset_n, 
				     ena => i2c_ena, 
				     addr => i2c_addr, 
				     rw => i2c_rw, 
				     data_wr => i2c_data_wr, 
				     busy => i2c_busy, 
				     data_rd => i2c_data_rd, 
				     ack_error => i2c_ack_err, 
				     sda => sda, 
				     scl => scl);

	--set the resolution bits for the Sensor Configuration Register value
	with resolution select config <= "00000000" when 13, --13 bits of resolution
		                             "00000001" when 16,
		                             "00000000" when others; --16 bits of resolution

    process (clk, reset_n)

    variable busy_cnt : integer range 0 to 2 := 0; --busy_cnt keeps track of which command we are on
    variable counter : integer range 0 to sys_clk_freq/10 := 0; --wait 100ms

		begin
			if reset_n = '0' then
				counter := 0;
				i2c_ena <= '0';
				busy_cnt := 0;
				temperature <= (others => '0');
				state <= start;
			elsif clk = '1' and clk'EVENT then
				case state is
					--100ms before communicating
					when start => 
						if counter < sys_clk_freq / 10 then
							counter := counter + 1;
						else
							counter := 0;
							state <= set_resolution;
						end if;

					--set the resolution of temperature data
					when set_resolution => 
						busy_prev <= i2c_busy; --previous i2c busy
						if busy_prev = '0' and i2c_busy = '1' then --rising edge
							busy_cnt := busy_cnt + 1;
						end if;
						case busy_cnt is --
							when 0 => --no command yet
								i2c_ena <= '1'; --initiate transaction
								i2c_addr <= temp_sensor_addr; --set temp sensor address
								i2c_rw <= '0';
								i2c_data_wr <= "00000011"; --set the Register Pointer to the Configuration Register
							when 1 => 
								i2c_data_wr <= config; --write the new config value to Register
							when 2 =>
								i2c_ena <= '0'; --stop transaction after this command
								if (i2c_busy = '0') then --transaction complete
									busy_cnt := 0;
									state <= read_msb;
								end if;
							when others => null;
					end case;
					
					--read MSB temp data
					when read_msb => 
						busy_prev <= i2c_busy; --capture the value of the previous i2c busy signal
						if busy_prev = '0' and i2c_busy = '1' then --i2c busy just went high
							busy_cnt := busy_cnt + 1;
						end if;
						case busy_cnt is
							when 0 => --no command
								i2c_ena <= '1'; --initiate transaction
								i2c_addr <= temp_sensor_addr;
								i2c_rw <= '0';
								i2c_data_wr <= "00000000"; --set the Register Pointer to the MSB Register
							when 1 =>
								i2c_ena <= '0'; --stop transaction
								if i2c_busy = '0' then --transaction complete
								    temp_data(15 downto 8) <= i2c_data_rd; --retrieve MSB of temp data
									busy_cnt := 0; 
									state <= read_lsb;
								end if;
							when others => null;
					end case;

					--read LSB temp data
					when read_lsb => 
						busy_prev <= i2c_busy;
						if busy_prev = '0' and i2c_busy = '1' then
							busy_cnt := busy_cnt + 1;
						end if;
						case busy_cnt is
							when 0 => --no command
								i2c_ena <= '1'; --initiate transaction
								i2c_addr <= temp_sensor_addr;
								i2c_rw <= '1';
								i2c_data_wr <= "00000001"; --set the Register Pointer to the LSB Register
							when 1 =>
								i2c_ena <= '0'; --stop transaction
								if (i2c_busy = '0') then --transaction complete
								    temp_data(7 downto 0) <= i2c_data_rd; --retrieve LSB of temp data
									busy_cnt := 0;
									state <= output_result;
								end if;
							when others => null;
					end case;

					--output the temperature data
					when output_result => 
						temperature <= temp_data(15 downto 16 - resolution); --write temperature data to output
						state <= read_msb; --retrieve the next temperature data

					when others => 
						state <= start;
				end case;
			end if;
		end process;

end Behavioral;