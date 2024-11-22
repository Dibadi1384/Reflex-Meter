// -------------------------------------------------------------------------------------
// Name:        Lab_4.S
// Purpose:     This code has 2 parts: the first part is to flash all 8 LED's on and off
//              at a rate between 1 - 10Hz while the random number generator is called
//              continuosly. The random number generated will generate a number that
//              gives a time delay of 5.0 to 25.0 seconds. with a resolution of 0.1s.
//              Pressing pushbutton S1 will create an interrupt in the microprocessor, 
//              forcing the interrupt service routine (ISR) to run.
//              The ISR program displays this random number (without a decimal) on 
//              the 8 LED's.  The program delays for 1 second (count of 10) and the
//              new count (time left) is diplayed. This continues until the count is
//              equal to or less than 0.  The program then exits the ISR and returns to
//              the main program and flashes all 8 LED's again as before.  
//              The program then waits for another press of pushbutton S1 and everything
//              repeats.

// Author:      Julius Olajos
// -------------------------------------------------------------------------------------

.section .text
.align 2
.globl _start

// Constants
GPIO_BASE                   = 0x10012000      // GPIO base address
GPIO_OUTPUT                 = 0x0C            // GPIO output register offset
GPIO_OUTPUT_ENABLE           = 0x08            // GPIO output enablr register offset
GPIO_INPUT                  = 0x00            // GPIO input register offset
GPIO_INPUT_ENABLE           = 0x04            // GPIO input enable register offset
GPIO_7SEGLED_PINS           = 0x0000023F      // Seven Segment LED Display Pins (7)
GPIO_LEDBAR_PINS            = 0x00FC0C00      // LED Bar Pins (8)
GPIO_ALL_LED_PINS           = 0x00FC0E3F      // All LED Pins (15)
GPIO_FALL_INTERRUPT_ENABLE  = 0x20            // Falling edge interrupt enable register offset
GPIO_FALL_INTERRUPT_PENDING = 0x24            // Falling Edge interrupt pending register offset
GPIO_IO_FUNCTION_ENABLE     = 0x028           // I/O function enable register offset
GPIO_IO_FUNCTION_SELECT     = 0x02C           // I/O function select register offset
GPIO_SW_1                   = 0x00001000      // SW1 pushbutton (bit 12)
GPIO_SW_2                   = 0x00002000      // SW2 Pushbutton (bit 13)
PLIC_BASE                   = 0x0C000000      // PLIC base address
PLIC_ENABLE                 = 0x2000          // PLIC interrupt enable register offset
PLIC_PRIORITY               = 0x0004          // PLIC priority register offset
PLIC_THRESHOLD              = 0x200000        // PLIC threshold register offset
PLIC_CLAIM                  = 0x200004        // PLIC claim/complete register offset
PLIC_INT_PEND               = 0x1000          // PLIC Interrupt pending register 1 offset
S1_GPIO_PIN                 = 12              // S1 pushbutton pin number (active low)
S1_IRQ                      = 12              // IRQ number for GPIO pin 12
S1_PLIC_ID                  = 20              // PLIC Interrupt source ID for GPIO pin 12
S1_PRIORITY                 = 7               // Interrupt priority for S1


// --------------------------------------------------------------------------------------------------------------
// This is the setup for the interrupt functionality of the RISC-V processor
//
// --------------------------------------------------------------------------------------------------------------

_start:
    // Set up mtvec with the address of the interrupt vector (S1_interrupt)
    la t0, S1_interrupt
    csrw mtvec, t0

    // Enable external machine interrupts in the mie register
    li t0, (1 << 11)                      // Enable machine external interrupts (MEIE bit in MIE register)
    csrs mie, t0

    // Enable global interrupts in the mstatus register
    csrr t0, mstatus
    li t1, (1 << 3)                       // Set MIE (Machine Interrupt Enable) bit mask in mstatus
    or t0, t0, t1
    csrw mstatus, t0

// You need to set up the pushbutton S1 in the GPIO pins as an input. Refer to your Lab 3 code.

