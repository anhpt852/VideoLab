//
//  VLEEffectItemModel.swift
//  VideoLab_Example
//
//  Created by Kay on 2022/10/9.
//  Copyright © 2022 Chocolate. All rights reserved.
//

import Foundation

enum VLEEffectFirstLevelItemType {
    case canvas
    case text
    case sticker
    case audio
    case filter
    case specialeffect
}

class VLEEffectItemModel {
    
    static let kIconKey = "icon"
    static let kIconType = "type"
    static let kIconTitleKey = "iconTitle"

    let firstLevelItemArray = [[kIconKey: "effect_level1_canvas", kIconTitleKey: "Canvas", kIconType: VLEEffectFirstLevelItemType.canvas],
                               [kIconKey: "effect_level1_text", kIconTitleKey: "Text", kIconType: VLEEffectFirstLevelItemType.text],
                               [kIconKey: "effect_level1_sticker", kIconTitleKey: "Sticker", kIconType:  VLEEffectFirstLevelItemType.sticker],
                               [kIconKey: "effect_level1_audio", kIconTitleKey: "Audio", kIconType: VLEEffectFirstLevelItemType.audio],
                               [kIconKey: "effect_level1_filter", kIconTitleKey: "Filter", kIconType:VLEEffectFirstLevelItemType.filter],
                               [kIconKey: "effect_level1_specialeffect", kIconTitleKey: "Special Effects", kIconType: VLEEffectFirstLevelItemType.specialeffect]]
}
