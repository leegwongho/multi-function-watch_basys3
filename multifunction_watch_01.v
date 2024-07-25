
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



module loadable_time_set_mode_clock_value(
input clk, reset_p,
input [2:0] btn_ctr,
output mode_led,
output [15:0] set_watch_value );

wire w_us_clk, w_ms_clk, w_s_clk, w_m_clk;

wire [3:0] w_watch_sec1, w_watch_sec10,  w_watch_min1,  w_watch_min10, set_sec10, set_sec1, set_min10, set_min1;

wire [15:0]  w_set_value, w_watch_value;

wire w_mode, sec_up_btn, min_up_btn, w_set_watch;

wire w_inc_sec; // w_inc_min; 필요 없음 

wire watch_time_load_en, set_time_load_en;

//wire watch_en;

//    assign watch_en = en ? clk : 0;

    button_cntr mode_set0( .btn(btn_ctr[0]), .clk(clk), .reset_p(reset_p), .btn_pedge(w_mode)); 
 
    button_cntr sec_up( .btn(btn_ctr[1]), .clk(clk), .reset_p(reset_p), .btn_pedge(sec_up_btn));  
 
    button_cntr min_up( .btn(btn_ctr[2]), .clk(clk), .reset_p(reset_p), .btn_pedge(min_up_btn)); 

    T_flip_flop_p t_mode( .clk(clk), .reset_p(reset_p), .t(w_mode), .q(w_set_watch));             
    
     edge_detector_n  t_p_n_edge (.clk(clk), .reset_p(reset_p), .cp(w_set_watch), .n_edge(watch_time_load_en), .p_edge(set_time_load_en));         

assign w_inc_sec = w_set_watch ? sec_up_btn : w_s_clk;                       

// assign w_inc_min = w_set_watch ? min_up_btn : w_m_clk;              //필요없음        

assign mode_led = w_set_watch;                                                                  

assign w_watch_value = {w_watch_min10 , w_watch_min1,w_watch_sec10, w_watch_sec1};

assign w_set_value = {set_min10, set_min1, set_sec10, set_sec1};

assign set_watch_value = w_set_watch ? w_set_value : w_watch_value;

clock_div_100 i_us_clk( .clk(clk), .reset_p(reset_p), .cp_div_100(w_us_clk));
    
clock_div_1000 i_ms_clk(.clk(clk), .reset_p(reset_p), .clk_source(w_us_clk), .cp_div_1000_nedge(w_ms_clk));
    
clock_div_1000 i_s_clk (.clk(clk), .reset_p(reset_p), .clk_source(w_ms_clk), .cp_div_1000_nedge(w_s_clk));

clock_div_60 i_m_clk(.clk(clk), .reset_p(reset_p), .clk_source(w_inc_sec), .cp_div_60_nedge(w_m_clk) );       
    
 loadable_counter_bcd_60 sec_watch (.clk(clk), .reset_p(reset_p), .clk_time(w_s_clk), .load_enable(watch_time_load_en),
                                                                   .load_bcd10(set_sec10), .load_bcd1(set_sec1), .bcd10(w_watch_sec10), .bcd1(w_watch_sec1) );

 loadable_counter_bcd_60 min_watch (.clk(clk), .reset_p(reset_p), .clk_time(w_m_clk), .load_enable(watch_time_load_en),
                                                                   .load_bcd10(set_min10), .load_bcd1(set_min1), .bcd10(w_watch_min10), .bcd1(w_watch_min1) );
                                                                   
 loadable_counter_bcd_60 sec_set (.clk(clk), .reset_p(reset_p), .clk_time(sec_up_btn), .load_enable(set_time_load_en),
                                                                   .load_bcd10(w_watch_sec10), .load_bcd1(w_watch_sec1), .bcd10(set_sec10), .bcd1(set_sec1) );

 loadable_counter_bcd_60 min_set (.clk(clk), .reset_p(reset_p), .clk_time(min_up_btn), .load_enable(set_time_load_en),
                                                                   .load_bcd10(w_watch_min10), .load_bcd1(w_watch_min1), .bcd10(set_min10), .bcd1(set_min1));
 

endmodule


