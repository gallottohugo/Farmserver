var update_milkers = function(){
  rq = $.ajax({ dataType: 'json', url:'milking_machines/data' });
  rq.complete(function(resp){ //For whatever reason "done" did not work here so I used "complete" as
    //quick workaround
    m = JSON.parse(resp.responseText);
    for(i=0;i<m.length;i=i+1){
      t0 = new Date(m[i].updated_at);
      t1 = new Date();
      if(t1-t0>300e6){
        document.getElementsByClassName('milking-volu').item(i).innerHTML = '-';
        document.getElementsByClassName('milking-temp').item(i).innerHTML = '-'; //temperatura  
        document.getElementsByClassName('milking-cond').item(i).innerHTML = '-'; //conductividad  
        document.getElementsByClassName('cow-eartag').item(i).innerHTML = '-';
        document.getElementsByClassName('milker-status').item(i).innerHTML = 'Offline';
        document.getElementsByClassName('milker-status').item(i).style.color = '#FF0000';
      }else{
        document.getElementsByClassName('milking-volu').item(i).innerHTML = m[i].volume.toFixed(2);  
        document.getElementsByClassName('milking-temp').item(i).innerHTML = m[i].temperature.toFixed(2); //temperatura  
        document.getElementsByClassName('milking-cond').item(i).innerHTML = m[i].conductivity.toFixed(2); //conductividad  
        document.getElementsByClassName('cow-eartag').item(i).innerHTML = m[i].eartag;  
        document.getElementsByClassName('milker-status').item(i).innerHTML = m[i].state;  
        document.getElementsByClassName('milker-status').item(i).style.color = '#0000FF';
      }
    }
  });
  rq.error(function(){console.log('aca fallo!')});
}
