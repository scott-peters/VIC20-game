# python3

'''
@author: Shankar Ganesh
@date: 16 Sep 2022
Takes in two arguments: the assembly and output name
Processes a 6502 assembly file.
Converts ASCII strings to PETSCII, if valid
'''

import sys
import re

ascii_to_petscii = {
        ' ':    '32',
        '!':    '33',         
        '"':    '34',           
        '#':    '35',           
        '$':    '36',           
        '%':    '37',           
        '&':    '38',           
        "'":    '39',           
        '(':    '40',           
        ')':    '41',           
        '*':    '42',           
        '+':    '43',           
        ',':    '44',           
        '-':    '45',           
        '.':    '46',           
        '/':    '47',           
        '0':    '48',           
        '1':    '49',           
        '2':    '50',           
        '3':    '51',           
        '4':    '52',           
        '5':    '53',           
        '6':    '54',           
        '7':    '55',           
        '8':    '56',           
        '9':    '57',           
        ':':    '58',           
        ';':    '59', 
        '<':    '60',         
        '=':    '61',         
        '>':    '62',         
        '?':    '63',         
        '@':    '64',         
        'A':    '65',         
        'B':    '66',
        'C':    '67',
        'D':    '68',
        'E':    '69',
        'F':    '70',
        'G':    '71',
        'H':    '72',
        'I':    '73',
        'J':    '74',
        'K':    '75',
        'L':    '76',
        'M':    '77',
        'N':    '78',
        'O':    '79',
        'P':    '80',
        'Q':    '81',
        'R':    '82',
        'S':    '83',
        'T':    '84',
        'U':    '85',
        'V':    '86',
        'W':    '87',
        'X':    '88',
        'Y':    '89',
        'Z':    '90',
        '[':    '91',
        '\\':   '92',
        ']':    '93',
        '^':    '94' 
        }
    
def convert(string: str) -> str:
    constr = str()
    inString = False
    entries = 0
    for char in string.upper():
        if char == '"':
            inString = not inString
            continue
        if char == ',' and not inString:
            continue
        try:
            constr += ascii_to_petscii[char] + ","
            entries += 1
            if entries >= 10:
                constr = constr[:-1]
                constr += "\n"
                entries = 0
        except KeyError:
            print(f"Invalid char string: {char}", file=sys.stderr)
    
    return constr[:-1]


def process(file: str, out: str):
    lines = []
    try:
        f = open(file, 'r')
        lines = f.readlines()
        f.close()
    except Exception as e:
        print(f"Failed to open {file}.\n", e, file=sys.stderr)
        return
    
    print("Converting... ", end='')
    if len(lines) == 0:
        print("\nFile empty. Nothing to do.")
        return

    
    output = []
    for line in lines:
        res = re.findall('^([^;]*dc(\.b)?\s*)(".*")+(.*)', line, re.IGNORECASE)
        if len(res) == 0:
            output += [line]
            continue

        for mtch in res:
            output += [mtch[0]]
            tabs = mtch[0].count('\t')
            spaces = mtch[0].count(' ')-1
            toreplace = "\n" + '\t'*tabs + ' '*spaces + "dc" + mtch[1] + '\t'
            toAdd = convert(mtch[2]).replace('\n', toreplace)
            output += [toAdd] + [mtch[3]]
    
    print("Success")
    print(f"Writing to {out}... ", end='')
    try:
        with open(out, 'w+') as f:
            for line in output:
                f.write(line)
    except Exception as e:
        print(f"Failed to write to {out}.\n", e, file=sys.stderr)
        return

    print('Success')


if __name__=='__main__':
    
    if len(sys.argv) != 3:
        print(f"Usage: python3 {sys.argv[0]} <file> <output>", file=sys.stderr)
        sys.exit(1)

    process(sys.argv[1], sys.argv[2])

