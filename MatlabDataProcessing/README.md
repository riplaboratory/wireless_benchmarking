# Matlab Data Processing Script

The compiled experimental data is stored in the files `rf2412Data.xlsx` (2.4 GHz data) and `rf5240Data.xlsx` (5 GHz data).

Run the `processData.m` to run the data processing script.  It will create three figures, you may save these conventionally within Matlab (File>Save As).  There are three examples already in this Git directory.  

Last tested in Matlab R2019a.

## Notes on the data import process

Because importing from `.xslx` files is slow, the script will generate two data files, `rf2412.mat` and `rf5240.mat` for speed.  You do not need to do anything with these except keep them in the same directory.  Set `excelImport = 0` on line 7 to import from the .xslx data files (slow), or set `excelImport = 1` to import from the `.mat` files (fast). 
