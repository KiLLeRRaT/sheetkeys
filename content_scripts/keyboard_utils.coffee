window.KeyboardUtils =
  # TODO(philc): keyNames should just be the inverse of this map.
  keyCodes:
    backspace: 8
    tab: 9
    ctrlEnter: 10
    enter: 13
    shiftKey: 16
    ctrlKey: 17
    esc: 27
    space: 32
    end: 35
    home: 36
    leftArrow: 37
    upArrow: 38
    rightArrow: 39
    downArrow: 40
    deleteKey: 46
    f1: 112
    f12: 123

  keyNames:
    { 37: "left", 38: "up", 39: "right", 40: "down", 27: "esc" }

  # This is a mapping of the incorrect keyIdentifiers generated by Webkit on Windows during keydown events to
  # the correct identifiers, which are correctly generated on Mac. We require this mapping to properly handle
  # these keys on Windows. See https://bugs.webkit.org/show_bug.cgi?id=19906 for more details.
  keyIdentifierCorrectionMap:
    "U+00C0": ["U+0060", "U+007E"] # `~
    "U+00BD": ["U+002D", "U+005F"] # -_
    "U+00BB": ["U+003D", "U+002B"] # =+
    "U+00DB": ["U+005B", "U+007B"] # [{
    "U+00DD": ["U+005D", "U+007D"] # ]}
    "U+00DC": ["U+005C", "U+007C"] # \|
    "U+00BA": ["U+003B", "U+003A"] # ;:
    "U+00DE": ["U+0027", "U+0022"] # '"
    "U+00BC": ["U+002C", "U+003C"] # ,<
    "U+00BE": ["U+002E", "U+003E"] # .>
    "U+00BF": ["U+002F", "U+003F"] # /?

  # Returns the string "<A-f>" if F is pressed.
  getKeyString: (event) ->
    keyString = KeyboardUtils.getKeyChar(event)
    # Ignore modifiers by themselves.
    return if keyString == ""
    modifiers = []

    if (event.shiftKey)
      keyString = keyString.toUpperCase()
    if (event.metaKey)
      modifiers.push("M")
    if (event.ctrlKey)
      modifiers.push("C")
    if (event.altKey)
      modifiers.push("A")

    for mod in modifiers
      keyString = mod + "-" + keyString

    keyString = "<#{keyString}>" if (modifiers.length > 0)
    keyString

  getKeyChar: (event) ->
    # Not a letter
    if (event.keyIdentifier.slice(0, 2) != "U+")
      return @keyNames[event.keyCode] if (@keyNames[event.keyCode])
      # F-key
      if (event.keyCode >= @keyCodes.f1 && event.keyCode <= @keyCodes.f12)
        return "f" + (1 + event.keyCode - keyCodes.f1)
      return ""

    keyIdentifier = event.keyIdentifier
    # On Windows, the keyIdentifiers for non-letter keys are incorrect. See
    # https://bugs.webkit.org/show_bug.cgi?id=19906 for more details.
    if ((@platform == "Windows" || @platform == "Linux") && @keyIdentifierCorrectionMap[keyIdentifier])
      correctedIdentifiers = @keyIdentifierCorrectionMap[keyIdentifier]
      keyIdentifier = if event.shiftKey then correctedIdentifiers[1] else correctedIdentifiers[0]
    unicodeKeyInHex = "0x" + keyIdentifier.substring(2)
    character = String.fromCharCode(parseInt(unicodeKeyInHex)).toLowerCase()
    if event.shiftKey then character.toUpperCase() else character

  createSimulatedKeyEvent: (el, type, keyCode, keyIdentifier) ->
    # How to do this in Chrome: http://stackoverflow.com/q/10455626/46237
    event = document.createEvent("KeyboardEvent")
    Object.defineProperty(event, "keyCode", get : -> @keyCodeVal)
    Object.defineProperty(event, "which", get: -> @keyCodeVal)
    Object.defineProperty(event, "keyIdentifier", get: -> keyIdentifier)
    event.initKeyboardEvent(type, true, true, document.defaultView, false, false, false, false, keyCode, 0)
    event.keyCodeVal = keyCode
    event.keyIdentifier = keyIdentifier
    event

  simulateKeypress: (el, keyCode, keyIdentifier) ->
    # console.log ">>>> simulating keypress on:", el, keyCode, keyIdentifier
    el.dispatchEvent(@createSimulatedKeyEvent(el, "keydown", keyCode, keyIdentifier))
    el.dispatchEvent(@createSimulatedKeyEvent(el, "keypress", keyCode, keyIdentifier))
    el.dispatchEvent(@createSimulatedKeyEvent(el, "keyup", keyCode, keyIdentifier))

  simulateClick: (el) ->
    eventSequence = ["mouseover", "mousedown", "mouseup", "click"];
    for eventName in eventSequence
      event = document.createEvent("MouseEvents");
      event.initMouseEvent(eventName, true, true, window, 1, 0, 0, 0,0, false, false, false, false, 0, null);
      el.dispatchEvent(event);
