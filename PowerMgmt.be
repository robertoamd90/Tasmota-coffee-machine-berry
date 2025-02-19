import persist

class PowerMgmt

  static var powerMgmt

  var powerStatus1
  var powerStatus2
  var coffeeStartTime
  var preloadPumpTime
  var autoStartEnabled

  var lastCoffeeTimeMqtt
  var statusMqtt
  var autoStartMqtt

  def init()
    self.powerStatus1 = gpio.digital_read(27)
    self.powerStatus2 = gpio.digital_read(14)
    self.preloadPumpTime = 2
    self.autoStartEnabled = false

    self.lastCoffeeTimeMqtt = HaMqttSensor('Last Coffee Time', 'LastCoffeeTime', 'mdi:coffee', nil, 2, 'sec')
    self.statusMqtt = HaMqttSensor('Status', 'Status', nil, nil, nil, nil)
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
    self.checkTelePeriodSend()
    self.updateStatus()
  end

  def powerStatus1Changed()
    if self.powerStatus1
      print('Power powerStatus1 changed to: 1')
      tasmota.cmd("SwitchMode2 3")
      self.power1SetTimer()
      tasmota.set_timer( int(1500), /-> self.checkPreloadPump(), "CheckPreloadPump")
    else
      print('Power powerStatus1 changed to: 0')
      tasmota.cmd("Power2 Off")
      tasmota.cmd("SwitchMode2 15")
      tasmota.remove_timer("OffDelay")
      tasmota.remove_timer("ShortTime")
      self.preloadPumpResetTimer()
      self.autoStartResetTimer()
      persist.Status= 'Standby'
      statusMqtt.setValue()
    end
    self.updateStatus()
  end

  def powerStatus2Changed()
    if self.powerStatus2
      print('Power powerStatus2 changed to: 1')
      if self.powerStatus1
        self.coffeeStartTime = tasmota.millis()
        self.power1SetTimer()
        self.power2SetTimer()
        self.preloadPumpResetTimer()
        self.autoStartResetTimer()
      else
        tasmota.cmd("Power2 Off")
      end
    else
      print('Power powerStatus2 changed to: 0')
      tasmota.remove_timer("ShortTime")
      self.preloadPumpResetTimer()
      self.autoStartResetTimer()
      self.checkLastCoffeeTimer()
    end
    self.updateStatus()
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

  def checkPreloadPump()
    print("### checkPreloadPump Start")
    print(format("### checkPreloadPump self.preloadPumpTime: /s"),self.preloadPumpTime )
    print(format("### checkPreloadPump energy.active_power: /s"),energy.active_power)
    print(format("### checkPreloadPump !self.autoStartEnabled: /s"),!self.autoStartEnabled )
    if self.preloadPumpTime
    && energy.active_power > 0
    && !self.autoStartEnabled
      self.preloadPump()
    end
  end

  def preloadPump()
    print("### preloadPump Start")
    print(format("### checkPreloadPump energy.active_power: /s"),energy.active_power)
    if energy.active_power == 0
      tasmota.cmd("Power2 On")
      tasmota.set_timer( int(self.preloadPumpTime * 1000), /-> tasmota.cmd("Power2 Off"), "PreloadPumpSwitchOff")
    else
      tasmota.set_timer( int(1000), /-> self.preloadPump(), "PreloadPump")
    end

  end
  
  def preloadPumpResetTimer()
    print("### preloadPumpResetTimer Start")
    tasmota.remove_timer("CheckPreloadPump")
    tasmota.remove_timer("PreloadPump")
  end

  def setAutoStart()
    print("### setAutoStart Start")
    if !self.powerStatus1
    && !self.powerStatus2
      self.autoStartEnabled = true
      tasmota.cmd("Power1 On")
      tasmota.set_timer( int(1000), /-> self.checkAutoStart(), "CheckAutoStart")
    end
  end

  def checkAutoStart()
    print("### checkAutoStart Start")
    print(format("### checkAutoStart energy.active_power: /s"),energy.active_power)
    if energy.active_power > 0
      self.preloadPumpResetTimer()
      self.autoStart()
    end
  end

  def autoStart()
    if energy.active_power == 0
      tasmota.cmd("Power2 On")
    else
      tasmota.set_timer( int(1000), /-> self.autoStart(), "AutoStart")
    end
  end

  def autoStartResetTimer()
    self.autoStartEnabled = false
    tasmota.remove_timer("CheckAutoStart")
    tasmota.remove_timer("AutoStart")
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

  def updateStatus()
    var oldStatus
    if self.powerStatus1
      if self.powerStatus2
        persist.Status= 'Brewing'
      else
        if energy.active_power == 0
          persist.Status= 'Ready'
        else
          persist.Status= 'Heating'
        end
      end
    else
      persist.Status= 'Standby'
    end
    if persist.Status != oldStatus
      statusMqtt.setValue()
    end
  end

end

PowerMgmt()
