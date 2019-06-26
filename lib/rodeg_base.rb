require 'bindata'
require 'serialport'

def FrameEnable(serial_port)
  serial_port_write.write("ATFR=1\r")
  serial_port_read.read()
end

def FrameDisable(serial_port)
  serial_port_write.write("ATFR=0\r")
  serial_port_read.read()
end

class RodegControllerBase
  #These class variables should be available through methods.
  @serial_port_name = nil
  @serial_port_read = nil
  @serial_port_write = nil
  @firmware_version = nil

  def serial_port_name
    return @serial_port_name
  end

  def firmware_version
    return @firmware_version
  end

  #TODO: this is for debugging only!
  def serial_port
    return @serial_port_read
  end

  #There should be only one interface, so we assume that by instantiating
  #we mean to automatically find the interface and initialize the object.
  def initialize
    if not self.scan_port()
      puts "ERROR: interface not found!"
      #What should I do here?
    else
      puts "Interface initialized"
    end
    set_firmware_version
  end

  def reset
    @serial_port_read.close
    @serial_port_write.close
    initialize
  end

  #Check for the RODEG word in the response to the ATI command.
  #We are only considering woring at 57600
  
  def test_port(pn)
    
    serial_port_read = SerialPort.new pn,57600
    serial_port_write = SerialPort.new pn,57600

    serial_port_read.binmode
    serial_port_write.binmode
    
    serial_port_read.flow_control = SerialPort::NONE
    serial_port_write.flow_control = SerialPort::NONE
    
    serial_port_read.read_timeout=1000
    serial_port_write.read_timeout=1000

    serial_port_read.read
    serial_port_write.write("ATI\r")

    response = serial_port_read.read
    if response.scan('RODEG').length > 0
      @serial_port_read  = serial_port_read
      @serial_port_write = serial_port_write
      @serial_port_name  = pn
      return true
    end
    return false
  end

  #Scan for files in /dev which have names compatible with possible
  #serial ports.
  def scan_port()
    portnames = ['ACM[0-9]*','USB[0-9]*']
    ports = []
    portnames.each do |pn|
      ports = ports+Dir.glob('/dev/tty'+pn)  
    end

    ports.each do |p|
      puts "Scanning port "+p
      serial_port_read = test_port(p)
      if @serial_port_read != nil
        puts "Found interface at port "+p
        return true
      end
    end
    puts "No interface found"
    return false
  end

  #Just in case it is useful
  def close
    @serial_port_read.close
    @serial_port_write.close
  end

  def set_firmware_version
    @serial_port_write.write("ATI\r")
    response = @serial_port_read.read
    @firmware_version = response.scan(/Firm (\d*\.?\d*)/)[0][0]
    puts @firmware_version.to_s
  end
end

