class HeatTambero < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    heat_icon :string
    eartag    :string
    pregnancy :string

    timestamps
  end
  attr_accessible :heat_icon, :eartag, :pregnancy

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
