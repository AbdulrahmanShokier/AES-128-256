import random
import os

# ============================================
# SETTINGS - Change these as you need
# ============================================
N_SYMBOLS = 2000           # How many symbols (each = 3 bits)
MODE      = 'random'      # 'random', 'zeros', 'ones', 'alt', 'pattern'
PATTERN   = ['101',       # Only used if MODE = 'pattern'
              '110', 
              '011']      
FILENAME  = 'data_bits.txt'  # Output file name
# ============================================


def generate_bits(n_symbols, filename, mode, pattern):

    with open(filename, 'w') as f:
        for i in range(n_symbols):

            if mode == 'random':
                bits = ''.join([str(random.randint(0, 1)) for _ in range(3)])

            elif mode == 'zeros':
                bits = '000'

            elif mode == 'ones':
                bits = '111'

            elif mode == 'alt':
                bits = '101' if i % 2 == 0 else '010'

            elif mode == 'pattern':
                bits = pattern[i % len(pattern)]

            else:
                print(f'Unknown mode: {mode}, defaulting to random')
                bits = ''.join([str(random.randint(0, 1)) for _ in range(3)])

            f.write(bits + '\n')


    print('=========================================')
    print(f'  Symbols generated : {n_symbols}')
    print(f'  Total bits        : {n_symbols * 3}')
    print(f'  Mode              : {mode}')
    print(f'  Saved to          : {os.path.abspath(filename)}')
    print('=========================================')


# ============ RUN ============
generate_bits(N_SYMBOLS, FILENAME, MODE, PATTERN)