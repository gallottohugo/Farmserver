class PedometriesController < ApplicationController

  hobo_model_controller

  auto_actions :all

  index_action :index_details, :index_history, :export_details, :export_history

  def index
  	@table_sessions = MilkingSession.find_by_sql("select ms.id, ms.date_at, ms.status, avg(pe.steps_number) steps, avg(pe.battery) battery, avg(pe.lying_time) lying, avg(pe.walking_time) walking, avg(pe.standing_time) standing from milking_sessions ms, pedometries pe where pe.milking_session_id = ms.id group by ms.id, pe.milking_session_id, ms.date_at, ms.status order by ms.date_at DESC LIMIT 100")

    @data = MilkingSession.find_by_sql("select * from milking_sessions ms, pedometries pe where pe.milking_session_id = ms.id group by ms.id, pe.milking_session_id, ms.date_at, ms.status order by ms.date_at DESC")
    
    if @table_sessions
      @steps_data_round     = @table_sessions.map{|s| s.steps.round(2).to_i}
      @lying_data_round     = @table_sessions.map{|l| l.lying.round(2).to_i}    
      @walking_data_round   = @table_sessions.map{|w| w.walking.round(2).to_i}
      @standing_data_round  = @table_sessions.map{|s| s.standing.round(2).to_i}
      @time_round           = @table_sessions.map{|t| t.date_at.strftime("%d%H%M").to_i}
    end
  end

  def index_details
  	@session_id = params["session_id"]
  	@table_pedometry = Pedometry.find_by_sql(["select * from pedometries where milking_session_id = ? order by eartag ASC LIMIT 100", @session_id])
    

    @table = Pedometry.find_by_sql(["select * from pedometries where milking_session_id = ? order by eartag ASC LIMIT 100", @session_id])
    if @table
      @steps_data_round    = @table.map{|s| s.steps_number.round(2).to_i}
      @lying_data_round    = @table.map{|l| l.lying_time.round(2).to_i}
      @walking_data_round  = @table.map{|w| w.walking_time.round(2).to_i}
      @standing_data_round = @table.map{|s| s.standing_time.round(2).to_i}
      @time_round          = @table.map{|t| t.eartag.to_i}
    end
  end

  def index_history
  	@eartag = params["eartag"]
  	@table_history = Pedometry.find_by_sql(["select * from pedometries where eartag = ? order by dated_at DESC LIMIT 100", @eartag])
  	@animal = Animal.where("rp_number = ?", @eartag).last
  	if @animal
  		@name = @animal.long_name
  	end
  	@avgs = Pedometry.find_by_sql(["select avg(steps_number) steps, avg(lying_time) lying, avg(walking_time) walking, avg(standing_time) standing from pedometries where eartag = ? order by created_at DESC LIMIT 100 ", @eartag]).last


    @table = Pedometry.find_by_sql(["select * from pedometries where eartag = ? order by dated_at LIMIT 100", @eartag])
    if @table
      @steps_data_round    = @table.map{|s| s.steps_number.round(2).to_i}
      @lying_data_round    = @table.map{|l| l.lying_time.round(2).to_i}
      @walking_data_round  = @table.map{|w| w.walking_time.round(2).to_i}
      @standing_data_round = @table.map{|s| s.standing_time.round(2).to_i}
    end
    

    @time = Pedometry.find_by_sql(["select dated_at from pedometries where eartag = ? order by dated_at DESC LIMIT 100", @eartag])
    if @time
      @time_round = @time.map{|t| t.dated_at.strftime("%y%m%d%H").to_i}
    end
  end

  def export_details    
    require 'spreadsheet'
    
    @newrndfile = params[:rndfile]
    @session_id = params[:session_id]
    
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet :name => 'Pedomery details'

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
    sheet1[nrow,1] = t("pedometry.exportExel.detail", :default => "Details of Milking Session")
    sheet1.row(nrow).default_format = format_header1
    
    sheet1.row(nrow).default_format = format_title
  
    nrow = 6
    sheet1[nrow,1] = t("pedometry.exportExel.date", :default => "Date")
    sheet1[nrow,2] = t("pedometry.exportExel.eartag", :default => "Eartag")
    sheet1[nrow,3] = t("pedometry.exportExel.steps", :default => "Steps")
    sheet1[nrow,4] = t("pedometry.exportExel.lying", :default => "Lying Time")
    sheet1[nrow,5] = t("pedometry.exportExel.walking", :default => "Walking Time")
    sheet1[nrow,6] = t("pedometry.exportExel.standing", :default => "Standing Time")
    
    
    sheet1.row(nrow).default_format = format_title

    @pedometry_export = Pedometry.where("milking_session_id = ?", params["session_id"])
    @pedometry_export.each do |pe|
      nrow = nrow + 1

      sheet1[nrow,1] = pe.dated_at.strftime("%d/%m/%Y - %H:%M")
      sheet1[nrow,2] = pe.eartag 
      sheet1[nrow,3] = pe.steps_number
      sheet1[nrow,4] = pe.lying_time
      sheet1[nrow,5] = pe.walking_time
      sheet1[nrow,6] = pe.standing_time
    end

    book.write "public/tmp/exp/pedometry_details_#{@session_id}_#{@newrndfile}.xls"
  end

  def export_history
    require 'spreadsheet'
    
    @newrndfile = params[:rndfile]
    @eartag = params[:eartag]
    
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet :name => 'Pedomery details'

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
    sheet1[nrow,1] = t("pedometry.exportExel.history", :default => "HISTORY PEDOMETRY")
    sheet1.row(nrow).default_format = format_header1
    
    sheet1.row(nrow).default_format = format_title
  
    nrow = 6
    sheet1[nrow,1] = t("pedometry.exportExel.Date", :default => "Date")
    sheet1[nrow,2] = t("pedometry.exportExel.eartag", :default => "Eartag")
    sheet1[nrow,3] = t("pedometry.exportExel.steps", :default => "Steps")
    sheet1[nrow,4] = t("pedometry.exportExel.lying", :default => "Lying Time")
    sheet1[nrow,5] = t("pedometry.exportExel.walking", :default => "Walking Time")
    sheet1[nrow,6] = t("pedometry.exportExel.standing", :default => "Standing Time")
       
    sheet1.row(nrow).default_format = format_title

    @pedometry_export = Pedometry.where("eartag = ?", params["eartag"])
    @pedometry_export.each do |pe|
      nrow = nrow + 1

      sheet1[nrow,1] = pe.dated_at.strftime("%d/%m/%Y - %H:%M")
      sheet1[nrow,2] = pe.eartag
      sheet1[nrow,3] = pe.steps_number
      sheet1[nrow,4] = pe.lying_time
      sheet1[nrow,5] = pe.walking_time
      sheet1[nrow,6] = pe.standing_time
    end

    book.write "public/tmp/exp/pedometry_history_#{@eartag}_#{@newrndfile}.xls"

  end

end
