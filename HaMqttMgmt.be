import mqtt
import string
import persist
import json

class HaMqttMgmt

  static var mac
  static var macShort

  var configTopic
  var availabilityTopic
  var stateTopic
  var commandTopic

  var mqttType
  var name
  var unique_id
  var icon
  var entityCategory
  var ready

  def init(name, unique_id, icon, entityCategory)

    if !name || !unique_id
      raise 'HaMqttMgmt.init error','invalid name and/or unique_id'
    end

    HaMqttMgmt.mac = string.split(tasmota.wifi()['mac'], ":").concat()
    HaMqttMgmt.macShort = string.split(HaMqttMgmt.mac, 6)[1]

    self.name = name
    self.unique_id = unique_id
    self.icon = icon
    self.entityCategory = entityCategory
    self.ready = false

  end

  def generateTopics()

    if !self.mqttType
      raise 'generateTopics error','invalid mqttType'
    end

    self.configTopic = format("homeassistant/%s/%s/%s/config", self.mqttType, HaMqttMgmt.mac, self.unique_id)
    self.availabilityTopic = format("tele/tasmota_%s/LWT", HaMqttMgmt.macShort)
    self.stateTopic = format("homeassistant/%s/%s/%s/state", self.mqttType, HaMqttMgmt.mac, self.unique_id)
    self.commandTopic = format("homeassistant/%s/%s/%s/set", self.mqttType, HaMqttMgmt.mac, self.unique_id)
    self.ready = true

  end

  def generateConfigBody()

    var configBody = {
      "name" : self.name,
      "unique_id" : format("%s_%s", HaMqttMgmt.mac, self.unique_id),
      "availability_topic" : self.availabilityTopic,
      "payload_available": "Online",
      "payload_not_available": "Offline",
      "command_topic" : self.commandTopic,
      #"command_template" : format("{\"%s\": {{ value }} }", self.unique_id),
      "device" : {"connections": [["mac", HaMqttMgmt.mac]]}
    }

    if self.entityCategory
      configBody['entity_category'] = self.entityCategory
    end
    if self.icon
      configBody['icon'] = self.icon
    end

    return configBody

  end

  def createEntity()
    if mqtt.connected()
      self.generateTopics()
      tasmota.remove_timer(format(self.unique_id,'_createEntityRetry'))
      var configBody = self.generateConfigBody()
      mqtt.publish(self.configTopic, json.dump(configBody), true)
    else
      tasmota.set_timer( 1000, /-> self.createEntity(), format(self.unique_id,'_createEntityRetry'))
    end
  end

end

class HaMqttWithState: HaMqttMgmt

  def generateConfigBody()
    var configBody = super(self).generateConfigBody()
    configBody['state_topic'] = self.stateTopic
    return configBody
  end

  def createEntity()
    super(self).createEntity()

    if self.commandTopic
      tasmota.set_timer( 1000, /-> self.setValue())
    end

  end

  def setValue()
    if self.ready && persist.has(self.unique_id)
      mqtt.publish(self.stateTopic, format('%s', persist.member(self.unique_id)), true)
    end
  end

end

class HaMqttSensor: HaMqttWithState

  var suggestedDisplayPrecision
  var unitOfMeasurement

  def init(name, unique_id, icon, entityCategory, suggestedDisplayPrecision, unitOfMeasurement)
    super(self).init(name, unique_id, icon, entityCategory)
    self.mqttType = "sensor"
    self.suggestedDisplayPrecision = suggestedDisplayPrecision
    self.unitOfMeasurement = unitOfMeasurement
    self.createEntity()
  end

  def generateConfigBody()
    var configBody = super(self).generateConfigBody()
    if self.suggestedDisplayPrecision
      configBody['suggested_display_precision'] = self.suggestedDisplayPrecision
    end
    if self.unitOfMeasurement
      configBody['unit_of_measurement'] = self.unitOfMeasurement
    end
    return configBody
  end

end

class HaMqttInputGen: HaMqttWithState

  def createEntity()
    super(self).createEntity()

    if self.commandTopic
      mqtt.subscribe(self.commandTopic,
        def (topic, idx, payload_s, payload_b)
          return self.getValue(topic, idx, payload_s, payload_b)
        end
      )
    end

  end

  def getValue(topic, idx, payload_s, payload_b)
    var payload_typed = self.castValue(payload_s)
    if payload_typed
      persist.setmember(self.unique_id, payload_typed)
      persist.save()
      self.setValue()
    end
    return true
  end

  def castValue(payload_s)
    return  payload_s
  end
  
end

class HaMqttInput: HaMqttInputGen
  
  var min
  var max
  var mode

  def init(name, unique_id, icon, entityCategory, min, max, mode)
    super(self).init(name, unique_id, icon, entityCategory)
    self.min = min
    self.max = max
    self.mode = mode
  end

  def generateConfigBody()
    var configBody = super(self).generateConfigBody()
    if self.min
      configBody['min'] = self.min
    end
    if self.max
      configBody['max'] = self.max
    end
    if self.mode
      configBody['mode'] = self.mode
    end
    return configBody
  end

end

class HaMqttText: HaMqttInput

  def init(name, unique_id, icon, entityCategory, min, max, mode)
    super(self).init(name, unique_id, icon, entityCategory, min, max, mode)
    self.mqttType = "text"
    self.createEntity()
  end

end

class HaMqttNumber: HaMqttInput

  var step
  var unitOfMeasurement

  def init(name, unique_id, icon, entityCategory, min, max, mode, step, unitOfMeasurement)
    super(self).init(name, unique_id, icon, entityCategory, min, max, mode)
    self.mqttType = "number"
    self.step = step
    self.unitOfMeasurement = unitOfMeasurement
    self.createEntity()
  end

  def generateConfigBody()
    var configBody = super(self).generateConfigBody()
    if self.step
      configBody['step'] = self.step
    end
    if self.unitOfMeasurement
      configBody['unit_of_measurement'] = self.unitOfMeasurement
    end
    return configBody
  end

  def castValue(payload_s)
    return  json.load(payload_s)
  end

end

class HaMqttSelect: HaMqttInputGen

  var options

  def init(name, unique_id, icon, entityCategory, options)
    if !options
      raise 'HaMqttSelect.init error','invalid options'
    end
    super(self).init(name, unique_id, icon, entityCategory)
    self.mqttType = "select"
    self.options = options
    self.createEntity()
  end

  def generateConfigBody()
    var configBody = super(self).generateConfigBody()
    configBody['options'] = self.options
    return configBody
  end

end

class HaMqttButton: HaMqttMgmt

  var buttonFunction

  def init(name, unique_id, icon, entityCategory, buttonFunction)
    super(self).init(name, unique_id, icon, entityCategory)
    self.mqttType = "button"    
    self.buttonFunction = buttonFunction
    self.createEntity()
  end

  def createEntity()
    super(self).createEntity()

    if self.commandTopic
      mqtt.subscribe(self.commandTopic,  self.buttonFunction)
    end

  end

end
