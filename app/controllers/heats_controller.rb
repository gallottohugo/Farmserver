class HeatsController < ApplicationController

  hobo_model_controller

  auto_actions :all

  index_action :confirm_heats

  def index
    	hobo_index do
          if TamberoApi.first then 
            @time_zone = TamberoApi.first.time_zone_user
            @days_next_heat = TamberoApi.first.period_between_heats
          end
        	@milking_session_id = MilkingSession.last.id
        	@avg_t = TamberoApi.first.per_temperature
        	@avg_p = TamberoApi.first.per_activity
        	@heats_table = Heat.find_by_sql(["Select am.id id_am, am.date_start_at, am.eartag, am.temperature, pe.id id_pe, pe.eartag, pe.real_steps  from animal_milkings am, pedometries pe, milking_sessions ms where am.milking_session_id = ms.id and pe.milking_session_id = ms.id and ms.id = ? and am.eartag = pe.eartag group by am.eartag, pe.eartag", @milking_session_id])
      end 
  end

  def edit
      @id = params[:id]
      @value = params[:checked]

      if @value == "true" then
          h = Heat.find(@id)
          h.confirm = true
          h.save
      elsif @value == "false"
          h = Heat.find(@id)
          h.confirm = false
          h.save
      end
  end

  



end