// --------------------------------------------------------------------------------------------------------------

//                   ;This is where you put your code for setting up the S1 pushbutton input

_configure_pb:
    li t0, GPIO_BASE          // Load Base Address for GPIO Control Registers
    li t1, GPIO_SW_1                    // Load GPIO Register to set GPIO_INPUT_EN for input pins
    sw t1, GPIO_INPUT_ENABLE(t0)            // Enable inputs on S1 Pushbutton pins   



// --------------------------------------------------------------------------------------------------------------

// You need to set up the LED's in the GPIO pins as outputs. Refer to your Lab 3 code.

// --------------------------------------------------------------------------------------------------------------

//                   ;This is where you put your code for setting up the LED outputs

    li t0, GPIO_BASE          // Load Base Address for GPIO Control Registers

    li t1, GPIO_ALL_LED_PINS            // Load GPIO Register to set GPIO_OUTPUT_EN and GPIO_OUTPUT_XOR registers for all GPIO LED Pins
    sw t1, GPIO_OUTPUT_ENABLE(t0)           // Enable outputs on all GPIO LED Pins
    li t2, 0xFF03F1C0
    sw t2, GPIO_OUTPUT(t0)          // Set all LED pins to zero to turn off all LEDS.


// --------------------------------------------------------------------------------------------------------------

// You need to configure the GPIO interrupt to trigger when S1 (GPIO pin 12) is on a falling edge.


//                   ;This is where you put your code for setting up the S1 pushbutton input interrupt
//                   ;trigger on a falling edge.

    li t0, GPIO_BASE
    li t1, GPIO_SW_1
    sw t1, GPIO_FALL_INTERRUPT_ENABLE(t0)

// --------------------------------------------------------------------------------------------------------------

    // Enable PLIC for S1 interrupt  
    li t1, PLIC_BASE + PLIC_ENABLE         // Calculate address of PLIC interrupt enable register
    li t2, (1 << 20)                       // Set bit 20 for PLIC Interrupt Source ID = 20 (GPIO pin 12)
    sw t2, 0(t1)

    // Set PLIC priority for S1 interrupt  // Set PLIC priority 
    li t1, PLIC_BASE
    li t2, 4*(S1_PLIC_ID)                  // Calculate address of Interrupt Priority Regoster
    add t2, t2, t1
    li t3, S1_PRIORITY                     // Set interrup priority = 7
    sw t3, 0(t2)

    // Set PLIC threshold to 6 (allow all interrupts)
    li t1, PLIC_BASE + PLIC_THRESHOLD      // Calculate address of PLIC threshold register
    li t2, 6                               // Set threshold to 6.  Masks all interrups of priority 6 or less
    sw t2, 0(t1) 

// --------------------------------------------------------------------------------------------------------------
 
// Main Program: Keep looping, let the interrupt handle events

// Initialize random number generator
 	li a7, 0xABCD

main_program:
//                   ;This is where you put your code for flashing LED's 
     flash_leds:
    // Turn all LEDs ON
    li t0, GPIO_BASE          // Load the GPIO base address
    li t1, GPIO_LEDBAR_PINS               // Set the value to 0xFF (all LEDs ON)
    sw t1, GPIO_OUTPUT(t0)    // Write to the GPIO output register to turn LEDs ON

    // Delay to keep LEDs ON for a short period (adjust to your needs)
    li a0, 0xF4240 
    jal ra, DELAY                 // Call delay subroutine for a short period

    // Turn all LEDs OFF
    li t0, GPIO_BASE          // Load the GPIO base address
    li t1, 0x00000000               // Set the value to 0x00 (all LEDs OFF)
    sw t1, GPIO_OUTPUT(t0)    // Write to the GPIO output register to turn LEDs OFF

    // Delay to keep LEDs OFF for a short period (adjust to your needs)
    li a0, 0xF4240 
    jal ra, DELAY                 // Call delay subroutine for a short period

    j main_program          // Continue in an infinite loop



