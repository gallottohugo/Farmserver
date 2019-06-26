# encoding: UTF-8
require 'rake'
require 'json'
require 'rest_client'


class FrontController < ApplicationController


  hobo_controller




  def select_language       
  end

  def export_backup
    if system("rake database_export_tambero")
      @transfer = ApiTransfer.new(
          :process_type => "output",
          :process_name => "export_backup",
          :date_at      => DateTime.now(),
          :result       => true)
      @transfer.save   
      redirect_to "/front", notice: 'El backup se guardo correctamente'   
    else  
      redirect_to "/front", notice: 'Ocurrio un error al guardar el Backup'    
    end
  end

  def up_database     
    if system("rake database_import_tambero")
        @transfer = ApiTransfer.new(
            :process_type => "input",
            :process_name => "database_import_tambero",
            :date_at      => DateTime.now(),
            :result       => true)
        @transfer.save   
      if system("rake upload_database")
        #Este ApiTrnsfers lo puse para actualizar la fecha, asi toma la fecha del dia que se subio el bucup
        @transfer = ApiTransfer.new(
            :process_type => "input",
            :process_name => "upload_database",
            :date_at      => DateTime.now(),
            :result       => true)
        @transfer.save

        @message_backup =  NotificationMessage.find_by_sql("select * from notification_messages where status = 1 and source = 'inputbackup'").last
        if @message_backup
            @message_backup.status = false
            @message_backup.save
        end
        redirect_to "/front", notice: 'El backup se levanto correctamente'   
      else
        redirect_to "/front", notice: 'Ocurrio un error al levantar el Backup'    
      end   
    else
      redirect_to "/front", notice: 'Ocurrio un error al levantar el Backup'    
    end
  end

  def index    
    @cant_sessions = MilkingSession.find_by_sql("select * from milking_sessions where status > 0")

    if TamberoApi.count == 0
      redirect_to  "/front/select_language"
    else
      if  current_user.guest?
        redirect_to "/login"
      else
        #notification_backup
        #notification_version
        notification_milking_machine
        notification_animals
        notification_connexion_input
        notification_connexion_output
        last_milking

        @table_notification = NotificationMessage.where("status = ?", true)       
      end
    end   
  end

  def summary
    if !current_user.administrator?
      redirect_to user_login_path
    end
  end

  def search
    if params[:query]
      site_search(params[:query])
    end
  end


  def notification_tambero_api
    if TamberoApi.count == 0
      unless @source = NotificationMessage.find_by_sql("select * from notification_messages where status = 1 and source = 'tamberoapi'").last
        @notification = NotificationMessage.new(:name => "Tambero Api",
                                                :message => t("notificationMessages.message.configuration", :default => "Warning: Setup information with Tambero.com has not been entered."),
                                                :source => "tamberoapi",
                                                :status => true,
                                                :link => "/tambero_apis/new",
                                                :color => "red",
                                                :type_message => "error")
        @notification.save         
      end
    end
  end

  def notification_milking_machine
    if MilkingMachine.count == 0
      unless @source = NotificationMessage.find_by_sql("select * from notification_messages where status = 1 and source = 'milkingmachine'").last
        @notification = NotificationMessage.new(:name => "Milking Machine",
                                                :message => t("notificationMessages.message.meters", :default => "Warning: There are no Milking meters in the system. Press here to fix the problem."),
                                                :source => "milkingmachine",
                                                :status => true,
                                                :link => "/milking_machines/index_new",
                                                :color => "red",
                                                :type_message => "error")
        @notification.save   
      end
    end
  end

=begin
  def notification_current_version
    @api = TamberoApi.first 
      unless @api == nil         
        if @api.current_version < @api.installed_version
          unless @source = NotificationMessage.find_by_sql("select * from notification_messages where status = 1 and source = 'currentversion'").last   
            @notification = NotificationMessage.new(:name => "Current Version",
                                                    :message => "Atencion: Existe una nueva versión del sistema",
                                                    :source => "currentversion",
                                                    :status => true,
                                                    :link => "-",
                                                    :color => "red",
                                                    :type_message => "error")
                                                    
            @notification.save 
          end
        end 

        if @api.current_version == @api.installed_version 
          @delete_notification = NotificationMessage.first(:conditions => ["source = ? and status = ?", "currentversion", true])
            unless @delete_notification == nil
             @delete_notification.status = false
             @delete_notification.save
          end           
        end
      end
  end
