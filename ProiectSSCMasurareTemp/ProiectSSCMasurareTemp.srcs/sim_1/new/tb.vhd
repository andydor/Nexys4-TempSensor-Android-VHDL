----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/26/2020 10:23:31 AM
-- Design Name: 
-- Module Name: tb - Behavioral
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

entity tb is
--  Port ( );
end tb;

architecture Behavioral of tb is

signal Clk, Rst, nRst: std_logic;
signal ena, rw, busy, ack_error, sda, scl: std_logic;
signal data_wr, data_rd: std_logic_vector(7 downto 0);
signal temp: std_logic_vector(12 downto 0);

constant CLK_PERIOD : TIME := 10 ns;

begin

--i2c: entity work.I2C_Controller port map(Clk, nRst, ena, addr, rw, data_wr, busy, data_rd, ack_error, sda, scl);
i2c: entity work.I2C_Slave port map(Clk, nRst, scl, sda, ack_error, temp);

nRst <= not Rst;

clk_gen: process
begin
    Clk <= '0';
    wait for (clk_period/2);
    Clk <= '1';
    wait for (clk_period/2);
end process;

gen_scl: process
begin
    scl <= '0';
    wait for clk_period;
    scl <= 'H';
    wait for clk_period;
end process;

sim: process
begin
    wait for 100 ns;
    Rst <= '1';
    wait for 100 ns;
    Rst <= '0';
    wait for 100 ns;
    
    sda <= 'H';
    wait for 15 ns;
    
    sda <= '0'; --start condition
    
    
    wait;
end process;

end Behavioral;