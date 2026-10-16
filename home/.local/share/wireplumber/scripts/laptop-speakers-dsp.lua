-- Włącza smart filter "Głośniki laptopa (DSP)" tylko wtedy, gdy aktywnym
-- portem wbudowanej karty są głośniki. Przy słuchawkach (ten sam sink ALSA,
-- inny port) filtr jest wyłączany, więc słuchawki grają bez obróbki.

cutils = require ("common-utils")
log = Log.open_topic ("s-laptop-speakers-dsp")

local CARD_NAME = "alsa_card.pci-0000_00_1f.3"
local FILTER_NODE = "effect_input.laptop_speakers"

devices_om = ObjectManager {
  Interest { type = "device", Constraint { "device.name", "=", CARD_NAME } }
}
filter_om = ObjectManager {
  Interest { type = "node", Constraint { "node.name", "=", FILTER_NODE } }
}
metadata_om = ObjectManager {
  Interest { type = "metadata", Constraint { "metadata.name", "=", "filters" } }
}

local function speakersActive (device)
  for p in device:iterate_params ("Route") do
    local route = cutils.parseParam (p, "Route")
    if route and route.direction == "Output" and
        route.name and route.name:find ("speaker", 1, true) then
      return true
    end
  end
  return false
end

local function update ()
  local device = devices_om:lookup ()
  local filter = filter_om:lookup ()
  local metadata = metadata_om:lookup ()
  if not (device and filter and metadata) then
    return
  end

  local id = filter["bound-id"]
  local disabled = speakersActive (device) and "false" or "true"
  if metadata:find (id, "filter.smart.disabled") ~= disabled then
    log:info ("filter.smart.disabled = " .. disabled)
    metadata:set (id, "filter.smart.disabled", "Spa:String:JSON", disabled)
  end
end

SimpleEventHook {
  name = "custom/laptop-speakers-dsp/route-changed",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "device-params-changed" },
      Constraint { "event.subject.param-id", "=", "Route" },
      Constraint { "device.name", "=", CARD_NAME },
    },
  },
  execute = function (event)
    update ()
  end
}:register ()

-- Filtr jest widoczny w KDE jako "Głośniki laptopa (DSP)". Gdy ktoś go wybierze
-- jako wyjście, traktujemy to jak wybór głośników: przełączamy kartę na profil
-- analogowy i ustawiamy domyślnie sprzętowy sink (filtr wepnie się sam).
local SPEAKER_PROFILE = "output:analog-stereo+input:analog-stereo"
local SPEAKER_SINK = "alsa_output.pci-0000_00_1f.3.analog-stereo"

local function setProfile (device, name)
  for p in device:iterate_params ("Profile") do
    local active = cutils.parseParam (p, "Profile")
    if active and active.name == name then
      return
    end
  end
  for p in device:iterate_params ("EnumProfile") do
    local profile = cutils.parseParam (p, "EnumProfile")
    if profile and profile.name == name then
      log:info ("przełączam profil na " .. name)
      device:set_param ("Profile", Pod.Object {
        "Spa:Pod:Object:Param:Profile", "Profile",
        index = profile.index,
        save = true,
      })
      return
    end
  end
end

SimpleEventHook {
  name = "custom/laptop-speakers-dsp/filter-selected",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "metadata-changed" },
      Constraint { "metadata.name", "=", "default" },
      Constraint { "event.subject.key", "=", "default.configured.audio.sink" },
    },
  },
  execute = function (event)
    local value = event:get_properties () ["event.subject.value"]
    if not value or Json.Raw (value):parse () ["name"] ~= FILTER_NODE then
      return
    end
    local device = devices_om:lookup ()
    if device then
      setProfile (device, SPEAKER_PROFILE)
    end
    event:get_subject ():set (0, "default.configured.audio.sink", "Spa:String:JSON",
        Json.Object { name = SPEAKER_SINK }:to_string ())
  end
}:register ()

-- Automatyczne przełączanie: gdy telewizor (HDMI) staje się dostępny, dźwięk
-- idzie na HDMI stereo; gdy znika (odłączony/wyłączony) — wraca na głośniki.
-- Reagujemy tylko na zmianę dostępności, więc ręczny wybór nie jest nadpisywany.
local HDMI_PROFILE = "output:hdmi-stereo+input:analog-stereo"
local HDMI_SINK = "alsa_output.pci-0000_00_1f.3.hdmi-stereo"
local hdmi_was_available = nil

default_metadata_om = ObjectManager {
  Interest { type = "metadata", Constraint { "metadata.name", "=", "default" } }
}

local function hdmiAvailable (device)
  for p in device:iterate_params ("EnumProfile") do
    local profile = cutils.parseParam (p, "EnumProfile")
    if profile and profile.name == HDMI_PROFILE then
      return profile.available == "yes"
    end
  end
  return false
end

local function setDefaultSink (name)
  local metadata = default_metadata_om:lookup ()
  if metadata then
    metadata:set (0, "default.configured.audio.sink", "Spa:String:JSON",
        Json.Object { name = name }:to_string ())
  end
end

local function checkHdmi ()
  local device = devices_om:lookup ()
  if not device then
    return
  end
  local now = hdmiAvailable (device)
  local before = hdmi_was_available
  hdmi_was_available = now
  if before == nil or before == now then
    return
  end
  if now then
    log:info ("telewizor dostępny — przełączam na HDMI")
    setProfile (device, HDMI_PROFILE)
    setDefaultSink (HDMI_SINK)
  else
    log:info ("telewizor niedostępny — wracam na głośniki")
    setProfile (device, SPEAKER_PROFILE)
    setDefaultSink (SPEAKER_SINK)
  end
end

SimpleEventHook {
  name = "custom/laptop-speakers-dsp/hdmi-availability",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "device-params-changed" },
      Constraint { "event.subject.param-id", "=", "EnumProfile" },
      Constraint { "device.name", "=", CARD_NAME },
    },
  },
  execute = function (event)
    checkHdmi ()
  end
}:register ()

devices_om:connect ("object-added", checkHdmi)
default_metadata_om:activate ()

devices_om:connect ("object-added", update)
filter_om:connect ("object-added", update)
metadata_om:connect ("object-added", update)

devices_om:activate ()
filter_om:activate ()
metadata_om:activate ()
