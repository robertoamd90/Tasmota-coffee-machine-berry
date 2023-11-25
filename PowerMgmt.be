import persist

class PowerMgmt

  static var powerMgmt

  var powerStatus1
  var powerStatus2
  var coffeeStartTime

  def init()
    self.powerStatus1 = gpio.digital_read(27)
    self.powerStatus2 = gpio.digital_read(14)

    if nil != PowerMgmt.powerMgmt
      tasmota.remove_driver(PowerMgmt.powerMgmt)
    end
    PowerMgmt.powerMgmt = self
    tasmota.add_driver(self)

  end

  def every_50ms()
    if self.powerStatus1 != gpio.digital_read(27)
      self.powerStatus1 = gpio.digital_read(27)
      self.powerStatus1Changed(self.powerStatus1)
    end

    if self.powerStatus2 != gpio.digital_read(14)
      self.powerStatus2 = gpio.digital_read(14)
      self.powerStatus2Changed(self.powerStatus2)  
    end
  end

  def every_second()

  end

  def powerStatus1Changed(newValue)
    if 1 == newValue
      print('Power powerStatus1 changed to: 1')
      tasmota.cmd("SwitchMode2 3")
      self.power1SetTimer()
    end
    if 0 == newValue
      print('Power powerStatus1 changed to: 0')
      tasmota.cmd("Power2 Off")
      tasmota.cmd("SwitchMode2 15")
      tasmota.remove_timer("OffDelay")
      tasmota.remove_timer("ShortTime")
    end
  end

  def powerStatus2Changed(newValue)
    if 1 == newValue
      print('Power powerStatus2 changed to: 1')
      if 0 == self.powerStatus1
        tasmota.cmd("Power2 Off")
      end
      if 1 == self.powerStatus1
        self.coffeeStartTime = tasmota.millis()
        self.power1SetTimer()
        self.power2SetTimer()
      end
    end
    if 0 == newValue
      print('Power powerStatus2 changed to: 0')
      tasmota.remove_timer("ShortTime")
      var lastCoffeeTimer = real(tasmota.millis() - self.coffeeStartTime)/1000
      if lastCoffeeTimer > 5
        print(format("Got LastCoffeeTime /s"),lastCoffeeTimer )
        persist.LastCoffeeTime = lastCoffeeTimer
        persist.save()
      end
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

end

PowerMgmt()
