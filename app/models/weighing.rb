class Weighing < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    dated_at :date
    hour     :string
    weight   :decimal
    eartag   :integer
    comments :text
    timestamps
  end
  attr_accessible :dated_at, :hour, :weight, :eartag, :comments
  belongs_to :weighing_session

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
