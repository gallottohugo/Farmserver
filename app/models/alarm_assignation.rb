class AlarmAssignation < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    eartag       :integer
    number_alarm :integer
    timestamps
  end
  attr_accessible :eartag, :number_alarm

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
