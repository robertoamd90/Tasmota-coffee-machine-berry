import persist
import webserver 

class WebUiMgmt

  static var webUiMgmt

  var OffDelayMin
  var OffDelayMax
  var ShortTimeMin
  var ShortTimeMax
  
  var OffDelayMqtt
  var ShortTimeMqtt
  
  def init()
    if ! persist.has("OffDelay")
      persist.OffDelay=  5
    end
    if ! persist.has("ShortTime")
      persist.ShortTime= 15
    end
    if ! persist.has("LastCoffeeTime")
      persist.LastCoffeeTime= 0
    end

    self.OffDelayMin = 5
    self.OffDelayMax = 15
    self.ShortTimeMin = 10
    self.ShortTimeMax = 30

    self.OffDelayMqtt = HaMqttNumber('Off Delay', 'OffDelay', 'mdi:timer', 'config', self.OffDelayMin, self.OffDelayMax, 'box', 1, 'min')
    self.ShortTimeMqtt = HaMqttNumber('Short Time', 'ShortTime', 'mdi:timer', 'config', self.ShortTimeMin, self.ShortTimeMax, 'box', 0.01, 'sec')

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
      webserver.content_send("<tr><td style='width:50%%'><p><b>Off delay time(m)</b></p></td>")
      webserver.content_send("<td style='width:20px;white-space:nowrap'></td>")
      webserver.content_send("<td style='style='width:50%%'><p><b>Shot coffee time(s)</b></p></td></tr>")
      webserver.content_send(format("<tr><td><p><input style='width:100px' type='number' min='%i' max='%i' name='OffDelay' value='%i'></p></td>", self.OffDelayMin, self.OffDelayMax, persist.OffDelay))
      webserver.content_send("<td style='width:20px;white-space:nowrap'></td>")
      webserver.content_send(format("<td><p><input style='width:100px' type='number' min='%i' max='%i' name='ShortTime' value='%.2f' step='0.01'></p></td></tr>", self.ShortTimeMin, self.ShortTimeMax, persist.ShortTime))
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
  
      webserver.content_start("Coffee Machine Configuration")           #- title of the web page -#
      webserver.content_send_style()                  #- send standard Tasmota styles -#
      webserver.content_send("<fieldset><style>.bdis{background:#888;}.bdis:hover{background:#888;}</style>")
      webserver.content_send(format("<legend><b title='CoffeeMachine'>Configuration Coffee Machine</b></legend>"))
      webserver.content_send("<p><form style='display: block;' action='/WebUiMgmt' method='post'>")
      webserver.content_send(format("<table style='width:100%%'>"))
      webserver.content_send("<tr><td style='width:300px'><b>Off delay time (min)</b></td>")
      webserver.content_send(format("<td style='width:100px'><input type='number' min='%i' max='%i' name='OffDelay' value='%i'></td></tr>", self.OffDelayMin, self.OffDelayMax, persist.OffDelay))
      webserver.content_send("<tr><td style='width:300px'><b>Shot coffee time (s)</b></td>")
      webserver.content_send(format("<td style='width:100px'><input type='number' min='%i' max='%i' name='ShortTime' value='%.2f' step='0.01'></td></tr>", self.ShortTimeMin, self.ShortTimeMax, persist.ShortTime))
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
          # read arguments
          persist.OffDelay = int(webserver.arg("OffDelay"))
          persist.ShortTime = real(webserver.arg("ShortTime"))
          print(format("Got OffDelay"),persist.OffDelay )
          print(format("Got ShortTime"),persist.ShortTime )
          persist.save()
          self.OffDelayMqtt.setValue()
          self.ShortTimeMqtt.setValue()
          webserver.redirect("/?")

        end
        if webserver.has_arg("LastCoffeeTimeApply")
          persist.ShortTime = persist.LastCoffeeTime
          print(format("Set LastCoffeeTime"),persist.LastCoffeeTime )
          persist.save()
          self.OffDelayMqtt.setValue()
          webserver.redirect("/?")

        end
      except .. as e,m
        print(format("BRY: Exception> '%s' - %s", e, m))
        #- display error page -#
        webserver.content_start("Parameter error")           #- title of the web page -#
        webserver.content_send_style()                  #- send standard Tasmota styles -#

        webserver.content_send(format("<p style='width:340px;'><b>Exception:</b><br>'%s'<br>%s</p>", e, m))

        webserver.content_button(webserver.button_CONFIGURATION) #- button back to management page -#
        webserver.content_stop()                        #- end of web page -#
      end
    end
      
    def web_add_handler()
      #- we need to register a closure, not just a function, that captures the current instance -#
      webserver.on("/WebUiMgmt", / -> self.page_MyWebUi(), webserver.HTTP_GET)
      webserver.on("/WebUiMgmt", / -> self.page_MyWebUi_ctl(), webserver.HTTP_POST)
    end

end 

WebUiMgmt()