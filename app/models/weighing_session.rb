class WeighingSession < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    dated_at :datetime
    status   :integer
    timestamps
  end
  attr_accessible :dated_at, :status
  has_many :weighings

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
