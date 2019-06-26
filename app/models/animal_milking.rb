# encoding: UTF-8
class AnimalMilking < ActiveRecord::Base



  hobo_model # Don't put anything above this

  fields do
    date_start_at :datetime
    date_end_at   :datetime
    conductivity  :float
    temperature   :float    
    volume        :float
    eartag        :integer
    meter         :integer
    timestamps
  end
  attr_accessible :date_start_at, :date_end_at, :conductivity, :temperature, :volume, :eartag, :meter, :animal_id
  belongs_to :milking_session
  has_many :animal_milking_details



  

  # --- Permissions --- #

  def create_permitted?
    true
  end

  def update_permitted?
    true
  end

  def destroy_permitted?
    true
  end

  def view_permitted?(field)
    true
  end

  def unknown_eartag
      @eartag = self.eartag    
      @result = Animal.where("rp_number = ?", @eartag).last
      return @result
  end

  def notification_unknown_eartag
    @id = self.id
    @notification = NotificationMessage.new(:name => "Unknown Eartag",
                                            :message => "Atencion: se ingreso una caravana desconocida",
                                            :source => "unknowneartag",
                                            :code => @id,
                                            :status => true,
                                            :link => "/notification_messages/index_unknown_eartag",
                                            :color => "red",
                                            :type_message => "error")
    @notification.save  
  end


  def avg_temperature_session #saca 
    i = 0
    temp = 0
    if @temperatures = AnimalMilking.where("milking_session_id = ?", self.milking_session_id) then
      @temperatures.each do |tm|
        temp = temp + tm.temperature
        i += 1
      end

      if i > 0 then
          avg_temp = temp / i
      else
          avg_temp = 0
      end
    end

    return avg_temp


  end
 

end
