AddEventHandler('onResourceStop', function(resName)
  if resName ~= RESOURCE then
    return
  end
  UbNpcCleanup(true)
  UbRetaliationCleanup()
  UbUiMinigameClose()
end)

RegisterNetEvent(UbEvent('client:forceCleanup'), function()
  if UbContractClientReset then
    UbContractClientReset()
  end
  UbNpcCleanup(true)
  UbRetaliationCleanup()
  UbUiMinigameClose()
end)
