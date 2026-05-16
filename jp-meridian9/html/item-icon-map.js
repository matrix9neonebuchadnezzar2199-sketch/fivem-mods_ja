/**
 * itemId → リソースルート相対パス（`fxmanifest.lua` の `files` に含めること）
 * PNG ファイル名は英語 snake_case（`image/item/<id>.png`）で Linux 本番互換。
 */
(function (g) {
    'use strict';

    /** @type {Record<string, string>} */
    g.MRD9_ITEM_ICON_MAP = {
        field_tool_kit: 'image/item/field_tool_kit.png',
        ration_pack: 'image/item/ration_pack.png',
        multitool: 'image/item/multitool.png',
        combat_boots: 'image/item/combat_boots.png',
        welding_torch: 'image/item/welding_torch.png',
        protective_mask: 'image/item/protective_mask.png',
        oxygen_cylinder: 'image/item/oxygen_cylinder.png',
        motion_sensor: 'image/item/motion_sensor.png',
        thermal_goggles: 'image/item/thermal_goggles.png',
        tactical_gloves: 'image/item/tactical_gloves.png',
        comms_unit: 'image/item/comms_unit.png',
        repair_drone: 'image/item/repair_drone.png',
        hacking_device: 'image/item/hacking_device.png',
        biometric_scanner: 'image/item/biometric_scanner.png',
        radiation_detector: 'image/item/radiation_detector.png',
        tactical_helmet: 'image/item/tactical_helmet.png',
        tactical_vest: 'image/item/tactical_vest.png',
        shield_booster: 'image/item/shield_booster.png',
        energy_cell: 'image/item/energy_cell.png',
        dimensional_scanner: 'image/item/dimensional_scanner.png',
        encrypted_keycard: 'image/item/encrypted_keycard.png',
        radiation_suit: 'image/item/radiation_suit.png',
        nanite_repair_paste: 'image/item/nanite_repair_paste.png',
        data_chip: 'image/item/data_chip.png',
    };
})(typeof window !== 'undefined' ? window : globalThis);
