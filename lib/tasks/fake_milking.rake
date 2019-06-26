desc "Create a random fake milking for a random assigned eartag assignemt"
task :fake_milking => :environment do
  asignaciones_de_caravana_activas=AsignacionDeCaravana.where(:fecha_de_baja=>nil)
  count=0
  asignaciones_de_caravana_activas.each do |aca|
    t=DateTime.now.prev_week.to_i
    count=count+1
    ordenadoras=Ordenadora.all #So the ID does not need to be consecutive
    while Time.now.to_i > t do
      t=t+60*(60*9+Random.rand(60*6)) #Random.rand is in hours;
      start_time=DateTime.strptime(t.to_s,'%s')
      finish_time=Time.strptime((start_time.to_i+300).to_s,'%s')
      so=SesionOrdene.new(:fecha_de_alta=>start_time,:fecha_de_baja=>finish_time)
      #, :ordenadora_id=>ordenadoras[count].id)
      volume=15+Random.rand(10)
      temperature=35.8+Random.rand(0.2)
      conductivity=15.8+Random.rand(0.2)
      puts [count, volume, temperature, conductivity, start_time, finish_time].join(",")
      m=Ordene.new(:volumen=>volume, :temperatura=>temperature, :conductividad=>conductivity, :tiempo=>start_time)
      m.save
      so.ordene = m
      so.save
      aca.sesiones_ordene<<so
      aca.save
      o=ordenadoras[count%Ordenadora.count]
      o.sesiones_ordene<<so
      o.save
    end
  end
end
