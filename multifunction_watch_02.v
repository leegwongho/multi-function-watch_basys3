
module  mode_watch_04(
    input clk, reset_p,
    input [3:0] btn,
    output reg [15:0] value,
    output [15:0] led
);
    
    parameter S_WATCH = 3'b001;
    parameter S_STOP_WATCH = 3'b010;
    parameter S_COOK_TIMER = 3'b100;
    
    wire w_btn_mode, w_btn_set, w_inc_sec, w_inc_min;

    wire [15:0] set_watch_value, stop_watch_value, cook_timer_value;
    
    reg [2:0] btn_mode_watch, btn_mode_stop;
    
    reg [2:0] btn_mode_cook;

    wire long_press, short_press;
    

    button_cntr btn_mode_set( .btn(btn[0]), .clk(clk), .reset_p(reset_p),  .btn_pedge(w_btn_mode));
    
    loadable_time_set_mode_clock_en watch( .clk(clk), .reset_p(reset_p), .btn_ctr(btn_mode_watch),  .set_watch_value(set_watch_value));
    
    stop_watch_msec_sec_value stop_watch(.clk(clk), .reset_p(reset_p), .btn_ctr(btn_mode_stop), .value(stop_watch_value));
    
     cook_timer_value cook_timer( .clk(clk), .reset_p(reset_p), .btn({long_press , btn_mode_cook}), .value(cook_timer_value), .timeout_led(led[15]));
    
    reg [2:0] mode, mode_next;
    
    wire clk_us, clk_ms;
    

    long_key long_key(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .long_press(long_press), .short_press(short_press) );
    
    reg [2:0] btn_ctr_mode;
    

    button_cntr btn_inc_min( .btn(btn[3]), .clk(clk), .reset_p(reset_p), .btn_pedge(btn_pedge) ,  .btn_nedge(w_inc_min));

    always @ (negedge clk, posedge reset_p) begin
        if (reset_p) begin
            mode = S_WATCH;
        end
        else begin 
            mode = mode_next;
        end
    end
    
    always @ (posedge clk, posedge reset_p) begin
          if (reset_p) begin 
            mode_next = S_WATCH;
            value = set_watch_value;
            btn_ctr_mode[2:0] = 0;
         end
        else begin
            case(mode)
                S_WATCH: begin
                    if (w_btn_mode) begin
                        mode_next = S_STOP_WATCH;
                    end
                    else begin
                         value = set_watch_value;
                          btn_mode_watch = {btn[3], btn[2],btn[1]};
                     end
                end
                S_STOP_WATCH : begin
                    if (w_btn_mode) begin
                        mode_next = S_COOK_TIMER;
                    end
                    else begin 
                        value = stop_watch_value;
                        btn_mode_stop = {btn[3], btn[2],btn[1]};
                    end
                end
                S_COOK_TIMER : begin
                    if (w_btn_mode) begin
                        mode_next = S_WATCH;
                    end
                    else begin 
                        value = cook_timer_value;
                        btn_mode_cook = {short_press,btn[2],btn[1]};       
                    end
                end
            endcase
        end
           
    end

    

endmodule


module fnd_4digit_cntr( clk, reset_p, com , value, seg_7 );
input clk, reset_p ;
input [15:0] value;
output [3:0] com;
output [7:0] seg_7;

reg [3:0] hex_value;

    ring_counter_bcd com_0 (.clk(clk), .reset_p(reset_p), . q(com));    // fnd占쏙옙 占쏙옙占쏙옙占쏙옙占쏙옙占쏙옙 키占쏙옙占쏙옙占쏙옙 占쏙옙카占쏙옙占쏙옙占쏙옙 占쏙옙占쏙옙占? com占쏙옙占쏙옙 占쏙옙占쏙옙
    
    decoder_7seg_behavioral  seg0(  .hex_value(hex_value),  .seg_7(seg_7));    

    always @ (posedge clk) begin                           // mux 占쏙옙占? 占싼곤옙占쏙옙  
               case(com)
                        4'b1110: hex_value = value[3:0];
                        4'b1101: hex_value = value[7:4];
                        4'b1011: hex_value = value[11:8];
                        4'b0111: hex_value = value[15:12];
               endcase
    end


endmodule


module button_cntr(
    input btn, clk, reset_p,
    output btn_pedge, btn_nedge
);

wire  btn_clk;

reg [16:0] clk_div;

reg debounced_btn;

always @ (posedge clk) clk_div = clk_div  + 1; 

edge_detector_n  ed1 (.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(btn_clk));


always @(posedge clk, posedge reset_p) begin
    if(reset_p) debounced_btn = 0;
    else if (btn_clk) debounced_btn = btn;
end



 edge_detector_n  ed0 (.clk(clk), .reset_p(reset_p), .cp(debounced_btn), .p_edge(btn_pedge), .n_edge(btn_nedge)); //클럭의 동기화를 위해서 btn_clk를 바로 집어넣지는 않는건가 
     
endmodule

