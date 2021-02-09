----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/15/2020 04:16:08 PM
-- Design Name: 
-- Module Name: uart_tx - Behavioral
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
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_tx is
	generic (baudRate : integer := 115_200);
	port (
		clk : in std_logic;
		rst : in std_logic;
		txData : in std_logic_vector(7 downto 0);
		start : in std_logic;
		tx : out std_logic;
		txReady : out std_logic);
end uart_tx;

architecture Behavioral of uart_tx is

	type Stare is (ready, load, send, waitbit, shift);

	signal TSR : std_logic_vector(9 downto 0) := (others => '0');
	constant freq : integer := 100_000_000;
	constant T_BIT : integer := freq / baudRate;

	signal St : Stare := ready;
	signal cntBit : integer := 0;
	signal cntRate : integer := 0;
	signal LdData : std_logic := '0';
	signal ShData : std_logic := '0';
	signal TxEn : std_logic := '0';

begin
	TSR1 : process (clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				TSR <= (others => '0');
			else
				if LdData = '1' then
					TSR <= '1' & txData & '0';
				else 
					if ShData = '1' then
						TSR <= '0' & TSR(9 downto 1);
					end if;
				end if;
			end if;
		end if;
	end process;

	-- Automat de stare pentru unitatea de control a transmitatorului serial
	proc_control : process (clk)
	begin
		if RISING_EDGE (clk) then
			if (rst = '1') then
				St <= ready;
			else
				case St is
					when ready => 
						CntRate <= 0;
						CntBit <= 0;
						if (start = '1') then
							St <= load;
						end if;
					when load => 
						St <= send;
					when send => 
						CntBit <= CntBit + 1;
						St <= waitbit;
					when waitbit => 
						CntRate <= CntRate + 1;
						if (CntRate = T_BIT - 3) then
							CntRate <= 0;
							St <= shift;
						end if;
					when shift => 
						--CntBit <= CntBit + 1;
						if (CntBit = 10) then
							St <= ready;
						else
							St <= send;
						end if;
					when others => 
						St <= ready;
				end case;
			end if;
		end if;
	end process proc_control;
 
	-- Setarea semnalelor de comanda
	LdData <= '1' when St = load else '0';
	ShData <= '1' when St = shift else '0';
	TxEn <= '0' when St = ready or St = load else '1';
	
	-- Setarea semnalelor de iesire
	Tx <= TSR(0) when TxEn = '1' else '1';
	TxReady <= '1' when St = ready else '0';

end Behavioral;