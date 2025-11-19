//
//  ShamCRMWidgetBundle.swift
//  ShamCRMWidget
//
//  Created by fingroupMac on 08.11.2025.
//

import WidgetKit
import SwiftUI

@main
struct ShamCRMWidgetBundle: WidgetBundle {
    var body: some Widget {
        ShamCRMWidget()
        ShamCRMWidgetControl()
        ShamCRMWidgetLiveActivity()
    }
}
