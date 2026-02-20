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

    self.checkInput2LongPressed()
  end

  def every_second()

  end

  def input1Changed()
    if self.input1
      print('Power input1 changed to: 1')
      self.input1PressedTime = nil
    else
      print('Power input1 changed to: 0')
      self.input1PressedTime = tasmota.millis()
    end
  end

  def input2Changed()
    if self.input2
      print('Power input2 changed to: 1')
      self.input2PressedTime = nil
    else
      print('Power input2 changed to: 0')
      self.input2PressedTime = tasmota.millis()
    end
  end

  def checkInput2LongPressed()
    if !self.input2 && self.input2PressedTime
      var PressedTimer = tasmota.millis() - self.input2PressedTime
      if PressedTimer > 2500
        print(format("Input 2 long pressed (%s ms)", PressedTimer))
        PowerMgmt.powerMgmt.setAutoStart()
        self.input2PressedTime = nil
      end
    end
  end

end

InputMgmt()
