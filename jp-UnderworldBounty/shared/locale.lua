--- ロケール文字列取得（ja / en）。欠けているキーはキー名をそのまま返す。
--- @param key string
--- @param ... any string.format 用
--- @return string
function _L(key, ...)
  local loc = (Config and Config.Locale) or 'ja'
  local bucket = Locales and (Locales[loc] or Locales['ja'])
  local template = (bucket and bucket[key]) or key
  if select('#', ...) > 0 then
    return string.format(template, ...)
  end
  return template
end
