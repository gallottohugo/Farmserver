# encoding: UTF-8
class TamberoApi < ActiveRecord::Base

  hobo_model # Don't put anything above this

  Language = HoboFields::Types::EnumString.for(:es_AR, :en_US)

  fields do
    tambero_api_key          :string
    tambero_user_id          :string
    tambero_last_upload_at   :datetime
    time_zone                :string
    end_milking              :integer
    min_milking              :integer
    language                 TamberoApi::Language
    installed_version        :float
    current_version          :float
    days_without_connexion   :integer
    pedometry_module         :boolean
    weighing_module          :boolean
    update_pedometer         :boolean
    per_temperature          :float  #porcentaje de temperatura de la leche, se compara con el promedio de la temperatura del ordeñe
    per_activity             :float  #porcentaje de variacion de actividad de un unimal en comparacion con su rodeo (podometria)
    heat_module              :boolean
    period_between_heats     :integer
    timestamps
  end

  attr_accessible :tambero_api_key, :tambero_user_id, :tambero_last_upload_at, :time_zone, :end_milking, :min_milking, :tambero_url, :language,
                  :installer_version, :current_version, :days_without_connexion, :pedometry_module, :weighing_module, :update_pedometer, :per_temperature,
                  :per_activity, :heat_module, :period_between_heats

  validates :tambero_user_id, numericality: { only_integer: true } 
  validates :end_milking, numericality: { only_integer: true }
  validates :min_milking, numericality: { only_integer: true }
  validates :days_without_connexion, numericality: { only_integer: true }

 
 



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

  def tambero_url
    #return "http://www.tambero.com"
    #return "http://192.168.0.201:3000"
    return "http://beta.tambero.com:3000"
  end

  def time_zone_user
      @time_zone = TamberoApi.first.time_zone[4..9]
      return @time_zone
  end


end
