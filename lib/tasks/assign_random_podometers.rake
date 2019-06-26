desc "Assign the first free podometer to the first free eartag  until running out of either"
task :assign_random_podometer => :environment do
  if Podometro.count == 0
    puts "No registered podometers: creating "+Vaca.count.to_s
    (5000..5000+Vaca.count).each do |n|
      puts "Creating podometer "+n.to_s
      p=Podometro.new(:numero=>n,:bateria=>Random.rand(10)+90)
      p.save
    end
  end
  Podometro.all.each do |p|
    if p.asignaciones_de_caravana.count == 0
      AsignacionDeCaravana.all.each do |ac|
        if ac.asignaciones_de_podometro.count == 0
          ap = AsignacionDePodometro.new()
          ap.fecha_de_alta=DateTime.now()-Random.rand(10).days-Random.rand(23).hour-Random.rand(59).minute
          ap.asignacion_de_caravana=ac
          ap.podometro=p
          ap.save
          break
        end
      end
    end
  end
end
