	component ip_cordic is
		port (
			a      : in  std_logic_vector(9 downto 0) := (others => 'X'); -- a
			areset : in  std_logic                    := 'X';             -- reset
			c      : out std_logic_vector(7 downto 0);                    -- c
			clk    : in  std_logic                    := 'X';             -- clk
			s      : out std_logic_vector(7 downto 0)                     -- s
		);
	end component ip_cordic;

	u0 : component ip_cordic
		port map (
			a      => CONNECTED_TO_a,      --      a.a
			areset => CONNECTED_TO_areset, -- areset.reset
			c      => CONNECTED_TO_c,      --      c.c
			clk    => CONNECTED_TO_clk,    --    clk.clk
			s      => CONNECTED_TO_s       --      s.s
		);

