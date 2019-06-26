class Heat < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    detected_at     :datetime
    detected_method :string
    comments        :string
    milk_temerature :float #temperatura de la leche que supera la temperatura normal
    activity        :integer #porcentaje de actividad (podometria) que supera al resto del rodeo
    probability_tambero :float #porcentaje de celo de tambero.com
    eartag          :integer
    confirm         :boolean
    transferred     :boolean
    timestamps
  end
  attr_accessible :detected_at, :detected_method, :comments, :milk_temerature, 
                  :activity, :probability_tambero, :eartag, :confirm, :milking_session_id, 
                  :transferred


  belongs_to :milking_session
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


  def detect_heat
      #si se exporto correctamente milking_session, comienzo con la deteccion de celos
      if @last_milking_session = MilkingSession.last then 
          #encontre la ultima session
          if @animal_milkings = AnimalMilking.where("milking_session_id = ?", @last_milking_session.id) then
              #encontre tods los animal_milkings de la session
              @animal_milkings.each do |am|
                  #comparo la temperatura del ordeñe con la temperatura maxima ingresada por el usuario
                  @milk_temperature = am.temperature
                  @avg_temperature_user = TamberoApi.first.max_temperature

                  if @milk_temperature.to_i > @max_milk_temperature.to_i then 
                      @heat_temperature = true
                  else
                      @heat_temperature = false
                  end

                  if @pedometry = Pedometry.where("milking_session_id = ? and eartag = ?", @last_milking_session.id, am.eartag).last then
                      #ecnontro pedometry de este animal

                      @steps_animal = @pedometry.real_steps
                      #busco la actividad por hora del animal y del rodeo
                      @avg_activity_animal = @pedometry.step_per_hour
                      @avg_activity_herd   = @pedometry.step_per_hour_herd

                      #Busco el porcentaje que ingreso el usuario en la configuracion
                      @activity_variation = TamberoApi.first.activity_variation

                      #calculo la actividad por hora de rodeo + el porcentaje que ingreso el usuario 
                      @new_avg_activity_herd = ((@avg_activity_herd.to_i * @activity_variation.to_i) / 100) + @avg_activity_herd

                      #comparo de promedio de pasos por hora de todo el rodeo + el porcentaje que ingreso el usuario contra el promedio de pasos por hora del animal
                      if @avg_activity_animal > @new_avg_activity_herd
                          @heat_activity = true
                      else
                          @heat_activity = false
                      end
                  end
                  #si los dos valores devuelven "true" inserto un registro nuevo en celos
                  @new_heat = Heat.new( :detected_at => Time.now,
                                        :milk_temerature => @milk_temperature.to_f,
                                        :activity => @steps_animal,
                                        :eartag   => am.eartag)
                  @new_heat.save

              end
          end
      end
  end


  def self.export_heats
      if @id_session = MilkingSession.last.id then 
          @heats_confirmed = Heat.where("milking_session_id = ? and confirm = ? and transferred = ?", @id_session, true, false)
          @id_last = @heats_confirmed.last.id

          @json_data_heats = '['
          @heats_confirmed.each do |h|
              @tambero_id = Animal.where("rp_number = ?", h.eartag).last.tambero_id
              @detected_at = h.detected_at.strftime('%Y%m%d%H%M%S')
              if h.id == @id_last
                  @text_heats = '{"heat":{"animal_id":"'+@tambero_id.to_s+'", "detected_at":"'+@detected_at.to_s+'", "detected_method":"'+h.detected_method+'", "comments":"'+h.comments+'"}}'              
              else
                  @text_heats = '{"heat":{"animal_id":"'+@tambero_id.to_s+'", "detected_at":"'+@detected_at.to_s+'", "detected_method":"'+h.detected_method+'", "comments":"'+h.comments+'"}, '
              end
              @json_data_heats = @json_data_heats + @text_heats
          end
          @json_data_heats = @json_data_heats + ']'                           

          puts "JSON_DATAAA: "+@json_data_heats.to_s

          api = TamberoApi.first
          url = api.tambero_url+"/apiv2/heats?userid="+api.tambero_user_id+"&apikey="+api.tambero_api_key+"&apilicense=rodegserver&apilang="+api.language+"&method=import"              
          cuenta = 0
          begin
              response_heats = RestClient.post("#{url}",
                                              @json_data_heats,    
                                              {:content_type => 'application/json',
                                               :accept => 'application/json'}) 
          rescue Errno::ECONNRESET => e
              cuenta += 1
              retry unless cuenta > 20
              return
          end
          puts "RESPONSE TAMBERO: "+response_heats.to_s  
          r_h = JSON.parse(response_heats)
            r_h.each do |h|
                if h == "msg"
                    next
                elsif "done" == h["status"]
                    puts "Entro a DONE"
                    @heats_confirmed.each do |hc|
                        hc.transferred = true
                        hc.save
                    end
                    @transfer = ApiTransfer.new(
                                      :process_type => "output",
                                      :process_name => "export_heats",
                                      :date_at      => DateTime.now(),
                                      :result       => false,
                                      :code_error   => h["code"].to_i,
                                      :error        => h["message"].to_s)
                      @transfer.save
                else
                    if h["code"] == "10110"
                        @transfer = ApiTransfer.new(
                                        :process_type => "output",
                                        :process_name => "export_heats",
                                        :date_at      => DateTime.now(),
                                        :result       => false,
                                        :code_error   => h["code"].to_i,
                                        :error        => h["message"].to_s)
                        @transfer.save
                        exit
                        #exit xq supero el limite de uso del api
                    else
                        puts "Error"
                        @transfer = ApiTransfer.new(
                                        :process_type => "output",
                                        :process_name => "export_heats",
                                        :date_at      => DateTime.now(),
                                        :result       => false,
                                        :code_error   => h["code"].to_i,
                                        :error        => h["message"].to_s)
                        @transfer.save
                    end
                end
            end
      end
  end




end
