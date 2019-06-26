# encoding: UTF-8
class MilkingMachine < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    number :integer
    timestamps
  end
  attr_accessible :number

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

end
