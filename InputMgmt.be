class InputMgmt

    static var inputMgmt
  
    var input1;
    var input2;
  
    def init()
      #Hight 0, Low 1
      self.input1 = gpio.digital_read(32)
      self.input2 = gpio.digital_read(33)
  
      if nil != InputMgmt.inputMgmt
        tasmota.remove_driver(InputMgmt.inputMgmt)
      end
      InputMgmt.inputMgmt = self
      tasmota.add_driver(self)
  
    end
  
    def every_50ms()
  
      if self.input1 != gpio.digital_read(32)
        self.input1 = gpio.digital_read(32)
        self.input1Changed(self.input1)
      end
  
      if self.input2 != gpio.digital_read(33)
        self.input2 = gpio.digital_read(33)
        self.input2Changed(self.input2)
      end
    end
  
    def every_second()
  
    end
  
    def input1Changed(newValue)
      if 1 == newValue
        print('Power input1 changed to: 1')
      end
      if 0 == newValue
        print('Power input1 changed to: 0')
      end
    end
  
    def input2Changed(newValue)
      if 1 == newValue
        print('Power input2 changed to: 1')
      end
      if 0 == newValue
        print('Power input2 changed to: 0')
      end
    end
  
  end
  
  InputMgmt()