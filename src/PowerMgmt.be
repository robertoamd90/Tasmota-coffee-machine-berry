import persist

class PowerMgmt

  static var powerMgmt

  var powerStatus1
  var powerStatus2
  var coffeeStartTime
  var delayEnergyCheckTime

  var lastCoffeeTimeMqtt
  var statusMqtt
  var modeMqtt
  var autoStartMqtt

  var autoStartEnabled
  var learningMode
  var preloadPumpActive

  def init()
    self.powerStatus1 = gpio.digital_read(27)
    self.powerStatus2 = gpio.digital_read(14)
    self.delayEnergyCheckTime = 2
    self.autoStartEnabled = false
    self.learningMode = false
    self.preloadPumpActive = false

    self.lastCoffeeTimeMqtt = HaMqttSensor('Last Coffee Time', 'LastCoffeeTime', 'mdi:coffee', nil, 2, 'sec')
    self.statusMqtt = HaMqttSensor('Status', 'Status', nil, nil, nil, nil)
    self.modeMqtt = HaMqttSensor('Mode', 'Mode', 'mdi:coffee-maker', nil, nil, nil)
    self.autoStartMqtt = HaMqttButton('-Auto Start Coffee', 'AutoStartCoffee', 'mdi:coffee-to-go', nil, /-> self.setAutoStart(persist.SelectedCoffee))

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
      tprint("[PowerMgmt] P1 ON")
      self.power1SetTimer()
      tasmota.set_timer(int(self.delayEnergyCheckTime * 1000), /-> self.checkPreloadPump(), "CheckPreloadPump")
    else
      tprint("[PowerMgmt] P1 OFF")
      self.learningMode = false
      tasmota.cmd("Power2 Off")
      tasmota.remove_timer("OffDelay")
      tasmota.remove_timer("CoffeeTime")
      self.preloadPumpResetTimer()
      self.autoStartResetTimer()
      self.updateMode()
    end
    self.updateStatus()
  end

  def powerStatus2Changed()
    if self.powerStatus2
      if self.powerStatus1
        tprint(format("[PowerMgmt] P2 ON | coffee=%s learning=%s", persist.SelectedCoffee, self.learningMode ? "on" : "off"))
        self.coffeeStartTime = tasmota.millis()
        self.power1SetTimer()
        self.power2SetTimer()
        if !self.preloadPumpActive
          self.preloadPumpResetTimer()
        end
        self.autoStartResetTimer()
      else
        tprint("[PowerMgmt] P2 ON but P1 OFF → forcing P2 OFF")
        tasmota.cmd("Power2 Off")
      end
    else
      tprint("[PowerMgmt] P2 OFF")
      tasmota.remove_timer("CoffeeTime")
      self.preloadPumpResetTimer()
      self.autoStartResetTimer()
      self.checkLastCoffeeTimer()
    end
    self.updateStatus()
  end

  def power1SetTimer()
    if persist.has("OffDelay")
      tasmota.remove_timer("OffDelay")
      tasmota.set_timer(int(persist.OffDelay * 1000 * 60), /-> tasmota.cmd("Power1 Off"), "OffDelay")
    end
  end

  def power2SetTimer()
    if self.learningMode return end
    var timeKey = "Coffee" + persist.SelectedCoffee + "Time"
    if persist.has(timeKey)
      tasmota.remove_timer("CoffeeTime")
      tasmota.set_timer(int(persist.member(timeKey) * 1000), /-> tasmota.cmd("Power2 Off"), "CoffeeTime")
    end
  end

  def activateLearningMode(coffeeNum)
    tprint(format("[PowerMgmt] activateLearningMode | coffee=%s", coffeeNum))
    persist.SelectedCoffee = coffeeNum
    if WebUiMgmt.webUiMgmt != nil
      WebUiMgmt.webUiMgmt.CoffeeSelectionMqtt.setValue()
    end
    self.learningMode = true
    self.updateMode()
    tasmota.cmd("Power2 On")
  end

  def checkPreloadPump()
    var enabled = persist.has('PreloadPumpEnabled') && persist.PreloadPumpEnabled
    var doPreload = enabled && energy.active_power > 0 && !self.autoStartEnabled
    tprint(format("[PowerMgmt] checkPreloadPump | enabled=%s time=%.1fs power=%iW autoStart=%s → %s",
      enabled ? "yes" : "no",
      persist.PreloadPumpTime,
      energy.active_power, self.autoStartEnabled ? "on" : "off",
      doPreload ? "start" : "skip"))
    if doPreload
      self.preloadPump()
    end
  end

  def preloadPump()
    tprint(format("[PowerMgmt] preloadPump | time=%.1fs power=%iW → %s",
      persist.PreloadPumpTime, energy.active_power, energy.active_power == 0 ? "P2 ON" : "retry in 1s"))
    if energy.active_power == 0
      self.preloadPumpActive = true
      self.updateMode()
      tasmota.cmd("Power2 On")
      tasmota.set_timer(int(persist.PreloadPumpTime * 1000), /-> self.preloadPumpEnd(), "PreloadPumpSwitchOff")
    else
      tasmota.set_timer(int(1000), /-> self.preloadPump(), "PreloadPump")
    end
  end

  def preloadPumpEnd()
    self.preloadPumpActive = false
    tasmota.cmd("Power2 Off")
    self.updateMode()
  end

  def preloadPumpResetTimer()
    self.preloadPumpActive = false
    tasmota.remove_timer("CheckPreloadPump")
    tasmota.remove_timer("PreloadPump")
    tasmota.remove_timer("PreloadPumpSwitchOff")
  end

  def onCoffeeSelected(coffeeNum)
    tprint(format("[PowerMgmt] onCoffeeSelected | coffee=%s p1=%s", coffeeNum, self.powerStatus1 ? "on" : "off"))
    persist.SelectedCoffee = coffeeNum
    if WebUiMgmt.webUiMgmt != nil
      WebUiMgmt.webUiMgmt.CoffeeSelectionMqtt.setValue()
    end

    if !self.powerStatus1
      tasmota.cmd("Power1 On")
    elif self.powerStatus1
      tasmota.cmd("Power2 Toggle")
    end
  end

  def setAutoStart(coffeeNum)
    tprint(format("[PowerMgmt] setAutoStart | coffee=%s p1=%s p2=%s", coffeeNum, self.powerStatus1 ? "on" : "off", self.powerStatus2 ? "on" : "off"))
    persist.SelectedCoffee = coffeeNum
    if WebUiMgmt.webUiMgmt != nil
      WebUiMgmt.webUiMgmt.CoffeeSelectionMqtt.setValue()
    end

    if !self.powerStatus1
    && !self.powerStatus2
      self.autoStartEnabled = true
      self.updateMode()
      tasmota.cmd("Power1 On")
      tasmota.set_timer(int(self.delayEnergyCheckTime * 1000), /-> self.checkAutoStart(), "CheckAutoStart")
    end
  end

  def checkAutoStart()
    tprint(format("[PowerMgmt] checkAutoStart | power=%iW → %s", energy.active_power, energy.active_power > 0 ? "start" : "skip"))
    if energy.active_power > 0
      self.preloadPumpResetTimer()
      self.autoStart()
    end
  end

  def autoStart()
    tprint(format("[PowerMgmt] autoStart | power=%iW → %s", energy.active_power, energy.active_power == 0 ? "P2 ON" : "retry in 1s"))
    if energy.active_power == 0
      tasmota.cmd("Power2 On")
    else
      tasmota.set_timer(int(1000), /-> self.autoStart(), "AutoStart")
    end
  end

  def autoStartResetTimer()
    self.autoStartEnabled = false
    tasmota.remove_timer("CheckAutoStart")
    tasmota.remove_timer("AutoStart")
    self.updateMode()
  end

  def checkLastCoffeeTimer()
    if self.coffeeStartTime
      var lastCoffeeTimer = real(format("%.2f", real(tasmota.millis() - self.coffeeStartTime)/1000))
      if lastCoffeeTimer > 5
        tprint(format("[PowerMgmt] lastCoffeeTime=%.2fs → saved (coffee=%s learning=%s)", lastCoffeeTimer, persist.SelectedCoffee, self.learningMode ? "on" : "off"))
        persist.LastCoffeeTime = lastCoffeeTimer
        self.lastCoffeeTimeMqtt.setValue()
        if self.learningMode
          WebUiMgmt.webUiMgmt.setLastCoffeeTime()
        end
      else
        tprint(format("[PowerMgmt] lastCoffeeTime=%.2fs → too short, discarded", lastCoffeeTimer))
      end
      self.learningMode = false
      self.coffeeStartTime = nil
      self.updateMode()
    end
  end

  def checkTelePeriodSend()
    if self.powerStatus1
      tasmota.cmd("TelePeriod")
    end
  end

  def updateStatus()
    var status
    if self.powerStatus1
      if self.powerStatus2
        status = 'Brewing'
      else
        if energy.active_power == 0
          status = 'Ready'
        else
          status = 'Heating'
        end
      end
    else
      status = 'Standby'
    end
    if persist.Status != status
      tprint(format("[PowerMgmt] status=%s", status))
      persist.Status = status
      self.statusMqtt.setValue()
    end
  end

  def updateMode()
    var mode
    if self.learningMode
      mode = 'Learning'
    elif self.autoStartEnabled
      mode = 'Auto-start'
    elif self.preloadPumpActive
      mode = 'Preload'
    else
      mode = 'Manual'
    end
    if persist.Mode != mode
      tprint(format("[PowerMgmt] mode=%s", mode))
      persist.Mode = mode
      self.modeMqtt.setValue()
    end
  end

end

PowerMgmt()
