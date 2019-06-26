require 'json'
require 'rest_client'

desc "Upload database from Tambero.com"
task :upload_database => :environment do

  t = rand(300)
  sleep t.seconds
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
          :process_name => "upload_database",
          :date_at      => DateTime.now(),
          :result       => false,
          :code_error   => 1,
          :error        => "Error ("+e.message+")")
        @transfer.save      
      return false
    end

    if data.include? "filename"
      puts "entro al data"
      @file_name = data["filename"]
      @file = ("/home/notroot/backup_farmserver_download/"+@file_name)

      if system ("gunzip < "+@file+" | mysql -u root -pabcdef1234 farmserver_d")
          puts "add backup"
          @transfer = ApiTransfer.new(
              :process_type => "input",
              :process_name => "upload_database",
              :date_at      => DateTime.now(),
              :result       => true)
            @transfer.save      
      else
          @transfer = ApiTransfer.new(
            :process_type => "input",
            :process_name => "upload_database",
            :date_at      => DateTime.now(),
            :result       => false,
            :code_error   => 1,
            :error        => "Error al subir el backup")
          @transfer.save     
          return false 
      end
    end

    if data.include? "error"
      data.each do |d|
          @transfer = ApiTransfer.new(
              :process_type => "input",
              :process_name => "upload_database",
              :date_at      => DateTime.now(),
              :result       => false,
              :code_error   => d["code"],
              :error        => d["message"])
          @transfer.save      
      end
      return false
    end
end


