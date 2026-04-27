# 出題庫 90 問を data/*.lua へ（H:\\CURSOR\\Dev\\jp-mechanic で: python tools/gen_slips.py）
from __future__ import annotations

import os

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))


def lua_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write_block(
    f,
    varname: str,
    rows: list[tuple[str, str, str, list[str]]],
) -> None:
    f.write(f"-- 出題 {len(rows)} 問（answers の id は config.lua Config.Parts と一致）\n")
    f.write(f"{varname} = {{\n")
    for s, v, d, a in rows:
        ids = ", ".join(f"'{x}'" for x in a)
        f.write("    {\n")
        f.write(f"        symptom = {lua_str(s)},\n")
        f.write(f"        vehicle = {lua_str(v)},\n")
        f.write(f"        diagnosis = {lua_str(d)},\n")
        f.write(f"        answers = {{ {ids} }},\n")
        f.write("    },\n")
    f.write("}\n")


EASY: list[tuple[str, str, str, list[str]]] = [
    ("エンジン始動が弱い", "国産セダン", "バッテリー点検", ["battery"]),
    ("オイル圧灯が点灯", "国産SUV", "オイル量・汚れ確認", ["engine_oil", "oil_filter"]),
    ("アイドリング不調", "軽四", "点検: スパーク・空気", ["spark_plug", "air_filter"]),
    ("白煙が出る", "小型トラック", "ATF/エンジンオイル要確認", ["transmission_oil", "engine_oil"]),
    ("回転に合わせ甲高い音", "国産セダン", "補助ベルト要確認", ["fan_belt"]),
    ("水漏れ跡あり", "輸入セダン", "クーラント/ラジエ", ["coolant", "radiator"]),
    ("水温上昇が遅い", "軽バン", "節温・水ポンプ", ["thermostat", "water_pump"]),
    ("減速時のキーキ音", "国産SUV", "パッド・液量", ["brake_pad", "brake_fluid"]),
    ("直進時ハンドル振れ", "セダン", "前輪・幾何", ["tire", "wheel_alignment"]),
    ("ペダル深め", "軽四", "パッド/ディスク", ["brake_pad", "brake_disc"]),
    ("吹き出し風量低下", "SUV", "エアフィル詰まり", ["air_filter"]),
    ("始動直後のギーギー", "国産SUV", "補助発電/ベルト", ["alternator", "fan_belt"]),
    ("セルが重い", "軽四", "始動/電源要見分", ["starter_motor", "battery"]),
    ("低燃費", "国産SUV", "点火・空気", ["spark_plug", "air_filter"]),
    ("舗装路で体が揺れる", "国産SUV", "減衰・足周り", ["suspension", "shock_absorber"]),
    ("排ガス匂い強い", "SUV", "排気/触媒", ["exhaust_pipe", "catalytic_conv"]),
    ("冷房弱い", "国産SUV", "クーラ系", ["coolant", "radiator"]),
    ("停車中ガソリン匂い", "軽SUV", "濾過/圧送", ["fuel_filter", "fuel_pump"]),
    ("夜道が暗い", "国産バン", "前照灯＋保護", ["headlight_bulb", "fuse"]),
    ("雨天視界悪", "国産SUV", "拭き取り", ["wiper_blade", "headlight_bulb"]),
    ("上り坂で力不足", "国産SUV", "トランスミッション要確認", ["clutch", "transmission_oil"]),
    ("低温始動遅", "SUV", "始動/点火", ["battery", "spark_plug"]),
    ("上り失速", "軽四", "燃料/排気", ["fuel_filter", "exhaust_pipe"]),
    ("全ブレーキ違和感", "セダン", "円盤/液", ["brake_disc", "brake_fluid"]),
    ("水ポンプ周囲粉状", "国産SUV", "洩水周辺", ["water_pump", "coolant"]),
    ("ベルト焼付臭", "SUV", "同時交換推奨", ["fan_belt", "timing_belt"]),
    ("Dレンジで突っ込み", "国産SUV", "ATF+吸気", ["transmission_oil", "air_filter"]),
    ("加速で失火っぽい", "SUV", "圧力/火花", ["fuel_pump", "spark_plug"]),
    ("減速前で不安", "SUV", "前輪制動", ["brake_pad", "tire"]),
    ("オルタ回り音", "国産セダン", "発電まわり点検", ["alternator", "engine_oil"]),
]

