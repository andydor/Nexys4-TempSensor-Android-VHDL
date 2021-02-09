----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/16/2020 06:10:35 PM
-- Design Name: 
-- Module Name: Placuta - Behavioral
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
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Placuta is
  Port ( Clk: in std_logic;
         Rst: in std_logic;
         TMP_SCL: inout std_logic;
         TMP_SDA: inout std_logic;
         --UART_TXD_IN: in std_logic;
         UART_TXD_OUT: out std_logic;
         i2c_err: out std_logic;
         An: out std_logic_vector(7 downto 0);
         Seg: out std_logic_vector(7 downto 0));
end Placuta;

architecture Behavioral of Placuta is

signal temp: std_logic_vector(12 downto 0);
signal temp_out: std_logic_vector(15 downto 0);
signal Send, Rdy_uart, nRst: std_logic;
signal Data: std_logic_vector(31 downto 0);

begin

process
begin
    if Rdy_uart = '1' then
        Send <= '1';
    end if;
    Send <= '0';
    wait for 1000000000ns;
end process;

temp_out <= "000" & temp;

Data <= x"0000" & temp_out;

nRst <= not Rst;

debouncer: entity work.debounce port map (Clk, Rst, nRst);

display: entity work.displ7seg port map (Clk, Rst, Data, An, Seg);

temp_i2c: entity work.I2C_Slave port map(Clk, nRst, TMP_SCL, TMP_SDA, i2c_err, temp);

uart_txd: entity work.uart_send16 port map(Clk, Rst, Send, temp_out, UART_TXD_OUT, Rdy_uart);

end Behavioral;