//
//  UIButton+Ext.swift
//  TransactionsTestTask
//
//  Created by Oleh Yeroshkin on 02.07.2025.
//

import UIKit

extension UIButton {
    func onTapEvent(event: UIControl.Event = .touchUpInside, handler: @escaping () -> Void) {
        addAction(UIAction { _ in
            handler()
        }, for: event)
    }
}
