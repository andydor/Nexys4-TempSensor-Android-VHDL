----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/07/2020 11:07:18 AM
-- Design Name: 
-- Module Name: displ7seg - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity displ7seg is
    Port ( Clk  : in  STD_LOGIC;
           Rst  : in  STD_LOGIC;
           Data : in  STD_LOGIC_VECTOR (31 downto 0);   -- date
           An   : out STD_LOGIC_VECTOR (7 downto 0);    -- anozi
           Seg  : out STD_LOGIC_VECTOR (7 downto 0));   -- catozi
end displ7seg;

architecture Behavioral of displ7seg is

constant CNT_100HZ : integer := 2**20; -- divizor pentru rata de reimprospatare de ~100 Hz
signal Num         : integer range 0 to CNT_100HZ - 1 := 0;
signal NumV        : STD_LOGIC_VECTOR (19 downto 0) := (others => '0');    
signal LedSel      : STD_LOGIC_VECTOR (2 downto 0) := (others => '0');
signal Hex         : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');

begin

-- Proces pentru divizarea ceasului
divclk: process (Clk)
        begin
        if (Clk'event and Clk = '1') then
            if (Rst = '1') then
                Num <= 0;
            elsif (Num = CNT_100HZ - 1) then
                Num <= 0;
            else
                Num <= Num + 1;
            end if;
        end if;
        end process;

    NumV <= CONV_STD_LOGIC_VECTOR (Num, 20);
    LedSel <= NumV (19 downto 17);

-- Selectia anodului activ
    An <= "11111110" when LedSel = "000" else
          "11111101" when LedSel = "001" else
          "11111011" when LedSel = "010" else
          "11110111" when LedSel = "011" else
          "11101111" when LedSel = "100" else
          "11011111" when LedSel = "101" else
          "10111111" when LedSel = "110" else
          "01111111" when LedSel = "111" else
          "11111111";

-- Selectia cifrei active
    Hex <= Data (3  downto  0) when LedSel = "000" else
           Data (7  downto  4) when LedSel = "001" else
           Data (11 downto  8) when LedSel = "010" else
           Data (15 downto 12) when LedSel = "011" else
           Data (19 downto 16) when LedSel = "100" else
           Data (23 downto 20) when LedSel = "101" else
           Data (27 downto 24) when LedSel = "110" else
           Data (31 downto 28) when LedSel = "111" else
           X"0";

-- Activarea/dezactivarea segmentelor cifrei active
    Seg <= "11000000" when Hex = "0000" else            -- 0
           "11111001" when Hex = "0001" else            -- 1
           "10100100" when Hex = "0010" else            -- 2
           "10110000" when Hex = "0011" else            -- 3
           "10011001" when Hex = "0100" else            -- 4
           "10010010" when Hex = "0101" else            -- 5
           "10000010" when Hex = "0110" else            -- 6
           "11111000" when Hex = "0111" else            -- 7
           "10000000" when Hex = "1000" else            -- 8
           "10010000" when Hex = "1001" else            -- 9
           "10001000" when Hex = "1010" else            -- A
           "10000011" when Hex = "1011" else            -- B
           "11000110" when Hex = "1100" else            -- C
           "10100001" when Hex = "1101" else            -- D
           "10000110" when Hex = "1110" else            -- E
           "10001110" when Hex = "1111";                -- F   
           
end Behavioral;