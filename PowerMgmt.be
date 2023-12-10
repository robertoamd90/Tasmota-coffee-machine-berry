import persist

class PowerMgmt

  static var powerMgmt

  var powerStatus1
  var powerStatus2
  var coffeeStartTime
  var autoStart

  var lastCoffeeTimeMqtt
  var autoStartMqtt

  def init()
    self.powerStatus1 = gpio.digital_read(27)
    self.powerStatus2 = gpio.digital_read(14)
    self.autoStart = false

    self.lastCoffeeTimeMqtt = HaMqttSensor('Last Coffee Time', 'LastCoffeeTime', 'mdi:coffee', nil, 2, 'sec')
    self.autoStartMqtt = HaMqttButton('-Auto Start Coffee', 'AutoStartCoffee', 'mdi:coffee-to-go' , nil, /-> self.setAutoStart() )

    if nil != PowerMgmt.powerMgmt
      tasmota.remove_driver(PowerMgmt.powerMgmt)
    end
    PowerMgmt.powerMgmt = self
    tasmota.add_driver(self)

  end

  def every_50ms()
    if self.powerStatus1 != gpio.digital_read(27)
      self.powerStatus1 = gpio.digital_read(27)
      self.powerStatus1Changed()
    end

    if self.powerStatus2 != gpio.digital_read(14)
      self.powerStatus2 = gpio.digital_read(14)
      self.powerStatus2Changed()
    end
  end

  def every_second()
    self.checkAutoStartReady()
    self.checkTelePeriodSend()
  end

  def powerStatus1Changed()
    if self.powerStatus1
      print('Power powerStatus1 changed to: 1')
      tasmota.cmd("SwitchMode2 3")
      self.power1SetTimer()
    else
      print('Power powerStatus1 changed to: 0')
      tasmota.cmd("Power2 Off")
      tasmota.cmd("SwitchMode2 15")
      tasmota.remove_timer("OffDelay")
      tasmota.remove_timer("ShortTime")
      self.autoStart = false
    end
  end

  def powerStatus2Changed()
    if self.powerStatus2
      print('Power powerStatus2 changed to: 1')
      if self.powerStatus1
        self.coffeeStartTime = tasmota.millis()
        self.power1SetTimer()
        self.power2SetTimer()
      else
        tasmota.cmd("Power2 Off")
      end
    else
      print('Power powerStatus2 changed to: 0')
      tasmota.remove_timer("ShortTime")
      self.checkLastCoffeeTimer()
    end
  end

  def power1SetTimer()
    if persist.has("OffDelay")
      tasmota.remove_timer("OffDelay")
      tasmota.set_timer( int(persist.OffDelay * 1000 * 60), /-> tasmota.cmd("Power1 Off"), "OffDelay")
    end
  end

  def power2SetTimer()
    if persist.has("ShortTime")
      tasmota.remove_timer("ShortTime")
      tasmota.set_timer( int(persist.ShortTime * 1000), /-> tasmota.cmd("Power2 Off"), "ShortTime")
    end
  end

  def setAutoStart()
    if !self.powerStatus1
    && !self.powerStatus2
      tasmota.cmd("Power1 On")
      self.autoStart = 2
    end
  end

  def checkAutoStartReady()
    if self.autoStart
    && self.autoStart > 1
      self.autoStart-=1
    elif self.autoStart 
    && self.powerStatus1 
    && !self.powerStatus2 
    && energy.active_power == 0
      tasmota.cmd("Power2 On")
      self.autoStart = false
    end
  end

  def checkLastCoffeeTimer()
    if self.coffeeStartTime
      var lastCoffeeTimer = real(format("%.2f", real(tasmota.millis() - self.coffeeStartTime)/1000))
      if lastCoffeeTimer > 5
        print(format("Got LastCoffeeTime /s"),lastCoffeeTimer )
        persist.LastCoffeeTime = lastCoffeeTimer
        self.lastCoffeeTimeMqtt.setValue()
      end
      self.coffeeStartTime = nil
    end
  end

  def checkTelePeriodSend()
    if self.powerStatus1
      tasmota.cmd("TelePeriod")
    end
  end

end

PowerMgmt()