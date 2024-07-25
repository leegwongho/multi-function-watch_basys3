
module edge_detector_n (clk, reset_p, cp, p_edge, n_edge);
input clk, reset_p, cp;
output   p_edge, n_edge;

 reg ff_cur, ff_old;       


    always @ (negedge clk, posedge reset_p) begin
            if(reset_p) begin
                ff_cur <= 0;
                ff_old <= 0;
            end
            else begin
                ff_cur <= cp;                   // 오른쪽 값을 먼저 구함 그후 대입 응애ㅜ
                ff_old <= ff_cur;
            end

    end

    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1: 0;
    
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1: 0;


endmodule


module T_flip_flop_p(                                 
    input clk, reset_p,                               
    input t,                                          
    output reg q);                                    
    
    reg clk_en;
    
    always @(posedge clk, posedge  reset_p)begin      
        if(reset_p)q <= 0;                            
        else if(clk_en) q <= ~q;                                                                                                    
    end 
    
    always @(*) begin
        clk_en = t;
    end                                              
   
endmodule      


module clock_div_100(
    input clk, reset_p,
    output clk_div_100,
    output cp_div_100
    );

    reg [6:0] count_sysclk;
    
    
    always @ (negedge clk, posedge reset_p) begin
        if (reset_p) count_sysclk = 0;
        else begin
            if (count_sysclk >= 99) begin 
                count_sysclk = 0;
                end
            else begin
                count_sysclk = count_sysclk +1;
            end
        end
    end
    
    assign cp_div_100 = (count_sysclk < 50) ? 0 : 1;
    
 edge_detector_n  edge_usec (.clk(clk), .reset_p(reset_p), .cp(cp_div_100), .n_edge(clk_div_100));
    

endmodule

module clock_div_1000(
    input clk, reset_p,
    input clk_source,
    output cp_div_1000_nedge
    );
    
    wire nedge_source;

 edge_detector_n  edge_usec0 (.clk(clk), .reset_p(reset_p), .cp(clk_source), .n_edge(nedge_source));


    reg [9:0] count_clk_source;
    
    
    always @ (negedge clk, posedge reset_p) begin
        if (reset_p) count_clk_source = 0;
        else if (nedge_source)begin
            if (count_clk_source >= 999) begin 
                count_clk_source = 0;
                end
            else begin
                count_clk_source = count_clk_source +1;
            end
        end
    end
    
    wire cp_div_1000;
    
    assign cp_div_1000 = (count_clk_source < 500) ? 0 : 1;
    
 edge_detector_n  edge_usec1 (.clk(clk), .reset_p(reset_p), .cp(cp_div_1000), .n_edge(cp_div_1000_nedge));
 
endmodule


module clock_div_60(
    input clk, reset_p,
    input clk_source,
    output cp_div_60_nedge
    );
    
    wire nedge_source, cp_div_60;

 edge_detector_n  edge_usec0 (.clk(clk), .reset_p(reset_p), .cp(clk_source), .n_edge(nedge_source));


    reg [5:0] count_clk_source;
    
    
    always @ (negedge clk, posedge reset_p) begin
        if (reset_p) count_clk_source = 0;
        else if (nedge_source)begin
            if (count_clk_source >= 59) begin 
                count_clk_source = 0;
                end
            else begin
                count_clk_source = count_clk_source +1;
            end
        end
    end
    
    assign cp_div_60 = (count_clk_source < 59) ? 0 : 1;
    
    edge_detector_n  edge_usec1 (.clk(clk), .reset_p(reset_p), .cp(cp_div_60), .n_edge(cp_div_60_nedge));

endmodule


module loadable_counter_bcd_60(
    input clk, reset_p,
    input   clk_time,
    input load_enable,
    input [3:0] load_bcd10, load_bcd1,
    output  reg [3:0] bcd10, bcd1 );
    
    wire counter_clk_n_edge;

     edge_detector_n  clk_source (.clk(clk), .reset_p(reset_p), .cp(clk_time), .n_edge(counter_clk_n_edge));



    always @ (posedge clk, posedge reset_p) begin
        if(reset_p) begin 
            bcd10 = 0;
            bcd1 = 0;
        end
        else 
                if(load_enable) begin
                    bcd10 = load_bcd10 ;
                    bcd1 =  load_bcd1;
                end
                else if (counter_clk_n_edge) begin
                    if (bcd1 >=9) begin
                        bcd1 = 0;
                        if(bcd10 >= 5) bcd10 = 0;
                        else bcd10 = bcd10 +1;
                    end
                   else bcd1 = bcd1 + 1;
              end
         end
    