module stop_watch_msec_sec_value(
    input clk, reset_p,
    input [2:0]btn_ctr,
    output [15:0] value
);
    
    wire btn0_pedge, btn1_pedge, start_stop, lap;
    
    wire w_us_clk, w_ms_clk, w_s_clk, w_m_clk, clear;
    
    wire [3:0] w_sec1, w_sec10;

    
    button_cntr btn_start( .btn(btn_ctr[0]), .clk(clk), .reset_p(reset_p), .btn_pedge(btn0_pedge)); 

    T_flip_flop_p t_start ( .clk(clk), .reset_p(reset_p), .t(btn0_pedge), .q(start_stop));             

    button_cntr btn_lap( .btn(btn_ctr[1]), .clk(clk), .reset_p(reset_p), .btn_pedge(btn1_pedge)); 
    
    button_cntr btn_clear( .btn(btn_ctr[2]), .clk(clk), .reset_p(reset_p), .btn_pedge(clear)); 
    
    T_flip_flop_p t_lap ( .clk(clk), .reset_p(reset_p), .t(btn1_pedge), .q(lap)); 
    
    wire clk_start;
    
   assign clk_start = start_stop ? clk: 0;
    
 
    
    wire clear_0;
    
    assign clear_0 = clear ? 1 : reset_p;
    
    
    clock_div_100 i_us_clk( .clk(clk_start), .reset_p(clear_0), .cp_div_100(w_us_clk));
    
    clock_div_1000 i_ms_clk(.clk(clk_start), .reset_p(clear_0), .clk_source(w_us_clk), .cp_div_1000_nedge(w_ms_clk));
    
    wire w_10ms_clk;
    

    wire [3:0] w_10msec1, w_10msec10; // wire 선언할떄 비트 수 확인, 이름 확인 할것! 
    
    clock_div_10 i_10ms_clk( .clk(clk_start), .reset_p(clear_0), .clk_source(w_ms_clk) , .cp_div_10_nedge(w_10ms_clk));
    
    clock_div_1000 i_s_clk (.clk(clk_start), .reset_p(clear_0), .clk_source(w_ms_clk), .cp_div_1000_nedge(w_s_clk));
    

    


    counter_bcd_100 msec_bcd(.clk(clk) , .reset_p(clear_0), .clk_time(w_10ms_clk) , .bcd10(w_10msec10), .bcd1(w_10msec1) );

    counter_bcd_60 sec_bcd(.clk(clk) , .reset_p(clear_0), .clk_time(w_s_clk) , .bcd10(w_sec10), .bcd1(w_sec1) );
    
    wire [15:0] cur_time;
    
    assign cur_time = {w_sec10, w_sec1,w_10msec10,w_10msec1};
    
    
    reg [15:0] lap_time;
    
    always@ (posedge clk, posedge reset_p) begin
        if(reset_p) begin
                lap_time = 0;
        end
        else if (btn1_pedge) begin
            lap_time = cur_time;
        end
        else if (clear) begin
            lap_time = 0;
        end
     end
     


    assign value = lap ? lap_time : cur_time;
    

endmodule


