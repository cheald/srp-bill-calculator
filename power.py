import numpy as np
import pandas as pd
import sys, getopt
import datetime
from os import path
from tabulate import tabulate

class BasePlan:
  name = "<not set>"
  notes = ""
  def __init__(self, df, kwdc=0):
    self.df = df.copy()
    self.kwdc = kwdc

    self.summer = (df.month >= 5) & (df.month <= 10)
    self.weekday = (df.dow >= 1) & (df.dow <= 5)
    self.on_peak = (df.hour >= 15) & (df.hour < 21) & self.weekday
    self.super_off_peak = (df.hour >= 10) & (df.hour < 15) & ~self.summer

  def __str__(self):
    return self.name

  def days_used(self):
    return len(self.df.Date_Time.dt.date.unique())

  def demand_charge(self):
    return 0

  def generation_credit(self):
    return self.df["Overgeneration Credit"].sum()

  def kwh_used(self):
    return self.df["Raw Usage(kWh)"].sum()

  def kwh_generated(self):
    return self.df["Generation (kW)"].sum()

########################################################################
########################################################################

class SaverChoice(BasePlan):
  name = "SaverChoice"

  def usage_charge(self):
    df, summer, on_peak, super_off_peak = self.df, self.summer, self.on_peak, self.super_off_peak
    df["rate"] = 0.10873 # base rate
    df.loc[summer & on_peak, "rate"] = 0.24314
    df.loc[~summer & on_peak, "rate"] = 0.23068
    df.loc[~summer & super_off_peak, "rate"] = 0.03200

    charges = (df.rate * df["Usage(kWh)"]).sum()
    return charges

  def service_charges(self):
    days = self.days_used()
    months = (days / 30.44496487119438)
    solar_charge = months * self.kwdc * .93
    base_charge = 0.427 * days
    return base_charge + solar_charge

########################################################################
########################################################################

class SaverChoicePlus(BasePlan):
  name = "SaverChoicePlus"

  def usage_charge(self):
    df, summer, on_peak = self.df, self.summer, self.on_peak

    df.loc[summer & on_peak, "rate"] = 0.13160
    df.loc[summer & ~on_peak, "rate"] = 0.07798
    df.loc[~summer & on_peak, "rate"] = 0.11017
    df.loc[~summer & ~on_peak, "rate"] = 0.07798

    charges = (df.rate * df["Usage(kWh)"]).sum()
    return charges

  def service_charges(self):
    return 0.427 * self.days_used()

  def demand_charge(self):
    df, summer, on_peak = self.df, self.summer, self.on_peak
    summer_charge = df[summer & on_peak].groupby("YearMonth")["Demand(kW)"].max().sum() * 8.4
    winter_charge = df[~summer & on_peak].groupby("YearMonth")["Demand(kW)"].max().sum() * 8.4
    return summer_charge + winter_charge

########################################################################
########################################################################

class SaverChoiceMax(BasePlan):
  name = "SaverChoiceMax"

  def usage_charge(self):
    df, summer, on_peak = self.df, self.summer, self.on_peak

    df.loc[summer & on_peak, "rate"] = 0.08683
    df.loc[summer & ~on_peak, "rate"] = 0.05230
    df.loc[~summer & on_peak, "rate"] = 0.06376
    df.loc[~summer & ~on_peak, "rate"] = 0.05230

    charges = (df.rate * df["Usage(kWh)"]).sum()
    return charges

  def service_charges(self):
    return 0.427 * self.days_used()

  def demand_charge(self):
    df, summer, on_peak = self.df, self.summer, self.on_peak
    summer_charge = df[summer & on_peak].groupby("YearMonth")["Demand(kW)"].max().sum() * 17.438
    winter_charge = df[~summer & on_peak].groupby("YearMonth")["Demand(kW)"].max().sum() * 12.239
    return summer_charge + winter_charge

########################################################################
########################################################################

class LiteChoice(BasePlan):
  name = "LiteChoice"
  notes = "Available if you use <600kWh/mo and do not have solar"

  def usage_charge(self):
    df = self.df
    df["rate"] = 0.11672
    return (df.rate * df["Usage(kWh)"]).sum()

  def service_charges(self):
    days = self.days_used()
    base_charge = 0.329 * days
    return base_charge

########################################################################
########################################################################

