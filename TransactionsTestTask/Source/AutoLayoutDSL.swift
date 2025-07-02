//
//  AutoLayoutDSL.swift
//  AutoLayoutDSL
//
//  Created by Oleh Yeroshkin on 23.06.2024.
//

///
/// Custom DSL for AutoLayout
///
/// **PURPOSE**
///
/// The purpose of this DSL is to simplify working with AutoLayout in Swift without relying on external libraries. It provides a more readable and concise way to define constraints programmatically.
///
/// **Simplified Constraint Definition**
///
/// With this DSL, you can replace the verbose standard AutoLayout code:
///
/// NSLayoutConstraint.activate([
///     myView.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 20),
///     myView.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -20),
///     myView.topAnchor.constraint(equalTo: superview.topAnchor, constant: 20),
///     myView.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -20)
/// ])
///
/// with a more readable syntax:
///
/// myView.layout(in: superview) {
///     $0.leading == superview.leadingAnchor + 20
///     $0.trailing == superview.trailingAnchor - 20
///     $0.top == superview.topAnchor + 20
///     $0.bottom == superview.bottomAnchor - 20
/// }
///
/// **CONSTRAINT TYPES**
///
/// With this DSL, you can easily define and assign various types of constraints to position and size your views. The following constraints can be assigned:
///
/// - **Leading and Trailing Anchors**: These define the horizontal edges of a view.
///   $0.leading == anotherView.leadingAnchor + 20
///   $0.trailing == anotherView.trailingAnchor - 20
///
/// - **Top and Bottom Anchors**: These define the vertical edges of a view.
///   $0.top == anotherView.topAnchor + 20
///   $0.bottom == anotherView.bottomAnchor - 20
///
/// - **Width and Height Anchors**: These define the dimensions of a view.
///   $0.width == 100
///   $0.height == 100
///
/// - **CenterX and CenterY Anchors**: These define the horizontal and vertical center alignment of a view.
///   $0.centerX == anotherView.centerXAnchor
///   $0.centerY == anotherView.centerYAnchor
///
/// **CUSTOM OPERATORS**
///
/// The DSL includes custom operators to handle various constraint types, making the syntax even more intuitive:
///
/// - **Equal to**`: ==
/// - **Greater than or equal to**: >=
/// - **Less than or equal to**: <=
/// - **Multiplication for dimensions**: *=
///
/// myView.layout(in: superview) {
///     $0.leading >= superview.leadingAnchor + 20
///     $0.trailing <= superview.trailingAnchor
///     $0.top >= superview.topAnchor + 20
///     $0.bottom <= superview.bottomAnchor
/// }
///
/// The `*=` operator allows you to define width and height constraints as a multiple of another dimension. It is important to use the `*` operator to specify the multiplier value, which makes the syntax clear and expressive.
///
/// someView.layout(in: instrumentsView) {
///     $0.width *= otherView.widthAnchor * 0.6      // someView's width will be 0.6 times otherView's width
///     $0.height == $0.width          // Height equal to width
/// }
///
/// In this example:
/// - someView.widthAnchor is set to 60% of otherView.widthAnchor.
/// - The `*` operator is essential to indicate the multiplier value, which follows the `*=` operator.
///
/// **PRIORITY CUSTOMIZATION**
///
/// A custom operator `~` allows you to specify layout priorities:
///
/// resizeGestureView.layout(in: view) {
///     $0.top == topAnchor - 16 ~ .defaultHigh
///     $0.leading == leadingAnchor - 16 ~ .defaultHigh
///     $0.trailing == trailingAnchor + 16 ~ .defaultHigh
///     $0.bottom == bottomAnchor ~ .defaultLow
///     $0.width >= 150
///     $0.height >= 100
///     $0.centerX == centerXAnchor
///     $0.centerY == centerYAnchor
/// }
///
/// **CONSTRAINT STORAGE**
///
/// Constraints can be assigned to variables for later modification if needed. The DSL allows for this by returning an active constraint from the constraint expression, which can be stored in a variable. This is useful when you need to modify or deactivate a specific constraint later in your code. The returned constraint is also marked as a discardable result, meaning you can choose to ignore it if you don’t need to keep a reference to it.
///
/// var someTopConstraint: NSLayoutConstraint?
///
/// myView.layout(in: anotherView) {
///     someTopConstraint = $0.top == anotherView.topAnchor + 20
///     $0.leading >= anotherView.leadingAnchor + 20
///     $0.trailing == anotherView.trailingAnchor - 20
///     $0.bottom == anotherView.bottomAnchor - 20
/// }
///
/// In this example:
/// - The top constraint for `myView` is assigned to the variable `someTopConstraint`.
/// - The DSL expression `$0.top == anotherView.topAnchor + 20` returns an active `NSLayoutConstraint`, which can be stored in `someTopConstraint`.
/// - You can later modify or deactivate `someTopConstraint` as needed.
///

