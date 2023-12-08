import persist

class PersistMgmt

  static var OffDelay
  static var ShortTime
  static var LastCoffeeTime

  static var OffDelayMin
  static var OffDelayMax
  static var ShortTimeMin
  static var ShortTimeMax

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

    PersistMgmt.OffDelay = persist.OffDelay
    PersistMgmt.ShortTime = persist.ShortTime
    PersistMgmt.LastCoffeeTime = persist.LastCoffeeTime

    PersistMgmt.OffDelayMin = 5
    PersistMgmt.OffDelayMax = 15
    PersistMgmt.ShortTimeMin = 10
    PersistMgmt.ShortTimeMax = 30

  end

  static def setShortTime(shortTime)
    PersistMgmt.ShortTime = shortTime
    persist.ShortTime = shortTime
    persist.save()
  end

  static def setOffDelay(offDelay)
    PersistMgmt.OffDelay = offDelay
    persist.OffDelay = offDelay
    persist.save()
  end

  static def setLastCoffeeTime(lastCoffeeTime)
    PersistMgmt.LastCoffeeTime = lastCoffeeTime
    persist.LastCoffeeTime = lastCoffeeTime
    persist.save()
  end

end

PersistMgmt()