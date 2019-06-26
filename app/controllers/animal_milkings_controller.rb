# encoding: UTF-8
class AnimalMilkingsController < ApplicationController

  hobo_model_controller

  

  auto_actions :all

  
  index_action :table, :graphic, :animal_milking_session, :table_milking, :meter_details

  def table
  	if params[:id_animal] 
      @animal = Animal.where("rp_number = ?", params[:id_animal]).last    
    end

    @milking = AnimalMilking.where("id = ?", params[:animalmilking]).last
    @table_flows = AnimalMilkingDetail.find_by_sql(["select * from animal_milking_details where animal_milking_id = ? order by created_at", @milking.id])
         
    if @animal_milking = AnimalMilking.find(params[:animalmilking])
      @date_session = @animal_milking.created_at.strftime("%d/%m/%y")
      @time_session =  @animal_milking.created_at.strftime("%I:%M%p")    
      @meter = @animal_milking.meter
    else
      @date_session = 0
      @time_session =  0
      @meter = 0
    end

  end



  def graphic
    @flow_1er_data = AnimalMilkingDetail.where("animal_milking_id = ?", params[:animalmilking]).order(:created_at).first
    if  @flow_1er_data.created_at
      @time_1er_data = @flow_1er_data.created_at.to_i
    else
      @time_1er_data = 0
    end

    @time = AnimalMilkingDetail.where("animal_milking_id = ?", params[:animalmilking]).order(:created_at).map{|t|  (t.created_at.to_i - @time_1er_data).to_i }

    @flow_data         = AnimalMilkingDetail.where("animal_milking_id = ?", params[:animalmilking]).order(:created_at).map{ |o| o.flow.round(5).abs  }
    @temperature_data  = AnimalMilkingDetail.where("animal_milking_id = ?", params[:animalmilking]).order(:created_at).map{ |o| o.temperature  }
    @volume_data       = AnimalMilkingDetail.where("animal_milking_id = ?", params[:animalmilking]).order(:created_at).map{ |o| o.volume  }
    @conductivity_data = AnimalMilkingDetail.where("animal_milking_id = ?", params[:animalmilking]).order(:created_at).map{ |o| o.conductivity  }
    
    if params[:id_animal]
      @animal = Animal.where("rp_number = ?", params[:id_animal]).last
    end

        
    @table_flows = AnimalMilkingDetail.where("animal_milking_id = ?", params[:animalmilking]).order(:updated_at)
    
    if @animal_milking = AnimalMilking.find(params[:animalmilking])
      @date_session = @animal_milking.date_start_at.strftime("%d/%m/%y")
      @time_session =  @animal_milking.date_start_at.strftime("%I:%M%p")
      @meter = @animal_milking.meter
    else
      @date_session = 0
      @time_session =  0
      @meter = 0
    end
  end


  def table_milking
    @animal = Animal.where("rp_number = ?", params[:id]).last

    @last_milking = AnimalMilking.where("eartag = ?", params[:id]).last
    @date_session = @last_milking.created_at.strftime("%d/%m/%y")
    @time_session =  @last_milking.created_at.strftime("%I:%M%p")

    @table_milking = AnimalMilking.find_by_sql(["select * from animal_milkings where eartag = ? order by date_start_at DESC LIMIT 80", params[:id]])
    @picture = "/assets/picture.png"
  end

  def meter_details
    @meter = params[:meter]
    @session = params[:session]
     
    @meter_details = AnimalMilking.find_by_sql(["select eartag, volume, temperature, conductivity from animal_milkings where meter = ? and milking_session_id = ? order by eartag", @meter, @session])   
  end

  def update
    hobo_update   do

      @eartag = this.eartag
      @id = this.id
      
      @am = AnimalMilking.find(@id)
      @unknown_eartag = @am.unknown_eartag

      if @unknown_eartag 
        @notification = NotificationMessage.where("code = ?", @id).last
        @notification.status = 0
        @notification.save         

        flash[:notice] = "Caravana actualizada correctamente"
        redirect_to "/notification_messages/index_unknown_eartag"           
      else          
        flash[:notice] = "La caravana ingresada es incorrecta"
        redirect_to "/notification_messages/index_unknown_eartag" 
      end  
    end
  end

   def eartag_confirmation    
  end
 
 

end