import UIKit

@MainActor
protocol LayoutAnchor {

    func constraint(equalTo anchor: Self, constant: CGFloat) -> NSLayoutConstraint
    func constraint(greaterThanOrEqualTo anchor: Self, constant: CGFloat) -> NSLayoutConstraint
    func constraint(lessThanOrEqualTo anchor: Self, constant: CGFloat) -> NSLayoutConstraint
}

@MainActor
protocol LayoutDimension: LayoutAnchor {

    func constraint(equalToConstant constant: CGFloat) -> NSLayoutConstraint
    func constraint(greaterThanOrEqualToConstant constant: CGFloat) -> NSLayoutConstraint
    func constraint(lessThanOrEqualToConstant constant: CGFloat) -> NSLayoutConstraint

    func constraint(equalTo anchor: Self, multiplier: CGFloat) -> NSLayoutConstraint
}

extension NSLayoutAnchor: LayoutAnchor {}
extension NSLayoutDimension: LayoutDimension {}

@MainActor
class LayoutProperty<Anchor: LayoutAnchor> {

    fileprivate let anchor: Anchor
    fileprivate let kind: Kind

    enum Kind { case leading, trailing, top, bottom, centerX, centerY, width, height }

    init(anchor: Anchor, kind: Kind) {
        self.anchor = anchor
        self.kind = kind
    }
}

@MainActor
class LayoutAttribute<Dimension: LayoutDimension>: LayoutProperty<Dimension> {

    fileprivate let dimension: Dimension

    init(dimension: Dimension, kind: Kind) {
        self.dimension = dimension

        super.init(anchor: dimension, kind: kind)
    }
}

@MainActor
final class LayoutProxy {

    lazy var leading = property(with: view.leadingAnchor, kind: .leading)
    lazy var trailing = property(with: view.trailingAnchor, kind: .trailing)
    lazy var top = property(with: view.topAnchor, kind: .top)
    lazy var bottom = property(with: view.bottomAnchor, kind: .bottom)
    lazy var centerX = property(with: view.centerXAnchor, kind: .centerX)
    lazy var centerY = property(with: view.centerYAnchor, kind: .centerY)
    lazy var width = attribute(with: view.widthAnchor, kind: .width)
    lazy var height = attribute(with: view.heightAnchor, kind: .height)

    private let view: UIView

    fileprivate init(view: UIView) {
        self.view = view
    }

    private func property<A: LayoutAnchor>(with anchor: A, kind: LayoutProperty<A>.Kind) -> LayoutProperty<A> {
        return LayoutProperty(anchor: anchor, kind: kind)
    }

    private func attribute<D: LayoutDimension>(with dimension: D, kind: LayoutProperty<D>.Kind) -> LayoutAttribute<D> {
        return LayoutAttribute(dimension: dimension, kind: kind)
    }
}

extension LayoutAttribute {

    @discardableResult
    func equal(to constant: CGFloat, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        let constraint = dimension.constraint(equalToConstant: constant)
        if let priority = priority {
            constraint.priority = priority
        }
        constraint.isActive = true
        return constraint
    }

    @discardableResult
    func equal(to otherDimension: Dimension,
               multiplier: CGFloat,
               priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        let constraint = dimension.constraint(equalTo: otherDimension, multiplier: multiplier)
        if let priority = priority {
            constraint.priority = priority
        }
        constraint.isActive = true
        return constraint
    }

    @discardableResult
    func greaterThanOrEqual(to constant: CGFloat, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        let constraint = dimension.constraint(greaterThanOrEqualToConstant: constant)
        if let priority = priority {
            constraint.priority = priority
        }
        constraint.isActive = true
        return constraint
    }

    @discardableResult
    func lessThanOrEqual(to constant: CGFloat, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        let constraint = dimension.constraint(lessThanOrEqualToConstant: constant)
        if let priority = priority {
            constraint.priority = priority
        }
        constraint.isActive = true
        return constraint
    }
}

extension LayoutProperty {

    @discardableResult
    func equal(to otherAnchor: Anchor,
               offsetBy constant: CGFloat = 0,
               priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        let constraint = anchor.constraint(equalTo: otherAnchor, constant: constant)
        if let priority = priority {
            constraint.priority = priority
        }
        constraint.isActive = true
        return constraint
    }

    @discardableResult
    func greaterThanOrEqual(to otherAnchor: Anchor,
                            offsetBy constant: CGFloat = 0,
                            priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        let constraint = anchor.constraint(greaterThanOrEqualTo: otherAnchor, constant: constant)
        if let priority = priority {
            constraint.priority = priority
        }
        constraint.isActive = true
        return constraint
    }

