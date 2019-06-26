class AlarmsController < ApplicationController

  hobo_model_controller

  auto_actions :all

  index_action :alarm_activation

  def index
  	@alarms = Alarm.all
  end

  def alarm_activation
  	@alarms = Alarm.all
  end

end
