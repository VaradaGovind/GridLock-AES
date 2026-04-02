`timescale 1ns / 1ps

module aes_tb;

    localparam int CLK_PERIOD          = 10;
    localparam     KEY                 = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    localparam     PLAINTEXT           = 128'h3243f6a8885a308d313198a2e0370734;
    localparam EXPECTED_CIPHERTEXT = 128'h3925841d02dc09fbdc118597196a0b32;

    logic aclk;
    logic aresetn;
    logic [31:0] status;

    axi4_lite_if #(
        .C_S_AXI_ADDR_WIDTH(5),
        .C_S_AXI_DATA_WIDTH(32)
    ) axi_lite_if_inst ();
    axi4_stream_if #(
        .TDATA_WIDTH(128)
    ) s_axis_if_inst ();
    axi4_stream_if #(
        .TDATA_WIDTH(128)
    ) m_axis_if_inst ();
    aes_axi_wrapper dut (
        .axi_lite(axi_lite_if_inst.slave),
        .s_axis(s_axis_if_inst.slave),
        .m_axis(m_axis_if_inst.master)
    );

    always #(CLK_PERIOD / 2) aclk = ~aclk;

    assign axi_lite_if_inst.aclk = aclk;
    assign axi_lite_if_inst.aresetn = aresetn;
    assign s_axis_if_inst.aclk = aclk;
    assign s_axis_if_inst.aresetn = aresetn;
    assign m_axis_if_inst.aclk = aclk;
    assign m_axis_if_inst.aresetn = aresetn;

    task automatic axi_lite_write(input logic [4:0] addr, input logic [31:0] data);
        @(posedge aclk);
        axi_lite_if_inst.awvalid <= 1'b1;
        axi_lite_if_inst.awaddr  <= addr;
        axi_lite_if_inst.wvalid  <= 1'b1;
        axi_lite_if_inst.wdata   <= data;
        wait (axi_lite_if_inst.awready && axi_lite_if_inst.wready);
        @(posedge aclk);
        axi_lite_if_inst.awvalid <= 1'b0;
        axi_lite_if_inst.wvalid  <= 1'b0;
        $display("TB: AXI-Lite Write to 0x%h -> 0x%h", addr, data);
    endtask

    task automatic axi_lite_read(input logic [4:0] addr, output logic [31:0] data);
        @(posedge aclk);
        axi_lite_if_inst.arvalid <= 1'b1;
        axi_lite_if_inst.araddr  <= addr;
        wait (axi_lite_if_inst.arready);
        @(posedge aclk);
        axi_lite_if_inst.arvalid <= 1'b0;
        wait (axi_lite_if_inst.rvalid);
        data = axi_lite_if_inst.rdata;
        $display("TB: AXI-Lite Read from 0x%h -> 0x%h", addr, data);
    endtask

    initial begin
        $display("TB: Simulation Started.");
        aclk = 1'b0;
        aresetn = 1'b0;
        axi_lite_if_inst.awvalid <= 1'b0;
        axi_lite_if_inst.wvalid  <= 1'b0;
        axi_lite_if_inst.arvalid <= 1'b0;
        s_axis_if_inst.tvalid    <= 1'b0;
        m_axis_if_inst.tready    <= 1'b1;

        repeat (5) @(posedge aclk);
        aresetn = 1'b1;

        $display("TB: Reset released.");
        $display("TB: Configuring key...");

        axi_lite_write(5'h00, KEY[31:0]);
        axi_lite_write(5'h04, KEY[63:32]);
        axi_lite_write(5'h08, KEY[95:64]);
        axi_lite_write(5'h0C, KEY[127:96]);

        $display("TB: Triggering key expansion...");
        axi_lite_write(5'h14, 32'h1);

        do begin
            axi_lite_read(5'h18, status);
            @(posedge aclk);
        end while (status[1] == 0);

        $display("TB: Key is ready.");
        $display("TB: Sending plaintext...");

        s_axis_if_inst.tvalid <= 1'b1;
        s_axis_if_inst.tdata  <= PLAINTEXT;
        wait (s_axis_if_inst.tready);
        @(posedge aclk);
        s_axis_if_inst.tvalid <= 1'b0;

        $display("TB: Plaintext sent.");
        $display("TB: Waiting for ciphertext...");
        wait (m_axis_if_inst.tvalid);
        $display("TB: Ciphertext received.");

        if (m_axis_if_inst.tdata == EXPECTED_CIPHERTEXT) begin
            $display("----------------------------------------");
            $display("---> TEST PASSED! <---");
            $display("Received: %h", m_axis_if_inst.tdata);
            $display("Expected: %h", EXPECTED_CIPHERTEXT);
            $display("----------------------------------------");
        end else begin
            $error("----------------------------------------");
            $error("---> TEST FAILED! <---");
            $error("Received: %h", m_axis_if_inst.tdata);
            $error("Expected: %h", EXPECTED_CIPHERTEXT);
            $error("----------------------------------------");
        end

        repeat (5) @(posedge aclk);
        $finish;
    end

endmodule
