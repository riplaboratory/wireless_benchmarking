# Matlab Data Processing Script

The compiled experimental data is stored in the files `compiledData.xlsx`.

Run the `processData.m` to run the data processing script.  It will create multiple figures, you may save these conventionally within Matlab (File>Save As). 

Last tested in Matlab R2019a.

## Notes on the data import process

Because importing from `.xslx` files is slow, the script will generate a data file `rfData.mat` for speed.  You do not need to do anything with these except keep them in the same directory.  Set `rfData = importDataRuns(0)` on line 5 to import from the .xslx data files (slow), or set `rfData = importDataRuns(1)` to import from the `.mat` files (fast). 