class PremierChoice(BasePlan):
  name = "PremierChoice"
  notes = "Available if you use 601-999kWh/mo and do not have solar"

  def usage_charge(self):
    df = self.df
    df["rate"] = 0.12393
    return (df.rate * df["Usage(kWh)"]).sum()

  def service_charges(self):
    days = self.days_used()
    base_charge = 0.493 * days
    return base_charge

########################################################################
########################################################################

def get_df(file):
  if path.exists("%s.hdf" % file):
    df = pd.read_hdf("%s.hdf" % file, "power")
  else:
    df = pd.read_csv(file, parse_dates=[['Date', 'Time']])
    df.to_hdf("%s.hdf" % file, "power")
  df["dow"] = df.Date_Time.dt.dayofweek
  df["hour"] = df.Date_Time.dt.hour
  df["month"] = df.Date_Time.dt.month
  df["YearMonth"] = df.Date_Time.dt.date - pd.offsets.MonthBegin(0)
  df["MonthDayHour"] = df.Date_Time.apply(lambda x: str(x.month * 10000 + x.day * 100 + x.hour))
  return df

def main():
  try:
    opts, args = getopt.getopt(sys.argv[1:], "k:p:f:", ["kwdc=", "pvwatts=", "file="])
  except getopt.GetoptError as err:
    print str(err)  # will print something like "option -a not recognized"
    sys.exit(2)

  kwdc = 0
  pvwatts = None
  fname = None
  for opt, arg in opts:
    if opt in ("-k", "--kwdc"):
      kwdc = float(arg)
    elif opt in ("-p", "--pvwatts"):
      pvwatts = arg
    elif opt in ("-f", "--file"):
      fname = arg

  df = get_df(fname)
  pv_df = None
  def parse_date(m, d, h):
    try:
      m, d, h = int(m), int(d), int(h)
      return datetime.datetime(2019, m, d, h)
    except ValueError:
      return None

  if pvwatts is not None:
    pv_df = pd.read_csv(pvwatts, skiprows=17, parse_dates=[["Month", "Day", "Hour"]], date_parser=parse_date)
    pv_df = pv_df.dropna()
    pv_df["MonthDayHour"] = pv_df.Month_Day_Hour.apply(lambda x: str(x.month * 10000 + x.day * 100 + x.hour))
    df["ts"] = df.Date_Time
    df = df.set_index("ts")

    df = df.merge(pv_df[["MonthDayHour", "AC System Output (W)"]], on="MonthDayHour")
    df["Raw Usage(kWh)"] = df["Usage(kWh)"]
    df["Generation (kW)"] = df["AC System Output (W)"] * (kwdc / 8000.)
    df["Usage(kWh)"] = df["Raw Usage(kWh)"] - df["Generation (kW)"]
    df["Overgeneration (kW)"] = 0
    df.loc[df["Usage(kWh)"] < 0, "Overgeneration (kW)"] = -df["Usage(kWh)"]
    df.loc[df["Usage(kWh)"] < 0, "Usage(kWh)"] = 0
    # 2018 RCP generation rate
    df["Overgeneration Credit"] = df["Overgeneration (kW)"] * 0.1161

  plans = [SaverChoice, SaverChoicePlus, SaverChoiceMax, LiteChoice, PremierChoice]
  results = []
  for plan in plans:
    p = plan(df, kwdc)
    results.append([p, p.usage_charge(), p.service_charges(), p.demand_charge(), p.generation_credit(), p.kwh_used(), p.kwh_generated()])

  r_df = pd.DataFrame(results, columns=["Plan", "UsageCharge", "ServiceCharge", "DemandCharge", "GenerationCredit", "kWh Used", "kwH Generated"])
  r_df["Total"] = r_df.UsageCharge + r_df.ServiceCharge + r_df.DemandCharge - r_df.GenerationCredit
  r_df["Notes"] = r_df.Plan.apply(lambda p: p.notes)


  for col in ["UsageCharge", "ServiceCharge", "DemandCharge", "GenerationCredit", "Total"]:
    r_df[col] = r_df[col].apply(lambda x: "${:2.2f}".format(x))
  r_df["Plan"] = r_df.Plan.apply(str)
  print(tabulate(r_df, headers=r_df.keys()))

  print("\n--------------------------\nUsage by month")
  monthly_usage = df.groupby("YearMonth")["Usage(kWh)"].sum().to_frame()
  print(monthly_usage)

if __name__ == "__main__":
  main()