=end


  def notification_version
    @api = TamberoApi.first
    url  = @api.tambero_url+'/api/version?userid='+@api.tambero_user_id+'&apikey='+@api.tambero_api_key+'&apilicense=rodegserver&apilang='+@api.language

    cuenta = 0
    begin
      @data = JSON.parse(RestClient.get(url))
      puts  @data
    rescue Errno::ECONNRESET => e
      cuenta += 1
      retry unless cuenta > 10
        puts e
        @transfer = ApiTransfer.new(
          :process_type => "input",
          :process_name => "notification_version",
          :date_at      => DateTime.now(),
          :result       => false,
          :code_error   => 1,
          :error        => "RestClient error ("+e.message+")")
        @transfer.save      
      return
    end

    unless @data == []
      @data.each do |d|
        d = JSON.parse(d)
        version = d["version"]
        nro = version["number"]
        a = TamberoApi.first
        a.current_version = nro.to_f
        if a.save
          @transfer = ApiTransfer.new(
            :process_type => "input",
            :process_name => "notification_version",
            :date_at      => DateTime.now(),
            :result       => true)
          @transfer.save      
        end
      end
    end
  end



  def notification_animals
    if Animal.count == 0 
      unless @source = NotificationMessage.find_by_sql("select * from notification_messages where status = 1 and source = 'animals'").last      
        @notification = NotificationMessage.new(:name => "Animals",
                                                :message => t("notificationMessages.message.animals", :default => "Warning. There are no animals in the database. Press here to fix the problem."),
                                                :source => "animals",
                                                :status => true,
                                                :link => "/tambero_apis/#{@api.id}",
                                                :color => "red",
                                                :type_message => "error")
        @notification.save
      end
    end 
  end


  def notification_connexion_input
      @now = DateTime.now.to_date
      @input = "input"
            
      @date_input_transfer = ApiTransfer.find_by_sql(["select created_at from api_transfers where process_type = ? order by created_at DESC LIMIT 1", @input]).last
        unless @date_input_transfer == nil
          @date_input = @date_input_transfer.created_at.to_date
          @difference_input = (@now - @date_input).to_i 
        else
          @difference_input = 0        
        end
        
        @api = TamberoApi.first
        unless @api == nil
          @days = @api.days_without_connexion
        
          if @difference_input > @days
            unless @source = NotificationMessage.find_by_sql("select * from notification_messages where status = 1 and source = 'inputconnexion'").last
              @notification = NotificationMessage.new(:name => "Connexion with Tambero.com",
                                                    :message => t("notificationMessages.message.connexion", :default => "Warning: It has been more of these days without connection to Tambero.com:"),
                                                    :source => "inputconnexion",
                                                    :status => true,
                                                    :link => " ",
                                                    :color => "red",
                                                    :type_message => "error")
              @notification.save
            end                          
          else
            @delete_notification = NotificationMessage.first(:conditions => ["source = ? and status = ?", "outputconnexion", true])
              unless @delete_notification == nil
                @delete_notification.status = false
                @delete_notification.save
              end
          end
        end
  end

  def notification_connexion_output
      @now = DateTime.now.to_date
      @output = "output"

      @date_output_transfer = ApiTransfer.find_by_sql(["select created_at from api_transfers where process_type = ? order by created_at DESC LIMIT 1", @output]).last
        unless @date_output_transfer == nil
          @date_output = @date_output_transfer.created_at.to_date
          @difference_output = (@now - @date_output).to_i
        else
          @difference_output = 0
        end
         
        @api = TamberoApi.first
        unless @api == nil
          @days = @api.days_without_connexion
      
          if @difference_output > @days 
            unless @source = NotificationMessage.find_by_sql("select * from notification_messages where status = 1 and source = 'outputconnexion'").last       
              @notification = NotificationMessage.new(:name => "Connexion with Tambero.com",
                                                      :message => t("notificationMessages.message.connexion", :default => "Warning: It has been more of these days without connection to Tambero.com:"),
                                                      :source => "outputconnexion",
                                                      :status => true,
                                                      :link => " ",
                                                      :color => "red",
                                                      :type_message => "error")
              @notification.save  
            end
          else
            @delete_notification = NotificationMessage.first(:conditions => ["source = ? and status = ?", "outputconnexion", true])
              unless @delete_notification == nil
                @delete_notification.status = false
                @delete_notification.save
              end
          end         
        end  
  end


  def notification_backup
    @api_transfers = ApiTransfer.where("process_name = ?", "database_export_tambero").last
    if @api_transfers
      @api_date = @api_transfers.created_at.strftime("%y%m%d")
    else
      @api_date = "000000"
    end

    @api = TamberoApi.first
    url  = @api.tambero_url+'/api/backup?userid='+@api.tambero_user_id+'&apikey='+@api.tambero_api_key+'&apilicense=rodegserver&apilang='+@api.language+'&status=download'
  
    
    cuenta = 0
    begin
      data = JSON.parse(RestClient.get(url))
      puts  data
    rescue Errno::ECONNRESET => e
      cuenta += 1
      retry unless cuenta > 10
        puts e
        puts "hay un error"
        @transfer = ApiTransfer.new(
          :process_type => "input",
          :process_name => "notification_backup",
          :date_at      => DateTime.now(),
          :result       => false,
          :code_error   => 1,
          :error        => "RestClient error ("+e.message+")")
        @transfer.save      
      return
    end

    
    if data.include? "filedate"
      @file_date = data["filedate"]
      if @file_date > @api_date
          unless @source = NotificationMessage.find_by_sql("select * from notification_messages where status = 1 and source = 'inputbackup'").last       
            @notification = NotificationMessage.new(:name    => "Import backup from Tambero.com",
                                                    :message => t("notificationMessages.message.backup", :default => "Warning: There is a backup available with latest information. Please click here to download it! (The process may take a few minutes)."),
                                                    :source  => "inputbackup",
                                                    :status  => true,
                                                    :link    => "/front/up_database",
                                                    :color   => "red",
                                                    :type_message => "information")
            @notification.save  
          end
      end
    end
  end


  def last_milking
    @last_sessions = MilkingSession.find_by_sql("select ms.id, min(am.date_start_at) date_start, max(am.date_end_at) date_end, ms.date_at, ms.status, sum(am.volume) volume, avg(am.volume) promedio, count(am.eartag) cant from milking_sessions ms, animal_milkings am where am.milking_session_id = ms.id group by ms.id, am.milking_session_id, ms.date_at, ms.status order by ms.date_at DESC LIMIT 6") 
         
      @last_duration = 0
      @last_dura = 0
      @last_cant = 0
      @last_minute_animal = 0
      @last_total = 0
      @last_average = 0
      @last_animal_minute = 0 
      @count = 0     

        if @last_sessions        
          @last_sessions.each do |ls| 
              @last_dura += (ls.date_end - ls.date_start)
              @last_cant += ls.cant
              @last_total += ls.volume
              @last_average += ls.promedio               
              @last_animal_minute = ls.average_duration_animal

              @count += 1             
            end 
            
            if  @count > 0
              @last_dura = (@last_dura / @count)
              @last_duration = Time.at(@last_dura).utc.strftime("%H:%M:%S")
              @last_cant = (@last_cant / @count)
              @last_total = (@last_total / @count).round(2)
              @last_average = (@last_average / @count).round(2)
              @last_animal_min = (@last_animal_minute / @count)
              @last_animal_minute = Time.at(@last_animal_minute).utc.strftime("%H:%M:%S")
            end              
        end
        
    @current_session = MilkingSession.find_by_sql("select ms.id, min(am.date_start_at) date_start, max(am.date_end_at) date_end, ms.date_at, ms.status, sum(am.volume) volume, avg(am.volume) promedio, count(am.eartag) cant from milking_sessions ms, animal_milkings am where am.milking_session_id = ms.id group by ms.id, am.milking_session_id, ms.date_at, ms.status order by ms.date_at DESC LIMIT 1").last
  end


  
end
