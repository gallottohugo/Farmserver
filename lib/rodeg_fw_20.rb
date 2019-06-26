class RawRSR < BinData::Record
  array   :data, :type=>:uint8, :initial_length=>8192
end

class RodegMilker_20 < BinData::Record
  endian  :big
  uint16  :eartag
  uint16  :volume #[cl]
  uint16  :temperature #[c degC]
  uint8   :conductivity #[0.1 uS]
  string  :flag_ascii, :read_length=>1
  uint8	  :version
  uint8   :milking
  uint8	  :assignment_status
  array   :data, :type => :uint8, :initial_length => 5
end

class RodegAntenna_20 < BinData::Record
  endian  :big
  uint8   :indice
  uint16	:uid
  uint16	:steps
  uint16	:t_lying
  uint16	:t_walking
  uint8		:battery
  uint8		:flag_hex
  array   :data, :type => :uint8, :initial_length => 5
end

class RodegDataGroup_20 < BinData::Record
  RodegMilker_20	:milkerdata
  #TODO: Cambiar este nombre
  RodegAntenna_20	:antenna_1
  RodegAntenna_20	:antenna_2
end

class RodegMessages_20 < BinData::Record
  array	:data, :type => :uint8, :initial_length => 8
end


class RodegSystem_20 < BinData::Record
  array	:preamble, :type => :uint8, :initial_length => 3
  uint8	:version
  uint8	:number_of_milkers
  uint8	:modo_tambo
  uint8	:update_pedometer
  array	:data, :type => :uint8, :initial_length => 17
  uint8	:rm1
  uint8	:rm2
  uint8	:rm3
  array	:data2, :type => :uint8, :initial_length => 7
  uint8 :chk_config
  #Arreglo de medidores
  array	:milkers, :type => :RodegDataGroup_20, :initial_length => :number_of_milkers
  #Asterisco de fin de trama
  uint8	:star #This should alwas be a *
  #Suma de verificación de
  uint8	:chk
end

#class RodegMilkerData_20 < BinData::Record
#	RodegSystem_20	:system
#	array	:milkers, :type => :RodegMilker_20, :initial_length => :system.number_of_milkers
#end


class RodegPedometer_20 < BinData::Record
  endian :big
  uint16 :uid
  uint16 :steps #[x10 steps]
  uint16 :time_laying #[x10s]
  uint16 :time_walking #[x10s]
  uint8  :battery #[%]
end

class RodegPedometerAssignation < BinData::Record
  endian  :big
  uint16	:eartag
  array   :data, :type => :uint8, :initial_length => 6
end

class RodegPedometerAssigationTable < BinData::Record
  array	:preamble, :type => :uint8, :initial_length => 3
  array	:pedometer_assignations, :type => :RodegPedometerAssignation, :initial_length => 500
  uint8	:star #This should alwas be a *
  uint8	:chk
end

class RodegRefrigeration_20 < BinData::Record
  array   :conf, :type => :uint8, :initial_length => 32
  array   :data, :type => :uint8, :initial_length => 32
end

class RodegWashing_20 < BinData::Record
  array   :conf, :type => :uint8, :initial_length => 32
  array   :data, :type => :uint8, :initial_length => 32
end

class RodegWeigthing_20 < BinData::Record
  array   :conf, :type => :uint8, :initial_length => 32
  array   :data, :type => :uint8, :initial_length => 32
end

class RodegFeeding_20 < BinData::Record
  array   :conf, :type => :uint8, :initial_length => 32
  array   :data, :type => :uint8, :initial_length => 32
end

class RodegRemoteAccess_20 < BinData::Record
  array   :conf, :type => :uint8, :initial_length => 32
  array   :data, :type => :uint8, :initial_length => 32
end

class Prueba_20 < BinData::Record
  endian :big
  uint16 :rp_number 
  uint8  :nro_msj
end



