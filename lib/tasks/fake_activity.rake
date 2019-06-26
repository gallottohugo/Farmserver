def random_kg(aca)
  if aca.ordenes.last == nil
    return seed_random_kg
  end
  o = aca.ordenes.last.volumen-0.5+Random.rand(1.0)
  v = aca.ordenes.first.volumen
  if o < v*0.85 or o > v*1.15
    return aca.ordenes.last.volumen
  end
  return o
end

def seed_random_kg
  bin=Random.rand(1.0)
  case bin 
  when 0..0.30
    kg = 6.0 + Random.rand(4.0)
  when 0.30..0.60
    kg = 10.0 + Random.rand(10.0)
  when 0.60..1.00
    kg = 20.0 + Random.rand(6.0)
  end
  return kg
end

def random_temperature
  return 37.0+Random.rand(1.0)
end

def random_conductivity
  bin=Random.rand(1.0)
  case bin 
  when 0..0.60
    cond = 8.0 + Random.rand(2.0)
  when 0.60..0.99
    cond = 10.0 + Random.rand(2.0)
  when 0.99..1.00
    cond = 12.0 + Random.rand(2.0)
  end
  return cond
end

def fake_data(date_time,podometer)
  #Podometry first
  steps=80+Random.rand(15)
  time_lying=12*60*6*0.28*Random.rand(0.4) #About 30% of 12 hours
  time_standing=12*60*6*0.48*Random.rand(0.4) #About 50% of 12 hours
  #      t=t+60*(60*9+Random.rand(60*6)-r) #Random.rand is in hours; r is in minutes
  puts podometer.podometro.numero.to_s+','+steps.to_s+','+time_lying.to_s+','+date_time.to_s
  podometria=Podometria.new(:steps=>steps, :tiempo_echada=>time_lying, :tiempo_parada=>time_standing, :tiempo=>date_time, :bateria=>podometer.podometro.bateria)
 # podometria.save
  podometer.podometrias<<podometria
  podometer.save

  #Now on with the milking
  ordenadoras=Ordenadora.all #So the ID does not need to be consecutive
  date_time = date_time + (1+Random.rand(2)).minute
  start_time = date_time
  finish_time = date_time+Random.rand(10).minute
  so=SesionOrdene.new(:fecha_de_alta=>start_time,:fecha_de_baja=>finish_time)
  aca=podometer.podometro.asignaciones_de_caravana.last
  volume=random_kg(aca)
  temperature=random_temperature
  conductivity=random_conductivity
  puts [volume, temperature, conductivity, start_time, finish_time].join(",")
  m=Ordene.new(:volumen=>volume, :temperatura=>temperature, :conductividad=>conductivity, :tiempo=>start_time)
#  m.save
  so.ordene = m
#  so.save
  aca.sesiones_ordene<<so
  aca.save
  o=ordenadoras[1+Random.rand(Ordenadora.count-1)]
  o.sesiones_ordene<<so
  o.save
end

desc "Create a random fake podometry for a random assigned podometer"
task :fake_activity => :environment do
  active_podometers = AsignacionDePodometro.where(:fecha_de_baja=>nil)

  #Delete all and seed a first timestamp
  #puts "Delete old milking data"
  #SesionOrdene.all.each do |s|
  #  s.destroy
  #end

  if SesionOrdene.last == nil
    puts "Empty database: starting from 3 days ago"
    date  = Date.today-3.day
  else
    date = SesionOrdene.last.fecha_de_baja+12.hour
  end
  start_date = date
  #puts "Delete old podometry data and start simulation"
  active_podometers.each do |p|
    #p.podometrias.all.each do |pd|
    #  pd.destroy
    #end
    hour = Random.rand(2)+2
    date_string = [date.year.to_s,'-',date.month.to_s,'-',date.day.to_s,' ',hour.to_s,':',Random.rand(59),' +0000']
    date_time = DateTime.strptime(date_string.join,'%Y-%m-%d %H:%M %z')
    fake_data(date_time,p)
  end

  active_podometers.each do |p|
    date_time = start_date
    while Time.now > date_time do
      date = p.podometrias.last.tiempo
      if date.hour < 5
        hour = Random.rand(2)+14
      else
        hour = Random.rand(2)+2
        date = date + 1.day
      end
      year  = date.year
      month = date.month
      day   = date.day
      date_string = [year.to_s,'-',month.to_s,'-',day.to_s,' ',hour.to_s,':',Random.rand(59),' -0300']
      date_time = DateTime.strptime(date_string.join,'%Y-%m-%d %H:%M %z')
      fake_data(date_time,p)
    end
  end
end
