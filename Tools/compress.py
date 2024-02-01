# python3

''' 
Encodes a blob of data using run lenghth encoding
in the form length, data.
'''

import sys
import argparse

def genericRLE(origData):
    count = 1
    toRet = bytearray()
    # Truncate to 512 bytes. Safe to do
    origData = origData[:512]
    prev = origData[0]
    
    # Max count is 255 as the VIC is an 8-bit system
    for b in origData:
        if b == prev:
            if count >= 255:
                toRet += bytearray([count,prev])
                count = 1
            else:
                count += 1
        elif b != prev:
            toRet += bytearray([count,prev])
            prev = b
            count = 1
    
    toRet += bytearray([count, prev])
    toRet += bytearray([0]) # Terminator
    return toRet


def screenSpecific(fill, addrs, origData):
    count = 1
    prev = origData[0]
    current_addr = 0
    offsets = addrs
    datta = bytearray([fill, offsets[0]//256, offsets[0]%256])
    
    for b in range(1, len(origData)):
        if origData[b] == 0:  # used to denote end of line/row
            datta += bytearray([count, prev])
            try:
                current_addr += 1
                datta += bytearray([0, offsets[current_addr]//256, offsets[current_addr]%256])
            except Exception as e:
                datta += bytearray([0])

            count = 0
            try:
                prev = origData[b+1]
            except:
                pass
        elif origData[b] == prev:
            if count >= 255:
                datta += bytearray([count, prev])
                count = 1
            else:
                count += 1
        elif origData[b] != prev:
            datta += bytearray([count, prev])
            prev = origData[b]
            count = 1

    datta += bytearray([0])
    return datta 


# simple. no compression but does use less space than rle
def custom(origData, addrs, fill):
    datta = bytearray([fill, addrs[0]//256, addrs[0]%256])
    curr = 1
    for b in origData:
        if b == 0:
            try:
                datta += bytearray([0, addrs[curr]//256, addrs[curr]%256])
                curr += 1
            except Exception as e:
                datta += bytearray([0])
        else:
            datta += bytearray([b])

    datta += bytearray([0])
    return datta 


# Converts hexstring to int
def inthex(x):
    return int(x, 16)


if __name__=="__main__":
    
    parser = argparse.ArgumentParser()
    parser.add_argument("-type", type=str, choices=["generic", "screenSpecificRLE", "custom"], default="genericRLE", help="Spcify type of compression. Default is generic RLE.")

    parser.add_argument("-fill", type=int, default=0x20, help="Fill with value. Used for screenSpecific RLE encoding. Default is 0x20 which is a space")

    parser.add_argument("-input", type=str, default=None, help="Data to encode in binary", required=True)
    parser.add_argument("-output", type=str, default="out.bin", help="Output file of compressed data. Default is out.bin")
    parser.add_argument("-address", type=inthex, default=None, nargs="+", help="The destination addresses in hex form. Used with screenSpecificRLE.")

    args = parser.parse_args()
    
    inputFile = args.input
    outputFile = args.output
    addresses = list(args.address)
    fill = args.fill

    if args.type == "screenSpecificRLE" or args.type == "custom":
        if args.address is None or len(args.address) == 0:
            print("Pass in list of destination addresses for this type of encoding.", sys.stderr)
            parser.print_help()

    
    data = []
    with open(inputFile, 'rb') as f:
        data = f.read() 
        f.close()
    
    #  print(f"Data to encode: {data}")

    freq = {}

    for b in data:
        if b == ',' or b == '$':
            continue
        if b in freq.keys():
            freq[b] += 1
        else:
            freq[b] = 1

    print(freq)
    encdata = None
    if args.type == "generic":
        encdata = genericRLE(data)
    elif args.type == "screenSpecificRLE":
        encdata = screenSpecific(fill, addresses, data)
    elif args.type == "custom":
        encdata = custom(data, addresses, fill)

    with open(outputFile, 'wb+') as f:
        f.write(bytes(encdata))
        f.close()

    #  print(screenSpecific(32, 0x1e02, data))
    print(f"Encoded data saved in {outputFile}")


