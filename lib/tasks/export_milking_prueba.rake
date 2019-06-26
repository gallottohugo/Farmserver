require 'net/ftp'
require 'net/http'
require 'rest_client'
require 'json'

desc "Export data for uploading to tambero.com"
  task :export_milking_prueba => :environment do

    #hago un random de 300 sgundos antes de ejecutar dns_tambero
    #t = rand(300)
    #puts "sleep de: " + t.to_s
    #sleep t.seconds
    dns_tambero

    if @tambero_api = TamberoApi.first
      @minimo_tiempo = @tambero_api.end_milking.minute
    end

    if @am = AnimalMilking.last
       if @am.date_start_at > Time.now.utc - (@minimo_tiempo + 1.minute) #Pregunta si pasaron mas minutos que @tambero_api.end_milking del ultimo ordeÃ±e a la hora actual
          puts "Last milking to close in time. Wait!"
        exit 
      end
      puts "Paso el minimo de tiempo y se ejecuta la rutina"
    end

    #if TamberoApi.count > 0
    #  Time.zone = TamberoApi.first.time_zone
    #end

    #hago un random de 300 sgundos antes de ejecutar la actualizacion de animales
    #t = rand(300)
    #puts "sleep de: " + t.to_s
    #sleep t.seconds
    #Animal.add_from_tambero
    #Animal.deactivate_from_tambero
    #Animal.update_from_tambero
    puts "se ejecutaron las tres rutinas de animales"


    #Actualizo los msj de alarmas en la tabla, alarmas por animal
    puts "Actualizo los msj de alarmas en la tabla, alarmas por animal"
    #update_alarms
    puts "paso el update_alarms"


       

    #Busco todos los animal_milkings con milking_session_id, busco la fecha del ultimo animal_milking o busco la fecha del primero sin milking_session_id
    puts "Animal_milking con session_id"
    @last_milking = AnimalMilking.find_by_sql(" select * from animal_milkings where milking_session_id is not null order by date_start_at").last
    if @last_milking
      @last_milking_date = @last_milking.date_start_at
    else
      if @last_milking = AnimalMilking.first 
        @last_milking_date = @last_milking.date_start_at
        #creo la session aca para identificar la de podometria de milking
        @ms_milking = MilkingSession.new(:date_at => @last_milking_date, :status => 0)      
        @ms_milking.save
      end      
    end


    #Busco todos los pedometries con milking_session_id, busco la fecha del ultimo animal_milking o busco la fecha del primero sin milking_session_id
    puts "Pedometry con session_id"
    @last_pedometry = Pedometry.find_by_sql(" select * from animal_milkings where milking_session_id is not null").last
    if @last_pedometry
      @last_pedometry_date = @last_pedometry.created_at
    else
      if @last_pedometry = Pedometry.first
        @last_pedometry_date = Pedometry.first.created_at
        #creo la session aca para identificar la de podometri de milking
        @ms_pedometry = MilkingSession.new(:date_at => @last_pedometry_date,
                                           :status => 0)      
        @ms_pedometry.save
      end
    end

  
    if @last_milking_date
      puts "busco animalmilking sin session_id"
      # busco todos Animal_Milkings sin milking_session_id y asigno el id
      AnimalMilking.all( :order => :date_start_at, :conditions => { :milking_session_id => nil } ).each do |animalmilking|
        @milking_current_date = animalmilking.date_start_at
        puts "entro a los animal milkings sin milking_session_id"

        if @milking_current_date == @last_milking_date
          puts "@milking_current_date == @last_milking_date"
          #entra solo la primera vez cuando empieza a registrar datos
          animalmilking.milking_session_id = @ms_milking.id
          animalmilking.save          
          puts "actualizo el primer animal milking de la base, PASA AL SIGUIENTE"
          puts "id_animal_milking: "+animalmilking.id.to_s
          puts "______"
          next
        elsif ((@milking_current_date - @last_milking_date ).second > @minimo_tiempo)
          puts "((@milking_current_date - @last_milking_date ).second > @minimo_tiempo)"   
          @ms_milking = MilkingSession.new(:date_at => @last_milking_date,  :status => 0)      
          @ms_milking.save
          puts "supero el MINIMO_TIEMPO, se creo un ms_milking"
          puts "______"
        elsif ((@milking_current_date - @last_milking_date ).second < @minimo_tiempo)
          puts "((@milking_current_date - @last_milking_date ).second < @minimo_tiempo)"   
          @ms_milking = MilkingSession.last
          
          puts "NO supero el MINIMO_TIEMPO, se busco el ultimo ms_milking"
          puts "______"
          
        end
        
        animalmilking.milking_session_id = @ms_milking.id
        animalmilking.save
        puts "@last_milking_date = @milking_current_date!!!"
        puts "______"
        @last_milking_date = @milking_current_date
      end
    end
  


  if @last_pedometry_date
      puts "busco pedometries sin session_id"
      # busco todos Animal_Milkings sin milking_session_id y asigno el id
      Pedometry.all( :order => :created_at, :conditions => { :milking_session_id => nil } ).each do |pedometry|
        @pedometry_current_date = pedometry.created_at

        if @pedometry_current_date == @last_pedometry_date
          #entra solo la primera vez cuando empieza a registrar datos
          pedometry.milking_session_id = @ms_pedometry.id
          pedometry.save          
          puts "actualizo el primer pedometry de la base"
          puts "deberia parar al siguiente"
          next
        elsif ((@pedometry_current_date - @last_pedometry_date ).second > @minimo_tiempo)   
          @ms_pedometry = MilkingSession.new(:date_at => @last_pedometry_date,
                                             :status => 0)       
          @ms_pedometry.save
          puts "supero el minimo de tiempo, se creo un ms_pedometry"
          puts "nuevo id de MS-animal_milking"+@ms_pedometry.id.to_s
        elsif ((@pedometry_current_date - @last_pedometry_date ).second < @minimo_tiempo)   
          @ms_milking = MilkingSession.last
        end
        pedometry.milking_session_id = @ms_pedometry.id
        pedometry.save
        @last_pedometry_date = @pedometry_current_date
      end
    end




    
    #  Busca MilkingSession status en 0 
    puts "busco Milking_sessions status 0"
    MilkingSession.all(:conditions=> ['status not in (?)',[100,21030,21040,500]]).each do |milkingsession|  
      puts "Encontro sesiones y entro al bucle"

      
      if @am_1  = AnimalMilking.where("milking_session_id = ?", milkingsession.id).last
        if  @am_2 = AnimalMilking.all( :order => :date_start_at, :conditions => { :milking_session_id => nil } ).first
          unless ((@am_2.created_at - @am_1.created_at).second > @minimo_tiempo) then
              puts "falta completar el milkiing session con animal milkings"
              exit
          end
        end
      end

      @last_animal_milking = AnimalMilking.where("milking_session_id = ?", milkingsession.id).last
      @last_pedometry = Pedometry.where("milking_session_id = ?", milkingsession.id).last




      @animal_milking = AnimalMilking.where("milking_session_id = ?", milkingsession.id)     
      @pedometry = Pedometry.where("milking_session_id = ?", milkingsession.id)     

      if @animal_milking.count > 0 or @pedometry.count  > 0
        #creo los json para enviar a tambero
        @json_data_details = '['
        @json_data_pedometry = '['



        unless @animal_milking == []
          #entro a armar el json_data_details
          puts "entro a armar el json_data_details"
            @animal_milking.order(:date_start_at).each do |animalmilking|     

          	    @eartag = animalmilking.eartag
                unless Animal.where("rp_number = ?", @eartag)
          	      next
                end
                date_milking = animalmilking.date_start_at
              
                unless @date = date_milking.strftime("%Y%m%d")
                  @date = "0"
                end
                unless @time = date_milking.strftime("%H%M")
                  @time = "0"
                end            
                unless @kg = animalmilking.volume
                  @kg = 0
                end            
                unless @temperature = animalmilking.temperature
                  @temperature = 0
                end            
                unless @conductivity = animalmilking.conductivity
                  @conductivity = 0
                end            
                @id = animalmilking.id            
                @milking_session = animalmilking.milking_session_id

                if @id == @last_animal_milking.id 
                  @text_details = '{"milking_detail":{"scc":0, "weight":0, "protein":0, "fat":0, "eartag":'+@eartag.to_s+', "total_value":'+@kg.to_s+', "value_1":'+@kg.to_s+', "charging_method":"file"}} '
                else
                  @text_details = '{"milking_detail":{"scc":0, "weight":0, "protein":0, "fat":0, "eartag":'+@eartag.to_s+', "total_value":'+@kg.to_s+', "value_1":'+@kg.to_s+', "charging_method":"file"}}, '
                end
                @json_data_details = @json_data_details + @text_details
            end
          @json_data_details = @json_data_details + ']'
          puts "___________________________"
          puts "Termine de armar el json de animal_milking"
          puts @json_data_details 
        end




        unless @pedometry == []
          puts "entro a armar el json_data_pedometry"
            @pedometry.order(:created_at).each do |pedometry|        

                @eartag = pedometry.eartag
                unless Animal.where("rp_number = ?", @eartag)
                  next
                end
                date_pedometry = pedometry.created_at
                unless @date_pedomery = date_pedometry.strftime("%Y%m%d")
                  @date_pedometry= "0"
                end

                unless @time_pedometry = date_pedometry.strftime("%H%M")
                  @time_pedometry = "0"
                end            

                unless @battery = pedometry.battery
                  @kg = 0
                end            

                unless @lying_time  = pedometry.lying_time 
                  @lying_time  = 0
                end            

                unless @walking_time  = pedometry.walking_time 
                  @walking_time  = 0
                end         

                unless @standing_time  = pedometry.standing_time 
                  @standing_time  = 0
                end         

                unless @real_steps  = pedometry.real_steps 
                  @real_steps  = 0
                end         


                @id_pedometry = pedometry.id            
                @milking_session_pedometry = pedometry.milking_session_id

                if @id == @last_pedometry.id 
                  @text_pedometry = '{"pedometry":{"dated_at":0, "hour":0, "steps_number":0, "lying_time":0, "walking_time":0, "standing_time":0, "eartag":'+@eartag.to_s+', "charging_method":"file"}} '
                else
                  @text_pedometry = '{"pedometry":{"dated_at":0, "hour":0, "steps_number":0, "lying_time":0, "walking_time":0, "standing_time":0, "eartag":'+@eartag.to_s+', "charging_method":"file"}}, '
                end
                @json_data_pedometry = @json_data_pedometry + @text_pedometry
            end
          @json_data_pedometry = @json_data_pedometry + ']'
          puts "___________________________"
          puts "Termine de armar el json de podometria"
          puts @json_data_pedometry
        end



        ms_date = MilkingSession.where("id = ?", milkingsession.id).last
        puts "MILKING_SESSION_ID = " + milkingsession.id.to_s
        @date = ms_date.date_at.strftime("%Y%m%d")
        
        #creo el json del animal_control
        @json_data_milking = '[{"milking":{"date":"'+@date+'","name":"Control Lechero Rodeg","comments":"Este control lechero se ha generado a traves de una importacion de datos automatica desde la ordenadora.","in_charge":"Ordenadora electronica Rodeg","unit":"Lts","herd_correction":0}}]'
        puts "__________________________"
        puts "Json del animal_control"
        puts @json_data_milking


        
        @date_1 = @date + "000000"
        api = TamberoApi.first
        url = api.tambero_url+"/apiv2/milkings?method=export&userid="+api.tambero_user_id+"&apikey="+api.tambero_api_key+"&apilicense=rodegserver&apilang="+api.language+"&apilist=equal_date&recordtype=new&recorddate="+@date.to_s
        puts url.to_s
        cuenta = 0
        begin
          data = JSON.parse(RestClient.get(url))
        rescue Errno::ECONNRESET => e
          cuenta += 1
          retry unless cuenta > 20
            @process_name = "export_milking_sessions"
            @code_error = 1
            @code = "No se pudo conectar con Tambero.com ("+e.message+")"
            api_transfers_error
          return
        end
        puts "data: " + data.to_s
        
        if data == []
            #insertar un registro nuevo
            #crear un animal_contro nuevo en tambero
            puts "creo un animal control en tambero"
            url_new_milking = api.tambero_url+"/apiv2/milkings?method=import&userid="+api.tambero_user_id+"&apikey="+api.tambero_api_key+"&apilicense=rodegserver&apilang="+api.language
            puts "URL: " + url_new_milking

            response1 = RestClient.post("#{url_new_milking}",
                                @json_data_milking,    
                                {:content_type => 'application/json',
                                 :accept => 'application/json'})


            puts "___________"
            puts "RESPONSE 1"
            puts response1
        
            #hago una consulta para averiguar el nro de id del animal_control que cree
            new_url = api.tambero_url+"/apiv2/milkings?method=export&userid="+api.tambero_user_id+"&apikey="+api.tambero_api_key+"&apilicense=rodegserver&apilang="+api.language+"&apilist=equal_date&recordtype=new&recorddate="+@date.to_s
            puts "NEW_URL: " + new_url.to_s
            cuenta = 0
            begin
              new_data = JSON.parse(RestClient.get(new_url))
            rescue Errno::ECONNRESET => e
              cuenta += 1
              retry unless cuenta > 20
                @process_name = "export_milking_sessions"
                @code_error = 1
                @error = "No se pudo conectar con Tambero.com ("+e.message+")"
                api_transfers_error
              return
            end

            puts "new_data: " + new_data.to_s

            new_data.each do |d|
              @animal_control = d["animal_control"]
              @id_animal_control = @animal_control["id"]
              puts "El id del animal_control es: " + @id_animal_control.to_s
            end

            #Creo un nuevo control_details con todos los animal_milkings
            puts "creo un nuevo control details"
            url_new_detail = api.tambero_url+"/apiv2/milkingdetails?method=import&userid="+api.tambero_user_id+"&apikey="+api.tambero_api_key+"&apilicense=rodegserver&apilang="+api.language+"&id_animal_control="+@id_animal_control.to_s
            puts "URL_new: " + url_new_detail

            response2 = RestClient.post("#{url_new_detail}",
                                @json_data_details,    
                                {:content_type => 'application/json',
                                 :accept => 'application/json'})
            puts "___________"
            puts "RESPONSE 2"
            puts response2
            r2_sum = 0




            r2 = JSON.parse(response2)
            r2.each do |r|
              if r2_sum == 1
                if "done" == r["status"]
                  puts "Entro a DONE"
                  milkingsession.status = 100
                  milkingsession.save
                  @process_name = "export_milking_sessions"
                  api_transfers_done
                else
                  if r["code"] == "10110"
                    puts "CODE 10110"
                    @process_name = "export_milking_sessions"
                    @code_error = r["code"].to_i
                    @error = r["message"].to_s
                    api_transfers_error
                    exit
                    #exit xq supero el limite de uso del api
                  else
                    @process_name = "export_milking_sessions"
                    @code_error = r["code"].to_i
                    @error = r["message"].to_s
                    api_transfers_error
                  end
                end
              else
                r2_sum += 1
              end
            end
        else
          data.each do |d|
            if @animal_control = d["animal_control"]
              @id_animal_control = @animal_control["id"]
              puts "El id del animal_control es: " + @id_animal_control.to_s

              #si tiene datos, actualizar el control details con ese id!
              puts "actualizo los control details"

              url_update_detail = api.tambero_url+"/apiv2/milkingdetails?method=update&userid="+api.tambero_user_id+"&apikey="+api.tambero_api_key+"&apilicense=rodegserver&apilang="+api.language+"&id_animal_control="+@id_animal_control.to_s
              puts "URL_update: " + url_update_detail

              response3 = RestClient.post("#{url_update_detail}",
                                    @json_data_details,    
                                    {:content_type => 'application/json',
                                      :accept => 'application/json'})

              puts "_______________________________________________"
              puts "RESPONSE 3"
              puts response3

              r3_sum = 0
              r3 = JSON.parse(response3)
              r3.each do |r|
                if r3_sum == 1
                  if "done" == r["status"]
                    milkingsession.status = 100
                    milkingsession.save
                    @process_name = "export_milking_sessions"
                    api_transfers_done
                  else
                    if r["code"] == "10110"
                      @process_name = "export_milking_sessions"
                      @code_error = r["code"].to_i
                      @error = r["message"].to_s
                      api_transfers_error
                      exit
                      #exit xq supero el limite de uso del api
                    elsif r["code"] == "20050"
                      milkingsession.status = 500
                      milkingsession.save

                      @process_name = "export_milking_sessions"
                      @code_error = r["code"].to_i
                      @error = "Milking_session: "+milkingsession.id.to_s+" no importada a tambero, supero el maximo permitido"
                      api_transfers_error
                      next
                    else
                      @process_name = "export_milking_sessions"
                      @code_error = r["code"].to_i
                      @error = r["message"].to_s
                      api_transfers_error
                    end
                  end
                else
                  r3_sum += 1
                end
              end
            elsif "error" == d["status"]
              if d["code"] == "10110"
                @process_name = "export_milking_sessions"
                @code_error = d["code"].to_i
                @error = d["message"].to_s
                api_transfers_error
                exit
                #exit xq supero el limite de uso del api
              else
                @process_name = "export_milking_sessions"
                @code_error = d["code"].to_i
                @error = d["message"].to_s
                api_transfers_error
              end
            end    
          end          
        end
      end 
    end 
  end
















  desc "Reset the export related data"
  task :reset_export_prueba => :environment do
    if @ms = MilkingSession.all
      @ms.each do |ms|
        ms.status = 0
        ms.save
      end
    end

    if @am = AnimalMilking.all
      @am.each do |am|
        am.milking_session_id = nil
        am.save
      end
    end 

    if @p = Pedometry.all
      @p.each do |p|
        p.milking_session_id = nil
        p.save
      end
    end
  end



  def dns_tambero
    cuenta = 0
    @url_ip = "http://whatismyip.akamai.com/"

    begin
      @mi_ip = RestClient.get(@url_ip)
      puts "ya tengo el ip"
      @mi_ip1 = @mi_ip.strip
      puts "hace el strip"
    rescue Errno::ECONNRESET => e
      cuenta += 1
      retry unless cuenta > 20
        puts "hay un error"
        @process_name = "dns"
        @code_error = 1
        @error = "No se pudo obtener direccion ip ("+e.message+")"
      return
    end    

    @api = TamberoApi.first
    puts "hago la consulta"
    @url_dns = @api.tambero_url+'/apiv2/dns?userid='+@api.tambero_user_id+'&apikey='+@api.tambero_api_key+'&apilicense=rodegserver&apiip='+@mi_ip1+'&apiport=1111&apilang='+@api.language
    r_dns = RestClient.get(@url_dns)
    response_dns = JSON.parse(r_dns) 

      dns_sum = 0
      response_dns.each do |r|
        if dns_sum == 1
          if "done" == r["status"]
            @process_name = "dns"
            api_transfers_done 
          else
            if r["code"] == "10110"
              @process_name = "dns"
              @code_error = r["code"].to_i
              @error = r["message"].to_s
              api_transfers_error
              exit
              #exit xq supero el limite de uso del api
            else
              @process_name = "dns"
              @code_error = 1
              @error = "Ocurrio un erro al grbar dns"
              api_transfers_error
            end
          end
        else
          dns_sum += 1
        end
      end    
