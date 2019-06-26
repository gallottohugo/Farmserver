class NotificationMessagesController < ApplicationController

  hobo_model_controller

  auto_actions :all
  index_action :index_unknown_eartag

  
  def index_unknown_eartag
    @table_eartags = NotificationMessage.find_by_sql(["select * from notification_messages where source = ? and status = ?", "unknowneartag", true])    
  end


end
