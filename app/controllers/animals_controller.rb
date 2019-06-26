# encoding: UTF-8
class AnimalsController < ApplicationController

  hobo_model_controller

  
  auto_actions :all
  index_action  :table, :index_inactive

  autocomplete 


  def index
    @tambero_api = TamberoApi.first   
  	@animals = Animal.where(:inactivated_at => nil).order(:rp_number).paginate(:page => params[:page], :per_page => 30)    
  end

  def show
  	  @animal = Animal.find(params[:id])
      if @animal.birth_date_at
        @birth = @animal.birth_date_at.strftime("%d / %m / %Y")
      end

      @am_desc = AnimalMilking.where("eartag = ?", @animal.rp_number).order("date_start_at DESC").limit(80)
      @am = @am_desc.sort_by { |ms| ms[:date_start_at] }      
      @time = @am.map{|t|  t.date_start_at.strftime("%d%m%y").to_i }
      @volume_data = @am.map{ |o| o.volume  }
      @temperature_data = @am.map{ |q| q.temperature  }
      @conductivity_data = @am.map{ |r| r.conductivity  }

      @picture = "/assets/picture.png"
      @milking = AnimalMilking.where("eartag = ?", @animal.rp_number).last       
      unless @milking 
        @date_session = 0
        @time_session = 0
        @duration = 0
      else
        @date_session = @milking.created_at.strftime("%d/%m/%y")
        @time_session =  @milking.created_at.strftime("%I:%M%p")  
        @duration = (@milking.date_end_at - @milking.date_start_at) / 60    
      end
  end

  def table
    @value = params[:search]
    if @value == nil or @value == 0 or @value == "0" or @value == ""
      redirect_to "/animals", notice: 'Caravana incorrecta'
    else
      @anim = Animal.where("rp_number = ?", @value).last
      unless @anim 
        redirect_to "/animals", notice: 'Caravana incorrecta'
      end
    end
  end

def index_inactive
  @tambero_api = TamberoApi.first
  @animals = Animal.find_by_sql("select * from animals where inactivated_at IS NOT NULL order by rp_number").paginate(:page => params[:page], :per_page => 30)
end

  


end


