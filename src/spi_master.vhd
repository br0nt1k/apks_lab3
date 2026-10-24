library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master is
    generic (
        CLK_DIV : integer := 4 -- Дільник системної частоти для SCK
    );
    port (
        clk      : in  std_logic;                    -- Системний годинник
        rst      : in  std_logic;                    -- Асинхронний ресет (активний '1')
        start    : in  std_logic;                    -- Сигнал початку передачі
        data_in  : in  std_logic_vector(7 downto 0); -- Байт для передачі
        miso     : in  std_logic;                    -- Вхід даних від Slave

        sck      : out std_logic;                    -- Лінія SCK
        mosi     : out std_logic;                    -- Лінія MOSI
        ss_n     : out std_logic;                    -- Лінія вибору Slave CS/SS (активний '0')
        busy     : out std_logic;                    -- Модуль зайнятий
        data_out : out std_logic_vector(7 downto 0)  -- Прийнятий байт від Slave
    );
end entity spi_master;

architecture rtl of spi_master is
    type state_type is (IDLE, PREPARE, TRANSFER, FINISH);
    signal state : state_type := IDLE;

    signal clk_cnt   : integer range 0 to CLK_DIV - 1 := 0;
    signal sck_reg   : std_logic := '0';
    signal bit_cnt   : integer range 0 to 7 := 7;
    signal tx_reg    : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_reg    : std_logic_vector(7 downto 0) := (others => '0');
    signal ss_reg    : std_logic := '1';
    signal mosi_reg  : std_logic := '0';
begin

    sck      <= sck_reg;
    mosi     <= mosi_reg;
    ss_n     <= ss_reg;
    busy     <= '0' when state = IDLE else '1';
    data_out <= rx_reg;

    process(clk, rst)
    begin
        if rst = '1' then
            state    <= IDLE;
            clk_cnt  <= 0;
            sck_reg  <= '0';
            bit_cnt  <= 7;
            tx_reg   <= (others => '0');
            rx_reg   <= (others => '0');
            ss_reg   <= '1';
            mosi_reg <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    sck_reg <= '0';
                    ss_reg  <= '1';
                    clk_cnt <= 0;
                    if start = '1' then
                        tx_reg   <= data_in;
                        bit_cnt  <= 7;
                        ss_reg   <= '0';
                        mosi_reg <= data_in(7);
                        state    <= PREPARE;
                    end if;

                when PREPARE =>
                    if clk_cnt = CLK_DIV - 1 then
                        clk_cnt <= 0;
                        sck_reg <= '1';
                        state   <= TRANSFER;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when TRANSFER =>
                    if clk_cnt = CLK_DIV - 1 then
                        clk_cnt <= 0;
                        if sck_reg = '1' then
                            sck_reg <= '0';
                            if bit_cnt > 0 then
                                bit_cnt  <= bit_cnt - 1;
                                mosi_reg <= tx_reg(bit_cnt - 1);
                            else
                                state <= FINISH;
                            end if;
                        else
                            sck_reg <= '1';
                            rx_reg(bit_cnt) <= miso;
                        end if;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when FINISH =>
                    if clk_cnt = CLK_DIV - 1 then
                        clk_cnt <= 0;
                        ss_reg  <= '1';
                        state   <= IDLE;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;
            end case;
        end if;
    end process;

end architecture rtl;