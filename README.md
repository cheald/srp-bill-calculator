# SRP & APS Bill calculator

This is a tool to estimate what your power costs would be on an hour-by-hour basis, for each of SRP and APS's different plans. I wrote it to determine which of SRP's plans would be least expensive for my family.

![](doc/Screenshot_20180630_085837.png)

## Usage

### SRP

1. Go to your account usage page at https://myaccount.srpnet.com/MyAccount/usage
2. Find the "Report Options" box
3. Change the "Daily" dropdown to "Hourly"
4. Change your Start Date and End Date to the desired range you want to project over
5. Click the "Export to Excel" button.

![](doc/Screenshot_20180629_020254.png)

### APS

1. Log in to your APS account
2. Select my energy > daily & hourly usage.

   ![](doc/aps/step_1.png)

3. Select the "detailed energy usage" tab

   ![](doc/aps/step_2.png)

4. At the very bottom of detailed energy usage, you have the option to export. The default range is a month. Change the date range to a year, and click "download"

   ![](doc/aps/step_3.png)

5. After exporting your .xslx, open it in Excel, LibreOffice, or Google Docs, and save it as a CSV

### Running the tool

Once you have your CSV, pass it to the tool:

    ruby power.rb -f 082-174-000-Hourly-20170620-20180627.csv -p srp
    ruby power.rb -f 082-174-000-Hourly-20170620-20180627.csv -p aps

And your projections per plan will be computed and displayed.
