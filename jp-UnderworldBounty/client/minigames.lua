UbMinigameFinish = nil

--- @param kind string lockpick|hacking|brute|none
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
    titleLock = _L('minigame_lockpick_title'),
    titleHack = _L('minigame_hack_title'),
    titleBrute = _L('minigame_brute_title'),
    success = _L('minigame_success'),
    fail = _L('minigame_fail'),
  }
  UbUiMinigameOpen(payload)
end
