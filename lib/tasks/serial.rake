require 'rodeg'

desc "Consultar el controlador Rodeg"
task poll_rodeg_controller: :environment do

  bad_log=File.open('log/poll_rodeg_controller-bad_frame.log','a+')
  err_log=File.open('log/poll_rodeg_controller-error.log','w+')

  
  #Pregunto si paso media hora del ultimo regitro de serial rake y gravo uno nuevo.
  @hour_ago = DateTime.now.utc - 30.minute
  unless  ApiTransfer.where("created_at >= ? and process_name = ?", @hour_ago, "serial_rake" ).last
    @transfer = ApiTransfer.new(
            :process_type => "new_serial_rake",
            :process_name => "serial_rake",
            :date_at      => DateTime.now(),
            :result       => true)
    @transfer.save
  end

  

  rc_test = RodegControllerBase.new

  fw = rc_test.firmware_version
  rc_test.close

  case fw.to_f
  when 6.0..7.999
    rc = RodegController_20.new
	
	puts rc.inspect
  else
    puts "Fimware version not supported: "+fw.to_s
    exit -1
  end


  puts "Start reading data"
  
  while true
    begin

      rc.read_data
    #  if Time.now.sec == 0
    #    puts "Check pedometer assignation table"
    #    if rc.check_pedometer_assignation_table != 0
    #      puts "Uploading pedometer asignation table"
    #      rc.upload_pedometer_assignation_table
    #    end
    #  end
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
      rc.reset

    end
  end
end
