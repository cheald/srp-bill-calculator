module AverageDemandConcern
  def add_demand(date, kwh)
    k = super date, kwh

    datekey = date.strftime("%Y-%m")
    demand_by_date[datekey] ||= {}
    dkey = date.strftime("%d")
    demand_by_date[datekey][dkey] ||= 0
    demand_by_date[datekey][dkey] = k if k > demand_by_date[datekey][dkey]

    return k
  end

  def demand_by_date
    @demand_by_date ||= {}
  end

  def demand_for_period(date)
    key = date.strftime("%Y-%m")
    demand = (demand_by_date[key] || {}).values
    return 0 if demand.empty?
    demand.inject(&:+) / demand.length.to_f
  end
end
