-- SPDX-License-Identifier: LGPL-3.0-or-later

---@class TectonCategoryEnum
Category = Category or {
    FURNITURE = 'furniture',
    DOOR = 'door',
    PARKING = 'parking',
    STASH = 'stash',
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
