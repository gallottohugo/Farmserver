require 'net/ftp'
require 'net/http'
require 'rest_client'
require 'json'


desc "Import database from Tambero.com"
task :database_import_tambero => :environment do
	
	#hago un random de 300 segundos antes de consultar el api
	t = rand(300)
    sleep t.seconds
    @api = TamberoApi.first
    url  = @api.tambero_url+'/api/backup?userid='+@api.tambero_user_id+'&apikey='+@api.tambero_api_key+'&apilicense=rodegserver&apilang='+@api.language+'&status=download'
    puts "hizo el url"
  
    cuenta = 0
	begin
	  data = JSON.parse(RestClient.get(url))
	  puts	data
	rescue Errno::ECONNRESET => e
	  cuenta += 1
	  retry unless cuenta > 10
	    puts e
	    puts "hay un error"
	    @transfer = ApiTransfer.new(
	      :process_type => "input",
	      :process_name => "database_import_tambero",
	      :date_at      => DateTime.now(),
	      :result       => false,
	      :code_error   => 1,
	      :error        => "RestClient error ("+e.message+")")
	    @transfer.save
	  return false
	end
	puts "paso el json"

    if data.include? "filename"
		name_database = "/"+data["filename"]
		path = "/home/notroot/backup_farmserver_download"+name_database

		begin
		    flag = 0
		    Net::FTP.open('ftp.tambero.com') do |ftp|
		  	ftp.login(user = "rodeg", passwd = "rodeg")
		  	ftp.chdir('/')
		    ftp.get(name_database, path)
		  	ftp.quit()
		  	flag = true
			end
		rescue
			cuenta += 1
		  retry unless cuenta > 10
		    @transfer = ApiTransfer.new(
		      :process_type => "input",
		      :process_name => "database_import_tambero",
		      :date_at      => DateTime.now(),
		      :result       => false,
		      :code_error   => 1,
		      :error        => "FTP error")
		    @transfer.save
		  return false
		end
		@transfer = ApiTransfer.new(
		      :process_type => "input",
		      :process_name => "database_import_tambero",
		      :date_at      => DateTime.now(),
		      :result       => true)
		@transfer.save
	end

	if data.include? "error"
		data.each do |d|
			@transfer = ApiTransfer.new(
			      :process_type => "input",
			      :process_name => "database_import_tambero",
			      :date_at      => DateTime.now(),
			      :result       => false,
			      :code_error   => d["code"],
			      :error        => d["message"])
			@transfer.save
	    end
	    return false
	end
end