    @discardableResult
    func lessThanOrEqual(to otherAnchor: Anchor,
                         offsetBy constant: CGFloat = 0,
                         priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        let constraint = anchor.constraint(lessThanOrEqualTo: otherAnchor, constant: constant)
        if let priority = priority {
            constraint.priority = priority
        }
        constraint.isActive = true
        return constraint
    }
}

// MARK: - UIView Extension

extension UIView {

    /// Layout without adding to superview.
    func layout(using closure: (LayoutProxy) -> Void) {
        translatesAutoresizingMaskIntoConstraints = false
        closure(LayoutProxy(view: self))
    }

    /// Added as subview to `superview` and setup constraints.
    func layout(in superview: UIView, using closure: (LayoutProxy) -> Void) {
        superview.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        closure(LayoutProxy(view: self))
    }

    /// Layout in superview's bounds without adding to subviews.
    func layout(to superview: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        layout { proxy in
            proxy.bottom == superview.bottomAnchor
            proxy.top == superview.topAnchor
            proxy.leading == superview.leadingAnchor
            proxy.trailing == superview.trailingAnchor
        }
    }

    /// Add this view to superview and clip it edges. Can set custom insets for each side.
    func layout(in superview: UIView, with insets: UIEdgeInsets = .zero) {
        superview.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        layout { proxy in
            proxy.bottom == superview.bottomAnchor - insets.bottom
            proxy.top == superview.topAnchor + insets.top
            proxy.leading == superview.leadingAnchor + insets.left
            proxy.trailing == superview.trailingAnchor - insets.right
        }
    }

    /// Added as subview to `superview` and clipped to its `safeAreaLayoutGuide`.
    func layoutToSafeArea(in superview: UIView) {
        superview.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        layout { proxy in
            proxy.bottom == superview.safeAreaLayoutGuide.bottomAnchor
            proxy.top == superview.safeAreaLayoutGuide.topAnchor
            proxy.leading == superview.safeAreaLayoutGuide.leadingAnchor
            proxy.trailing == superview.safeAreaLayoutGuide.trailingAnchor
        }
    }

    /// Added as subview to `superview` and set custom inset for all edges.
    func layout(in superview: UIView, allEdges insets: CGFloat) {
        superview.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        layout { proxy in
            proxy.bottom == superview.bottomAnchor - insets
            proxy.top == superview.topAnchor + insets
            proxy.leading == superview.leadingAnchor + insets
            proxy.trailing == superview.trailingAnchor - insets
        }
    }
}

// MARK: - Operators

func + <A: LayoutAnchor>(lhs: A, rhs: CGFloat) -> (A, CGFloat) {
    return (lhs, rhs)
}

func * <A: LayoutDimension>(lhs: A, rhs: CGFloat) -> (A, CGFloat) {
    return (lhs, rhs)
}

func - <A: LayoutAnchor>(lhs: A, rhs: CGFloat) -> (A, CGFloat) {
    return (lhs, -rhs)
}

/// Custom operator for UILayoutPriority.
/// Example:
/// myView.layout(in: view) {
///    $0.top == view.topAnchor
///    $0.bottom <= view.bottomAnchor - 20
///    $0.bottom == anotherView.bottomAnchor + 20 ~ .defaultHigh
///    $0.leading == view.leadingAnchor + 10
///    $0.trailing == view.trailingAnchor - 10
/// }
infix operator ~: AdditionPrecedence

func ~ <A: LayoutAnchor>(lhs: A, rhs: UILayoutPriority) -> (A, UILayoutPriority) {
    return (lhs, rhs)
}

func ~ <A: LayoutAnchor>(lhs: (A, CGFloat), rhs: UILayoutPriority) -> ((A, CGFloat), UILayoutPriority) {
    return (lhs, rhs)
}

func ~ (lhs: CGFloat, rhs: UILayoutPriority) -> (CGFloat, UILayoutPriority) {
    return (lhs, rhs)
}


// MARK: - ==

@MainActor
@discardableResult
func == <A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: (A, CGFloat)) -> NSLayoutConstraint {
    return lhs.equal(to: rhs.0, offsetBy: rhs.1)
}

@MainActor
@discardableResult
func == <A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: ((A, CGFloat), UILayoutPriority)) -> NSLayoutConstraint {
    return lhs.equal(to: rhs.0.0, offsetBy: rhs.0.1, priority: rhs.1)
}

@MainActor
@discardableResult
func == <A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: (A, UILayoutPriority)) -> NSLayoutConstraint {
    return lhs.equal(to: rhs.0, priority: rhs.1)
}

@MainActor
@discardableResult
func == <A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: A) -> NSLayoutConstraint {
    return lhs.equal(to: rhs)
}

// MARK: - >=

