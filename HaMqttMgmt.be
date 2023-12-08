import mqtt
import string
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

  def init(name, unique_id, icon, entityCategory)

    if !name || !unique_id
      raise 'HaMqttMgmt.init error','invalid name and/or unique_id'
    end

    var mac = tasmota.wifi()['mac']
    var macSplitted = string.split(mac, ":")
    HaMqttMgmt.mac = macSplitted.concat()
    HaMqttMgmt.macShort = string.split(mac, 6)[1]

    self.name = name
    self.unique_id = unique_id
    self.icon = icon
    self.entityCategory = entityCategory

  end

  def generateTopics()

    if !self.mqttType
      raise 'generateTopics error','invalid mqttType'
    end

    self.configTopic = format("homeassistant/%s/%s/%s/config", self.mqttType, HaMqttMgmt.mac, self.unique_id)
    self.availabilityTopic = format("tele/tasmota_%s/LWR", HaMqttMgmt.macShort)
    self.stateTopic = format("homeassistant/%s/%s/%s/state", self.mqttType, HaMqttMgmt.mac, self.unique_id)
    self.commandTopic = format("homeassistant/%s/%s/%s/set", self.mqttType, HaMqttMgmt.mac, self.unique_id)

  end

  def generateConfigBody()

    var configBody = {
      "name" : self.name,
      "unique_id" : format("%s_%s", HaMqttMgmt.mac, self.unique_id),
      #"availability_topic" : self.availabilityTopic,
      "command_topic" : self.commandTopic,
      #"command_template" : format("{\"%s\": {{ value }} }", self.unique_id),
      "icon" : self.icon,
      "entity_category" : self.entityCategory,
      "device" : {"connections": [["mac", HaMqttMgmt.mac]]}
    }

    return configBody

  end

  def createEntity()
    if mqtt.connected()
      tasmota.remove_timer(format(self.unique_id,'_createEntityRetry'))
      self.generateTopics()
      if self.setValue
        tasmota.set_timer( 1000, /-> self.setValue())
      end
      var configBody = self.generateConfigBody()
      mqtt.publish(self.configTopic, json.dump(configBody))
    else
      tasmota.set_timer( 1000, /-> self.createEntity(), format(self.unique_id,'_createEntityRetry'))
    end
  end

end

class HaMqttInput: HaMqttMgmt
  
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
    configBody['state_topic'] = self.stateTopic
    #configBody['value_template] = format("{{ value_json.%s }}", self.unique_id)
    configBody['min'] = self.min
    configBody['max'] = self.max
    configBody['mode'] = self.mode
    return configBody
  end

  def createEntity()
    super(self).createEntity()

    mqtt.subscribe(self.commandTopic,
      def (topic, idx, payload_s, payload_b)
        return self.getValue(topic, idx, payload_s, payload_b)
      end
    )

  end

  def getValue(topic, idx, payload_s, payload_b)

    print(">>>", payload_s)

    var payload_object = json.load(payload_s)

    if payload_object
      persist.setmember(self.unique_id, payload_object)
      persist.save()
      self.setValue()
    end

    return true
  end

  def setValue()
    if persist.has(self.unique_id)
      mqtt.publish(self.stateTopic, json.dump(persist.member(self.unique_id)))
    end
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
    configBody['step'] = self.step
    configBody['unit_of_measurement'] = self.unitOfMeasurement
    return configBody
  end

end