MEDIUM: list[tuple[str, str, str, list[str]]] = [
    (
        "ブローバイ白煙・圧上がり感",
        "国産SUV",
        "オイル/吸気/点火を総点検",
        ["engine_oil", "air_filter", "spark_plug"],
    ),
    (
        "冷却全般不調",
        "国産SUV",
        "水回り",
        ["thermostat", "radiator", "coolant", "water_pump"],
    ),
    (
        "左右ブレ+焼付臭",
        "セダン",
        "制動一式",
        ["brake_pad", "brake_disc", "brake_fluid", "tire"],
    ),
    (
        "補助ベルト+充電",
        "軽SUV",
        "同時交換",
        ["fan_belt", "alternator", "battery", "starter_motor"],
    ),
    (
        "ATとエンジン同時不調",
        "SUV",
        "2系統",
        ["transmission_oil", "engine_oil", "oil_filter", "air_filter"],
    ),
    (
        "排ガス/燃費悪化",
        "SUV",
        "空気+燃料+排気",
        ["catalytic_conv", "exhaust_pipe", "fuel_filter", "air_filter"],
    ),
    (
        "上り+シフト鈍い",
        "SUV",
        "Dトレイン要確認",
        ["clutch", "transmission_oil", "shock_absorber", "tire"],
    ),
    (
        "下回り点検一括",
        "SUV",
        "走行・足・排気",
        ["suspension", "tire", "exhaust_pipe", "wheel_alignment"],
    ),
    (
        "前照+雨天",
        "国産SUV",
        "可視+ワイパ",
        ["headlight_bulb", "wiper_blade", "power_steering", "fuse"],
    ),
    (
        "ブレーキ+ハンドル",
        "SUV",
        "制御と幾何",
        ["brake_fluid", "brake_disc", "wheel_alignment", "power_steering"],
    ),
    (
        "オイル+ベルト+発電",
        "セダン",
        "前側補助系",
        ["engine_oil", "fan_belt", "alternator", "starter_motor"],
    ),
    (
        "冷却+エア+点火",
        "SUV",
        "熱と燃焼",
        ["coolant", "radiator", "spark_plug", "air_filter"],
    ),
    (
        "燃料+排ガス+触媒",
        "国産SUV",
        "系統圧力",
        ["fuel_pump", "fuel_filter", "catalytic_conv", "exhaust_pipe"],
    ),
    (
        "足回り+タイヤ+減衰",
        "SUV",
        "接地",
        ["suspension", "shock_absorber", "tire", "wheel_alignment"],
    ),
    (
        "オイル+フィルタ+点火+吸気",
        "軽四",
        "定番4点",
        ["engine_oil", "oil_filter", "air_filter", "spark_plug"],
    ),
    (
        "エンジンルーム総ざらい",
        "国産SUV",
        "消耗まとめ",
        ["engine_oil", "oil_filter", "battery", "air_filter"],
    ),
    (
        "冬季スタート不調",
        "軽SUV",
        "電源と点火",
        ["battery", "spark_plug", "starter_motor", "engine_oil"],
    ),
    (
        "減速ジワつき+異音",
        "セダン",
        "足+制動",
        ["suspension", "brake_pad", "tire", "shock_absorber"],
    ),
    (
        "水回り+エア+ベルト",
        "SUV",
        "前側一括",
        ["water_pump", "thermostat", "coolant", "fan_belt"],
    ),
    (
        "AT異音+吹き抜け弱",
        "SUV",
        "AT+吸気",
        ["transmission_oil", "air_filter", "spark_plug", "fuel_filter"],
    ),
    (
        "排ガス+燃費+匂い",
        "SUV",
        "燃焼後",
        ["exhaust_pipe", "catalytic_conv", "air_filter", "engine_oil"],
    ),
    (
        "上り+クラッチ粘り",
        "国産SUV",
        "Dトレイン",
        ["clutch", "transmission_oil", "suspension", "tire"],
    ),
    (
        "可視+電装",
        "SUV",
        "灯+ヒューズ",
        ["headlight_bulb", "fuse", "wiper_blade", "battery"],
    ),
    (
        "パワセフ漏れ+操舵重",
        "SUV",
        "油圧+幾何",
        ["power_steering", "wheel_alignment", "tire", "brake_fluid"],
    ),
    (
        "小刻み水漏れ+水温",
        "SUV",
        "冷却",
        ["radiator", "thermostat", "coolant", "exhaust_pipe"],
    ),
    (
        "減速ブレ+振れ+鳴",
        "セダン",
        "円盤+足",
        ["brake_disc", "brake_pad", "suspension", "wheel_alignment"],
    ),
    (
        "高回転不味",
        "SUV",
        "点火+燃料+吸気",
        ["spark_plug", "fuel_pump", "air_filter", "oil_filter"],
    ),
    (
        "出だし鈍+始動遅",
        "軽SUV",
        "初動",
        ["starter_motor", "battery", "engine_oil", "alternator"],
    ),
    (
        "長距離前点検",
        "国産SUV",
        "定番+タイヤ",
        ["tire", "brake_fluid", "air_filter", "shock_absorber"],
    ),
    (
        "多発不調 総点検",
        "SUV",
        "冷却制動併走",
        ["brake_pad", "coolant", "radiator", "spark_plug", "tire"],
    ),
]

