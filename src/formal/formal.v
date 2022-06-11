initial reset_n = 0;

// Assert that we're never valid in reset,
// and that valid data won't change without tready
always @(posedge clk) begin
    if (!reset_n) assert (!tvalid_master);
    if (tvalid_slave_1 && !tready_slave_1 && reset_n) assert ($stable(tdata_slave_1));
    if (tvalid_slave_2 && !tready_slave_2 && reset_n) assert ($stable(tdata_slave_1));
end