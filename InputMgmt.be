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
  end

  def every_second()

  end

  def input1Changed()
    if self.input1
      print('Power input1 changed to: 1')
      self.checkInput1Release()
    else
      print('Power input1 changed to: 0')
      self.input1PressedTime = tasmota.millis()
    end
  end

  def input2Changed()
    if self.input2
      print('Power input2 changed to: 1')
      self.checkInput2Release()
    else
      print('Power input2 changed to: 0')
      self.input2PressedTime = tasmota.millis()
    end
  end

  def checkInput1Release()
    if self.input1PressedTime
      var pressTimer = tasmota.millis() - self.input1PressedTime
      if pressTimer < 2500
        print(format("Input 1 pressed for %i ms", pressTimer))
        # TODO: PowerMgmt.powerMgmt.startCoffee1()
      else
        print(format("Input 1 long pressed (%i ms)", pressTimer))
        # TODO: PowerMgmt.powerMgmt.setAutoStart()
      end
    end
    self.input1PressedTime = nil
  end

  def checkInput2Release()
    if self.input2PressedTime
      var pressTimer = tasmota.millis() - self.input2PressedTime
      if pressTimer < 2500
        print(format("Input 2 pressed for %i ms", pressTimer))
        # TODO: PowerMgmt.powerMgmt.startCoffee2()
      else
        print(format("Input 2 long pressed (%i ms)", pressTimer))
        PowerMgmt.powerMgmt.setAutoStart()
      end
    end
    self.input2PressedTime = nil
  end

end

InputMgmt()
