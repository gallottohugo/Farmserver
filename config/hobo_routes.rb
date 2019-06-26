# This is an auto-generated file: don't edit!
# You can add your own routes in the config/routes.rb file
# which will override the routes in this file.

Farmserver::Application.routes.draw do


  # Resource routes for controller weighing_sessions
  resources :weighing_sessions


  # Resource routes for controller notification_messages
  resources :notification_messages do
    collection do
      get 'index_unknown_eartag'
    end
  end


  # Resource routes for controller feeders
  resources :feeders


  # Resource routes for controller api_transfers
  resources :api_transfers


  # Resource routes for controller scales
  resources :scales


  # Resource routes for controller users
  resources :users, :only => [:edit, :show, :create, :update, :destroy] do
    collection do
      post 'signup', :action => 'do_signup'
      get 'signup'
    end
    member do
      get 'account'
      put 'reset_password', :action => 'do_reset_password'
      get 'reset_password'
    end
  end

  # User routes for controller users
  post 'login(.:format)' => 'users#login', :as => 'user_login_post'
  get 'login(.:format)' => 'users#login', :as => 'user_login'
  get 'logout(.:format)' => 'users#logout', :as => 'user_logout'
  get 'forgot_password(.:format)' => 'users#forgot_password', :as => 'user_forgot_password'
  post 'forgot_password(.:format)' => 'users#forgot_password', :as => 'user_forgot_password_post'


  # Resource routes for controller heat_tamberos
  resources :heat_tamberos


  # Resource routes for controller animals
  resources :animals do
    collection do
      get 'table'
      get 'index_inactive'
      get 'complete_'
    end
  end


  # Resource routes for controller tambero_apis
  resources :tambero_apis


  # Resource routes for controller pedometries
  resources :pedometries do
    collection do
      get 'index_details'
      get 'index_history'
      get 'export_details'
      get 'export_history'
    end
  end


  # Resource routes for controller animal_milkings
  resources :animal_milkings do
    collection do
      get 'table'
      get 'graphic'
      get 'animal_milking_session'
      get 'table_milking'
      get 'meter_details'
    end
  end


  # Resource routes for controller milking_sessions
  resources :milking_sessions do
    member do
      get 'excel_export'
    end
  end


  # Resource routes for controller alarm_assignations
  resources :alarm_assignations


  # Resource routes for controller animal_milking_details
  resources :animal_milking_details


  # Resource routes for controller weighings
  resources :weighings do
    collection do
      get 'index_details'
      get 'index_history'
      get 'export_details'
      get 'export_history'
    end
  end


  # Resource routes for controller milking_machine_reads
  resources :milking_machine_reads


  # Resource routes for controller milking_machines
  resources :milking_machines do
    collection do
      get 'index_new'
      get 'new_machines'
      get 'data'
    end
  end


  # Resource routes for controller heats
  resources :heats do
    collection do
      get 'confirm_heats'
    end
  end


  # Resource routes for controller alarms
  resources :alarms do
    collection do
      get 'alarm_activation'
    end
  end

  namespace :concerns do

  end

end
