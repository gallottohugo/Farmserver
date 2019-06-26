class Pedometry < ActiveRecord::Base

  hobo_model # Don't put anything above this

  after_create :calculate_steps

  fields do
    battery       :integer
    dated_at      :datetime
    steps_number  :integer
    real_steps    :integer #diferencia entre steps_number y 6500(max de pasos)
    lying_time    :integer
    walking_time  :integer
    standing_time :integer
    eartag        :integer
    timestamps
  end
  attr_accessible :battery, :dated_at, :steps_number, :real_steps, :lying_time, :walking_time, :standing_time, :eartag, :calculate_steps
  belongs_to :milking_session

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator?
  end

  def update_permitted?
    acting_user.administrator?
  end

  def destroy_permitted?
    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end

  def calculate_steps
    @eartag = 100
    @pedometries = Pedometry.find_by_sql(["select * from pedometries where eartag = ? order by id DESC limit 2", @eartag])

      unless @pedometries == [] then
          if @pedometries.count == 1 then
              @pedometry = @pedometries.first
              @pedometry.real_steps = @pedometry.steps_number
              @pedometry.save 
          end

          if @pedometries.count == 2 then
              @last_steps = @pedometries.first.steps_number
              @first_steps = @pedometries.last.steps_number

              if @last_steps <  @first_steps then
                  #calcular los pasos xq dio la vuelta
                  @maximum_steps = 65535

                  @real_steps_1 = @maximum_steps - @first_steps
                  @real_steps   = @real_steps_1 + @last_steps

                  @update_pedometry = @pedometries.first  
                  @update_pedometry.real_steps = @real_steps
                  @update_pedometry.save
              else
                  #hacer la diferencia para actualizar el valor de real_steps
                  @real_steps = @last_steps - @first_steps
                  @update_pedometry = @pedometries.first  
                  @update_pedometry.real_steps = @real_steps
                  @update_pedometry.save
              end
          end
      end
  end

  def step_per_hour
    @eartag = self.eartag
    @pedometries = Pedometry.find_by_sql(["select * from pedometries where eartag = ? order by dated_at DESC limit 2", @eartag])
    unless @pedometries == [] then
          if @pedometries.count == 1 then
              @first_date = @pedometries.first.dated_at
              @last_date = @pedometries.first.dated_at - 12.hour
          elsif @pedometries.count == 2
              @first_date = @pedometries.first.dated_at
              @last_date = @pedometries.last.dated_at
          end
          
              @hour_diff = (@first_date.to_i - @last_date.to_i) / 3600
              @step_hour =  @pedometries.first.real_steps / @hour_diff
          
      end
  end

  def step_per_hour_herd
    @animal = Animal.where("rp_number = ?", self.eartag).last
    @herd_id = @animal.herd_id
    @i = 0
    @steps = 0

    if @data_pedometry = Pedometry.where("milking_session_id = ?", self.milking_session) then
          @data_pedometry.each do |dp|
              @new_herd_id = Animal.where("rp_number = ?", dp.eartag).last.herd_id
              if @herd_id == @new_herd_id then
                  if dp.real_steps.to_i > 0 then
                      @i = @i + 1
                      @steps = @steps + dp.real_steps.to_i  
                  end
              end
          end
          
          if @i == 0 then 
              avg_step_per_hour = 0
          else 
              #Busco la diferencia entre las dos ultimas fechas para sacar las horas de duracion entre un registro y otro
              @pedometries = Pedometry.find_by_sql(["select dated_at from pedometries where eartag = ? order by dated_at DESC limit 2", self.eartag])
              if @pedometries.count == 1 then
                @first_date = @pedometries.first.dated_at
                @last_date = @pedometries.first.dated_at - 12.hour
                @hour_diff = (@first_date.to_i - @last_date.to_i) / 3600
              elsif @pedometries.count == 2
                  @first_date = @pedometries.first.dated_at
                  @last_date = @pedometries.last.dated_at
                  @hour_diff = (@first_date.to_i - @last_date.to_i) / 3600
              end
              avg_step = @steps / @i
              avg_step_per_hour = avg_step.to_i / @hour_diff.to_i
          end
    end
    return avg_step_per_hour
  end
end
