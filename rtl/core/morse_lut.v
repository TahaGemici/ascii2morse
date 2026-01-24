module morse_lut(
    input[7:0] ascii,
    output reg[23:0] morse
);
    localparam DOT  = 3'b010, DASH = 3'b011, LAST = 3'b100;

    localparam[23:0] space = LAST << 18,
                     charA = {DOT, DASH|LAST} << 18,
                     charB = {DASH, DOT, DOT, DOT|LAST} << 12,
                     charC = {DASH, DOT, DASH, DOT|LAST} << 12,
                     charD = {DASH, DOT, DOT|LAST} << 15,
                     charE = {DOT|LAST} << 21,
                     charF = {DOT, DOT, DASH, DOT|LAST} << 12,
                     charG = {DASH, DASH, DOT|LAST} << 15,
                     charH = {DOT, DOT, DOT, DOT|LAST} << 12,
                     charI = {DOT, DOT|LAST} << 18,
                     charJ = {DOT, DASH, DASH, DASH|LAST} << 12,
                     charK = {DASH, DOT, DASH|LAST} << 15,
                     charL = {DOT, DASH, DOT, DOT|LAST} << 12,
                     charM = {DASH, DASH|LAST} << 18,
                     charN = {DASH, DOT|LAST} << 18,
                     charO = {DASH, DASH, DASH|LAST} << 15,
                     charP = {DOT, DASH, DASH, DOT|LAST} << 12,
                     charQ = {DASH, DASH, DOT, DASH|LAST} << 12,
                     charR = {DOT, DASH, DOT|LAST} << 15,
                     charS = {DOT, DOT, DOT|LAST} << 15,
                     charT = {DASH|LAST} << 21,
                     charU = {DOT, DOT, DASH|LAST} << 15,
                     charV = {DOT, DOT, DOT, DASH|LAST} << 12,
                     charW = {DOT, DASH, DASH|LAST} << 15,
                     charX = {DASH, DOT, DOT, DASH|LAST} << 12,
                     charY = {DASH, DOT, DASH, DASH|LAST} << 12,
                     charZ = {DASH, DASH, DOT, DOT|LAST} << 12,
                     num0 = {DASH, DASH, DASH, DASH, DASH|LAST} << 9,
                     num1 = {DOT, DASH, DASH, DASH, DASH|LAST} << 9,
                     num2 = {DOT, DOT, DASH, DASH, DASH|LAST} << 9,
                     num3 = {DOT, DOT, DOT, DASH, DASH|LAST} << 9,
                     num4 = {DOT, DOT, DOT, DOT, DASH|LAST} << 9,
                     num5 = {DOT, DOT, DOT, DOT, DOT|LAST} << 9,
                     num6 = {DASH, DOT, DOT, DOT, DOT|LAST} << 9,
                     num7 = {DASH, DASH, DOT, DOT, DOT|LAST} << 9,
                     num8 = {DASH, DASH, DASH, DOT, DOT|LAST} << 9,
                     num9 = {DASH, DASH, DASH, DASH, DOT|LAST} << 9,
                     punctPeriod     = {DOT, DASH, DOT, DASH, DOT, DASH|LAST} << 6,
                     punctComma      = {DASH, DASH, DOT, DOT, DASH, DASH|LAST} << 6,
                     punctColon      = {DASH, DASH, DASH, DOT, DOT, DOT|LAST} << 6,
                     punctQuestion   = {DOT, DOT, DASH, DASH, DOT, DOT|LAST} << 6,
                     punctApostrophe = {DOT, DASH, DASH, DASH, DASH, DOT|LAST} << 6,
                     punctHyphen     = {DASH, DOT, DOT, DOT, DOT, DASH|LAST} << 6,
                     punctSlash      = {DASH, DOT, DOT, DASH, DOT|LAST} << 9,
                     punctLeftPar    = {DASH, DOT, DASH, DASH, DOT|LAST} << 9,
                     punctRightPar   = {DASH, DOT, DASH, DASH, DOT, DASH|LAST} << 6,
                     punctQuotation  = {DOT, DASH, DOT, DOT, DASH, DOT|LAST} << 6,
                     punctEqual      = {DASH, DOT, DOT, DOT, DASH|LAST} << 9,
                     punctError      = {DOT, DOT, DOT, DOT, DOT, DOT, DOT, DOT|LAST},
                     punctCross      = {DOT, DASH, DOT, DASH, DOT|LAST} << 9,
                     punctAt         = {DOT, DASH, DASH, DOT, DASH, DOT|LAST} << 6;

    always @* begin
        case(ascii)
            8'd32: morse = space;
            8'd34: morse = punctQuotation;
            8'd39: morse = punctApostrophe;
            8'd40: morse = punctLeftPar;
            8'd41: morse = punctRightPar;
            8'd43: morse = punctCross;
            8'd44: morse = punctComma;
            8'd45: morse = punctHyphen;
            8'd46: morse = punctPeriod;
            8'd47: morse = punctSlash;
            8'd48: morse = num0;
            8'd49: morse = num1;
            8'd50: morse = num2;
            8'd51: morse = num3;
            8'd52: morse = num4;
            8'd53: morse = num5;
            8'd54: morse = num6;
            8'd55: morse = num7;
            8'd56: morse = num8;
            8'd57: morse = num9;
            8'd58: morse = punctColon;
            8'd61: morse = punctEqual;
            8'd63: morse = punctQuestion;
            8'd64: morse = punctAt;
            8'd97, 8'd65: morse = charA;
            8'd98, 8'd66: morse = charB;
            8'd99, 8'd67: morse = charC;
            8'd100, 8'd68: morse = charD;
            8'd101, 8'd69: morse = charE;
            8'd102, 8'd70: morse = charF;
            8'd103, 8'd71: morse = charG;
            8'd104, 8'd72: morse = charH;
            8'd105, 8'd73: morse = charI;
            8'd106, 8'd74: morse = charJ;
            8'd107, 8'd75: morse = charK;
            8'd108, 8'd76: morse = charL;
            8'd109, 8'd77: morse = charM;
            8'd110, 8'd78: morse = charN;
            8'd111, 8'd79: morse = charO;
            8'd112, 8'd80: morse = charP;
            8'd113, 8'd81: morse = charQ;
            8'd114, 8'd82: morse = charR;
            8'd115, 8'd83: morse = charS;
            8'd116, 8'd84: morse = charT;
            8'd117, 8'd85: morse = charU;
            8'd118, 8'd86: morse = charV;
            8'd119, 8'd87: morse = charW;
            8'd120, 8'd88: morse = charX;
            8'd121, 8'd89: morse = charY;
            8'd122, 8'd90: morse = charZ;
            default: morse = punctError;
        endcase
    end
endmodule