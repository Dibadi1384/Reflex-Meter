
.section .text
.align 2
.globl _start


// -------------------------------------------------------------------------------------
// Name:        Lab_3.S
// Purpose:     This code has 2 parts: the first part is to create a simple counter
//              subroutine that increments from 0x00 to 0xFF, wraps to 0 and continues
//              counting.  There is a 100ms delay between the display of the count. 
//		The second part is a reflex meter that will measure how fast
//              a user responds to an event accurate to a 10th of a millisecond.
//              Initially, all LED's are off and after a random amount of time
//              (between 2 and 10 seconds), one LED turns on (LED_6) and then the user
//		presses pushbutton S1.  The press of the button will be monitored by
//		using "polling".
//
// Author:      Julius Olajos
// -------------------------------------------------------------------------------------


_start:

// -------------------------------------------------------------------------------------
// GPIO Control Registers Memory Mapping

    .equ GPIO_BASE_CTRL_ADDR, 0x10012000    // Base address for the GPIO control registers
    .equ GPIO_OUTPUT_EN,      0x08          // address offset for enabling GPIO outputs
    .equ GPIO_OUTPUT_VAL,     0x0C          // Address offset for writing to GPIO outputs
    .equ GPIO_OUTPUT_XOR,     0x40          // Address offset for GPIO Outputs XOR
    .equ GPIO_INPUT_VAL,      0x00          // Address offset for reading GPIO inputs
    .equ GPIO_INPUT_EN,       0x04          // address offset for enabling GPIO inputs
    .equ GPIO_PUE,            0x10          // address offset for internal GPIO pull-up resistor

// -------------------------------------------------------------------------------------
// 8 LEDS, 7 Segment LED Display Pins Register Address Mapping

    .equ GPIO_7SEGLED_PINS,   0x0000023F      // Seven Segment LED Display Pins (7)
    .equ GPIO_LEDBAR_PINS,    0x00FC0C00      // LED Bar Pins (8)
    .equ GPIO_ALL_LED_PINS,   0x00FC0E3F      // All LED Pins (15)
    .equ GPIO_LEDBAR_LED_1,   0x00000800      // LEDBAR LED1

// -------------------------------------------------------------------------------------
// Pushbuttons SW(x) Register Address Mapping

    .equ GPIO_SW_1,           0x00001000      // SW1 pushbutton (bit 12)
    .equ GPIO_SW_2,           0x00002000      // SW2 Pushbutton (bit 13)
    .equ GPIO_ALL_PBS,        0x00003000      // All Pushbutton Pins (bits 12, 13)

// Initialize the GPIO control registers
// -------------------------------------------------------------------------------------

    li t0, GPIO_BASE_CTRL_ADDR          // Load Base Address for GPIO Control Registers
    li t1, GPIO_ALL_LED_PINS            // Load GPIO Register to set GPIO_OUTPUT_EN and GPIO_OUTPUT_XOR registers for all GPIO LED Pins
    sw t1, GPIO_OUTPUT_EN(t0)           // Enable outputs on all GPIO LED Pins
    li t2, 0xFF03F1C0
    sw t2, GPIO_OUTPUT_VAL(t0)          // Set all LED pins to zero to turn off all LEDS.
    li t1, GPIO_SW_1                    // Load GPIO Register to set GPIO_INPUT_EN for input pins
    sw t1, GPIO_INPUT_EN(t0)            // Enable inputs on all Pushbutton pins

// -------------------------------------------------------------------------------------


INITIAL:
    li a7, 0xABCD                   // Initializes register a7 to a 16-bit non-zero value
    j REFLEXT_METER

COUNTER:
    li s0, 0                   // Initialize counter to 0
    li s1, 255                  // Load the constant 256 into t1

COUNT_LOOP:
    // Check if counter has reached 256 (0x100)
        bge s0, s1, RESET_COUNTER
    

    // Set a7 to the current counter value (0 - 255)
    mv a2, s0               // Copy counter value to a2
    jal ra, DISPLAY_NUM          // Call the display routine

    li a0, 1000
    jal ra, DELAY                // Call the delay routine

    // Increment the counter
    addi s0, s0, 1               // Increment counter
    j COUNT_LOOP                 // Jump back to count loop
    
RESET_COUNTER:
    j COUNTER                 

REFLEXT_METER: //for reflex meter
//  Generate random number
    jal ra, RandomNum

