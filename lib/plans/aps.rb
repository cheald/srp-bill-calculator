require_relative "./base"

module Plans
  module APS
    class Base < ::Plans::SolarBase
      def reset_monthly_usage
        [0, @monthly_usage].min
      end
    end

    require_relative "aps/saver_choice"
    require_relative "aps/saver_choice_plus"
    require_relative "aps/saver_choice_max"
    require_relative "aps/premier_choice"
    require_relative "aps/premier_choice_large"
    require_relative "aps/lite_choice"

    PLANS = [
      Plans::APS::SaverChoice,
      Plans::APS::SaverChoiceMax,
      Plans::APS::SaverChoicePlus,
      Plans::APS::PremierChoice,
      Plans::APS::PremierChoiceLarge,
      Plans::APS::LiteChoice,
    ]
  end
end