HARD: list[tuple[str, str, str, list[str]]] = [
    (
        "総合: 起動+走行+排気+冷却",
        "SUV",
        "フロント全般",
        [
            "battery",
            "starter_motor",
            "alternator",
            "engine_oil",
            "oil_filter",
            "air_filter",
            "spark_plug",
        ],
    ),
    (
        "総合: 足+制動+幾何",
        "SUV",
        "接地と減速",
        [
            "suspension",
            "shock_absorber",
            "tire",
            "wheel_alignment",
            "brake_pad",
            "brake_disc",
        ],
    ),
    (
        "水回りフル+ベルト",
        "国産SUV",
        "冷却/駆動補助",
        [
            "thermostat",
            "radiator",
            "water_pump",
            "coolant",
            "fan_belt",
            "alternator",
        ],
    ),
    (
        "燃料系フル+排ガス",
        "SUV",
        "圧力と後処理",
        [
            "fuel_pump",
            "fuel_filter",
            "catalytic_conv",
            "exhaust_pipe",
            "air_filter",
            "engine_oil",
        ],
    ),
    (
        "Dトレイン+潤滑",
        "SUV",
        "動力系",
        [
            "clutch",
            "transmission_oil",
            "engine_oil",
            "oil_filter",
            "spark_plug",
        ],
    ),
    (
        "可視+電装+制動感",
        "SUV",
        "安全一式",
        [
            "headlight_bulb",
            "fuse",
            "wiper_blade",
            "brake_fluid",
            "power_steering",
        ],
    ),
    (
        "多地点リーク想定",
        "国産SUV",
        "冷却/油/燃料匂",
        [
            "coolant",
            "water_pump",
            "engine_oil",
            "oil_filter",
            "fuel_filter",
        ],
    ),
    (
        "減速と操舵同時不調",
        "セダン",
        "圧/幾何",
        [
            "brake_pad",
            "brake_disc",
            "tire",
            "wheel_alignment",
            "suspension",
        ],
    ),
    (
        "出荷前一括点検(重)",
        "SUV",
        "既定6点",
        [
            "air_filter",
            "spark_plug",
            "battery",
            "radiator",
            "thermostat",
            "exhaust_pipe",
        ],
    ),
    (
        "高負荷後点検(重)",
        "国産SUV",
        "熱+摩擦",
        [
            "transmission_oil",
            "engine_oil",
            "brake_fluid",
            "tire",
            "coolant",
            "fan_belt",
        ],
    ),
    (
        "長距離+山岳",
        "SUV",
        "冷却+ブレ+点火",
        [
            "spark_plug",
            "air_filter",
            "fuel_pump",
            "brake_disc",
            "brake_pad",
        ],
    ),
    (
        "多症状の寄せ集め(重)",
        "SUV",
        "混合5",
        [
            "shock_absorber",
            "suspension",
            "tire",
            "wheel_alignment",
            "exhaust_pipe",
        ],
    ),
    (
        "倉庫戻り車 総仕上げ(重)",
        "国産SUV",
        "7項目",
        [
            "engine_oil",
            "transmission_oil",
            "coolant",
            "brake_fluid",
            "battery",
            "alternator",
            "headlight_bulb",
        ],
    ),
    (
        "前後ブレ+足(重)",
        "SUV",
        "6枠",
        [
            "brake_pad",
            "brake_disc",
            "brake_fluid",
            "suspension",
            "tire",
            "shock_absorber",
        ],
    ),
    (
        "燃焼系詳細(重)",
        "SUV",
        "5+2",
        [
            "spark_plug",
            "air_filter",
            "fuel_filter",
            "catalytic_conv",
            "exhaust_pipe",
            "oil_filter",
        ],
    ),
    (
        "冷間始動(重)",
        "軽SUV",
        "6系",
        [
            "battery",
            "starter_motor",
            "engine_oil",
            "coolant",
            "thermostat",
            "water_pump",
        ],
    ),
    (
        "高湿度地域向け(重)",
        "SUV",
        "排気+潤+拭き",
        [
            "air_filter",
            "catalytic_conv",
            "exhaust_pipe",
            "engine_oil",
            "oil_filter",
            "wiper_blade",
        ],
    ),
    (
        "多地点リーク(重)B",
        "SUV",
        "油水燃料",
        [
            "engine_oil",
            "transmission_oil",
            "power_steering",
            "water_pump",
            "coolant",
            "radiator",
        ],
    ),
    (
        "Dレンジフル(重)",
        "SUV",
        "6枠",
        [
            "clutch",
            "transmission_oil",
            "engine_oil",
            "shock_absorber",
            "suspension",
            "tire",
        ],
    ),
    (
        "高速巡航後(重)",
        "SUV",
        "熱+潤+摩擦",
        [
            "engine_oil",
            "oil_filter",
            "air_filter",
            "transmission_oil",
            "tire",
            "brake_fluid",
        ],
    ),
    (
        "街乗り慢性(重)",
        "SUV",
        "6枠 燃焼+排ガス",
        [
            "spark_plug",
            "fuel_pump",
            "fuel_filter",
            "air_filter",
            "catalytic_conv",
            "exhaust_pipe",
        ],
    ),
    (
        "エンジン前側まとめ(重)",
        "SUV",
        "ベルト+補助+水",
        [
            "fan_belt",
            "alternator",
            "starter_motor",
            "water_pump",
            "thermostat",
            "coolant",
        ],
    ),
    (
        "可視+操舵(重)",
        "SUV",
        "5点+タイヤ幾何",
        [
            "headlight_bulb",
            "fuse",
            "wiper_blade",
            "power_steering",
            "wheel_alignment",
            "tire",
        ],
    ),
    (
        "多地点サビ車(重)",
        "SUV",
        "足+排気+摩擦",
        [
            "suspension",
            "tire",
            "brake_disc",
            "exhaust_pipe",
            "catalytic_conv",
            "fuel_filter",
        ],
    ),
    (
        "シフト+加速(重)",
        "SUV",
        "3+3",
        [
            "clutch",
            "transmission_oil",
            "engine_oil",
            "air_filter",
            "spark_plug",
            "fuel_pump",
        ],
    ),
    (
        "冷却+ブレ(重) 複合",
        "国産SUV",
        "熱+減速",
        [
            "coolant",
            "radiator",
            "thermostat",
            "brake_fluid",
            "brake_pad",
            "brake_disc",
        ],
    ),
    (
        "電装多発(重)",
        "SUV",
        "5枠 電",
        [
            "battery",
            "alternator",
            "starter_motor",
            "fuse",
            "headlight_bulb",
        ],
    ),
    (
        "長期放置車(重)",
        "SUV",
        "6枠 総点検",
        [
            "engine_oil",
            "transmission_oil",
            "battery",
            "brake_fluid",
            "tire",
            "air_filter",
        ],
    ),
    (
        "オールマイティ(重) A",
        "SUV",
        "7枠",
        [
            "engine_oil",
            "oil_filter",
            "air_filter",
            "spark_plug",
            "fuel_pump",
            "brake_pad",
            "tire",
        ],
    ),
    (
        "オールマイティ(重) B",
        "SUV",
        "7枠+冷却",
        [
            "coolant",
            "water_pump",
            "fan_belt",
            "alternator",
            "battery",
            "suspension",
            "exhaust_pipe",
        ],
    ),
]

