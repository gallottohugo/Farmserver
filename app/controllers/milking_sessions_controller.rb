# encoding: UTF-8
class MilkingSessionsController < ApplicationController

  hobo_model_controller

  auto_actions :all

  show_action :excel_export

  def index    
    @milking_session = MilkingSession.find_by_sql("select ms.id, min(am.created_at) inicio, max(am.date_end_at) final, ms.date_at, ms.status, sum(am.volume) volume, avg(am.volume) promedio, avg(am.conductivity) conductivity, avg(temperature) temperature from milking_sessions ms, animal_milkings am where am.milking_session_id = ms.id group by ms.id, am.milking_session_id, ms.date_at, ms.status order by inicio DESC LIMIT 60")
    
    @milkin_ses = @milking_session.sort_by { |ms| ms[:date_at] }

    @time = @milkin_ses.map{|t| t.date_at.strftime("%d%m%y").to_i}
    @control_volu    = @milkin_ses.map{|v| v.volume.round(2)}
    @control_avg     = @milkin_ses.map{|p| p.promedio.round(2)}
    @control_temp    = @milkin_ses.map{|t| t.temperature.round(2)}
    @control_condu   = @milkin_ses.map{|c| c.conductivity.round(2)}    

    @time_zone = TamberoApi.first.time_zone[4..9]
  end



  def milking_in_session        
    @table_session = AnimalMilking.where("milking_session_id = ?", params[:session] )
    @session_ordene = MilkingSession.find_by_sql("select ms.id, min(am.created_at) inicio, max(am.date_end_at) final, ms.date_at, ms.status, sum(am.volume) volumen, avg(am.volume) promedio from  milking_sessions ms, animal_milkings am where am.milking_session_id = ms.id and ms.id = #{params[:session]} group by ms.id, am.milking_session_id, ms.date_at, ms.status order by ms.date_at")
    
    respond_to do |format|
      format.html { render 'milking_session' }
    end
  end

  def show
    hobo_show do
      @table_milking_session = MilkingSession.find_by_sql(["select ms.id id, min(am.created_at) date_start, max(am.date_end_at) date_end, ms.date_at, ms.status, sum(am.volume) volume, avg(am.volume) promedio from milking_sessions ms, animal_milkings am where am.milking_session_id = ms.id  and ms.id = ? group by ms.id, am.milking_session_id, ms.date_at, ms.status order by ms.date_at", this.id]).last
      @table_animal_milking = AnimalMilking.find_by_sql(["select * from animal_milkings where milking_session_id = ? order by eartag", this.id])
      @inactive_table = Animal.find_by_sql(["select * from animals where inactivated_at is null and rp_number not in (select eartag from animal_milkings where milking_session_id = ?) order by rp_number", this.id]) 
      @time_zone = TamberoApi.first.time_zone[4..9]
    end 
  end


  def excel
    #hola
  end

  def excel_export    
   hobo_show      
    require 'spreadsheet'

    @time_zone = TamberoApi.first.time_zone[4..9]
    @newrndfile = params[:rndfile]
    
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet :name => 'Milking Session'

    format_header = Spreadsheet::Format.new :color => :green, :weight => :bold, :size => 20
    format_header1 = Spreadsheet::Format.new :color => :green, :weight => :bold, :size => 12
    format_title = Spreadsheet::Format.new :color => :blue, :weight => :bold                                           
    format_name = Spreadsheet::Format.new :color => :black, :weight => :bold, :size => 18
  
    nrow = 1
    sheet1[nrow,1] = "Farmserver"
    sheet1.row(nrow).default_format = format_header

    nrow = 2
    sheet1[nrow,1] = Date.today.strftime("%d/%m/%Y")
    
    nrow = 4
    sheet1[nrow,1] = t("milkingSession.exportExel.detail", :default => "Details of Milking Session")
    sheet1.row(nrow).default_format = format_header1
    nrow = 6
    sheet1[nrow,1] = t("milkingSession.exportExel.date", :default => "Date")
    sheet1[nrow,2] = t("milkingSession.exportExel.start", :default => "Start")
    sheet1[nrow,3] = t("milkingSession.exportExel.end", :default => "End")
    sheet1[nrow,4] = t("milkingSession.exportExel.duration", :default => "Duration")
    sheet1[nrow,5] = t("milkingSession.exportExel.volume", :default => "Volume")
    sheet1[nrow,6] = t("milkingSession.exportExel.average", :default => "Average")

    sheet1.row(nrow).default_format = format_title

    @table_milking_session = MilkingSession.find_by_sql(["select ms.id id, min(am.created_at) date_start, max(am.date_end_at) date_end, ms.date_at, ms.status, sum(am.volume) volume, avg(am.volume) promedio from milking_sessions ms, animal_milkings am where am.milking_session_id = ms.id  and ms.id = ? group by ms.id, am.milking_session_id, ms.date_at, ms.status order by ms.date_at", this.id]).last
    @duration = @table_milking_session.date_end - @table_milking_session.date_start
    
    nrow = nrow + 1
    sheet1[nrow,1] = @table_milking_session.date_at.strftime("%d/%m/%Y")
    sheet1[nrow,2] = @table_milking_session.date_start.localtime(@time_zone).strftime("%d/%m/%Y - %H:%M")
    sheet1[nrow,3] = @table_milking_session.date_end.localtime(@time_zone).strftime("%d/%m/%Y - %H:%M")
    sheet1[nrow,4] = Time.at(@duration).utc.strftime("%H:%M:%S")
    sheet1[nrow,5] = @table_milking_session.volume.round(2)
    sheet1[nrow,6] = @table_milking_session.promedio.round(2)
      
    nrow = 10
    sheet1[nrow,1] = t("milkingSession.exportExel.start", :default => "Start")
    sheet1[nrow,2] = t("milkingSession.exportExel.end", :default => "End")
    sheet1[nrow,3] = t("milkingSession.exportExel.eartag", :default => "Eartag")
    sheet1[nrow,4] = t("milkingSession.exportExel.volume", :default => "Volume")
    sheet1[nrow,5] = t("milkingSession.exportExel.conductivity", :default => "Conductivity")
    sheet1[nrow,6] = t("milkingSession.exportExel.temperature", :default => "Temperature")
    sheet1[nrow,7] = t("milkingSession.exportExel.meter", :default => "Meter")
    
    sheet1.row(nrow).default_format = format_title

    @animal_milkings_export = AnimalMilking.where("milking_session_id = ?", this.id)
    @animal_milkings_export.each do |am|
      nrow = nrow + 1

      sheet1[nrow,1] = am.date_start_at.strftime("%d/%m/%Y - %H:%M")
      sheet1[nrow,2] = am.date_end_at.strftime("%d/%m/%Y - %H:%M")
      sheet1[nrow,3] = am.eartag
      sheet1[nrow,4] = am.volume
      sheet1[nrow,5] = am.conductivity
      sheet1[nrow,6] = am.temperature
      sheet1[nrow,7] = am.meter      
    end
     
     # charset = %w{1 2 3 4 6 7 9 a b c d e f g h i j k l m n o p q r s t u v w x y z}
     # @rndfile = (0...12).map{ charset.to_a[rand(charset.size)] }.join    

     book.write "public/tmp/exp/milking_session_#{this.id}_#{@newrndfile}.xls"
     # redirect_to "/milking_sessions/#{this.id}"
  end

end
