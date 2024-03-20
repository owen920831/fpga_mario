
cnt = 0
ss = []
l = []
for i in range(1024):
    s = input()
    ss.append(s)
    if (i+1) % 32 == 0:
        l.append(ss)
        ss = []


with open("sprite3.txt", "w") as f:
    for i in range(32):
        for j in range(32):
            f.write(l[i][31-j])
            f.write('\n')
