#!/usr/bin/python

import sys

def eval_(input_):
    mem_cell = [0] * 5000
    c = ''
    ptr = in_ptr = loop = 0

    while in_ptr < len(input_):
        in_ = input_[in_ptr]

        if   in_ == '>': ptr += 1
        elif in_ == '<': ptr -= 1
        elif in_ == '+': mem_cell[ptr] += 1
        elif in_ == '-': mem_cell[ptr] -= 1
        elif in_ == '.': sys.stdout.write(chr(mem_cell[ptr]))
        elif in_ == ',': mem_cell[ptr] = sys.stdin.read(1)
        elif in_ == '[':
            if mem_cell[ptr] == 0:
                loop = 1
                while loop > 0:
                    in_ptr += 1
                    c = input_[in_ptr]
                    if   c == '[': loop += 1
                    elif c == ']': loop -= 1
        elif in_ == ']':
            loop = 1
            while loop > 0:
                in_ptr -= 1
                c = input_[in_ptr]
                if   c == '[': loop -= 1
                elif c == ']': loop += 1
            in_ptr -= 1

        in_ptr += 1



if __name__ == '__main__':
    input_ = ""
    for s in sys.stdin.readlines():
        input_ += s
    eval_(input_)

