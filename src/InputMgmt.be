class InputMgmt

  static var inputMgmt

  var input1
  var input2

  var input1PressedTime
  var input2PressedTime

  def init()
    #Hight 0, Low 1
    self.input1 = gpio.digital_read(32)
    self.input2 = gpio.digital_read(33)

    self.input1PressedTime = nil
    self.input2PressedTime = nil

    # Configure button inputs in detached mode (not linked to power relays)
    tasmota.cmd("SwitchMode1 15")  # Input 1 (GPIO 32) - Coffee1
    tasmota.cmd("SwitchMode2 15")  # Input 2 (GPIO 33) - Coffee2

    if nil != InputMgmt.inputMgmt
      tasmota.remove_driver(InputMgmt.inputMgmt)
    end
    InputMgmt.inputMgmt = self
    tasmota.add_driver(self)

  end

  def every_50ms()

    if self.input1 != gpio.digital_read(32)
      self.input1 = gpio.digital_read(32)
      self.input1Changed()
    end

    if self.input2 != gpio.digital_read(33)
      self.input2 = gpio.digital_read(33)
      self.input2Changed()
    end

    self.checkSimultaneousPress()
    self.checkInput1LongPress()
    self.checkInput2LongPress()
  end

  def every_second()

  end

  def input1Changed()
    if self.input1
      tprint("[InputMgmt] input1 released")
      self.checkInput1Release()
    else
      tprint("[InputMgmt] input1 pressed")
      self.input1PressedTime = tasmota.millis()
    end
  end

  def input2Changed()
    if self.input2
      tprint("[InputMgmt] input2 released")
      self.checkInput2Release()
    else
      tprint("[InputMgmt] input2 pressed")
      self.input2PressedTime = tasmota.millis()
    end
  end

  def checkInput1Release()
    if self.input1PressedTime
      var pressTimer = tasmota.millis() - self.input1PressedTime
      if pressTimer < 2500
        tprint(format("[InputMgmt] input1 short press | duration=%ims → onCoffeeSelected", pressTimer))
        PowerMgmt.powerMgmt.onCoffeeSelected("1")
      end
      self.input1PressedTime = nil
    end
  end

  def checkInput2Release()
    if self.input2PressedTime
      var pressTimer = tasmota.millis() - self.input2PressedTime
      if pressTimer < 2500
        tprint(format("[InputMgmt] input2 short press | duration=%ims → onCoffeeSelected", pressTimer))
        PowerMgmt.powerMgmt.onCoffeeSelected("2")
      end
      self.input2PressedTime = nil
    end
  end

  def checkSimultaneousPress()
    if self.input1PressedTime != nil && self.input2PressedTime != nil
      var delta = self.input1PressedTime - self.input2PressedTime
      if delta < 0  delta = -delta  end
      if delta < 500
        tprint(format("[InputMgmt] simultaneous press | delta=%ims → P1 OFF", delta))
        self.input1PressedTime = nil
        self.input2PressedTime = nil
        tasmota.cmd("Power1 Off")
      end
    end
  end

  def checkInput1LongPress()
    if self.input1PressedTime
      var elapsed = tasmota.millis() - self.input1PressedTime
      if elapsed >= 2500
        self.input1PressedTime = nil
        if PowerMgmt.powerMgmt.powerStatus1
          tprint(format("[InputMgmt] input1 long press | duration=%ims → learningMode", elapsed))
          PowerMgmt.powerMgmt.activateLearningMode("1")
        else
          tprint(format("[InputMgmt] input1 long press | duration=%ims → autoStart", elapsed))
          PowerMgmt.powerMgmt.setAutoStart("1")
        end
      end
    end
  end

  def checkInput2LongPress()
    if self.input2PressedTime
      var elapsed = tasmota.millis() - self.input2PressedTime
      if elapsed >= 2500
        self.input2PressedTime = nil
        if PowerMgmt.powerMgmt.powerStatus1
          tprint(format("[InputMgmt] input2 long press | duration=%ims → learningMode", elapsed))
          PowerMgmt.powerMgmt.activateLearningMode("2")
        else
          tprint(format("[InputMgmt] input2 long press | duration=%ims → autoStart", elapsed))
          PowerMgmt.powerMgmt.setAutoStart("2")
        end
      end
    end
  end

end

InputMgmt()
