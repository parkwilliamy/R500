import serial

# MAKE SURE INPUT HANDLING WORKS AT THE END (ie, proper data/file format)

# Configure the serial port
ser = serial.Serial(
    port='COM8',                  # Use COM4
    baudrate=1000000,              # Baud rate: 1000000
    bytesize=serial.EIGHTBITS,    # 8 data bits
    parity=serial.PARITY_NONE,    # No parity bit
    stopbits=serial.STOPBITS_ONE, # 1 stop bit
    timeout=1                     # 1 second timeout for reads
)

def main():

    if ser.isOpen():
        print("Serial port COM4 opened successfully.")
    else:
        ser.open()
    
    while (1):
        while (1):
            mode = "".join(input("Enter R for Read Mode, Enter W for Write Mode, Enter q to quit: ").split())
            if mode == "R" or mode == "W":
                break
            elif mode == "q":
                quit()

        MEM_SIZE = 0x8000
        MEM_WORDS = ((MEM_SIZE-4) // 4) + 1
        ADDR_LOW = -1
        ADDR_HIGH = -1
        
        if mode == "R":
            while (ADDR_LOW < 0 or ADDR_LOW > MEM_SIZE or ADDR_LOW % 4 != 0):
                ADDR_LOW = "".join(input(f"Enter start address, must be a multiple of 4 and between 0 and {hex(MEM_SIZE)}: ").split())
                ADDR_LOW = int(ADDR_LOW, 0)

            while (ADDR_HIGH < ADDR_LOW or ADDR_HIGH > MEM_SIZE or ADDR_HIGH % 4 != 0):
                ADDR_HIGH = "".join(input(f"Enter end address, must be a multiple of 4 and between {hex(ADDR_LOW)} and {hex(MEM_SIZE)}: ").split())
                ADDR_HIGH = int(ADDR_HIGH, 0)

            read_mem_frame(ADDR_LOW, ADDR_HIGH)

            data_word = 0

            while data_word != b'':
                data_word = ser.read(4)
                if data_word != b'':
                    print(data_word.hex())
            

        elif mode == "W":
            MEM_FILE = "".join(input(f"Enter path to program/data file, must be .hex format: ").split())

            words_written = 0

            with open(MEM_FILE, "r") as f:
                for line_num, line in enumerate(f):
                    word_str = line.strip()
                    word = int(word_str, 16)

                    addra = line_num*4
                    wea = 0b1111

                    write_mem_frame(addra, wea, word)

                    words_written += 1

            while (words_written < MEM_WORDS):

                addra = words_written*4
                wea = 0b1111

                write_mem_frame(addra, wea, 0x00000000)

                words_written += 1

def write_mem_frame(addra, wea, word):

    start = 0x0F
    addra = format(addra, "016b")
    wea = format(wea, "08b")
    word = format(word, "032b")
    
    frame = [
        start,
        int(addra[8:16], 2),
        int(addra[0:8],  2),
        int(wea, 2),
        int(word[24:32],2),
        int(word[16:24],2),
        int(word[8:16], 2),
        int(word[0:8],  2),
    ]
    ser.write(bytes(frame))

def read_mem_frame(ADDR_LOW, ADDR_HIGH):

    start = 0xFF

    ADDR_LOW = format(ADDR_LOW, "016b")
    ADDR_HIGH = format(ADDR_HIGH, "016b")

    frame = [
        start,
        int(ADDR_HIGH[8:16], 2),
        int(ADDR_HIGH[0:8],  2),
        int(ADDR_LOW[8:16],  2),
        int(ADDR_LOW[0:8],   2),
    ]

    ser.write(bytes(frame))

if __name__ == "__main__":
    main()