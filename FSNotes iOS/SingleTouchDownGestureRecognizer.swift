//
//  SingleTouchDownGestureRecognizer.swift
//  FSNotes iOS
//
//  Created by Oleksandr Glushchenko on 8/30/18.
//  Copyright © 2018 Oleksandr Glushchenko. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass

class SingleTouchDownGestureRecognizer: UIGestureRecognizer {
    private var beginTimer: Timer?
    private var beginTime: Date?
    public var isLongPress: Bool = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if touches.count > 1 {
            self.state = .failed
            invalidateTimer()
        }

        if self.state == .possible {
            for touch in touches {
                guard let view = self.view as? EditTextView else { continue }

                if UIMenuController.shared.isMenuVisible {
                    UIMenuController.shared.setMenuVisible(false, animated: false)
                }

                let point = touch.location(in: view)
                let glyphIndex = view.layoutManager.glyphIndex(for: point, in: view.textContainer)

                if view.isTodo(at: glyphIndex) {
                    self.state = .possible
                    return
                }

                let location = touch.location(in: view)
                let maxX = Int(view.frame.width - 25)
                let minX = Int(25)

                let isImage = view.isImage(at: glyphIndex)
                let glyphRect = view.layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: view.textContainer)

                if isImage, glyphIndex < view.textStorage.length, glyphRect.contains(point) {
                    if Int(location.x) > minX && Int(location.x) < maxX {
                        if !view.isFirstResponder {
                            beginTimer?.invalidate()
                            beginTimer = Timer.scheduledTimer(timeInterval: 0.4,
                                                              target: self,
                                                              selector: #selector(endTimer),
                                                              userInfo: nil,
                                                              repeats: false)

                            beginTime = Date.init()
                        }

                        view.lasTouchPoint = touch.location(in: view.superview)
                        self.state = .possible
                        return
                    } else {
                        self.state = .failed
                        return
                    }
                }

                if !isImage && glyphRect.contains(point) && view.isLink(at: glyphIndex) {
                    self.state = .possible
                    return
                }
            }

            self.state = .failed
            invalidateTimer()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        invalidateTimer()
        isLongPress = false

        if self.state == .possible {
            for touch in touches {
                guard let view = self.view as? EditTextView else { continue }

                let characterIndex = view.layoutManager.characterIndex(for: touch.location(in: view), in: view.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

                if view.isImage(at: characterIndex) {
                    self.state = .recognized
                    return
                }

                let point = touch.location(in: view)
                let glyphIndex = view.layoutManager.glyphIndex(for: point, in: view.textContainer)
                if view.isTodo(at: glyphIndex) {
                    self.state = .recognized
                    return
                }

                let glyphRect = view.layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: view.textContainer)
                if glyphRect.contains(point) && view.isLink(at: glyphIndex) {
                    self.state = .recognized
                    return
                }
            }

            self.state = .failed
        }
    }

    @objc private func endTimer() {
        invalidateTimer()
        isLongPress = true

        if Date.init().timeIntervalSince(beginTime!) > 0.5 {
            self.state = .failed
            return
        }
        
        self.state = .recognized
    }

    private func invalidateTimer() {
        beginTimer?.invalidate()
        beginTimer = nil
    }

}
