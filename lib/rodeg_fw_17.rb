class RawRSR_17 < BinData::Record
array   :data, :type=>:uint8, :initial_length=>8192
end

class RodegMilkerConfig_17 < BinData::Record
uint8   :flags
array   :data, :type => :uint8, :initial_length => 31
end

class RodegPodometer_17 < BinData::Record
endian  :big
uint16 :uid
uint16 :steps #[x10 steps]
uint16 :time_laying #[x10s]
uint16 :time_walking #[x10s]
uint8  :battery #[%]
end

class RodegMilkerData_17 < BinData::Record
endian  :big
uint16  :eartag
uint16  :volume #[cl]
uint16  :temperature #[c degC]
uint8   :conductivity #[0.1 uS]
string  :flag_ascii, :read_length=>1
uint8   :flag_hex
uint8   :milking
array   :data, :type => :uint8, :initial_length => 13
RodegPodometer_17 :podometer
end

class RodegRefrigeration_17 < BinData::Record
array   :conf, :type => :uint8, :initial_length => 32
array   :data, :type => :uint8, :initial_length => 32
end

class RodegWashing_17 < BinData::Record
array   :conf, :type => :uint8, :initial_length => 32
array   :data, :type => :uint8, :initial_length => 32
end

class RodegWeigthing_17 < BinData::Record
array   :conf, :type => :uint8, :initial_length => 32
array   :data, :type => :uint8, :initial_length => 32
end

class RodegFeeding_17 < BinData::Record
array   :conf, :type => :uint8, :initial_length => 32
array   :data, :type => :uint8, :initial_length => 32
end

class RodegRemoteAccess_17 < BinData::Record
array   :conf, :type => :uint8, :initial_length => 32
array   :data, :type => :uint8, :initial_length => 32
end

class RodegAntenna_17 < BinData::Record
array   :conf, :type => :uint8, :initial_length => 32
array   :data, :type => :uint8, :initial_length => 32
end

class RodegController_17 < BinData::Record
array   :conf, :type => :uint8, :initial_length => 32
array   :data, :type => :uint8, :initial_length => 32
end

class RodegSharedRAM_17 < BinData::Record
array :milkerconf, :type => :RodegMilkerConfig_17, :initial_length => 100
array :milkerdata, :type => :RodegMilkerData_17, :initial_length => 100
RodegRefrigeration_17 :fridge
RodegWashing_17 :washer
RodegWeigthing_17 :weigthing_scale
RodegFeeding_17 :feeder
RodegRemoteAccess_17 :remote_access
RodegAntenna_17 :antenna
RodegController_17 :controller
array :podometers, :type => :RodegPodometer_17, :initial_length => 100
array :unused, :type => :uint8, :initial_length => 243
uint8 :next_podometer_pointer #So that this-1 is where the last podometer reading was stored
string :ok , read_length: 6
end


