`timescale 1ns / 1ps

module process(
    input clk,               // clock
    input [23:0] in_pix,     // value of the pixel at position [in_row, in_col] in the input image (R 23:16; G 15:8; B 7:0)
    output reg [5:0] row,     // selects a row and column in the image
    output reg [5:0] col,     // activates writing for the output image (write enable)
    output reg out_we,        // activates writing for the output image (write enable)
    output reg [23:0] out_pix, // value of the pixel that will be written to the output image at position [out_row, out_col] (R 23:16; G 15:8; B 7:0)
    output reg mirror_done,    // signals the completion of the mirroring operation (active on 1)
    output reg gray_done,     // signals the completion of the grayscale conversion operation (active on 1)
    output reg filter_done    // signals the completion of the application of the sharpness filter (active on 1)
);

// TODO add your finite state machines here


//state si next state au aceasta dimensiune(dimenisiune de 2^6 stari), deoarece m-am folosit de 39 de stari
reg [6:0] state = 0;
reg [6:0] next_state = 0;
reg [5:0] next_col, next_row; //au aceeasi dimensiune ca row, respectiv col
reg [23:0] aux1 = 0, aux2 = 0, suma = 0; //auxiliari folositi pentru salvarea valorilor
reg [7:0] red, green, blue; //
reg [7:0] max, min, gray_medie; //variabilele folosite pentru determinarea maximului, minimului si a mediei din cerinta cu grayscale

//starile utilizate pentru cerinta cu mirror
parameter S0 = 0;
parameter S1 = 1;
parameter S2 = 2;
parameter S3 = 3;
parameter S4 = 4;
parameter S5 = 5;
parameter S6 = 6;

//starile utilizate pentru cerinta cu grayscale
parameter S7 = 7;
parameter S8 = 8;
parameter S9 = 9;

//starile utilizate pentru cerinta cu sharpness
parameter S10 = 10;
parameter S11 = 11;
parameter S12 = 12;
parameter S13 = 13;
parameter S14 = 14;
parameter S15 = 15;
parameter S16 = 16;
parameter S17 = 17;
parameter S18 = 18;
parameter S19 = 19;
parameter S20 = 20;
parameter S21 = 21;
parameter S22 = 22;
parameter S23 = 23;
parameter S24 = 24;
parameter S25 = 25;
parameter S26 = 26;
parameter S27 = 27;
parameter S28 = 28;
parameter S29 = 29;
parameter S30 = 30;
parameter S31 = 31;
parameter S32 = 32;
parameter S33 = 33;
parameter S34 = 34;
parameter S35 = 35;
parameter S36 = 36;
parameter S37 = 37;
parameter S38 = 38;
parameter S39 = 39;


always @(posedge clk) begin
    state <= next_state;
    col <= next_col; //folosit pt actualizarea coloanei/randului pe un semnal de ceas pozitiv
    row <= next_row;
end

always @(*) begin
    case(state)
        S0: begin
            col = 0;
            row = 0;
            next_row = row;
            next_col = col;
            mirror_done = 0;
            next_state = S1;
            end
       
        S1: begin
            aux1 = in_pix; //salvez in variabila auxiliara valoarea pixelului pe care sunt(col - 0, row - 8)
            if (row < 32) begin //conditie pentru row care determina ce elementele din prima jumatate de valori a coloanei x, respectiv din a doua jumatate de valori,se interschimba intre ele
                next_row = 63 - row;
                next_state = S2;
            end else begin
            next_state = S6; //daca row are valoarea mai mare de jumatatea numarului de randuri, insemana ca interschimbarea a avut deja loc
            end
            end
 
        S2: begin
            out_we = 1;
            out_pix = aux1; //out_we = 1 -> folosit pentru scrierea lui out_pix(ia valoarea auxiliarului aux1)
            aux2 = in_pix; //introduc in aux2 valoarea pixelului curent(care se afla in a doua jumatate de valori a coloanei)
            next_state = S3;
            end
 
        S3: begin
            out_we = 0; //la starea urmatoare out_we devinde 0
            next_row = 63 - row;
            next_state = S4;
            end
 
        S4: begin
            out_we = 1; //scriu un pixel in imaginea prelucrata(dureaza un ciclu de ceas)
            out_pix = aux2;
            next_state = S5;
            end

        S5: begin
            out_we = 0;
            if (col == 63) begin //daca am ajuns la finalul randuli, pe ultima coloana continui parcurgerea in jos(pe randuri) a acesteia
                next_row = row + 1;
                next_col = 0;
            end else begin
            next_col = col + 1; //daca nu am ajuns pe ultima coloana, indexul coloanei se incrementeaza si continui procesul
            end
            next_state = S1;
            end
 
        S6: begin
            mirror_done = 1; //se incheie prelucrarii mirrorul
            red = 0;
            green = 0;
            blue = 0;
            row = 0;
            col = 0;
            next_row = 0;
            next_col = 0;
            gray_done = 0;
            next_state = S7;
            end
 
        S7: begin
            max = 0;
            min = 0;
            red = in_pix[23:16];
            green = in_pix[15:8]; //se extrage ce este pe canalul de culoare al pixelului
            blue = in_pix[7:0];
           
            if (red >= blue && red > green) begin //folosesc if-urile pentru a compara cele 3 canale in vederea obtinerii maximului si a minimului
                max = red;
            end else if (blue > red && blue > green) begin
                max = blue;
            end else begin
                max = green;
            end

            if (red <= blue && red < green) begin
                min = red;
            end else if (blue < red && blue < green) begin
                min = blue;
            end else begin
                min = green;
            end
           
            gray_medie = (max + min) / 2; //dupa calcularea valorii maxime si minime se face media
            out_we = 1;
            out_pix[23:16] = 0;
            out_pix[15:8] = gray_medie; //canalul green primeste valoarea mediei, in timp ce restul sunt setate la valoarea 0
            out_pix[7:0] = 0;
            next_state = S8;
            end
 
        S8: begin
            out_we = 0;
            if(col >= 0 && col < 63) begin
                next_col = col + 1;
                next_state = S7;
            end
            else begin
                if(row >= 0 && row < 63) begin
                next_row = row + 1;
                next_col = 0;
                next_state = S7;
            end
                else begin
                if(col == 0 && row == 0) begin
                next_col = col + 1;
                next_state = S7;
            end
                else begin
                next_state = S9;
                end
                end
                end
            end
        S9: begin
            gray_done = 1;
            row = 0;
            col = 0;
            next_row = row;
            next_col = col;
            filter_done = 0;
            next_state = S10;
				end

        //Cazul general in care matricea de 3x3 se afla in interiorul matricei imaginii
        S10: begin
            suma = 0;

            if (row > 0 && row < 63) begin
                if (col > 0 && col < 63) begin //se verifica daca nu se afla pe marginea imaginii
                    suma = suma + in_pix * 9;
                end
            end
            next_row = row - 1;
            next_state = S11;
            end

        S11: begin
            suma = suma + in_pix * (-1);
            next_col = col + 1;
            next_state = S12;
            end

        S12: begin
            suma = suma + in_pix * (-1);
            next_row = row + 1;
            next_state = S13;
            end

        S13: begin
            suma = suma + in_pix *(-1);
            next_row = row + 1;
            next_state = S14;
            end

        S14: begin
            suma = suma + in_pix *(-1);
            next_col = col - 1;
            next_state = S15;
            end

        S15: begin
            suma = suma + in_pix *(-1);
            next_col = col - 1;
            next_state = S16;
            end

        S16: begin
            suma = suma + in_pix *(-1);
            next_row = row - 1;
            next_state = S17;
            end

        S17: begin
            suma = suma + in_pix *(-1);
            next_row = row - 1;
            next_state = S18;
            end

        S18: begin
            suma = suma + in_pix *(-1);
            next_col = col + 1;
            next_row = row + 1;
            out_we = 1;
            out_pix = suma;
            next_state = S19;
            end

        S19: begin
            out_we = 0;
            next_state = S20;
            end

        //Cazul in care se afla in coltul din stanga sus
        S20:begin
            suma = 0;
            if (row == 0 && col == 0) begin
                suma = suma + in_pix * 9;
                next_col = col + 1;
                next_state = S21;
            end
            end

        S21: begin
            suma = suma + in_pix * (-1);
            next_row = row + 1;
            next_state = S22;
        end

        S22: begin
            suma = suma + in_pix * (-1);
            next_col = col - 1;
            next_state = S23;
            end

        S23: begin
            suma = suma + in_pix * (-1);
            next_row = row - 1;
            out_we = 1;
            out_pix = suma;
            next_state = S24;
            end

        S24: begin
            out_we = 0;
            next_state = 25;
            end
       
        //Cazul in care se afla in coltul din stanga jos
        S25:begin
            suma = 0;
            if (row == 63 && col == 0) begin
					suma = suma + in_pix * 9;
            end
            next_row = row - 1;
            next_state = S26;
            end

        S26: begin
            suma = suma + in_pix * (-1);
            next_col = col + 1;
            next_state = S27;
            end

        S27: begin
            suma = suma + in_pix * (-1);
            next_row = row + 1;
            next_state = S28;
            end

        S28: begin
            suma = suma + in_pix * (-1);
            next_col = col - 1;
            out_we = 1;
            out_pix = suma;
            next_state = S29;
            end

        S29 : begin
            out_we = 0;
            next_state = S30;
            end

        //Cazul in care se afla in coltul din dreapta sus
        S30:begin
            suma = 0;
            if (row == 0 && col == 63) begin
                suma = suma + in_pix * 9;
            end
            next_row = row + 1;
            next_state = S31;
            end

        S31: begin
            suma = suma + in_pix * (-1);
            next_col = col - 1;
            next_state = S32;
            end

        S32: begin
            suma = suma + in_pix * (-1);
            next_row = row - 1;
            next_state = S33;
            end

        S33: begin
            suma = suma + in_pix * (-1);
            next_col = col + 1;
            out_we = 1;
            out_pix = suma;
            next_state = S34;
            end

        S34: begin
            out_we = 0;
            next_state = 35;
            end

        //Cazul in care se afla in coltul din dreapta sus
        S35:begin
            suma = 0;
            if (row == 63 && col == 63) begin
					suma = suma + in_pix * 9;
            end
            next_col = col - 1;
            next_state = S36;
            end

        S36: begin
            suma = suma + in_pix * (-1);
            next_row = row - 1;
            next_state = S37;
            end

        S37: begin
            suma = suma + in_pix * (-1);
            next_col = col + 1;
            next_state = S38;
            end

        S38: begin
            suma = suma + in_pix * (-1);
            next_row = row + 1;
            out_we = 1;
            out_pix = suma;
            next_state = S39;
            end

        S39: begin
            out_we = 0;
            filter_done = 1;
            end
    endcase
    end
endmodule
