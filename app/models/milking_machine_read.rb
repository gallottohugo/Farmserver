# encoding: UTF-8
class MilkingMachineRead < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    eartag                 :integer
    volume                 :float
    temperature            :float
    conductivity           :float
    state                  :string
    flow                   :float
    meter                  :integer
    milking_current       :integer
    timestamps
  end
  attr_accessible :eartag, :volume, :temperature, :conductivity, :state, :flow, :meter, :milking_current

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
