// ==================================================
// AES_config.v
// AES Configuration Parameters
// Supports AES-128, AES-192, and AES-256
// ==================================================
`ifndef AES_CONFIG_V
`define AES_CONFIG_V

// ===== User Parameter =====
// Choose one: 128, 192, or 256
parameter integer KEY_LENGTH = 128;

// ===== Derived Parameters =====
localparam integer Nb = 4;  // Block size (fixed for AES)

//Number of words in the original key
localparam integer Nk = (KEY_LENGTH == 128) ? 4 :
                        (KEY_LENGTH == 192) ? 6 :
                        (KEY_LENGTH == 256) ? 8 :
                        0;
//Number of rounds
localparam integer Nr = (KEY_LENGTH == 128) ? 10 :
                        (KEY_LENGTH == 192) ? 12 :
                        (KEY_LENGTH == 256) ? 14 :
                        0;

// ===== Sanity Check =====
initial begin
    if (Nk == 0 || Nr == 0)
        $error("Invalid KEY_LENGTH: must be 128, 192, or 256.");
end

// ===== Rcon Table =====
// Round constants for key expansion (only first byte used)
parameter [7:0] Rcon [0:10] = '{
    8'h00, 8'h01, 8'h02, 8'h04, 8'h08,
    8'h10, 8'h20, 8'h40, 8'h80, 8'h1B, 8'h36
};

`endif


// notes (abdulrahman hassan)
//this code have some parts working only with SystemVerilog 
/*


        Feature	             SystemVerilog	Verilog-2001
'{' ... '} array literal	      ✅	            ❌

parameter array	                  ✅	            ❌

$error	                          ✅	            ❌

$display, $stop	                  ✅	            ✅

*/