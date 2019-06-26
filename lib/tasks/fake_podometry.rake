desc "Create a random fake podometry for a random assigned podometer"
task :fake_podometry => :environment do
  active_podometers=AsignacionDePodometro.where(:fecha_de_baja=>nil)
  active_podometers.each do |p|
    t=DateTime.now.prev_week.to_i
    while Time.now.to_i > t do
      steps=250+Random.rand(100)
      r=rand(60)
      if r<20
        r=0
      end
      time_lying=r
      time_standing=240-r+Random.rand(10)
      t=t+60*(60*9+Random.rand(60*6)-r) #Random.rand is in hours; r is in minutes
      date_time=DateTime.strptime(t.to_s,'%s')
      puts p.podometro.numero.to_s+','+steps.to_s+','+time_lying.to_s+','+date_time.to_s
      podometria=Podometria.new(:steps=>steps, :tiempo_echada=>time_lying, :tiempo_parada=>time_standing, :tiempo=>date_time)
      podometria.save
      p.podometrias<<podometria
      p.save
    end
  end
end
