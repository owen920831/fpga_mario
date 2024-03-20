import openpyxl
import numpy as np

filename = 'map.xlsx'  # replace with your .xlsx file

try:
    # Read the data from the .xlsx file
    workbook = openpyxl.load_workbook(filename)
    sheet = workbook.active  # get the first sheet
    sheet_data = []
    for row in sheet.rows:
        sheet_data.append([cell.value for cell in row])

    # Process the data
    processed_data = []
    for row in sheet_data:
        processed_row = []
        for cell in row:
            byte_str = "{0:b}".format(int(cell)).rjust(5, '0')
            processed_row.append(byte_str)
        processed_data.append(processed_row)

    # Open the output file in binary write mode
    with open('map.bin', 'wb') as f:
        s = 0
        while(len(processed_data) > s):
            trans = np.array(processed_data[s:s+15]).T.tolist()
            for string_slice in trans:
                for string in string_slice:
                    f.write(string.encode())
                    f.write("\n".encode())
            s = s+15
finally:
    pass
