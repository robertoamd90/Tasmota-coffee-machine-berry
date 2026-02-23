def ts()
  var t = tasmota.rtc()['local']
  return format("%02i:%02i:%02i", (t % 86400) / 3600, (t % 3600) / 60, t % 60)
end

def tprint(msg)
  print("[" + ts() + "] " + msg)
end
