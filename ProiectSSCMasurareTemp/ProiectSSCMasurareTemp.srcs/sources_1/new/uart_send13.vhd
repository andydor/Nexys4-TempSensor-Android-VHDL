----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/29/2020 12:27:51 PM
-- Design Name: 
-- Module Name: uart_send13 - Behavioral
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
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_send16 is
  Port ( Clk: in std_logic;
         Rst: in std_logic;
         Send: in std_logic;
         Data1: in std_logic_vector(15 downto 0);
         Tx: out std_logic;
         Rdy: out std_logic);
end uart_send16;

architecture Behavioral of uart_send16 is

    --constant CR    : STD_LOGIC_VECTOR (7 downto 0) := x"0D";
    --constant LF    : STD_LOGIC_VECTOR (7 downto 0) := x"0A";
    type ST_TYPE is (ready, send_byte, wait_rdy, inc_cnt, test_cnt);
    signal St      : ST_TYPE := ready;
    signal TxData  : STD_LOGIC_VECTOR (7 downto 0) := x"00";
    signal Start   : STD_LOGIC := '0';
    signal TxRdy   : STD_LOGIC := '0';
    signal CntSend : INTEGER range 0 to 2 := 0;

begin

-- Instantierea modulului uart_tx
    uart_tx_i: entity WORK.uart_tx port map (
                Clk => Clk,
                Rst => Rst,
                TxData => TxData,
                Start => Start,
                Tx => Tx,
                TxReady => TxRdy);

-- Automatul de stare pentru transmisia caracterelor
    proc_send: process (Clk)
    begin
        if rising_edge (Clk) then
            if (Rst = '1') then
                CntSend <= 0;
                St <= ready;
            else
                case St is
                    when ready =>
                        CntSend <= 0;
                        if (Send = '1') then
                            St <= send_byte;
                        end if;
                    when send_byte =>
                        St <= wait_rdy;
                    when wait_rdy =>
                        if (TxRdy = '1') then
                            St <= inc_cnt;
                        end if;
                    when inc_cnt =>
                        CntSend <= CntSend + 1;
                        St <= test_cnt;
                    when test_cnt =>
                        if (CntSend = 2) then
                            St <= ready;
                        else
                            St <= send_byte;
                        end if;
                    when others =>
                        St <= ready;
                end case;
            end if;
        end if;
    end process proc_send;

    Start <= '1' when St = send_byte else '0';
    Rdy   <= '1' when St = ready else '0';

-- Selectia octetului care trebuie transmis
    with CntSend select
        TxData <= Data1 (15 downto 8) when 00,
                  Data1 (7 downto 0) when 01,
                  --CR when 03,
                  --LF when 04,
                  x"20" when others;
          
end Behavioral;