# encoding: UTF-8
class MilkingMachinesController < ApplicationController

  hobo_model_controller

  auto_actions :all

  index_action :index_new, :new_machines, :data
  
  def index
    @milking_machines = MilkingMachine.all
  end


  def new_machines
    unless MilkingMachine.count == 0
     	  MilkingMachine.destroy_all   	
    end
  	 
    @machines = params[:number]
    @nro = @machines.to_i

    MilkingMachineRead.destroy_all
     

    for i in (1..@nro)
      @milking_m = MilkingMachine.new(:number => i)
      @milking_m.save
    end

    @delete_notification = NotificationMessage.first(:conditions => ["source = ? and status = ?", "milkingmachine", true])
      unless @delete_notification == nil
        @delete_notification.status = false
        @delete_notification.save
      end
    
    redirect_to "/milking_machines"  	
  end


  def data
    @milking_machines = MilkingMachine.count * 3
    @dit = MilkingMachineRead.last(@milking_machines)
    respond_to do | format |
      format.json { render json: @dit, status: 200 }
    end
    
  end

end
