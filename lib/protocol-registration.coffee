Registy = require 'winreg'

class ProtocolRegistration
  constructor: (key, parts) ->
    @key = key
    @parts = parts

  isRegistered: (callback) =>
    new Registry({hive: 'HKCU', key: "#{@key}\\#{@parts[0].key}"})
      .get @parts[0].name, (err, val) =>
        callback(not err? and val? and val.value is @parts[0].value)

  register: (callback) =>
    doneCount = @parts.length
    @parts.forEach (part) =>
      reg = new Registry({hive: 'HKCU', key: if part.key? then "#{@key}\\#{part.key}" else @key})
      reg.create( -> reg.set part.name, Registry.REG_SZ, part.value, -> callback() if --doneCount is 0)

  deregister: (callback) =>
    @isRegistered (isRegistered) =>
      if isRegistered
        new Registry({hive: 'HKCU', key: @key}).destroy -> callback null, true
      else
        callback null, false

  update: (callback) =>
    new Registry({hive: 'HKCU', key: "#{@key}\\#{@parts[0].key}"})
      .get @parts[0].name, (err, val) =>
        if err? or not val?
          callback(err)
        else
          @register callback

module.exports = ProtocolRegistration
