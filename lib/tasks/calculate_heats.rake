desc "calcula la probablidad de celo por animal"
task :calculate_heats => :environment do
	
	#si se exporto correctamente milking_session, comienzo con la deteccion de celos
    if @ms = MilkingSession.last then
          #encontre la ultima session
        if @animal_milkings = AnimalMilking.where("milking_session_id = ?", @ms) then
              #encontre tods los animal_milkings de la session
              @animal_milkings.each do |am|
                  #comparo la temperatura del ordeñe con la temperatura maxima ingresada por el usuario
                  @avg_temperature = am.avg_temperature_session
                  @avg_user = TamberoApi.first.per_temperature
                  @new_avg_temperature = (@avg_temperature * @avg_user) / 100

                  if am.temperature > @new_avg_temperature then 
                      @heat_temperature = true
                  else
                      @heat_temperature = false
                  end

                  if @pedometry = Pedometry.where("milking_session_id = ? and eartag = ?", @ms, am.eartag).last then
                        #encontro pedometry de este animal
                        @steps_animal = @pedometry.real_steps
                        #busco la actividad por hora del animal y del rodeo
                        @avg_activity_animal = @pedometry.step_per_hour
                        @avg_activity_herd   = @pedometry.step_per_hour_herd

                        #Busco el porcentaje que ingreso el usuario en la configuracion
                        @activity_variation = TamberoApi.first.per_activity

                        #calculo la actividad por hora de rodeo + el porcentaje que ingreso el usuario 
                        @new_avg_activity_herd = (@avg_activity_herd.to_i * @activity_variation.to_i) / 100

                        #comparo de promedio de pasos por hora de todo el rodeo + el porcentaje que ingreso el usuario contra el promedio de pasos por hora del animal
                        if @avg_activity_animal > @new_avg_activity_herd
                            @heat_activity = true
                        else
                            @heat_activity = false
                        end

                        #si los dos valores devuelven "true" inserto un registro nuevo en celos
                        if @heat_activity == true and @heat_temperature == true then
                            @new_heat = Heat.new( :detected_at => Time.now,
                                                  :detected_method => "Farmserver",
                                                  :comments => "Celo importado desde el servidor de Farmserver",
                                                  :milk_temerature => am.temperature.to_f,
                                                  :activity => @steps_animal,
                                                  :eartag => am.eartag,
                                                  :milking_session_id => @ms.id,
                                                  :confirm => false,
                                                  :transferred => false)
                            @new_heat.save
                        end
                  end
              end
              
              @animals = AnimalMilking.find_by_sql(["select * from animal_milkings where milking_session_id = 315 order by eartag"])
              @id_last = @animals.last.id
              @json_data_animals = '['
              @animals.each do |a|
                  if a.id == @id_last
                      @text_animal = '{"animal":{"rp_number":"'+a.eartag.to_s+'"}}'
                  else
                      @text_animal = '{"animal":{"rp_number":"'+a.eartag.to_s+'"}}, '
                  end
                  @json_data_animals = @json_data_animals + @text_animal
              end
              @json_data_animals = @json_data_animals + ']'                           
              puts @json_data_animals.to_s

              api = TamberoApi.first
              url = api.tambero_url+"/apiv2/heats?userid="+api.tambero_user_id+"&apikey="+api.tambero_api_key+"&apilicense=rodegserver&apilang="+api.language+"&method=heat_detected"
              
              cuenta = 0
              begin
                    response_heats = RestClient.post("#{url}",
                                                    @json_data_animals,    
                                                    {:content_type => 'application/json',
                                                     :accept => 'application/json'}) 

              rescue Errno::ECONNRESET => e
                  cuenta += 1
                  retry unless cuenta > 20
                  return
              end

              if response_heats then
                  @destroy_heat = HeatTambero.destroy_all
                  response_heats = JSON.parse(response_heats)
                  #puts response_heats.inspect
                  response_heats.each do |rh|
                      if @heat_animal = rh["animal"] then
                          @new_heat_tambero = HeatTambero.new( :eartag => @heat_animal["rp_number"],
                                                               :heat_icon => @heat_animal["heat_icon"],
                                                               :pregnancy => @heat_animal["pregnancy"])
                          @new_heat_tambero.save
                      end
                  end
              end
          end
    end
end