module cook_timer_value (
    input clk, reset_p,
    input [3:0] btn,
    output [15:0] value,
    output  reg timeout_led);
    
        wire [3:0] btn_pedge;
          
        button_cntr btstart( .btn(btn[0]), .clk(clk), .reset_p(reset_p), .btn_pedge(btn_pedge[0])); 
        reg start_stop;
    
    //    wire alarm_off, inc_min, inc_sec, btn_start;
    
        wire load_enable;
    
        
        wire w_us_clk, w_ms_clk, w_s_clk;
    
            
        wire [15:0] set_time, cur_time;

        wire [3:0] w_set_sec1, w_set_sec10, w_set_min1, w_set_min10;

        wire [3:0] cur_sec10, cur_sec1, cur_min10, cur_min1;
    
        wire dec_clk, dec_clk0;
    
    
     //   assign {alarm_off, inc_min, inc_sec, btn_start} = btn_pedge;
    
        
        always @ (posedge clk, posedge reset_p) begin
            if(reset_p) begin
                start_stop = 0;
                timeout_led= 0;
                
            end
            else begin 
                if(btn_pedge[0]) start_stop = ~start_stop;
                else if(cur_time == 0 && start_stop) begin 
                        start_stop = 0;
                         timeout_led =1;
                         
                  end
                 else if (btn[3]) timeout_led = 0; 
            end
        end
    
    
    //T_flip_flop_p t_start ( .clk(clk), .reset_p(reset_p), .t(btn_pedge[0]), .q(start_stop));             


        button_cntr btn_inc_sec( .btn(btn[1]), .clk(clk), .reset_p(reset_p), .btn_pedge(btn_pedge[1])); 
    
        
       
    

        edge_detector_n  clk_source (.clk(clk), .reset_p(reset_p), .cp(start_stop), .p_edge(load_enable));


        clock_div_100 i_us_clk( .clk(clk), .reset_p(reset_p), .cp_div_100(w_us_clk));
    
        clock_div_1000 i_ms_clk(.clk(clk), .reset_p(reset_p), .clk_source(w_us_clk), .cp_div_1000_nedge(w_ms_clk));
    
        clock_div_1000 i_s_clk (.clk(clk), .reset_p(reset_p), .clk_source(w_ms_clk), .cp_div_1000_nedge(w_s_clk));
    


        counter_bcd_60 sec_bcd(.clk(clk) , .reset_p(reset_p), .clk_time(btn_pedge[1]) , .bcd10(w_set_sec10), .bcd1(w_set_sec1) );

        counter_bcd_60 min_bcd(.clk(clk) , .reset_p(reset_p), .clk_time(btn[2]) , .bcd10(w_set_min10), .bcd1(w_set_min1) );


        loadable_down_counter_bcd_60 cur_sec(  .clk(clk), .reset_p(reset_p), 
                                                                .clk_time(w_s_clk), .load_enable(load_enable),
                                                                .load_bcd10(w_set_sec10), .load_bcd1(w_set_sec1),
                                                                .bcd10(cur_sec10), .bcd1(cur_sec1),  .dec_clk(dec_clk) );
    
        loadable_down_counter_bcd_60 cur_min(  .clk(clk), .reset_p(reset_p), 
                                                                .clk_time(dec_clk), .load_enable(load_enable),
                                                                .load_bcd10(w_set_min10), .load_bcd1(w_set_min1),
                                                                .bcd10(cur_min10), .bcd1(cur_min1),  .dec_clk(dec_clk0) );

        assign set_time = {w_set_min10,w_set_min1,w_set_sec10,w_set_sec1};

        assign cur_time = {cur_min10,cur_min1,cur_sec10,cur_sec1};

        assign value = start_stop ? cur_time : set_time;
    
        

    
    
    endmodule

    
 module   ring_counter_bcd (clk, reset_p,  q);
input clk, reset_p;
output  reg [3:0] q;

    reg [16:0] clk_div;
    always @(posedge clk) clk_div = clk_div +1;                         // 이런식으로 분주를하네  클럭을 이용하여 카운터를 생성하니까 그 카운터의 2번쨰 비트는 4배 분주가된다 
   wire  clk_div_16_p;
   
    edge_detector_n de_clk (.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16_p));

always @(posedge clk , posedge reset_p)begin                        // always  문에 clk아닌 다른 것이 들어가면 안된다 따라서 에지 디텍터를 이용 
    if(reset_p) q = 4'b1110;                                                            // 리셋 을 주지않아도 FPGA에서 리셋된 값이 들어가는것 파워리셋이 존제하여 파워가 들어올때 리셋을 진행함 이는  클럭을 가지고 리셋을 1로 변경하는 것이아닌 자체 리셋이다. (플립 플롭의 프리셋과 리셋 을 이용함) 
    else if (clk_div_16_p)  
               if (q == 4'b0111) q = 4'b1110;
               else q = {q[2:0], 1'b1};
    end 
    
endmodule


module decoder_7seg_behavioral(                              
    input [3:0] hex_value,                       
    output reg [7:0] seg_7);                        

    always @(hex_value) begin                    
        case(hex_value)                            
                               
            4'b0000 : seg_7 = 8'b0000_0011;       
            4'b0001 : seg_7 = 8'b1001_1111;       
            4'b0010 : seg_7 = 8'b0010_0101;       
            4'b0011 : seg_7 = 8'b0000_1101;        
            4'b0100 : seg_7 = 8'b1001_1001;       
            4'b0101 : seg_7 = 8'b0100_1001;      
            4'b0110 : seg_7 = 8'b0100_0001;       
            4'b0111 : seg_7 = 8'b0001_1111;      
            4'b1000 : seg_7 = 8'b0000_0001;      
            4'b1001 : seg_7 = 8'b0001_1001;       
            4'b1010 : seg_7 = 8'b0001_0001;      
            4'b1011 : seg_7 = 8'b1100_0001;       
            4'b1100 : seg_7 = 8'b0110_0011;       
            4'b1101 : seg_7 = 8'b1000_0101;      
            4'b1110 : seg_7 = 8'b0110_0001;        
            4'b1111 : seg_7 = 8'b0111_0001;       
        endcase                               
    end                                        

endmodule  // 紐⑤뱢 醫낅즺