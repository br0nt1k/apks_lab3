library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master_tb is
end entity spi_master_tb;

architecture sim of spi_master_tb is
    constant CLK_PERIOD : time := 20 ns;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '0';
    signal start    : std_logic := '0';
    signal data_in  : std_logic_vector(7 downto 0) := (others => '0');
    signal miso     : std_logic := '0';
    signal sck      : std_logic;
    signal mosi     : std_logic;
    signal ss_n     : std_logic;
    signal busy     : std_logic;
    signal data_out : std_logic_vector(7 downto 0);

    signal slave_tx_data : std_logic_vector(7 downto 0) := x"3C";
    signal sim_done      : boolean := false; -- Прапорець зупинки тактування
begin

    uut: entity work.spi_master
        generic map (
            CLK_DIV => 4
        )
        port map (
            clk      => clk,
            rst      => rst,
            start    => start,
            data_in  => data_in,
            miso     => miso,
            sck      => sck,
            mosi     => mosi,
            ss_n     => ss_n,
            busy     => busy,
            data_out => data_out
        );

    -- Генератор годинника зупиняється, коли sim_done = true
    clk_process : process
    begin
        while not sim_done loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Імітація Slave-пристрою
    slave_process : process(sck, ss_n)
        variable bit_idx : integer := 7;
    begin
        if ss_n = '1' then
            bit_idx := 7;
            miso <= '0';
        elsif falling_edge(sck) then
            miso <= slave_tx_data(bit_idx);
            if bit_idx > 0 then
                bit_idx := bit_idx - 1;
            end if;
        end if;
    end process;

    -- Тестовий процес
    stim_process : process
    begin
        -- Скидання
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 40 ns;

        -- Передача байта 0xA5
        data_in <= x"A5";
        start   <= '1';
        wait for CLK_PERIOD;
        start   <= '0';

        -- Очікуємо завершення передачі
        wait until busy = '0';
        wait for 200 ns;

        assert false report "Simulation completed successfully!" severity note;
        sim_done <= true; -- Зупиняємо симуляцію коректно
        wait;
    end process;

end architecture sim;