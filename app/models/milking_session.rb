# encoding: UTF-8
class MilkingSession < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    date_at :datetime
    status  :integer
    timestamps
  end
  attr_accessible :date_at, :status
  has_many :animal_milkings
  has_many :pedometries
  has_many :heats

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
  
  public
  def average_duration_animal
      
    @minute_animal = AnimalMilking.find_by_sql(["select date_start_at, date_end_at from animal_milkings where milking_session_id = ?", self.id])
    if @minute_animal == [] or @minute_animal == nil
       @minute_animal = 0
    else
    
    @r = Array.new
    if @minute_animal
      @minute_animal.each do |ma|
        duration = ma.date_end_at - ma.date_start_at
        @r.push duration
      end
    end

      cant = @r.count
      @r_new = 0
      @r.each do |r|
        @r_new = @r_new+r.to_i
      end

       @final = @r_new / cant

      return @final
    end

  end




end
