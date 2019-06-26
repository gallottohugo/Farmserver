class WeighingsController < ApplicationController

  hobo_model_controller

  auto_actions :all

  index_action :index_details, :index_history, :export_details, :export_history

  def index
  	@table_weighing = WeighingSession.find_by_sql("select ws.id, ws.dated_at, ws.status, avg(we.weight) weight, count(we.eartag) animals from weighing_sessions ws, weighings we where we.weighing_session_id = ws.id group by ws.id, we.weighing_session_id, ws.dated_at, ws.status order by ws.created_at DESC LIMIT 100")

    @table = WeighingSession.find_by_sql("select ws.id, ws.dated_at, ws.status, avg(we.weight) weight, count(we.eartag) animals from weighing_sessions ws, weighings we where we.weighing_session_id = ws.id group by ws.id, we.weighing_session_id, ws.dated_at, ws.status order by ws.created_at LIMIT 100")
    if @table
      @weight_data_round  = @table.map{|w| w.weight.round(2).to_i}
      @time_round         = @table.map{|t| t.dated_at.strftime("%m%d%H%M").to_i}
    end
     
  end

  def index_details
  	@session_id = params["session_id"]
  	@table_weighing = Weighing.find_by_sql(["select * from weighings where weighing_session_id = ? order by eartag ASC LIMIT 100", @session_id])

    @table = Weighing.find_by_sql(["select * from weighings where weighing_session_id = ? order by eartag ASC LIMIT 100", @session_id])
    if @table
      @weight_data_round = @table.map{|w| w.weight.round(2).to_i}
      @time_round        = @table.map{|t| t.eartag.to_i}
    end
  end

  def index_history
	@eartag = params["eartag"]
  	@table_history = Weighing.find_by_sql(["select * from weighings where eartag = ? order by created_at DESC LIMIT 100", @eartag])
  	@animal = Animal.where("rp_number = ?", @eartag).last
  	if @animal
  		@name = @animal.long_name
  	end

  	@last_weight = Weighing.where("eartag = ?", @eartag).last.weight

    @table = Weighing.find_by_sql(["select * from weighings where eartag = ? order by created_at LIMIT 100", @eartag])
    if @table
      @weight_data_round  = @table.map{|w| w.weight.round(2).to_i}
      @time_round = @table.map{|t| t.created_at.strftime("%m%d%H%M").to_i}
    end
  end



  def export_details    
    require 'spreadsheet'
    
    @newrndfile = params[:rndfile]
    @session_id = params[:session_id]
    
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet :name => 'Weighing details'

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
    sheet1[nrow,1] = t("weighing.exportExel.detail", :default => "Details of Weighing Session")
    sheet1.row(nrow).default_format = format_header1
    
    sheet1.row(nrow).default_format = format_title
  
    nrow = 6
    sheet1[nrow,1] = t("weighing.exportExel.date", :default => "Date")
    sheet1[nrow,2] = t("weighing.exportExel.eartag", :default => "Eartag")
    sheet1[nrow,3] = t("weighing.exportExel.hour", :default => "Hour")
    sheet1[nrow,4] = t("weighing.exportExel.weight", :default => "Weight")
    
    
    sheet1.row(nrow).default_format = format_title

    @weighing_export = Weighing.where("weighing_session_id = ?", params["session_id"])
    @weighing_export.each do |we|
      nrow = nrow + 1

      sheet1[nrow,1] = we.dated_at.strftime("%d/%m/%Y - %H:%M")
      sheet1[nrow,2] = we.eartag 
      sheet1[nrow,3] = we.hour
      sheet1[nrow,4] = we.weight
    end

    book.write "public/tmp/exp/weighing_details_#{@session_id}_#{@newrndfile}.xls"
  end

  def export_history
    require 'spreadsheet'
    
    @newrndfile = params[:rndfile]
    @eartag = params[:eartag]
    
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet :name => 'Weighing details'

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
    sheet1[nrow,1] = t("weighing.exportExel.history", :default => "HISTORY WEIGHING")
    sheet1.row(nrow).default_format = format_header1
    
    sheet1.row(nrow).default_format = format_title
  
    nrow = 6
    sheet1[nrow,1] = t("weighing.exportExel.Date", :default => "Date")
    sheet1[nrow,2] = t("weighing.exportExel.eartag", :default => "Eartag")
    sheet1[nrow,3] = t("weighing.exportExel.hour", :default => "Hour")
    sheet1[nrow,4] = t("weighing.exportExel.weight", :default => "Weight")
       
    sheet1.row(nrow).default_format = format_title

    @weighing_export = Weighing.where("eartag = ?", params["eartag"])
    @weighing_export.each do |we|
      nrow = nrow + 1

      sheet1[nrow,1] = we.dated_at.strftime("%d/%m/%Y - %H:%M")
      sheet1[nrow,2] = we.eartag
      sheet1[nrow,3] = we.hour
      sheet1[nrow,4] = we.weight
    end

    book.write "public/tmp/exp/weighing_history_#{@eartag}_#{@newrndfile}.xls"

  end
end