class RodegController_20 < RodegControllerBase
  def initialize
    super
    @last_reading = Array.new
  end

  #Chechsum is plain masked 8 bit sum, excluding preamble, the * and checksum intself.
  def chk_config(frame)
	#i=0
    calc_chk=0
    
    raw = frame.to_binary_s
    if @checksum_comments
        puts raw.inspect
    end

    raw[3..33].split(//).each do |b|
        calc_chk = 0xFF & (calc_chk+BinData::Int8.read(b))
    end
        if @checksum_comments
            puts "_______________"
            puts "CHECKSUM RETURN"
            puts calc_chk.to_s
        end
        return calc_chk
  end

  def chk(frame)
	    return 1
  end
  
  def upload_pedometer_assignation_table()
    	@animal = Animal.find_by_sql("select rp_number, rfid_tag from animals where rfid_tag !='' ")
          @animal.each do |a_data|
              @alarm_data = AlarmAssignation.where("eartag = ?", a_data.rp_number).last
              if @alarm_data
                  @alarm = @alarm_data.number_alarm
              else
                  @alarm = 0
              end
             
              puts "Podometro:"+ a_data.rfid_tag + "| caravana:" + a_data.rp_number.to_s + "| alarm:" + @alarm.to_s 

              #Codigo para grabar con alarma
              @serial_port_write.write("ATWDP%03i:%04X%02X%010X\r" % [ a_data.rfid_tag, a_data.rp_number, @alarm, 0 ])
              puts "ATWDP%03i:%04X%02X%010X\r" % [ a_data.rfid_tag, a_data.rp_number, @alarm,0 ]


              #Codigo para grabar sin alarma
              #@serial_port_write.write("ATWDP%03i:%04X%012X\r" % [ a_data.rfid_tag, a_data.rp_number, 0 ])
        	    #puts "ATWDP%03i:%04X%012X\r"% [ a_data.rfid_tag, a_data.rp_number, 0 ]

        	    sleep 0.5.seconds
        	    @serial_answer = @serial_port_read.read()
              puts "respuesta: " + @serial_answer
          end
    	sleep 2.seconds
      @serial_port_write.write("ATCA\r")
  end

  def save_pedometry
    @pedometry = Pedometry.new(:dated_at => Time.now,      
                               :steps_number => @pedometer.steps,
                               :lying_time => @pedometer.t_lying,
                               :walking_time => @pedometer.t_walking,
                               :standing_time => 0,
                               :battery => @pedometer.battery,
                               :eartag => @eartag_pedometer)
    @pedometry.save
  end



  def read_data()  
    @pedometries_comments = true
    @milkings_comments = true 
    @checksum_comments = false

    bad_log=File.open('log/poll_rodeg_controller-bad_frame.log','a+')
    err_log=File.open('log/poll_rodeg_controller-error.log','a+')    

    @serial_port_read.read()
    @serial_port_write.write("ATRDA\r")
    sleep 0.5.seconds
    rsr = RodegSystem_20.new
  	rsr.read(@serial_port_read.read)
    
    
  	puts " "
    puts " "
    puts "INSPECT PREVIO AL LOOP:"
	  puts rsr.inspect
    puts " "
    puts " "
	
	
    @new_pedometers = TamberoApi.first.update_pedometer
    if rsr.update_pedometer == 0 or @new_pedometers == true
      if @pedometries_comments
        puts "-- Updating pedometer assignation table -- "
      end
        
        upload_pedometer_assignation_table

        if @tambero_api = TamberoApi.first
            @tambero_api.update_pedometer = false
            @tambero_api.save
        end
    end
  

    if chk_config(rsr) != rsr.chk_config
      if @checksum_comments
        puts  "//////////////// - ERROR: bad checksum - ////////////////"      
      end
      ##########################################################################
      #COLOCAR EL COMANDO ADECUADO PARA QUE COMIENCE DE NUEVO DESDE EL PRINCIPIO
      ##########################################################################
	  else
      if @checksum_comments
	      puts "//////////////// - CHK config zone OK - ////////////////"
      end
    end

	  traza = "ok"
  
    begin
		sleep 2.seconds
		puts "Inicio loop." if traza == "ok"   	 
		puts "Consulto cantidad de Medidores."  if traza == "ok"

		@milking_machines = MilkingMachine.all
		@milking_machines.each do |m|
			 
		puts "-------------------------------------------- " if traza == "ok"
		puts "Leyendo Medidor nro: " + m.number.to_s if traza == "ok"
    
		index = m.number-1

          
        volumen = rsr.milkers[index].milkerdata.volume/100.0
        temperatura = ( rsr.milkers[index].milkerdata.temperature & 0x03FF )/10.0
        conductividad = ( rsr.milkers[index].milkerdata.conductivity & 0x03FF )/10.0
        medidor = index
		    caudal = "0"
        flag = rsr.milkers[index].milkerdata.flag_ascii

        if not ['P','D','R','L','A','M','O'].include? flag #If the flag is not a valid one, then the milker is not connected or sending data.
          flag = '-'
        end

		    puts "Estado del medidor es: " + flag.to_s if traza == "ok"
        act_log = File.open('log/poll_rodeg_controller-activity-'+Time.now().strftime('%Y_%m_%d')+'.log','a+')
        act_log.write(Time.now.to_s+"> Mlkr "+index.to_s+": "+rsr.milkers[index].milkerdata.inspect+"\n")

        act_log.close

        mdit = MilkingMachineRead.where(:meter => m.number).last
        if mdit == nil
          mdit = MilkingMachineRead.new()          
        end
        if @last_reading[index] == nil
           puts "------------ El last reading esta en nil por eso reasigno -----------------"
           @last_reading[index] = rsr.milkers[index]
        end

  		if flag != "O"
        if @milkings_comments
  			   puts "Datos de caravana, volumen, temperatura y conductividad se ignoran y dejan en 0." if traza == "ok"
        end
  			mdit.eartag = "0"
  			mdit.volume = "0"
  			mdit.temperature = "0"
  			mdit.conductivity = "0"
  			mdit.milking_current = nil
  			mdit.meter = medidor + 1
  			mdit.state = flag.to_s   
  			mdit.updated_at = Time.now    
      else
        if @milkings_comments
  			   puts "Leyendo datos de trama." if traza == "ok"
        end
  			mdit.eartag = rsr.milkers[index].milkerdata.eartag
  			mdit.volume = volumen
  			mdit.temperature = temperatura
  			mdit.conductivity = conductividad
  			mdit.meter = medidor + 1
  			mdit.state = flag.to_s
  			mdit.updated_at = Time.now 		 
  		end
      mdit.save

      if @milkings_comments
        puts "mdit"
        puts mdit.inspect
        puts "Datos de trama guardados en tabla temporal." if traza == "ok"
    
        puts "Milking Anterior = " + @last_reading[index].milkerdata.milking.to_s 
        puts "Milking Actual = " + rsr.milkers[index].milkerdata.milking.to_s 
      end
	          
      if (rsr.milkers[index].milkerdata.milking != @last_reading[index].milkerdata.milking and rsr.milkers[index].milkerdata.flag_ascii.to_i != 0xFF and flag == "O" ) or ( rsr.milkers[index].milkerdata.milking == 0 and mdit.milking_current == nil and flag == "O")   then
          
		  	  @animal = Animal.where("rp_number = ?", mdit.eartag).last
        
          if @milkings_comments
  			    puts "Inicio nuevo Animal Milking" if traza == "ok"
  		      puts "paso la traza"
          end
    		  @am = AnimalMilking.new(:date_start_at => Time.now, 
  		                            :date_end_at => Time.now, 
                                  :eartag => mdit.eartag,
                     	            :volume => 0,
                    	            :temperature => 0,
                     	            :conductivity => 0,
                     	            :meter => mdit.meter)
          @am.save
          if @milkings_comments
    			   puts "Se ha creado un nuevo Animal_milking." if traza == "ok"
          end

          @unknown_eartag = @am.unknown_eartag
          unless @unknown_eartag
  	         	@last_animal_milking = AnimalMilking.find(@am.id)        
  	         	@last_animal_milking.notification_unknown_eartag
          end
      
  		    mdit.milking_current = @am.id 
  		    mdit.save
          if @milkings_comments
  		      puts "Se ha actualizado Sesion de Ordene en Tabla Temporal." if traza == "ok"
          end
      	 






          # PEDOMETER_READING
          # buscar id de podometro cuya caravana tiene el medidor, cual es podometro asociado a la caravana y buscar el medidor que tiene ese id!

          # si la caravana que busque es igual a la caravana que tiene el medidor, grabar la informacion de podometria.
          # si no es igual la busco en la otra antena.
          # si no esta en la segunda antena recorrer los medidores buscando esa caravana.

          # buscar  id de podometro cuya caravana tiene el medidor, cual es podometro asociado a la caravana y buscar el medidor que tiene ese id!

          # busco entre las dos antenas 
          # busco antena 1 si no está entonces
          # busco antena 2 si sigue sin encontrar la caravana entonces
          # recorro todos medidores buscando el podometro de la caravana 

          if @pedometries_comments
            puts "#######################"
            puts "DATA PEDOMETRY"
          end

          @pedometer = rsr.milkers[index].antenna_1
          @pedometer_number = @pedometer.uid
          if @pedometries_comments
            puts @pedometer.inspect
            puts "PEDOMETER_NUMBER: " + @pedometer_number.to_s
          end

          if @animal_pedometer = Animal.where("rfid_tag = ?", @pedometer_number.to_s).last
              @eartag_pedometer = @animal_pedometer.rp_number
          else
             @eartag_pedometer = 0
          end

          if  mdit.eartag != nil and mdit.eartag > 0 
            if mdit.eartag == @eartag_pedometer
                if @pedometries_comments
                  puts "-------------------------"
                  puts "LAS CARAVANAS SON IGUALES"
                  puts "-------------------------"
                end

                  save_pedometry
            else
              if @pedometries_comments
                puts "NO ENCONTRO EN ANTENA_1 - BUSCA EN ANTENA_2"			
              end
              @pedometer = rsr.milkers[index].antenna_2
              @pedometer_number = @pedometer.uid
                if @pedometries_comments
                  puts @pedometer.inspect
                  puts "PEDOMETER_NUMBER: " + @pedometer_number.to_s
                end

              if @animal_pedometer = Animal.where("rfid_tag = ?", @pedometer_number.to_s).last
                  @eartag_pedometer = @animal_pedometer.rp_number
              else
                  @eartag_pedometer = 0
              end

              if mdit.eartag == @eartag_pedometer
                if @pedometries_comments
                  puts "-------------------------"
                  puts "LAS CARAVANAS SON IGUALES"
                  puts "-------------------------"
                end

                  save_pedometry            
              end
            end
          end		
        end
      







        if (rsr.milkers[index].milkerdata.milking != @last_reading[index].milkerdata.milking and rsr.milkers[index].milkerdata.flag_ascii.to_i != 0xFF and flag != "O" ) then    
               puts 'NO SE CUMPLIERON LAS CONDICIONES' if traza == "ok"
               next	
        end
    
        ### si no cambió el milking >>> sigue el mismo, hacer un find del ordeñe actual y update de ordeñe.  
        if flag == "O" then	
          if @milkings_comments
  	         puts mdit.inspect
          end
		    if mdit.milking_current != nil and mdit.milking_current > 0        
        #if mdit.milking_current > 0        
        if @milkings_comments
			     puts "Inicio actualizacion valor actual de Animal_milking." if traza == "ok"
			     puts "Animal_milking a buscar:" +  mdit.milking_current.to_s if traza == "ok"
        end
			
			  @update_milking = AnimalMilking.find(mdit.milking_current) 
          if @milkings_comments
  			    puts "Animal_Milking actual encontrada:" + @update_milking.id.to_s if traza == "ok"
  			    puts @update_milking.inspect  	  			        if traza == "ok" 
          end
			   
			    @update_milking.volume = volumen
				  @update_milking.temperature = temperatura
			    @update_milking.updated_at = Time.now
			    @update_milking.conductivity = conductividad
				  @update_milking.date_end_at = Time.now
          if @milkings_comments
            puts "volumen asignado." if traza == "ok"
            puts "temperatura asignado." if traza == "ok"
            puts "updated asignado." if traza == "ok"
            puts "conductividad asignado." if traza == "ok"
  				  puts "date_end actualizada"
          end

			    @update_milking.save
          if @milkings_comments
				    puts "se actualizo el milking"
          end
          if @milkings_comments								
            puts "Se fin de actualizacion de valor actual de Animal_Milking"  if traza == "ok"			  
  			    puts "Inicio Calculo de Caudal" if traza == "ok"
          end
    
				unless @flow_old
					@flow_old = AnimalMilkingDetail.where("animal_milking_id = ? and volume < ?", mdit.milking_current, volumen).last
          if @milkings_comments
					  puts "asigono los datos a flow_old"
          end
						if @flow_old == nil then
              if @milkings_comments
							  puts "flow_old era nulo"
              end
							@flow_old = AnimalMilkingDetail.new(
							  :volume => volumen,
							  :temperature => temperatura,
							  :conductivity => conductividad,
							  :animal_milking_id => mdit.milking_current,
							  :flow => 0)
							@flow_old.save
						end
          if @milkings_comments
					  puts "Actualizo el animal milking details"
          end 
				end
    
				if @flow_old then
				  if (@flow_old.volume.to_f != volumen.to_f) then 
					  @medida_volumen1 = @flow_old.volume.to_f 
					  @tiempo_volumen1 = @flow_old.created_at
            if @milkings_comments
  					  puts "Medida volumen 1:" + @medida_volumen1.to_s
  					  puts "Tiempo volumen 1:" + @tiempo_volumen1.to_s
            end
					  
					  @medida_volumen2 = volumen.to_f
					  @tiempo_volumen2 = Time.now
            if @milkings_comments
  					  puts "Medida volumen 2:" + @medida_volumen2.to_s
  					  puts "Tiempo volumen 2:" + @tiempo_volumen2.to_s
            end
					  
					  @diferencia_medida = (@medida_volumen2 - @medida_volumen1).to_f
					  @diferencia_tiempo = @tiempo_volumen2 - @tiempo_volumen1
				    
					  @caudal_minuto = (@diferencia_medida / @diferencia_tiempo * 60).to_f
            if @milkings_comments
					    puts "Diferencia medida" + @diferencia_medida.to_s
					    puts "Diferencia de Tiempo" + @diferencia_tiempo.to_s
					    puts "Caudal por Minuto" + @caudal_minuto.to_s
            end
					end 
				end 
        if @milkings_comments
				  puts "FIN CALCULO CAUDAL"
        end

				@caudal_minuto = 0 unless @caudal_minuto			  
    
		 	  @flow_new = AnimalMilkingDetail.new(
					   :volume => volumen,
					   :temperature => temperatura,
					   :conductivity => conductividad,
					   :flow => @caudal_minuto.to_f,
					   :animal_milking_id => mdit.milking_current )
			  @flow_new.save
			   
			  @caudal_minuto = 0	
			  if @milkings_comments
			    puts "##### FIN creo caudales ### " 
        end
		  end    
    end
	    
    @last_reading[index] = rsr.milkers[index]
    puts @last_reading[index].inspect
    puts "Actualizacion datos anteriores realizada." if traza == "ok"
  
    end


##################################################################################################################	
	
	
    rescue => e
        puts '########################################## An error occurred ##########################################'
        err_log.write("---------------- Error message ---------------------\n")

        err_log.write(e.message)
        err_log.write("\n------- END Error message | Start backtrace --------\n")
        e.backtrace.each do |b|
          err_log.write(b.to_s+"\n")
        end
        err_log.write("------------------ END backtrace -------------------\n")
        err_log.sync = true
    end
    err_log.close
    bad_log.close
  end
end
