UbMinigameFinish = nil

--- @param kind string lockpick|hacking|brute|timing_wheel|none
--- @param cb fun(ok: boolean)
function UbRunMinigame(kind, cb)
  if kind == 'none' or kind == nil then
    cb(true)
    return
  end
  UbMinigameFinish = function(ok)
    UbMinigameFinish = nil
    cb(ok)
  end
  local payload = {
    kind = kind,
    lockpickMs = Config.MinigameLockpickDurationMs,
    hackSteps = Config.MinigameHackSteps,
    bruteHits = Config.MinigameBruteHits,
    timingWheelMs = Config.MinigameTimingWheelMs,
    titleLock = _L('minigame_lockpick_title'),
    titleHack = _L('minigame_hack_title'),
    titleBrute = _L('minigame_brute_title'),
    titleTimingWheel = _L('minigame_timing_wheel_title'),
    descTimingWheel = _L('minigame_timing_wheel_desc'),
    statusTimingWheel = _L('minigame_timing_wheel_status'),
    success = _L('minigame_success'),
    fail = _L('minigame_fail'),
  }
  UbUiMinigameOpen(payload)
end
