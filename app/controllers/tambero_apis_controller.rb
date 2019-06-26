# encoding: UTF-8
class TamberoApisController < ApplicationController

  hobo_model_controller

  auto_actions :all


  def update    
    @tambero_apis = TamberoApi.first

      unless @tambero_apis
          @tambero_api = TamberoApi.new    
         
          respond_to do |format|
            if @tambero_api.update_attributes(params[:tambero_api])
              @delete_notification = NotificationMessage.first(:conditions => ["source = ? and status = ?", "tamberoapi", true])

              if @delete_notification 
                  @delete_notification.status = false
                  @delete_notification.save
              end            
              format.html { redirect_to "/front", notice: 'Datos ingresados correctamente.' }
            else
              format.html { redirect_to "/tambero_apis/new", notice: "Ocurrio un error al grabar los datos" }
            end
          end
      else
          respond_to do |format|
            if @tambero_apis.update_attributes(params[:tambero_api])
              format.html { redirect_to "/front", notice: 'Datos actualizados correctamente.' }
            else
              format.html { redirect_to "/tambero_apis/#{@tambero_apis.id}/edit", notice: "Ocurrio un error al grabar los datos" }
            end
          end
      end
  end


  def index 
    @tambero_apis = TamberoApi.first 
  end

  def show
    @tambero_api = TamberoApi.first
  end


  def synchronization        
    Animal.add_from_tambero
    Animal.deactivate_from_tambero
    Animal.update_from_tambero      

    respond_to do |format|
       format.html { redirect_to "/animals", notice: 'Datos actualizados correctamente.' }
     end    
  end


 

end
