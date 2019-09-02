# encoding: UTF-8
class Animal < ActiveRecord::Base

    hobo_model # Don't put anything above this

    SpeciesType = HoboFields::Types::EnumString.for(:cow, :zebu, :buffalo, :goat, :sheep, :llama, :alpaca, :vicuna, :camel, :dromedary )

    fields do
        inactivated_at   :datetime
        long_name        :string
        id_fiscal        :string
        male             :boolean
        breed            :string
        weight           :integer
        origin           :string
        birth_date_at    :datetime
        state            :string
        tambero_id       :integer
        comment_state    :string
        rp_number        :integer
        rp_sire          :integer    
        rp_dam           :integer    
        owner_id         :integer
        species_type     Animal::SpeciesType
        life_production  :integer
        herd_id          :integer
        rfid_tag         :string
        timestamps
    end
  
    attr_accessible :inactivated_at, :long_name, :id_fiscal, :breed, :weight, :origin, 
                    :birth_date_at, :state, :tambero_id, :comment_state, :rp_number, :male, 
                    :rp_sire, :rp_dam, :owner_id, :species_type, :life_production, :herd_id, :rfid_tag

    # --- Permissions --- #

    def create_permitted?
        true
    end

    def update_permitted?
        true
    end

    def destroy_permitted?
        true
    end

    def view_permitted?(field)
        true
    end


    def self.add_from_tambero
        @api = TamberoApi.first
        @date = ApiTransfer.find_by_sql("select created_at from api_transfers where process_name = 'add_from_tambero' and result = 1").last

        if @date 
            t = @date.created_at.strftime("%Y%m%d%H%M")
        else
            @date = DateTime.new(2000,1,1)
            t = @date.strftime("%Y%m%d%H%M")
        end
         
        url = @api.tambero_url+'/api/export?userid='+@api.tambero_user_id+'&apikey='+@api.tambero_api_key+'&apilicense=rodegserver&apitype=animals&apilist=afterdatetime&recordtype=new&recorddate='+t+'&recordstatus=active&apilang='+@api.language
    
        t = rand(60)
        sleep t.seconds
        puts "sleep"+t.to_s
        flag = 0 
        cuenta = 0
        begin
            data = JSON.parse(RestClient.get(url))
        rescue Errno::ECONNRESET => e
            cuenta += 1
            retry unless cuenta > 15

            @transfer = ApiTransfer.new(
                :process_type => "input",
                :process_name => "add_from_tambero",
                :date_at      => DateTime.now(),
                :result       => false,
                :code_error   => 1,
                :error        => "No se pudo conectar con Tambero.com ("+e.message+")")
            @transfer.save
            return
        end
    
        unless data.include? "error"
            begin      
                unless data == nil    
                    data.each do |d|
                        @animal_tambero=d["animal"]
                        puts @animal_tambero["rp_number"].to_s+"|"+@animal_tambero["long_name"].to_s
            
                        if @animal_tambero["comments"] != nil then
                            comment = @animal_tambero["comments"]
                        else
                            comment = " - "
                        end

                        male = 0
                        if @animal_tambero["male"] 
                            male = 1
                        end

                        if @tambero_api = TamberoApi.first
                            @tambero_api.update_pedometer = true
                            @tambero_api.save
                        end
            
                        @animal_api = Animal.new(
                            :comment_state => comment,
                            :birth_date_at => @animal_tambero["birth_date"],
                            :long_name => @animal_tambero["long_name"],
                            :breed => @animal_tambero["breed"],
                            :male => male,
                            :tambero_id => @animal_tambero["id"],
                            :rp_number => @animal_tambero["rp_number"],
                            :id_fiscal =>@animal_tambero["id_fiscal"], 
                            :weight => @animal_tambero["weight"], 
                            :origin => @animal_tambero["origin"],  
                            :state => @animal_tambero["state"],  
                            :rp_sire => @animal_tambero["rp_sire"], 
                            :rp_dam => @animal_tambero["rp_dam"], 
                            :owner_id => @animal_tambero["owner_id"], 
                            :species_type => @animal_tambero["species_type"], 
                            :life_production => @animal_tambero["life_production"], 
                            :herd_id => @animal_tambero["herd_id"])
                        @animal_api.save
                    end
                end

                @transfer = ApiTransfer.new(
                    :process_type => "input",
                    :process_name => "add_from_tambero",
                    :date_at      => DateTime.now(),
                    :result       => true)
                @transfer.save             

                @delete_notification = NotificationMessage.first(:conditions => ["source = ? and status = ?", "Animals", true])
                unless @delete_notification == nil then
                    @delete_notification.status = false
                    @delete_notification.save
                end           
            rescue => e
                @transfer = ApiTransfer.new(
                    :process_type => "input",
                    :process_name => "add_from_tambero",
                    :date_at      => DateTime.now(),
                    :result       => false,
                    :code_error   => 1,
                    :error        => e.message)
                @transfer.save 
            end
        end
    

        if data.include? "error"
            data.each do |d|
                @transfer = ApiTransfer.new(
                    :process_type => "input",
                    :process_name => "add_from_tambero",
                    :date_at      => DateTime.now(),
                    :result       => false,
                    :code_error   => d["code"],
                    :error        => d["message"])
                @transfer.save 
            end
        end
    end
  

  def self.deactivate_from_tambero
    @api=TamberoApi.first
    @date = ApiTransfer.find_by_sql("select created_at from api_transfers where process_name = 'deactivate_from_tambero' and result = 1").last
    
    unless @date == nil
      t = @date.created_at.strftime("%Y%m%d%H%M")
    else
      @date = DateTime.new(2000,1,1)
      t = @date.strftime("%Y%m%d%H%M")
    end

    url = @api.tambero_url+'/api/export?userid='+@api.tambero_user_id+'&apikey='+@api.tambero_api_key+'&apilicense=rodegserver&apitype=animals&apilist=afterdatetime&recordtype=update&recorddate='+t+'&recordstatus=inactive&apilang='+@api.language
    
    t = rand(60)
    sleep t.seconds
    cuenta = 0
    begin
      data = JSON.parse(RestClient.get(url))
    rescue Errno::ECONNRESET => e
      cuenta += 1
      retry unless cuenta > 15
      
      @transfer = ApiTransfer.new(
        :process_type => "input",
        :process_name => "deactivate_from_tambero",
        :date_at      => DateTime.now(),
        :result       => false,
        :code_error   => 1,
        :error        => "No se pudo conectar con Tambero.com ("+e.message+")")
      @transfer.save       
      return
    end
    
    unless data.include? "error"
      begin
        unless data == nil    
          data.each do |d|
            @animal_tambero=d["animal"]
          
            @animal_api = Animal.where("tambero_id = ?", @animal_tambero["id"]).last
            @animal_api.inactivated_at = DateTime.now()
            @animal_api.save
          end
        end
        @transfer = ApiTransfer.new(
          :process_type => "input",
          :process_name => "deactivate_from_tambero",
          :date_at      => DateTime.now(),
          :result       => true)
        @transfer.save  
             
      rescue => e
        @transfer = ApiTransfer.new(
          :process_type => "input",
          :process_name => "deactivate_from_tambero",
          :date_at      => DateTime.now(),
          :result       => false,
          :code_error   => 1,
          :error        => e.message)
        @transfer.save
      end
    end
    

    if data.include? "error"
      data.each do |d|
         @transfer = ApiTransfer.new(
          :process_type => "input",
          :process_name => "add_from_tambero",
          :date_at      => DateTime.now(),
          :result       => false,
          :code_error   => d["code"],
          :error        => d["message"])
        @transfer.save 
      end
    end
  end


  def self.update_from_tambero
    @api = TamberoApi.first
    @date = ApiTransfer.find_by_sql("select created_at from api_transfers where process_name = 'update_from_tambero' and result = 1").last
    
    unless @date == nil
      t = @date.created_at.strftime("%Y%m%d%H%M")
    else
      @date = DateTime.new(2000,1,1)
      t = @date.strftime("%Y%m%d%H%M")
    end

    url = @api.tambero_url+'/api/export?userid='+@api.tambero_user_id+'&apikey='+@api.tambero_api_key+'&apilicense=rodegserver&apitype=animals&apilist=afterdatetime&recordtype=update&recorddate='+t+'&recordstatus=active&apilang='+@api.language
    
    t = rand(60)
    sleep t.seconds
    cuenta = 0
    begin
      data = JSON.parse(RestClient.get(url))
    rescue Errno::ECONNRESET => e
      cuenta += 1
      retry unless cuenta > 15
        @transfer = ApiTransfer.new(
          :process_type => "input",
          :process_name => "update_from_tambero",
          :date_at      => DateTime.now(),
          :result       => false,
          :code_error   => 1,
          :error        => "No se pudo conectar con Tambero.com ("+e.message+")")
        @transfer.save 
      return
    end
    
    unless data.include? "error"
      begin
        unless data == nil 
          data.each do |d|
            animal_tambero = d["animal"]

            unless animal_tambero["comments"] == nil
              comment = animal_tambero["comments"]
            else
              comment = " - "
            end

            if @tambero_api = TamberoApi.first
                @tambero_api.update_pedometer = true
                @tambero_api.save
            end

            @animal_api = Animal.where("tambero_id = ?", animal_tambero["id"]).last
              @animal_api.comment_state = comment
              @animal_api.birth_date_at = animal_tambero["birth_date"]
              @animal_api.long_name = animal_tambero["long_name"]
              @animal_api.breed = animal_tambero["breed"]
              @animal_api.male = animal_tambero["male"]
              @animal_api.rp_number = animal_tambero["rp_number"]
              @animal_api.id_fiscal = animal_tambero["id_fiscal"]
              @animal_api.weight = animal_tambero["weight"]
              @animal_api.origin = animal_tambero["origin"]
              @animal_api.state = animal_tambero["state"]
              @animal_api.rp_sire = animal_tambero["rp_sire"]
              @animal_api.rp_dam = animal_tambero["rp_dam"]
              @animal_api.owner_id = animal_tambero["owner_id"]
              @animal_api.species_type = animal_tambero["species_type"]
              @animal_api.life_production = animal_tambero["life_production"]
              @animal_api.herd_id = animal_tambero["herd_id"]
            @animal_api.save      
          end        
        end
        @transfer = ApiTransfer.new(
          :process_type => "input",
          :process_name => "update_from_tambero",
          :date_at      => DateTime.now(),
          :result       => true)
        @transfer.save      
      rescue => e
        @transfer = ApiTransfer.new(
          :process_type => "input",
          :process_name => "update_from_tambero",
          :date_at      => DateTime.now(),
          :result       => false,
          :code_error   => 1,
          :error        => e.message)
        @transfer.save
      end
    end
    
    if data.include? "error"
      data.each do |d|
         @transfer = ApiTransfer.new(
          :process_type => "input",
          :process_name => "add_from_tambero",
          :date_at      => DateTime.now(),
          :result       => false,
          :code_error   => d["code"],
          :error        => d["message"])
        @transfer.save 
      end
    end
  end
end
