# Overview
This readme explains the functionality and interface of vdecode.sv .

## Purpose of module
VDecode module serves two purposes:

- Improve connectability of RISC-V2 .

- Τurn RISC-V2 fully compatible with RISC-V "V" Vector Extension Version 1.0 . 

### Interface
The module needs a negative reset and a clock as inputs to operate.

Inputs of the module :
 - Ready  signal of vector processor.
 - Valid  signal of the scalar processor or the buffer/queue that holds the instruction .
 - 96-bit signal that includes three separate 32-bit fields as shown below. 

        |:---------------------------------------------------------------:|
        |                         96 bit signal                           |
        |:------32-bits------:|:------32-bits------:|:------32-bits------:|
        | 95               64 | 63               32 | 31                0 |  
        |:-------------------:|:-------------------:|:-------------------:|
        |     instruction     |        data2        |        data1        |
        |:---------------------------------------------------------------:|

 Since the vector processor doesn't have access at the scalar register file, we need to pass the values of those registers through those two 32-bit fields, data1 and data2. Data1 and Data2 refer to rs1 and rs2 ( if necessary ) respectively, as they are clarified from the instruction format of the isa.


Outputs of the module :
 - Encoded format of the instruction . 
 - Ready signal that ends up at the scalar processor or the buffer/queue , declaring whether the vector processor is ready to fetch a new instruction .
 - Valid signal that ends up at the vector processor , declaring whether the scalar processor pushed a new valid instruction .

#### Lmul and Sew restrictions
All lmuls are supported from the RISC-V2.

RISC-V2 is designed only for 32-bit arithmetic operations even though loads of 8,16-bit elements are supported. In order to be compatible with the those sew values, we store those them in 32-bit elements and operate as they were 32-bit. At the end the store of the operation will keep the 8 or 16 less significant bits. Also for a vector register length of 256 bit, as RISC-V2 is designed, we expect 32 and 16 elements to be operated at every instruction respectively. Since we support only 32-bit elements we must change our lmul to achieve it. Below is the supported sews and lmuls for every combination of lmul and sew. 

            _____________________ _____________________ _____________________ _____________________
           |          M1         |          M2         |         M4          |          M8         |
           |:-------------------:|:-------------------:|:-------------------:|:-------------------:|
    e8     |          m4         |          m8         |          X          |          X          | 
           |:-------------------:|:-------------------:|:-------------------:|:-------------------:|
    e16    |          m2         |          m4         |         m2          |          X          | 
           |:-------------------:|:-------------------:|:-------------------:|:-------------------:| 
    e32    |          m1         |          m2         |         m4          |          m8         |
           |:-------------------:|:-------------------:|:-------------------:|:-------------------:| 
    e64    |          m1         |          m2         |         m4          |          m8         |
           |:-------------------:|:-------------------:|:-------------------:|:-------------------:|
            
 * X-label is initial LMUL, Y-label is SEW . Value of cell defines the final lmul value we will use for the combination of initial lmul and sew selected .     
 * X means that combination of lmul and sew is not supported .