@MainActor
@discardableResult
func >= <A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: A) -> NSLayoutConstraint {
    return lhs.greaterThanOrEqual(to: rhs)
}

@MainActor
@discardableResult
func >= <A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: (A, CGFloat)) -> NSLayoutConstraint {
    return lhs.greaterThanOrEqual(to: rhs.0, offsetBy: rhs.1)
}

@MainActor
@discardableResult
func >= <A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: ((A, CGFloat), UILayoutPriority)) -> NSLayoutConstraint {
    return lhs.greaterThanOrEqual(to: rhs.0.0, offsetBy: rhs.0.1, priority: rhs.1)
}

@MainActor
@discardableResult
func >= <A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: (A, UILayoutPriority)) -> NSLayoutConstraint {
    return lhs.lessThanOrEqual(to: rhs.0, priority: rhs.1)
}

// MARK: - <=

@MainActor
@discardableResult
func <= <A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: A) -> NSLayoutConstraint {
    return lhs.lessThanOrEqual(to: rhs)
}

@MainActor
@discardableResult
func <= <A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: (A, CGFloat)) -> NSLayoutConstraint {
    return lhs.lessThanOrEqual(to: rhs.0, offsetBy: rhs.1)
}

@MainActor
@discardableResult
func <= <A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: ((A, CGFloat), UILayoutPriority)) -> NSLayoutConstraint {
    return lhs.lessThanOrEqual(to: rhs.0.0, offsetBy: rhs.0.1, priority: rhs.1)
}

@MainActor
@discardableResult
func <= <A: LayoutAnchor>(lhs: LayoutProperty<A>, rhs: (A, UILayoutPriority)) -> NSLayoutConstraint {
    return lhs.lessThanOrEqual(to: rhs.0, priority: rhs.1)
}

// MARK: - Dimensions
// MARK: - ==

@MainActor
@discardableResult
func == <D: LayoutDimension>(lhs: LayoutAttribute<D>, rhs: CGFloat) -> NSLayoutConstraint {
    return lhs.equal(to: rhs)
}

@MainActor
@discardableResult
func == <D: LayoutDimension>(lhs: LayoutAttribute<D>, rhs: (CGFloat, UILayoutPriority)) -> NSLayoutConstraint {
    return lhs.equal(to: rhs.0, priority: rhs.1)
}

@MainActor
@discardableResult
func == <D: LayoutDimension>(lhs: LayoutAttribute<D>, rhs: LayoutAttribute<D>) -> NSLayoutConstraint {
    return lhs.equal(to: rhs.dimension)
}

// MARK: - *= Multiply

@MainActor
@discardableResult
func *= <D: LayoutDimension>(lhs: LayoutAttribute<D>, rhs: (D, CGFloat)) -> NSLayoutConstraint {
    return lhs.equal(to: rhs.0, multiplier: rhs.1)
}

@MainActor
@discardableResult
func *= <D: LayoutDimension>(lhs: LayoutAttribute<D>, rhs: (LayoutAttribute<D>, CGFloat)) -> NSLayoutConstraint {
    return lhs.equal(to: rhs.0.dimension, multiplier: rhs.1)
}

@MainActor
@discardableResult
func *= <D: LayoutDimension>(lhs: LayoutAttribute<D>, rhs: (LayoutAttribute<D>)) -> NSLayoutConstraint {
    return NSLayoutConstraint()
}

@MainActor
@discardableResult
func *= <D: LayoutDimension>(lhs: LayoutAttribute<D>,
                             rhs: ((D, CGFloat), UILayoutPriority)) -> NSLayoutConstraint {
    return lhs.equal(to: rhs.0.0, multiplier: rhs.0.1, priority: rhs.1)
}

// MARK: - >=

@MainActor
@discardableResult
func >= <D: LayoutDimension>(lhs: LayoutAttribute<D>, rhs: CGFloat) -> NSLayoutConstraint {
    return lhs.greaterThanOrEqual(to: rhs)
}

@MainActor
@discardableResult
func >= <D: LayoutDimension>(lhs: LayoutAttribute<D>, rhs: (CGFloat, UILayoutPriority)) -> NSLayoutConstraint {
    return lhs.greaterThanOrEqual(to: rhs.0, priority: rhs.1)
}

// MARK: - <=

@MainActor
@discardableResult
func <= <D: LayoutDimension>(lhs: LayoutAttribute<D>, rhs: CGFloat) -> NSLayoutConstraint {
    return lhs.lessThanOrEqual(to: rhs)
}

@MainActor
@discardableResult
func <= <D: LayoutDimension>(lhs: LayoutAttribute<D>, rhs: (CGFloat, UILayoutPriority)) -> NSLayoutConstraint {
    return lhs.lessThanOrEqual(to: rhs.0, priority: rhs.1)
}
