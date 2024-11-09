module i2cControl (
input clk_50Mhz,
input SW1,
inout i2c_0_scl, // i2c_scl_pin
inout i2c_0_sda, // i2c_sda_pin
output [6:0] led1,
output [6:0] led2,
output [6:0] led3,
output [6:0] led4,
output [6:0] led5,
output [6:0] led6
);

wire m_sda_in;
wire m_scl_in;
wire m_sda_oe;
wire m_scl_oe;
assign i2c_0_sda = m_sda_oe ? 1'b0 : 1'bz;
assign m_sda_in = i2c_0_sda;
assign i2c_0_scl = m_scl_oe ? 1'b0 : 1'bz;
assign m_scl_in = i2c_0_scl;

I2C soc_inst (
.clk_clk (clk_50Mhz), // clk.clk
.reset_reset_n (SW1), // reset.reset_n
.i2c_sda_in (m_sda_in), // i2c0.sda_in
.i2c_scl_in (m_scl_in), // .scl_in
.i2c_sda_oe (m_sda_oe), // .sda_oe
.i2c_scl_oe (m_scl_oe), // .scl_oe
.led1_export(led1),   //  led1.export
.led2_export(led2),   //  led2.export
.led3_export(led3),   //  led3.export
.led4_export(led4),   //  led4.export
.led5_export(led5),   //  led5.export
.led6_export(led6)    //  led6.export
);
endmodule