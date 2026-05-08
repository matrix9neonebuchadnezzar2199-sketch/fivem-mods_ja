-- SPDX-License-Identifier: LGPL-3.0-or-later

---@class TectonCategoryEnum
Category = Category or {
    FURNITURE = 'furniture',
    DOOR = 'door',
    PARKING = 'parking',
    STASH = 'stash',
}

--- Config.Props / カテゴリツリーの8ルート id（`tools/category_map.json` と一致）
Category.ROOTS = {
    'furniture',
    'decoration',
    'exterior',
    'structure',
    'industrial',
    'commercial',
    'vehicle_related',
    'misc',
}

---@class TectonOpTypeEnum
OpType = OpType or {
    CREATE = 'create',
    UPDATE = 'update',
    DELETE = 'delete',
}

---@class TectonActionEnum
Action = Action or {
    CREATE = 'create',
    UPDATE = 'update',
    DELETE = 'delete',
    MOVE = 'move',
    ROTATE = 'rotate',
    RECOLOR = 'recolor',
}