DISPLAY_8_BIT:
    // This function takes in 8 bit number a0 and reads it

    addi sp, sp,-4
    sw ra, 0(sp)

    mv t0, a0
    li t1, 0xFFFFFFFC // 1111 1100 // 0 bits 16 and 17
    and t0, t0, t1
    slli t0, t0, 16

    // now t0 contains the correct bits 18:23

    mv t2, a0
    li t1, 0xFFFFFF03 // 0000 0011 // 0 bits 16 and 17
    and t2, t2, t1
    slli t2, t2, 10

    or t0, t0, t2
    // t0 now contains correct bit mask
    // 1110
    mv a0, t0 // 0b 0000 0000 0001 0000 0000 0000 0000 0000

    li t0, GPIO_BASE          // Load Base Address for GPIO Control Registers
    sw a0, GPIO_OUTPUT(t0)      // Set a0 LED value

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

DELAY:
    addi sp, sp,-4
    sw ra, 0(sp)

DELAY_OUTER:
    li t4, 0xC3500 // = 800,000 => 100ms atomic delay. 

DELAY_INNER:
    addi t4, t4, -1          // Decrement the counter value in t4
    bnez t4, DELAY_INNER      // Branch to loop1 if t4 is not zero
    addi a0, a0, -1          // a0 stores the multiplier * 100ms
    bnez a0, DELAY_OUTER     // Branch to loop1 if t4 is not zero

    lw ra, 0(sp)
    addi sp, sp, 4
    ret



// Random Number generator Subroutine
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

// --------------------------------------------------------------------------------------------------------------
// Interrupt Service Routine (ISR) for S1 interrupt
S1_interrupt:

    addi sp, sp,-8
    sw s6, 0(sp)
    sw s5, 4(sp)

      // Acknowledge the interrupt in the PLIC (write the IRQ number to PLIC claim/complete register)
    li t1, PLIC_BASE + PLIC_CLAIM          // Calculate address of PLIC claim/complete register
    lw t5, 0(t1)                           // Read the PLIC Interrupt ID
    mv s5, t5

//                   ;This is where you put your code:
//                   ;Calculate the time from the randomly generated number in register a7. You will have to scale the random number. Perhaps a7 mod 200 + 50 would work?
//                   ;Display this number on the 8 LED's
//                   ;Subtract 10 (Hex A) and display the number again until it is less than or equal to 0
//                   ;Reset counter to 0 before exiting the subroutine so it's ready to be used again

    jal ra, RandomNum // generate random num
    mv a0, a7 // load a7 random num into a0

    li t0, 200
    and t1, a0, t0

    //a7 = a7 + z
    li t0, 50
    add t1, t1, t0

    mv a0, t1

    mv s6, a0 // load scaled random number into s0

    DECREMENTLOOP:
        // Check if number is less than <= 0
        bge x0, a0, DISPLAY_ZERO

        mv a0, s6
        jal ra, DISPLAY_8_BIT

        addi s6, s6, -10 // decrement s0 by 10

        li a0, 10
        jal ra, DELAY

        j interrupt_comp        

    DISPLAY_ZERO:
        mv a0, x0
        jal ra, DISPLAY_8_BIT

        li a0, 10
        jal ra, DELAY


// You need to clear the interrupt pending flag for S1 (GPIO pin 12). Refer to Appendix I in the lab manual
//                   ;This is where you put your code for clearing the interrupt pending flag for S1

        li t0, GPIO_BASE
        li t1, GPIO_SW_1
        sw t1, GPIO_FALL_INTERRUPT_PENDING(t0)


// You need to acknowledge the interrupt is complete in the PLIC Refer to Appendix I in the lab manual
//                   ;This is where you put your code for acknowledging the interrupt in the PLIC

        li t1, PLIC_BASE + PLIC_CLAIM          // Calculate address of PLIC claim/complete register
        sw s5, 0(t1)                           // Store the PLIC Interrupt ID
        
        lw s6, 0(sp)
        lw s5, 4(sp)
        addi sp, sp, 8

        li a0, 1 // bugs out otherwise
        li t4, 0xC3500

end_interrupt:
    mret                                   // Return from interrupt

      

