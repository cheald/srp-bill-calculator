# SRP Bill calculator

This is a tool to estimate what your SRP power costs would be on each of their different plans. I wrote it to determine which of SRP's plans would be most beneficial for my home.

![](doc/Screenshot_20180629_013435.png)

## Usage

1. Go to your account usage page at https://myaccount.srpnet.com/MyAccount/usage
2. Find the "Report Options" box
3. Change the "Daily" dropdown to "Hourly"
4. Change your Start Date and End Date to the desired range you want to project over
5. Click the "Export to Excel" button.

Once you have your CSV, pass it to the tool:

    ruby power.rb -f 082-174-000-Hourly-20170620-20180627.csv

And your projections per plan will be computed and displayed.
