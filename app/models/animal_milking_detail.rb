# encoding: UTF-8
class AnimalMilkingDetail < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    time_at      :datetime
    conductivity :float
    temperature  :float
    volume       :float
    flow         :float
    
    timestamps
  end
  attr_accessible :conductivity, :temperature, :time_at, :volume, :flow, :animal_milking_id
  belongs_to :animal_milking
  

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator?
  end

  def update_permitted?
    acting_user.administrator?
  end

  def destroy_permitted?
    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end

end
