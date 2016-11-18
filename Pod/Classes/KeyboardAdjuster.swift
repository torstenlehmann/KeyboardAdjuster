//
//  Copyright 2016 Lionheart Software LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  Modifications copyright (C) 2016 Torsten Lehmann
//

import UIKit

public class KeyboardAdjuster {
    
    enum KeyboardState {
        case hidden
        case visible
    }
    
    public weak var view: UIView?
    public var constraint: NSLayoutConstraint?
    public var animated: Bool
    
    public init(view: UIView? = nil, constraint: NSLayoutConstraint? = nil, animated: Bool = true) {
        self.view = view
        self.constraint = constraint
        self.animated = animated
    }
    
    /**
     Activates keyboard adjustment on the set view.
     
     - seealso: `activateKeyboardAdjuster(showBlock:hideBlock:)`
     - author: Daniel Loewenherz
     - copyright: ©2016 Lionheart Software LLC
     - date: February 18, 2016
     */
    public func activate() {
        activate(nil, hideBlock: nil)
    }
    
    /**
     Enable keyboard adjustment for the current view controller, providing optional closures to call when the keyboard appears and when it disappears.
     
     - parameter showBlock: (optional) a closure that's called when the keyboard appears
     - parameter hideBlock: (optional) a closure that's called when the keyboard disappears
     - author: Daniel Loewenherz
     - copyright: ©2016 Lionheart Software LLC
     - date: February 18, 2016
     */
    public func activate(_ showBlock: AnyObject?, hideBlock: AnyObject?) {
        // Activate the bottom constraint.
        constraint?.isActive = true
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: hideBlock)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: showBlock)
        
        guard let viewA = constraint?.firstItem as? UIView,
            let viewB = constraint?.secondItem as? UIView else {
                return
        }
        
        if viewB.subviews.contains(viewA) {
            assertionFailure("Please reverse the order of arguments in your keyboard Adjuster constraint.")
        }
    }
    
    /**
     Call this in your `viewDidDisappear` method for your `UIViewController`. This method removes any active keyboard observers from your view controller.
     
     - author: Daniel Loewenherz
     - copyright: ©2016 Lionheart Software LLC
     - date: February 18, 2016
     */
    public func deactivate() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    /**
     A callback that manages the bottom constraint before the keyboard is shown.
     
     - parameter sender: An `NSNotification` containing a `Dictionary` with information regarding the keyboard appearance.
     - author: Daniel Loewenherz
     - copyright: ©2016 Lionheart Software LLC
     - date: February 18, 2016
     */
    @objc func keyboardWillShow(_ sender: Notification) {
        keyboardWillChangeAppearance(sender, toState: .visible)
    }
    
    /**
     A callback that manages the bottom constraint when the keyboard is about to be hidden.
     
     - parameter sender: An `NSNotification` containing a `Dictionary` with information regarding the keyboard appearance.
     - author: Daniel Loewenherz
     - copyright: ©2016 Lionheart Software LLC
     - date: February 18, 2016
     */
    @objc func keyboardWillHide(_ sender: Notification) {
        keyboardWillChangeAppearance(sender, toState: .hidden)
    }
    
    private func keyboardWillChangeAppearance(_ sender: Notification, toState: KeyboardState) {
        guard
            let view = view,
            let constraint = constraint,
            let userInfo = (sender as NSNotification).userInfo as? [String: AnyObject],
            let _curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? Int,
            let curve = UIViewAnimationCurve(rawValue: _curve),
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double else {
                return
        }
        
        if let block = sender.object as? (() -> Void) {
            block()
        }
        
        var curveAnimationOption: UIViewAnimationOptions
        switch curve {
        case .easeIn:
            curveAnimationOption = .curveEaseIn
            
        case .easeInOut:
            curveAnimationOption = UIViewAnimationOptions()
            
        case .easeOut:
            curveAnimationOption = .curveEaseOut
            
        case .linear:
            curveAnimationOption = .curveLinear
        }
        
        switch toState {
        case .hidden:
            constraint.constant = 0
            
        case .visible:
            guard let value = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
                debugPrint("UIKeyboardFrameEndUserInfoKey not available.")
                break
            }
            
            let frame = value.cgRectValue
            let keyboardFrameInViewCoordinates = view.convert(frame, from: nil)
            constraint.constant = view.bounds.height - keyboardFrameInViewCoordinates.origin.y
        }
        
        if animated {
            let animationOptions: UIViewAnimationOptions = [UIViewAnimationOptions.beginFromCurrentState, curveAnimationOption]
            UIView.animate(withDuration: duration, delay: 0, options: animationOptions, animations: view.layoutIfNeeded, completion:nil)
        } else {
            view.layoutIfNeeded()
        }
    }
    
}