end

def api_transfers_error
  @transfer = ApiTransfer.new(
                  :process_type => "output",
                  :process_name => @process_name,
                  :date_at      => DateTime.now(),
                  :result       => false,
                  :code_error   => @code_error,
                  :error        => @error)
  @transfer.save
end

def api_transfers_done
  @transfer = ApiTransfer.new(
                    :process_type => "output",
                    :process_name => @process_name,
                    :date_at      => DateTime.now(),
                    :result       => true)
  @transfer.save
end



def update_alarms
      if @api = TamberoApi.first
        url_alarm = @api.tambero_url+'/apiv2/alarms?userid='+@api.tambero_user_id+'&apikey='+@api.tambero_api_key+'&apilicense=rodegserver&apilang='+@api.language
        puts "url_alarm: "+url_alarm
          begin
              @data_alarm = JSON.parse(RestClient.get(url_alarm))
          rescue Errno::ECONNRESET => e
              cuenta += 1
              retry unless cuenta > 20
                @process_name = "update_alarms"
                @code_error = 1
                @code = "No se pudo conectar con Tambero.com ("+e.message+")"
                api_transfers_error
            return
          end
        
        puts "data_alarm: "+@data_alarm.to_s
        #prgunto si data no esta vacio o es nulo
        unless @data_alarm == [] or @data_alarm == nil
          #pregunto si data vino con error, sino tiene error, entra
          unless @data_alarm.include? "error"
              #recorro data
              AlarmAssignation.destroy_all
              @data_alarm.each do |da|

                da = JSON.parse(da)
                alarm = da["alarm"]
                eartag = alarm["eartag"]
                if alarm["name"] == "heat"
                  new_alarm = AlarmAssignation.new(:eartag => eartag, :number_alarm => 12) #12 = Alarma por celos
                  new_alarm.save
                elsif alarm["name"] == "medication"
                  new_alarm = AlarmAssignation.new(:eartag => eartag, :number_alarm => 11) #11 = Alarma por antibiotico
                  new_alarm.save
                end
              end
               @api.update_pedometer = 1
               @api.save
               @process_name = "update_alarms"
               api_transfers_done
          else
              @data_alarm.each do |da|
                  #si tiene limite de uso salgo con el exit
                  if da["code"] == "10110"
                    @process_name = "update_alarms"
                    @code_error = da["code"].to_i
                    @error = da["message"].to_s
                    api_transfers_error
                    exit
                    #exit xq supero el limite de uso del api
                  else
                    #sino grabo el error tmb!
                    @process_name = "update_alarms"
                    @code_error = da["code"].to_i
                    @error = da["message"].to_s
                    api_transfers_error
                  end
              end
          end
        end
      end

end
