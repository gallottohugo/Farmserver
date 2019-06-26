require 'net/ftp'
require 'net/http'
require 'rest_client'
require 'json'



desc "Export database a tambero.com"
task :database_export_tambero => :environment do

  system("mysqldump -u root -pabcdef1234 farmserver_d | gzip -f -9 > /home/notroot/backup_farmserver/farmserver_backup$(date +%y%m%d).sql.gz")
  
	#Buscar el archivo, renombrarlo y dps subirlo
  @api = TamberoApi.first
  @week = Time.now.strftime('%W')
  @today = Date.today.strftime("%y%m%d")
  
  database_file = ("/home/notroot/backup_farmserver/Farmserver_backup"+@today+".sql.gz")
  file = "farmserver_backup"+@today+".sql.gz"

  path = "/home/notroot/backup_farmserver"
  new_name = @api.tambero_user_id+"_"+@week+".sql.gz"

  Dir.open(path).each do |p|
    puts "entro al each"
    if p == file
      puts "entro al if"
      old = path + "/" + p
      new_name_file = path + "/" + new_name
      File.rename(old, new_name_file)
      puts "rename file"
    end
  end
  puts "paso el each"
    
  new_database_file = (path+"/"+new_name) 

  @filename = new_name
  
  #hago un random de 300 segundos antes de ejecutar upload_json_backup
  t = rand(300)
  sleep t.seconds
  upload_json_backup

  if @resp.include? "error"
    @resp.each do |r|
      @transfer = ApiTransfer.new(
        :process_type => "output",
        :process_name => "database_export_tambero",
        :date_at      => DateTime.now(),
        :result       => false,
        :code_error   => r["code"],
        :error        => r["message"])
      @transfer.save  
    end
  end

  if upload_backup(new_database_file)
      @transfer = ApiTransfer.new(
          :process_type => "output",
          :process_name => "database_export_tambero",
          :date_at      => DateTime.now(),
          :result       => true)
      @transfer.save 
  end  
end


def upload_backup(new_database_file)
  cuenta = 0
  begin
    ftp = Net::FTP.new('ftp.tambero.com')
    ftp.passive = true
    ftp.login(user = "rodeg", passwd = "rodeg")
    ftp.put(new_database_file)
    ftp.quit()
    return true
  rescue
    cuenta += 1
    retry unless cuenta > 10
      @transfer = ApiTransfer.new(
          :process_type => "output",
          :process_name => "database_export_tambero",
          :date_at      => DateTime.now(),
          :result       => false,
          :code_error   => 1,
          :error        => "FTP error")
      @transfer.save
      return false  
  end
end




def upload_json_backup
  cuenta = 0
  url =  @api.tambero_url+'/api/backup?userid='+@api.tambero_user_id+'&apikey='+@api.tambero_api_key+'&apilicense=rodegserver&apisource=ftp&apilang='+@api.language+'&filename='+@filename+'&status=upload'
  begin
    @resp = JSON.parse(RestClient.get(url))
    puts @resp
  rescue Errno::ECONNRESET => e
    cuenta += 1
    retry unless cuenta > 5
      puts "hay un error"
      @transfer = ApiTransfer.new(
        :process_type => "output",
        :process_name => "database_export_tambero",
        :date_at      => DateTime.now(),
        :result       => false,
        :code_error   => 1,
        :error        => "No se pudo realizar el query ("+e.message+")")
      @transfer.save      
  end 
end


