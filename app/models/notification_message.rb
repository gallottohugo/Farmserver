class NotificationMessage < ActiveRecord::Base

  hobo_model # Don't put anything above this

=begin
  Source = HoboFields::Types::EnumString.for(:tamberoapi, :milkingmachine, :currentversion, :animals, :inputconnexion, :outputconnexion)
=end

  fields do
    name         :string
    message      :string
    source       :string
    code         :integer
    status       :boolean
    link         :string
    color        :string
    type_message :string
    timestamps
  end
  attr_accessible :name, :message, :source, :code, :status, :link, :color, :type_message

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
