 
module mode_watch_top_long_key_nedge(
    input clk, reset_p,
    input [3:0] btn,
    output [15:0] led,
    output [3:0] com,
    output [7:0] seg_7 );
    
    wire [15:0] value;
    
    mode_watch_long_key_nedge long_key( clk, reset_p, btn, value, led);
    

    
   fnd_4digit_cntr fnd_on ( .clk(clk), .reset_p(reset_p), .com(com) , .value(value), .seg_7(seg_7) );

endmodule