//  Once your number has been generated, it will be stored in register a7. Do not overwrite this!
//  You will now need to set up delays, subroutines to turn the LED ON and OFF, and for polling whether the Pushbutton S1 has been pressed.
//  Keep in mind that you will get a 32-bit number back from the random number generator.  You will need to display this 8 bits at a time,
//  starting with the lowest 8 bits.
//  You will probably want to rotate 8 bits at a time for display.
//   --------------- Place your code here ----------------------------------------

    //part a- turn leds off
    li t0, GPIO_BASE_CTRL_ADDR
    sw zero, GPIO_OUTPUT_VAL(t0)

    //part b, scale and offset random number-this could be wrong
    mv a0, a7 //not overwritting a7

    li t0, 122                         // Load scale factor (122) into t0
    mul a0, a0, t0                      // Scale random value by 122

    li t1, 80000                        // Load modulus value (80000) into t1
    rem a0, a0, t1                      // Reduce random value to stay within range [0, 79999]

    li t1, 20000                        // Load minimum delay (20000) into t1 (2 seconds)
    add a0, a0, t1                      // Add minimum delay to random value (range 20000 to 99999)

    jal ra, DELAY                       // Call DELAY subroutine

    //part d turn led 6 on
    li t0, GPIO_BASE_CTRL_ADDR
    li t1,  (1 << 22)                // Load a mask with bit 6 set (for LED_6) 
    sw t1, GPIO_OUTPUT_VAL(t0)     // Write to GPIO register to turn on LED_6

    li s1, 0 //set value for increment counter

INCREMENT_LOOP:
    addi s1, s1, 1                //Increment counter register s1

    //part e, monitor status of the s1 button
    li t0, GPIO_BASE_CTRL_ADDR
    lw t1, GPIO_INPUT_VAL(t0)           // Read GPIO input value
    li t2, GPIO_SW_1                    // Set bitmask for switch 1
    and t1, t1, t2                      // Check if switch 1 is pressed
    beqz t1, DISPLAY                    // Branch to DISPLAY if pressed, part f

    // 0.1 ms delays
    li a0, 1                       
    jal ra, DELAY                      

    j INCREMENT_LOOP              


DISPLAY:    
// Display the 32-bit number on the 8-LED Bar

// Register t1 holds the value of the number to be displayed
// Map each bit of the number to the corresponding LED Bar bit
// MSB to LSB: bits 23, 22, 21, 20, 19, 18, 11, 10


//part j, do 4 times
li t5, 4 //number of times the 8-bit loop runs
mv a3, s1
j DISPLAY_LOOP

DISPLAY_NUM:
// Remember, the 8 LEDS are mapped to the GPIO as bits MSB to LSB: bits 23, 22, 21, 20, 19, 18, 11, 10
//   --------------- Place your code here for displaying the 8-bit values --------------- 

li t0, GPIO_BASE_CTRL_ADDR //base address
li t1, 0         // Initial value for GPIO output (all LEDs off), turn to 0 if dont work
li t2, 0

srli t3, a2, 2            // Shift right by 2 to get upper 6 bits (bits 23-18)
slli t3, t3, 18           // Shift to LED bar position (position 18-23)

andi t2, a2, 0x3          // Mask with 0x3 (binary: 11) to get lower 2 bits (bits 1 and 0)
slli t2, t2, 10           // Shift to LED bar position (position 10-11)

or t5, t2, t3
sw t5, GPIO_OUTPUT_VAL(t0)//output to gpio

ret


DISPLAY_LOOP:
    //part g, get the first lowest-8-bits
    andi a2, a3, 0x0FF //get the lowest 8-bits
    jal ra, DISPLAY_NUM //find bit patter for that 8-bit segment, display

    //part h, wait for two seconds
    li a0, 20000
    jal ra, DELAY

    srli a3, a3, 8 //fix the register for the next 8 bits, part i

    addi t5, t5, -1
    blt t5, zero, END_DISPLAY
    j DISPLAY_LOOP

//part k, wait 5 seconds
END_DISPLAY:
    li a0, 50000
    jal ra, DELAY
    j DISPLAY 

  
// Random Number generator
// Register a7 holds the random number.
// You can read this value anywhere in the code, but this register can only be written to by this subroutine
// Or Else!

RandomNum:
     addi sp, sp, -16
     sw ra, 12(sp)


     li s4, 0x8000		     // Load upper 20 bits
     and t1, a7, s4  		     // Mask to lower 16 bits
     li s4, 0x2000  		     // Load upper 20 bits
     and t3, a7, s4  		     // Mask to lower 16 bits


     slli t3, t3, 2
     xor t3, t1, t3
     li s4, 0x1000  		     // Load upper 20 bits
     and t1, a7, t0		     // Mask to lower 16 bits

     slli t1, t1, 3
     xor t3, t3, t1
     andi t1, a7, 0x0400
     slli t1, t1, 5
     xor t3, t3, t1
     srli t3, t3, 15
     slli a7, a7, 1
     or a7, a7, t3		     // Register a7 holds the random number

     lw ra, 12(sp)
     addi sp, sp, 16
     ret

DELAY:
    addi sp, sp, -16
    sw ra, 12(sp)
    
    mv t0, a0 
    li t1, 800
    mul t0,t0,t1         

DelayLoop:
    addi t0, t0, -1
    bnez t0, DelayLoop

    lw ra, 12(sp)
    addi sp, sp, 16
    ret


