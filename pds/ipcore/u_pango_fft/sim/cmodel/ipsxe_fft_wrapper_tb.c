//////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2022 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
//////////////////////////////////////////////////////////////////////////////
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "ipsxe_fft_def_v1_0.h"

// parameters:
// fft_arch          0: pipeline; 1: radix-2 burst
// log2_fft_len      3~16
// output_order      1: natural; 0: bit reversed
// scale_mode        1: block floating point; 0: unscaled
// round_mode        1: convergent rounding; 0: truncation
// input_width       8~34
// twiddle_width     8~34

// configuration:
// fft_mode          1: fft; 0: ifft

void main() {   
    int fft_arch, log2_fft_len, output_order, scale_mode, round_mode, input_width, twiddle_width, fft_mode;
    // -----------------------------------------------   
    int blk_exp;
    
    struct ipsxe_fft_data *xn_comp; 
    struct ipsxe_fft_data *xk_comp;  

    double *re_exp;
    double *im_exp;
    
    int err = 0;
    
    int fft_size;
    int mem_size= 1024;
  
    int i, j;
    
    xn_comp = (struct ipsxe_fft_data*)malloc(mem_size * sizeof(struct ipsxe_fft_data));
    xk_comp = (struct ipsxe_fft_data*)malloc(mem_size * sizeof(struct ipsxe_fft_data));

    re_exp = (double*)malloc(mem_size * sizeof(double));
    im_exp = (double*)malloc(mem_size * sizeof(double));    
      
    // initialization
    for (i=0; i<2; i++) {
        // parameter definitions:
        if (i == 0) {                                     
            fft_arch = 0;
            log2_fft_len = 4;
            output_order = 1;
            scale_mode = 0;    
            round_mode = 1;
            input_width = 16;
            twiddle_width = 16;
            fft_mode = 1;
            xn_comp[0].creal  = 0x7FFF;
            xn_comp[1].creal  = 0x4FCF;
            xn_comp[2].creal  = 0xE384;
            xn_comp[3].creal  = 0x8CAD;
            xn_comp[4].creal  = 0x8CAD;
            xn_comp[5].creal  = 0xE384;
            xn_comp[6].creal  = 0x4FCF;
            xn_comp[7].creal  = 0x7FFF;
            xn_comp[8].creal  = 0x4FCF;
            xn_comp[9].creal  = 0xE384;
            xn_comp[10].creal = 0x8CAD;
            xn_comp[11].creal = 0x8CAD;
            xn_comp[12].creal = 0xE384;
            xn_comp[13].creal = 0x4FCF;
            xn_comp[14].creal = 0x7FFF;
            xn_comp[15].creal = 0x4FCF;
            
            xn_comp[0].cimag  = 0x0000;
            xn_comp[1].cimag  = 0x6413;
            xn_comp[2].cimag  = 0x7CCA;
            xn_comp[3].cimag  = 0x378A;
            xn_comp[4].cimag  = 0xC876;
            xn_comp[5].cimag  = 0x8336;
            xn_comp[6].cimag  = 0x9BED;
            xn_comp[7].cimag  = 0x0000;
            xn_comp[8].cimag  = 0x6413;
            xn_comp[9].cimag  = 0x7CCA;
            xn_comp[10].cimag = 0x378A;
            xn_comp[11].cimag = 0xC876;
            xn_comp[12].cimag = 0x8336;
            xn_comp[13].cimag = 0x9BED;
            xn_comp[14].cimag = 0x0000;
            xn_comp[15].cimag = 0x6413;
            // --------------------------------
            re_exp[0]  = 0x00CFCB;
            re_exp[1]  = 0x01401F;
            re_exp[2]  = 0x04A545;
            re_exp[3]  = 0x1E9446;
            re_exp[4]  = 0x1F9BEE;
            re_exp[5]  = 0x1FE476;
            re_exp[6]  = 0x000869;
            re_exp[7]  = 0x001F46;
            re_exp[8]  = 0x003031;
            re_exp[9]  = 0x003E1B;
            re_exp[10] = 0x004ABD;
            re_exp[11] = 0x00570E;
            re_exp[12] = 0x006412;
            re_exp[13] = 0x00730C;
            re_exp[14] = 0x0085FD;
            re_exp[15] = 0x00A126;
                                     
            im_exp[0]  = 0x006412;
            im_exp[1]  = 0x00F0EB;
            im_exp[2]  = 0x0532CC;
            im_exp[3]  = 0x1D9766;
            im_exp[4]  = 0x1EE203;
            im_exp[5]  = 0x1F3CF8;
            im_exp[6]  = 0x1F6A0C;
            im_exp[7]  = 0x1F86BA;
            im_exp[8]  = 0x1F9BEE;
            im_exp[9]  = 0x1FAD69;
            im_exp[10] = 0x1FBD38;
            im_exp[11] = 0x1FCCAA;
            im_exp[12] = 0x1FDCFD;
            im_exp[13] = 0x1FEFC4;
            im_exp[14] = 0x000784;
            im_exp[15] = 0x002992;            
        } 
        else {
            fft_arch = 1;
            log2_fft_len = 4;
            output_order = 0;
            scale_mode = 1;    
            round_mode = 0;
            input_width = 16;
            twiddle_width = 16;
            fft_mode = 0;

            xn_comp[0].creal  = 0x0EE7;
            xn_comp[1].creal  = 0x16F5;
            xn_comp[2].creal  = 0x554B;
            xn_comp[3].creal  = 0xE5EA;
            xn_comp[4].creal  = 0xF8D3;
            xn_comp[5].creal  = 0xFE06;
            xn_comp[6].creal  = 0x009B;
            xn_comp[7].creal  = 0x023E;
            xn_comp[8].creal  = 0x0375;
            xn_comp[9].creal  = 0x0475;
            xn_comp[10].creal = 0x055C;
            xn_comp[11].creal = 0x063E;
            xn_comp[12].creal = 0x072D;
            xn_comp[13].creal = 0x0840;
            xn_comp[14].creal = 0x099C;
            xn_comp[15].creal = 0x0B8F;
            
            xn_comp[0].cimag  = 0x072D;
            xn_comp[1].cimag  = 0x1147;
            xn_comp[2].cimag  = 0x5F71;
            xn_comp[3].cimag  = 0xD3C7;
            xn_comp[4].cimag  = 0xEB7D;
            xn_comp[5].cimag  = 0xF203;
            xn_comp[6].cimag  = 0xF53F;
            xn_comp[7].cimag  = 0xF74D;
            xn_comp[8].cimag  = 0xF8D3;
            xn_comp[9].cimag  = 0xFA14;
            xn_comp[10].cimag = 0xFB36;
            xn_comp[11].cimag = 0xFC51;
            xn_comp[12].cimag = 0xFD7D;
            xn_comp[13].cimag = 0xFED6;
            xn_comp[14].cimag = 0x008A;
            xn_comp[15].cimag = 0x02FB;
            // --------------------------------            
            re_exp[0]  = 0x1259;
            re_exp[1]  = 0x0B74;
            re_exp[2]  = 0xEF76;
            re_exp[3]  = 0xFBEB;
            re_exp[4]  = 0xFBE9;
            re_exp[5]  = 0xEF76;
            re_exp[6]  = 0x0B72;
            re_exp[7]  = 0x125D;
            re_exp[8]  = 0x0B70;
            re_exp[9]  = 0xFBEA;
            re_exp[10] = 0xFBEA;
            re_exp[11] = 0x0B74;
            re_exp[12] = 0xEF75;
            re_exp[13] = 0xEF76;
            re_exp[14] = 0x125C;
            re_exp[15] = 0x0B75;
                                     
            im_exp[0]  = 0xFFFF;
            im_exp[1]  = 0x0E5A;
            im_exp[2]  = 0xF808;
            im_exp[3]  = 0xEE1B;
            im_exp[4]  = 0x11E7;
            im_exp[5]  = 0x07F7;
            im_exp[6]  = 0xF1A6;
            im_exp[7]  = 0x0000;
            im_exp[8]  = 0x0E59;
            im_exp[9]  = 0x11E7;
            im_exp[10] = 0xEE1A;
            im_exp[11] = 0xF1A6;
            im_exp[12] = 0x07F6;
            im_exp[13] = 0xF80A;
            im_exp[14] = 0xFFFF;
            im_exp[15] = 0x0E59;                        
        }
               
        // run FFT/IFFT
        blk_exp = ipsxe_fft_wrapper_v1_0(xn_comp, xk_comp, fft_arch, log2_fft_len, output_order, scale_mode, round_mode, input_width, twiddle_width, fft_mode);   
    
        fft_size = pow(2, log2_fft_len);
        printf("----------------------------\n"); 
        printf("case%-d:\n", i+1);        
        printf("Transform Length: %-d\n", fft_size);
        printf("Input Data Width: %-d\n", input_width);
        printf("Twiddle Width: %-d\n", twiddle_width);
        
        if (fft_mode == 1)    
            printf("Type: FFT\n");
        else if (fft_mode == 0)
            printf("Type: IFFT\n");
        
        if (fft_arch == 0)    
            printf("Architecture: Pipeline\n");
        else if (fft_arch == 1)
            printf("Architecture: Radix-2 Burst\n");    
        
        if (output_order == 1)    
            printf("Output Order: Natural Order\n");
        else if (output_order == 0)
            printf("Output Order: Bit Reversed\n");  
            
        if (round_mode == 1)    
            printf("Round Mode: Convergent Rounding\n");
        else if (round_mode == 0)
            printf("Round Order: Truncation\n"); 
            
        if (scale_mode == 1)    
            printf("Scale Mode: Block Floating Point\n");
        else if (scale_mode == 0)
            printf("Scale Order: Unscaled\n");     
        
        printf("--------\n"); 
        printf("[Result]\n");                               
        printf("Block Exponential = %d\n", blk_exp);
        for (j=0; j<fft_size; j++) {
            if (xk_comp[j].creal != re_exp[j])
                err = 1;
            else if (xk_comp[j].cimag != im_exp[j])
                err = 1;
        }
        
        if (err == 1)
            printf("FFT Simulation is failed.\n");
        else
            printf("FFT Simulation is successful.\n");
    }
           
    free(re_exp);
    free(im_exp);
    free(xn_comp);
    free(xk_comp);    
}