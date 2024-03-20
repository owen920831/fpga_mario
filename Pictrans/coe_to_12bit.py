
cnt = 0
with open("out.coe", "r") as f:

    for line in f:
        if line.startswith("memory"):
            cnt += 1
        if cnt == 2:
            break

    data = f.read().replace('\n', '').replace(',', '\n').replace(';', '\n')


if len(data) % 4 != 0:
    print(len(data), "Error: Invalid data length")
    exit(1)


with open("sprite2.bin", "wb") as f:

    data_bin = b''
    for i in range(0, len(data), 4):
        try:
            data_bin += bin(int(data[i:i+4], 16))[2:].rjust(12, '0').encode('utf-8')
            if (i+4) % 4 == 0:
                data_bin += b'\n'
        except ValueError:
            print("Error: Invalid data")
            exit(1)

    f.write(data_bin)
