require_relative "./base"

module Plans
  module SRP
    require_relative "srp/dates"
    require_relative "srp/ezthree"
    require_relative "srp/time_of_use"
    require_relative "srp/tou_solar"
    require_relative "srp/ev"
    require_relative "srp/ev_solar"
    require_relative "srp/basic"
    require_relative "srp/m_power"
    require_relative "srp/solar"
    require_relative "srp/solar-e15"
    PLANS = [
      Plans::SRP::EZThree,
      Plans::SRP::TimeOfUse,
      Plans::SRP::ElectricVehicle,
      Plans::SRP::Basic,
      Plans::SRP::MPower,
      Plans::SRP::Solar,
      Plans::SRP::EVSolar,
      Plans::SRP::TimeOfUseSolar,
      Plans::SRP::SolarAverage,
    ]
  end
end