ALLOWED = {
    "engine_oil",
    "oil_filter",
    "air_filter",
    "spark_plug",
    "battery",
    "alternator",
    "starter_motor",
    "brake_pad",
    "brake_disc",
    "brake_fluid",
    "tire",
    "wheel_alignment",
    "suspension",
    "shock_absorber",
    "coolant",
    "radiator",
    "thermostat",
    "fan_belt",
    "timing_belt",
    "water_pump",
    "fuel_filter",
    "fuel_pump",
    "exhaust_pipe",
    "catalytic_conv",
    "transmission_oil",
    "clutch",
    "power_steering",
    "wiper_blade",
    "headlight_bulb",
    "fuse",
}


def validate(name: str, rows: list[tuple[str, str, str, list[str]]]) -> None:
    assert len(rows) == 30, f"{name} expect 30, got {len(rows)}"
    for i, (s, v, d, a) in enumerate(rows, 1):
        for x in a:
            assert x in ALLOWED, f"{name} row {i} bad id {x}"


def main() -> None:
    data_dir = os.path.join(ROOT, "data")
    os.makedirs(data_dir, exist_ok=True)
    validate("EASY", EASY)
    validate("MEDIUM", MEDIUM)
    validate("HARD", HARD)
    with open(os.path.join(data_dir, "slips_easy.lua"), "w", encoding="utf-8") as f:
        write_block(f, "Config.Slips", EASY)
    with open(os.path.join(data_dir, "slips_medium.lua"), "w", encoding="utf-8") as f:
        write_block(f, "Config.SlipsMedium", MEDIUM)
    with open(os.path.join(data_dir, "slips_hard.lua"), "w", encoding="utf-8") as f:
        write_block(f, "Config.SlipsHard", HARD)
    print("Wrote data/slips_*.lua (3 files)")


if __name__ == "__main__":
    main()