endmodule


module loadable_down_counter_bcd_60(
    input clk, reset_p,
    input   clk_time,
    input load_enable,
    input [3:0] load_bcd10, load_bcd1,
    output  reg [3:0] bcd10, bcd1,
    output reg dec_clk );
    
    wire counter_clk_n_edge;


    always @ (posedge clk, posedge reset_p) begin
        
        if(reset_p) begin 
            bcd10 = 0;
            bcd1 = 1;
            dec_clk = 0;
        end
        else  begin
                if(load_enable) begin
                    bcd10 = load_bcd10 ;
                    bcd1 =  load_bcd1;
                end
                else if (clk_time) begin
                    if (bcd1 == 0) begin
                        bcd1 = 9;
                        if(bcd10 == 0) begin
                                dec_clk = 1;
                                 bcd10 = 5;
                                
                         end
                        else bcd10 = bcd10 -1;
                    end
                   else bcd1 = bcd1 - 1;
              end
              else dec_clk = 0;
         end
    end


endmodule


module clock_div_10(
    input clk, reset_p,
    input clk_source,
    output cp_div_10_nedge
    );
    
    wire nedge_source, cp_div_10;

 edge_detector_n  edge_usec0 (.clk(clk), .reset_p(reset_p), .cp(clk_source), .n_edge(nedge_source));


    reg [3:0] count_clk_source;    
     
         
    always @ (negedge clk, posedge reset_p) begin
        if (reset_p) count_clk_source = 0;
        else if (nedge_source)begin
            if (count_clk_source >= 9) begin 
                count_clk_source = 0;
                end
            else begin
                count_clk_source = count_clk_source +1;
            end
        end
    end
    
    assign cp_div_10 = (count_clk_source < 5) ? 0 : 1;
    
 edge_detector_n  edge_usec1 (.clk(clk), .reset_p(reset_p), .cp(cp_div_10), .n_edge(cp_div_10_nedge));
 
endmodule


module counter_bcd_60(
    input clk, reset_p,
    input   clk_time,
    output  reg [3:0] bcd10, bcd1 );
    
    wire counter_clk_n_edge;

     edge_detector_n  clk_source (.clk(clk), .reset_p(reset_p), .cp(clk_time), .n_edge(counter_clk_n_edge));

    always @ (posedge clk, posedge reset_p) begin
        if(reset_p) begin 
            bcd10 = 0;
            bcd1 = 0;
        end
        else if (counter_clk_n_edge) begin
            if (bcd1 >=9) begin
                bcd1 = 0;
                if(bcd10 >= 5) bcd10 = 0;
                else bcd10 = bcd10 +1;
            end
            else bcd1 = bcd1 + 1;
        end
    end


endmodule


module button_long_short (
    input  clk,          
    input  reset_p,        
    input  button,       
    output reg short_press,  
    output reg long_press    
);

    parameter LONG_PRESS_COUNT = 27'd100000000;  
    
    reg button_prev;
    reg [27:0] counter;
    
    wire btn_pedge;
    
    button_cntr_long long( .btn(button), .clk(clk), .reset_p(reset_p), .btn_long(btn_pedge));
    
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            counter <= 0;
            short_press <= 0;
            long_press <= 0;
            button_prev <= 0;
        end 
        else begin  
            button_prev <= btn_pedge;
            if (btn_pedge == 1 && button_prev == 0) begin
                counter <= 0;
            end 
            else if (btn_pedge && button_prev) begin
                counter <= counter + 1;
            end 
            else if (btn_pedge == 0 && button_prev == 1) begin
                if (counter > LONG_PRESS_COUNT) begin
                    counter <= 0;
                    short_press <= 0;
                    long_press <= 1;
                end 
                else begin
                    counter <=0;
                    short_press <= 1;
                    long_press <= 0;
                end
            end 
            else begin
                short_press <= 0;
                long_press <= 0;
            end
        end
    end

endmodule

  
module button_cntr_long(
    input btn, clk, reset_p,
    output btn_long
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

assign btn_long = debounced_btn;
  
endmodule