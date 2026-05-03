--- フレームワーク種別を決定する（Config.Framework とリソース状態を参照）
Framework = 'standalone'

local function detect_auto()
  if GetResourceState('es_extended') == 'started' then
    return 'esx'
  end
  if GetResourceState('qbx_core') == 'started' then
    return 'qbox'
  end
  if GetResourceState('qb-core') == 'started' then
    return 'qbcore'
  end
  return 'standalone'
end

local mode = (Config and Config.Framework) or 'auto'
if mode == 'auto' then
  Framework = detect_auto()
else
  Framework = mode
end
