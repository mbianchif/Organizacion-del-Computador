class col:
    green = '\033[92m'
    white = '\033[0m'


def TFA(num,base):
    length = len(num)
    total = 0
    i = 1
    for c in num:
        try:
            n = int(c)
        except:
            n = ord(c.upper()) - 55
        total += n*base**(length - i)
        i += 1
    return total
    

def SUCDIV(num,base):
    digits = []
    while num != 0:
        div = int(num / base)
        rem = int(num % base)
        num = div
        digits.insert(0, rem)
    return "".join(digits)


def printRes(res,dst,type):
    print(col.green + '> ' + col.white, end='')
    print('{}[{}]'.format(res, dst))


def transformer():
    msg = '\n_______[SRC] -> [DES]\n\n'
    line = input(msg + col.green + '> ' + col.white)

    num = line[:line.find('[')]
    src = int(line[line.find('[')+1:line.find(']')])
    dst = int(line[line.find('-> [')+4:line.find(']\n')])

    if src == dst or dst == 1:
        quit()

    if dst == 10:
        printRes(TFA(num, src), dst, 'int')

    elif src == 10:
        printRes(SUCDIV(int(num), dst), dst, 'list')

    else:
        printRes(SUCDIV(TFA(num, src), dst), dst, 'list')
        

if __name__ == '__main__':
    transformer()