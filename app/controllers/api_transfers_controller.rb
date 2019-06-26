# encoding: UTF-8
class ApiTransfersController < ApplicationController

  hobo_model_controller

  auto_actions :all

  def index
  	@t = ApiTransfer.last
  	@new_id = @t.id - 250
  	@transfer = ApiTransfer.order('date_at DESC').all

  	@transfer = ApiTransfer.where("id > ?", @new_id).order('date_at DESC')
  end

end
