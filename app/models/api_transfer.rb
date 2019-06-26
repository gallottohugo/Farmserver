# encoding: UTF-8
class ApiTransfer < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    process_type :string
    process_name :string
    date_at      :datetime
    result       :boolean
    code_error   :integer
    error        :string

    timestamps
  end
  attr_accessible :process_type, :process_name, :date_at, :result, :code_error, :error

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
