library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LedMatrix8x8 is
    port(
        clock_50mhz : in  std_logic;
        row         : out std_logic_vector(7 downto 0);
        col         : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of LedMatrix8x8 is

    signal stt      : unsigned(3 downto 0) := (others => '0');
    signal counter  : unsigned(14 downto 0) := (others => '0');
    signal clock    : std_logic := '0';

    -- mảng chứa dữ liệu cột LED
	 
	     -- CONSTANT PATTERN
    type col_array is array(0 to 7) of std_logic_vector(7 downto 0);

    constant data_col : col_array := (
        0 => not "00111100",
        1 => not "01000010",
        2 => not "10100101",
        3 => not "10000001",
        4 => not "10100101",
        5 => not "10011001",
        6 => not "01000010",
        7 => not "00111100"
    );

begin

    ---------------------------------------------------------
    -- TẠO CLOCK 1 kHz (50MHz / 25000 = 2kHz -> clock toggle)
    ---------------------------------------------------------
    ClockGen : process(clock_50mhz)
    begin
        if rising_edge(clock_50mhz) then
            if counter = 25000 then
                counter <= (others => '0');
                clock   <= not clock;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;


    ---------------------------------------------------------
    -- QUÉT LED 8x8
    ---------------------------------------------------------
    ScanMatrix : process(clock)
    begin
        if rising_edge(clock) then

            if stt < 8 then
                col <= data_col(to_integer(stt));

                -- tạo row = (1 << stt)
                row <= std_logic_vector(shift_left(to_unsigned(1, 8), to_integer(stt)));


                stt <= stt + 1;

            else
                stt <= (others => '0');
                col <= (others => '1'); -- tắt hết cột
            end if;

        end if;
    end process;

end architecture;
