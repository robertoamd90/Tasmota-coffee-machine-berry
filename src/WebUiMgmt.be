import persist
import webserver

class WebUiMgmt

  static var webUiMgmt

  var OffDelayMin
  var OffDelayMax
  var CoffeeTimeMin
  var CoffeeTimeMax

  var OffDelayMqtt
  var Coffee1TimeMqtt
  var Coffee2TimeMqtt
  var CoffeeSelectionMqtt
  var SetLastCoffeeTimeMqtt
  var PreloadPumpTimeMqtt
  var PreloadPumpEnabledMqtt

  def init()
    if ! persist.has("OffDelay")
      persist.OffDelay = 5
    end
    if ! persist.has("Coffee1Time")
      persist.Coffee1Time = 15
    end
    if ! persist.has("Coffee2Time")
      persist.Coffee2Time = 15
    end
    if ! persist.has("LastCoffeeTime")
      persist.LastCoffeeTime = 0
    end
    if ! persist.has("SelectedCoffee")
      persist.SelectedCoffee = "1"
    end
    if ! persist.has("PreloadPumpEnabled")
      persist.PreloadPumpEnabled = true
    end
    if ! persist.has("PreloadPumpTime")
      persist.PreloadPumpTime = 1
    end

    self.OffDelayMin = 5
    self.OffDelayMax = 15
    self.CoffeeTimeMin = 10
    self.CoffeeTimeMax = 30

    self.OffDelayMqtt = HaMqttNumber('Off Delay', 'OffDelay', 'mdi:timer', 'config', self.OffDelayMin, self.OffDelayMax, 'box', 1, 'min')
    self.Coffee1TimeMqtt = HaMqttNumber('Coffee 1 Time', 'Coffee1Time', 'mdi:timer', 'config', self.CoffeeTimeMin, self.CoffeeTimeMax, 'box', 0.01, 'sec')
    self.Coffee2TimeMqtt = HaMqttNumber('Coffee 2 Time', 'Coffee2Time', 'mdi:timer', 'config', self.CoffeeTimeMin, self.CoffeeTimeMax, 'box', 0.01, 'sec')
    self.CoffeeSelectionMqtt = HaMqttSelect('Coffee Selection', 'SelectedCoffee', 'mdi:coffee', nil, ['1', '2'])
    self.SetLastCoffeeTimeMqtt = HaMqttButton('Set Last coffee time', 'SetLastCoffeeTime', 'mdi:coffee', 'config', /-> self.setLastCoffeeTime())
    self.PreloadPumpTimeMqtt = HaMqttNumber('Preload Pump Time', 'PreloadPumpTime', 'mdi:pump', 'config', 0.1, 10, 'box', 0.1, 'sec')
    self.PreloadPumpEnabledMqtt = HaMqttSwitch('Preload Pump', 'PreloadPumpEnabled', 'mdi:pump', 'config')

    if nil != WebUiMgmt.webUiMgmt
      tasmota.remove_driver(WebUiMgmt.webUiMgmt)
    end
    WebUiMgmt.webUiMgmt = self
    tasmota.add_driver(self)
    self.web_add_handler()
  end

  def web_add_main_button()
    webserver.content_send("<fieldset><style>.bdis{background:#888;}.bdis:hover{background:#888;}</style>")
    webserver.content_send("<legend><b title='CoffeeMachine'>Coffee Machine</b></legend>")
    webserver.content_send("<p><form style='display: block;' action='/WebUiMgmt' method='post'>")

    webserver.content_send("<table style='width:100%'>")
    webserver.content_send(format("<tr><td style='width:50%%'><p>Status: <b>%s</b></p></td><td style='width:50%%'><p>Mode: <b>%s</b></p></td></tr>", persist.Status, persist.has('Mode') ? persist.Mode : 'Manual'))
    webserver.content_send("<tr><td style='width:50%%'><p><b>Off delay time (m)</b></p></td>")
    webserver.content_send("<td style='width:50%%'><p><b>Selected Coffee Profile</b></p></td></tr>")
    webserver.content_send(format("<tr><td><p><input style='width:100px' type='number' min='%i' max='%i' name='OffDelay' value='%i'></p></td>", self.OffDelayMin, self.OffDelayMax, persist.OffDelay))
    webserver.content_send("<td><select name='SelectedCoffee' style='width:150px'>")
    webserver.content_send(format("<option value='1'%s>Coffee 1</option>", persist.SelectedCoffee == "1" ? " selected" : ""))
    webserver.content_send(format("<option value='2'%s>Coffee 2</option>", persist.SelectedCoffee == "2" ? " selected" : ""))
    webserver.content_send("</select></td></tr>")
    webserver.content_send("<tr><td style='width:50%%'><p><b>Coffee 1 time (s)</b></p></td>")
    webserver.content_send("<td style='width:50%%'><p><b>Coffee 2 time (s)</b></p></td></tr>")
    webserver.content_send(format("<tr><td><p><input style='width:100px' type='number' min='%i' max='%i' name='Coffee1Time' value='%.2f' step='0.01'></p></td>", self.CoffeeTimeMin, self.CoffeeTimeMax, persist.Coffee1Time))
    webserver.content_send(format("<td><p><input style='width:100px' type='number' min='%i' max='%i' name='Coffee2Time' value='%.2f' step='0.01'></p></td></tr>", self.CoffeeTimeMin, self.CoffeeTimeMax, persist.Coffee2Time))
    webserver.content_send("<tr><td style='width:50%'><p><b>Preload pump</b></p></td>")
    webserver.content_send(format("<td><p><input type='checkbox' name='PreloadPumpEnabled' value='1'%s></p></td></tr>", persist.PreloadPumpEnabled ? " checked" : ""))
    webserver.content_send("<tr><td style='width:50%'><p><b>Preload pump time (s)</b></p></td>")
    webserver.content_send(format("<td><p><input style='width:100px' type='number' min='0.1' max='10' step='0.1' name='PreloadPumpTime' value='%.1f'></p></td></tr>", persist.PreloadPumpTime))
    webserver.content_send("</table>")

    webserver.content_send("<table style='width:100%'>")
    webserver.content_send(format("<tr><td style='width:70%%'><p>Last coffee time: <b>%.2f</b>(s)</p></td>", persist.LastCoffeeTime))
    webserver.content_send("<td><button name='LastCoffeeTimeApply' class='button bgrn'>Set</button></td></tr>")
    webserver.content_send("</table><hr>")

    webserver.content_send("<button name='CoffeeSettingsApply' class='button bgrn'>Save</button>")
    webserver.content_send("</form></p>")
    webserver.content_send("<p><form action='/WebUiMgmt' style='display: block;' method='get'><button>Configure</button></form></p>")
    webserver.content_send("<p></p></fieldset><p></p>")
  end

  def page_MyWebUi()
    if !webserver.check_privileged_access() return nil end

    webserver.content_start("Coffee Machine Configuration")
    webserver.content_send_style()
    webserver.content_send("<fieldset><style>.bdis{background:#888;}.bdis:hover{background:#888;}</style>")
    webserver.content_send("<legend><b title='CoffeeMachine'>Configuration Coffee Machine</b></legend>")
    webserver.content_send("<p><form style='display: block;' action='/WebUiMgmt' method='post'>")
    webserver.content_send("<table style='width:100%%'>")
    webserver.content_send("<tr><td style='width:300px'><b>Off delay time (min)</b></td>")
    webserver.content_send("<td style='width:300px'><b>Selected Coffee Profile</b></td></tr>")
    webserver.content_send(format("<td style='width:100px'><input type='number' min='%i' max='%i' name='OffDelay' value='%i'></td>", self.OffDelayMin, self.OffDelayMax, persist.OffDelay))
    webserver.content_send("<td style='width:100px'><select name='SelectedCoffee'>")
    webserver.content_send(format("<option value='1'%s>Coffee 1</option>", persist.SelectedCoffee == "1" ? " selected" : ""))
    webserver.content_send(format("<option value='2'%s>Coffee 2</option>", persist.SelectedCoffee == "2" ? " selected" : ""))
    webserver.content_send("</select></td></tr>")
    webserver.content_send("<tr><td style='width:300px'><b>Coffee 1 time (s)</b></td>")
    webserver.content_send("<td style='width:300px'><b>Coffee 2 time (s)</b></td></tr>")
    webserver.content_send(format("<td style='width:100px'><input type='number' min='%i' max='%i' name='Coffee1Time' value='%.2f' step='0.01'></td>", self.CoffeeTimeMin, self.CoffeeTimeMax, persist.Coffee1Time))
    webserver.content_send(format("<td style='width:100px'><input type='number' min='%i' max='%i' name='Coffee2Time' value='%.2f' step='0.01'></td></tr>", self.CoffeeTimeMin, self.CoffeeTimeMax, persist.Coffee2Time))
    webserver.content_send("<tr><td style='width:300px'><b>Preload pump</b></td>")
    webserver.content_send(format("<td style='width:100px'><input type='checkbox' name='PreloadPumpEnabled' value='1'%s></td></tr>", persist.PreloadPumpEnabled ? " checked" : ""))
    webserver.content_send("<tr><td style='width:300px'><b>Preload pump time (s)</b></td>")
    webserver.content_send(format("<td style='width:100px'><input type='number' min='0.1' max='10' step='0.1' name='PreloadPumpTime' value='%.1f'></td></tr>", persist.PreloadPumpTime))
    webserver.content_send("</table><hr>")
    webserver.content_send("<button name='CoffeeSettingsApply' class='button bgrn'>Save</button>")
    webserver.content_send("</form></p>")
    webserver.content_send("<p></p></fieldset><p></p>")
    webserver.content_button(webserver.BUTTON_MAIN)
    webserver.content_stop()
  end

  def page_MyWebUi_ctl()
    if !webserver.check_privileged_access() return nil end
    import introspect

    try
      if webserver.has_arg("CoffeeSettingsApply")
        persist.SelectedCoffee = webserver.arg("SelectedCoffee")
        persist.OffDelay = int(webserver.arg("OffDelay"))
        persist.Coffee1Time = real(webserver.arg("Coffee1Time"))
        persist.Coffee2Time = real(webserver.arg("Coffee2Time"))
        persist.PreloadPumpEnabled = webserver.has_arg("PreloadPumpEnabled")
        persist.PreloadPumpTime = real(webserver.arg("PreloadPumpTime"))
        tprint(format("[WebUiMgmt] settings saved | SelectedCoffee=%s OffDelay=%i Coffee1Time=%.2f Coffee2Time=%.2f PreloadPump=%s %.1fs",
          persist.SelectedCoffee, persist.OffDelay, persist.Coffee1Time, persist.Coffee2Time,
          persist.PreloadPumpEnabled ? "on" : "off", persist.PreloadPumpTime))
        persist.save()
        self.CoffeeSelectionMqtt.setValue()
        self.OffDelayMqtt.setValue()
        self.Coffee1TimeMqtt.setValue()
        self.Coffee2TimeMqtt.setValue()
        self.PreloadPumpEnabledMqtt.setValue()
        self.PreloadPumpTimeMqtt.setValue()
        webserver.redirect("/?")
      end
      if webserver.has_arg("LastCoffeeTimeApply")
        persist.SelectedCoffee = webserver.arg("SelectedCoffee")
        self.setLastCoffeeTime()
        webserver.redirect("/?")
      end
    except .. as e,m
      print(format("BRY: Exception> '%s' - %s", e, m))
      webserver.content_start("Parameter error")
      webserver.content_send_style()
      webserver.content_send(format("<p style='width:340px;'><b>Exception:</b><br>'%s'<br>%s</p>", e, m))
      webserver.content_button(webserver.button_CONFIGURATION)
      webserver.content_stop()
    end
  end

  def web_add_handler()
    webserver.on("/WebUiMgmt", / -> self.page_MyWebUi(), webserver.HTTP_GET)
    webserver.on("/WebUiMgmt", / -> self.page_MyWebUi_ctl(), webserver.HTTP_POST)
  end

  def setLastCoffeeTime()
    if persist.SelectedCoffee == "1"
      persist.Coffee1Time = persist.LastCoffeeTime
      self.Coffee1TimeMqtt.setValue()
    elif persist.SelectedCoffee == "2"
      persist.Coffee2Time = persist.LastCoffeeTime
      self.Coffee2TimeMqtt.setValue()
    end
    tprint(format("[WebUiMgmt] setLastCoffeeTime | coffee=%s time=%.2fs", persist.SelectedCoffee, persist.LastCoffeeTime))
    persist.save()
  end

end

WebUiMgmt()
