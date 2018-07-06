// Copyright 2016-2017 Cisco Systems Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

func KTDegreesToRadians(_ d:CGFloat) -> CGFloat {
    return d * 0.0174532925199432958;
}

func KTRadiansToDegrees(_ r:CGFloat) -> CGFloat {
    return r * 57.29577951308232;
}

// MARK: CGPoint
extension CGPoint {
    public init(_ x: CGFloat, _ y: CGFloat) {
        self.x = x
        self.y = y
    }
    
    public init(_ x: Int, _ y: Int) {
        self.x = CGFloat(x);
        self.y = CGFloat(y);
    }
    
    public init(start:CGPoint, end:CGPoint) {
        self.x = (start.x + end.x) * 0.5;
        self.y = (start.y + end.y) * 0.5;
    }
    
    public func with(x: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: y)
    }
    
    public func with(y: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: y)
    }
    
    public func roundPoint() -> CGPoint {
        return CGPoint(round(x), round(y));
    }
    
    public func offset(offset:CGPoint) -> CGPoint {
        return CGPoint(x: self.x + offset.x, y: self.y + offset.y);
    }
    
    public func rotate(angle:Int, center:CGPoint) -> CGPoint {
        let radians = KTDegreesToRadians(CGFloat(angle));
        let ox = center.x;
        let oy = center.y;
        let px = self.x;
        let py = self.y;
        let x2 = cos(radians) * (px-ox) - sin(radians) * (py-oy) + ox;
        let y2 = sin(radians) * (px-ox) + cos(radians) * (py-oy) + oy;
        return CGPoint(x2, y2);
    }
    
    public func isInside(points:[CGPoint]) -> Bool {
        let rect = CGRect(points);
        if (!rect.contains(self)) {
            return false;
        }
        let path = UIBezierPath();
        if let first = points.first {
            path.move(to: first);
            let corners = points.count;
            if corners > 1 {
                for i in 1..<corners {
                    path.addLine(to: points[i]);
                }
            }
            path.addLine(to: first);
            path.close();
            return path.contains(self);
        }
        return false;
    }
    
    public func isInside(rect:CGRect, angle:Int) -> Bool {
        let center = rect.center;
        let points = [rect.topLeft.rotate(angle: angle, center: center),
                      rect.topRight.rotate(angle: angle, center: center),
                      rect.bottomRight.rotate(angle: angle, center: center),
                      rect.bottomLeft.rotate(angle: angle, center: center)];
        return self.isInside(points: points);
    }
    
    public func isBetween(p1:CGPoint, _ p2:CGPoint, margin:CGFloat) -> Bool {
        let xDelta = p2.x - p1.x;
        if (xDelta == 0 && (abs(self.x - p1.x) <= margin)) {
            return true;
        }
        else {
            let lac = sqrt(pow((p1.x - p2.x), 2) + pow((p1.y - p2.y), 2));
            let lbc = sqrt(pow((self.x - p2.x), 2) + pow((self.y - p2.y), 2));
            let lab = sqrt(pow((p1.x - self.x), 2) + pow((p1.y - self.y), 2));
            if (lab + lbc < lac + margin) {
                return true;
            }
        }
        return false;
    }
    
    public func distance(point:CGPoint) -> Float {
        return sqrtf(powf(Float(point.x - self.x), 2) + powf(Float(point.y - self.y), 2));
    }
    
}

// MARK: CGSize

extension CGSize {
    public init(_ width: CGFloat, _ height: CGFloat) {
        self.width = width
        self.height = height
    }
    
    public init(_ width: Int, _ height: Int) {
        self.width = CGFloat(width);
        self.height = CGFloat(height);
    }
    
    /// Returns a copy with the width value changed.
    public func with(width: CGFloat) -> CGSize {
        return CGSize(width: width, height: height)
    }
    /// Returns a copy with the height value changed.
    public func with(height: CGFloat) -> CGSize {
        return CGSize(width: width, height: height)
    }
    
    public func bigger(size:CGSize) -> CGSize {
        var ret = self;
        if (ret.width < size.width) {
            ret.width = size.width;
        }
        if (ret.height < size.height) {
            ret.height = size.height;
        }
        return ret;
    }
    
    public func sizeByAspectScaledToFitSize(size:CGSize, keepIfSmall:Bool = false) -> CGSize {
        if (keepIfSmall) {
            if (self.width == 0 || self.height == 0) {
                return self;
            }
            if (self.width <= size.width && self.height <= size.height) {
                return self;
            }
        }
        let origAspectRatio = self.width / self.height
        let targetAspectRatio = size.width / size.height
        var resizeFactor: CGFloat
        if origAspectRatio > targetAspectRatio {
            resizeFactor = size.width / self.width
        }
        else {
            resizeFactor = size.height / self.height
        }
        return CGSize(width: self.width * resizeFactor, height: self.height * resizeFactor)
    }
    
    public func sizeByAspectScaledToFill(size:CGSize) -> CGSize {
        let imageAspectRatio = self.width / self.height
        let canvasAspectRatio = size.width / size.height
        var resizeFactor: CGFloat
        if imageAspectRatio > canvasAspectRatio {
            resizeFactor = size.height / self.height
        }
        else {
            resizeFactor = size.width / self.width
        }
        return CGSize(width: self.width * resizeFactor, height: self.height * resizeFactor)
    }
    
    public func sizeByAspectScaledToMatchX(size:CGSize) -> CGSize {
        return CGSize(width: size.width, height: (size.width/self.width) * self.height);
    }
    
    public func sizeByAspectScaledToMatchY(size:CGSize) -> CGSize {
        return CGSize(width: (size.height/self.height) * self.width, height: size.height);
    }
}

// MARK: CGRect

extension CGRect {
    
    /// Creates a rect with unnamed arguments.
    public init(_ origin: CGPoint, _ size: CGSize) {
        self.origin = origin
        self.size = size
    }
    
    public init(_ origin: CGPoint, _ width: CGFloat, _ height: CGFloat) {
        self.origin = origin
        self.size = CGSize(width, height);
    }
    
    public init(_ x: CGFloat, _ y: CGFloat, _ size: CGSize) {
        self.origin = CGPoint(x, y);
        self.size = size;
    }
    
    public init(_ x: Int, _ y: Int, _ size: CGSize) {
        self.origin = CGPoint(x, y);
        self.size = size;
    }
    
    /// Creates a rect with unnamed arguments.
    public init(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
        self.origin = CGPoint(x: x, y: y)
        self.size = CGSize(width: width, height: height)
    }
    
    public init(_ x: Int, _ y: Int, _ width: Int, _ height: Int) {
        self.origin = CGPoint(x: x, y: y)
        self.size = CGSize(width: width, height: height)
    }
    
    public init(_ points:[CGPoint]) {
        if (points.count == 0) {
            self.origin = CGPoint.zero;
            self.size = CGSize.zero;
        }
        else {
            var maxX = points[0].x;
            var maxY = points[0].y;
            var minX = points[0].x;
            var minY = points[0].y;
            for i in 1 ..< points.count {
                let point = points[i];
                maxX = max(maxX, point.x);
                maxY = max(maxY, point.y);
                minX = min(minX, point.x);
                minY = min(minY, point.y);
            }
            self.origin = CGPoint(minX, minY);
            self.size = CGSize(maxX - minX,  maxY - minY)
        }
    }
    
    public init(_ points:Array<String>) {
        var bounds = CGRect.zero;
        for i in 0 ..< points.count {
            if let value = points.safeObjectAtIndex(i) {
                let point = CGPointFromString(value);
                if (i == 0) {
                    bounds = CGRect(point, 0, 0);
                }
                else {
                    var xLeft = bounds.origin.x;
                    var xRight = xLeft + bounds.size.width;
                    var yTop = bounds.origin.y;
                    var yBottom = bounds.origin.y + bounds.size.height;
                    if (point.x < xLeft) {
                        xLeft = point.x;
                    }
                    if (point.x > xRight) {
                        xRight = point.x;
                    }
                    if (point.y < yTop) {
                        yTop = point.y;
                    }
                    if (point.y > yBottom) {
                        yBottom = point.y;
                    }
                    bounds = CGRect(xLeft, yTop, xRight-xLeft, yBottom-yTop);
                }
            }
        }
        self.origin = bounds.origin;
        self.size = bounds.size;
    }
    
    public init(point1:CGPoint, point2:CGPoint) {
        var xLeft = point2.x;
        var xRight = point2.x;
        var yTop = point2.y;
        var yBottom = point2.y;
        if (point1.x < xLeft) {
            xLeft = point1.x;
        }
        if (point1.x > xRight) {
            xRight = point1.x;
        }
        if (point1.y < yTop) {
            yTop = point1.y;
        }
        if (point1.y > yBottom) {
            yBottom = point1.y;
        }
        self.origin = CGPoint(xLeft, yTop);
        self.size = CGSize(xRight-xLeft, yBottom-yTop);
    }
    
    public init(center:CGPoint, size:CGSize) {
        self.origin = CGPoint(center.x - size.width/2, center.y - size.height/2);
        self.size = size;
    }
    
    // MARK: access shortcuts
    
    /// Alias for origin.x.
    public var x: CGFloat {
        get {return origin.x}
        set {origin.x = newValue}
    }
    /// Alias for origin.y.
    public var y: CGFloat {
        get {return origin.y}
        set {origin.y = newValue}
    }
    
    /// Accesses origin.x + 0.5 * size.width.
    public var centerX: CGFloat {
        get {return x + width * 0.5}
        set {x = newValue - width * 0.5}
    }
    /// Accesses origin.y + 0.5 * size.height.
    public var centerY: CGFloat {
        get {return y + height * 0.5}
        set {y = newValue - height * 0.5}
    }
    
    // MARK: edges
    
    /// Alias for origin.x.
    public var left: CGFloat {
        get {return origin.x}
        set {origin.x = newValue}
    }
    /// Accesses origin.x + size.width.
    public var right: CGFloat {
        get {return x + width}
        set {x = newValue - width}
    }
    
    #if os(iOS)
    /// Alias for origin.y.
    public var top: CGFloat {
        get {return y}
        set {y = newValue}
    }
    /// Accesses origin.y + size.height.
    public var bottom: CGFloat {
        get {return y + height}
        set {y = newValue - height}
    }
    #else
    /// Accesses origin.y + size.height.
    public var top: CGFloat {
    get {return y + height}
    set {y = newValue - height}
    }
    /// Alias for origin.y.
    public var bottom: CGFloat {
    get {return y}
    set {y = newValue}
    }
    #endif
    
    // MARK: points
    
    /// Accesses the point at the top left corner.
    public var topLeft: CGPoint {
        get {return CGPoint(x: left, y: top)}
        set {left = newValue.x; top = newValue.y}
    }
    /// Accesses the point at the middle of the top edge.
    public var topCenter: CGPoint {
        get {return CGPoint(x: centerX, y: top)}
        set {centerX = newValue.x; top = newValue.y}
    }
    /// Accesses the point at the top right corner.
    public var topRight: CGPoint {
        get {return CGPoint(x: right, y: top)}
        set {right = newValue.x; top = newValue.y}
    }
    
    /// Accesses the point at the middle of the left edge.
    public var centerLeft: CGPoint {
        get {return CGPoint(x: left, y: centerY)}
        set {left = newValue.x; centerY = newValue.y}
    }
    /// Accesses the point at the center.
    public var center: CGPoint {
        get {return CGPoint(x: centerX, y: centerY)}
        set {centerX = newValue.x; centerY = newValue.y}
    }
    /// Accesses the point at the middle of the right edge.
    public var centerRight: CGPoint {
        get {return CGPoint(x: right, y: centerY)}
        set {right = newValue.x; centerY = newValue.y}
    }
    
    /// Accesses the point at the bottom left corner.
    public var bottomLeft: CGPoint {
        get {return CGPoint(x: left, y: bottom)}
        set {left = newValue.x; bottom = newValue.y}
    }
    /// Accesses the point at the middle of the bottom edge.
    public var bottomCenter: CGPoint {
        get {return CGPoint(x: centerX, y: bottom)}
        set {centerX = newValue.x; bottom = newValue.y}
    }
    /// Accesses the point at the bottom right corner.
    public var bottomRight: CGPoint {
        get {return CGPoint(x: right, y: bottom)}
        set {right = newValue.x; bottom = newValue.y}
    }
    
    // MARK: with
    
    /// Returns a copy with the origin value changed.
    public func with(origin: CGPoint) -> CGRect {
        return CGRect(origin: origin, size: size)
    }
    /// Returns a copy with the x and y values changed.
    public func with(x: CGFloat, y: CGFloat) -> CGRect {
        return with(origin: CGPoint(x: x, y: y))
    }
    /// Returns a copy with the x value changed.
    public func with(x: CGFloat) -> CGRect {
        return with(x: x, y: y)
    }
    /// Returns a copy with the y value changed.
    public func with(y: CGFloat) -> CGRect {
        return with(x: x, y: y)
    }
    
    /// Returns a copy with the size value changed.
    public func with(size: CGSize) -> CGRect {
        return CGRect(origin: origin, size: size)
    }
    /// Returns a copy with the width and height values changed.
    public func with(width: CGFloat, height: CGFloat) -> CGRect {
        return with(size: CGSize(width: width, height: height))
    }
    /// Returns a copy with the width value changed.
    public func with(width: CGFloat) -> CGRect {
        return with(width: width, height: height)
    }
    /// Returns a copy with the height value changed.
    public func with(height: CGFloat) -> CGRect {
        return with(width: width, height: height)
    }
    
    /// Returns a copy with the x and width values changed.
    public func with(x: CGFloat, width: CGFloat) -> CGRect {
        return CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }
    /// Returns a copy with the y and height values changed.
    public func with(y: CGFloat, height: CGFloat) -> CGRect {
        return CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }
    
    // MARK: offset
    
    /// Returns a copy with the x and y values offset.
    public func offsetBy(dx: CGFloat, _ dy: CGFloat) -> CGRect {
        return with(x: x + dx, y: y + dy)
    }
    /// Returns a copy with the x value values offset.
    public func offsetBy(dx: CGFloat) -> CGRect {
        return with(x: x + dx)
    }
    /// Returns a copy with the y value values offset.
    public func offsetBy(dy: CGFloat) -> CGRect {
        return with(y: y + dy)
    }
    /// Returns a copy with the x and y values offset.
    public func offsetBy(by: CGSize) -> CGRect {
        return with(x: x + by.width, y: y + by.height)
    }
    
    /// Modifies the x and y values by offsetting.
    public mutating func offsetInPlace(dx: CGFloat, dy: CGFloat) {
        offsetInPlace(dx: dx)
        offsetInPlace(dy: dy)
    }
    /// Modifies the x value values by offsetting.
    public mutating func offsetInPlace(dx: CGFloat = 0) {
        x += dx
    }
    /// Modifies the y value values by offsetting.
    public mutating func offsetInPlace(dy: CGFloat = 0) {
        y += dy
    }
    /// Modifies the x and y values by offsetting.
    public mutating func offsetInPlace(by: CGSize) {
        offsetInPlace(dx: by.width, dy: by.height)
    }
    
    // MARK: inset
    
    /// Returns a copy inset on all edges by the same value.
    public func insetBy(by: CGFloat) -> CGRect {
        return insetBy(dx: by, dy: by)
    }
    
    /// Returns a copy inset on the left and right edges.
    public func insetBy(dx: CGFloat) -> CGRect {
        return with(x: x + dx, width: width - dx * 2)
    }
    /// Returns a copy inset on the top and bottom edges.
    public func insetBy(dy: CGFloat) -> CGRect {
        return with(y: y + dy, height: height - dy * 2)
    }
    
    /// Returns a copy inset on all edges by different values.
    public func insetBy(minX: CGFloat = 0, minY: CGFloat = 0, maxX: CGFloat = 0, maxY: CGFloat = 0) -> CGRect {
        return CGRect(x: x + minX, y: y + minY, width: width - minX - maxX, height: height - minY - maxY)
    }
    
    /// Returns a copy inset on all edges by different values.
    public func insetBy(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) -> CGRect {
        #if os(iOS)
            return CGRect(x: x + left, y: y + top, width: width - right - left, height: height - top - bottom)
        #else
            return CGRect(x: x + left, y: y + bottom, width: width - right - left, height: height - top - bottom)
        #endif
    }
    
    // MARK: sizes
    
    /// Returns a rect of the specified size centered in this rect.
    public func center(size: CGSize) -> CGRect {
        let dx = width - size.width
        let dy = height - size.height
        return CGRect(x: x + dx * 0.5, y: y + dy * 0.5, width: size.width, height: size.height)
    }
    
    /// Returns a rect of the specified size centered in this rect touching the specified edge.
    public func center(size: CGSize, alignTo edge: CGRectEdge) -> CGRect {
        return CGRect(origin: alignedOrigin(size: size, edge: edge), size: size)
    }
    
    private func alignedOrigin(size: CGSize, edge: CGRectEdge) -> CGPoint {
        let dx = width - size.width
        let dy = height - size.height
        switch edge {
        case .minXEdge:
            return CGPoint(x: x, y: y + dy * 0.5)
        case .minYEdge:
            return CGPoint(x: x + dx * 0.5, y: y)
        case .maxXEdge:
            return CGPoint(x: x + dx, y: y + dy * 0.5)
        case .maxYEdge:
            return CGPoint(x: x + dx * 0.5, y: y + dy)
        }
    }
    
    /// Returns a rect of the specified size centered in this rect touching the specified corner.
    public func align(size: CGSize, corner e1: CGRectEdge, _ e2: CGRectEdge) -> CGRect {
        return CGRect(origin: alignedOrigin(size: size, corner: e1, e2), size: size)
    }
    
    private func alignedOrigin(size: CGSize, corner e1: CGRectEdge, _ e2: CGRectEdge) -> CGPoint {
        let dx = width - size.width
        let dy = height - size.height
        switch (e1, e2) {
        case (.minXEdge, .minYEdge), (.minYEdge, .minXEdge):
            return CGPoint(x: x, y: y)
        case (.maxXEdge, .minYEdge), (.minYEdge, .maxXEdge):
            return CGPoint(x: x + dx, y: y)
        case (.minXEdge, .maxYEdge), (.maxYEdge, .minXEdge):
            return CGPoint(x: x, y: y + dy)
        case (.maxXEdge, .maxYEdge), (.maxYEdge, .maxXEdge):
            return CGPoint(x: x + dx, y: y + dy)
        default:
            preconditionFailure("Cannot align to this combination of edges")
        }
    }
    
    public func rotate(angle:Int) -> CGRect {
        let center = self.center;
        return CGRect([self.topLeft.rotate(angle: angle, center: center),
                       self.topRight.rotate(angle: angle, center: center),
                       self.bottomLeft.rotate(angle: angle, center: center),
                       self.bottomRight.rotate(angle: angle, center: center)]);
    }
    
    public func extend(point:CGPoint) -> CGRect {
        var xLeft = self.x;
        var xRight = xLeft + self.width;
        var yTop = self.y;
        var yBottom = yTop + self.height;
        if (point.x < xLeft) {
            xLeft = point.x;
        }
        if (point.x > xRight) {
            xRight = point.x;
        }
        if (point.y < yTop) {
            yTop = point.y;
        }
        if (point.y > yBottom) {
            yBottom = point.y;
        }
        return CGRect(xLeft, yTop, xRight-xLeft, yBottom-yTop);
    }
    
    func trimToNil() -> CGRect? {
        if self.isNull {
            return nil;
        }
        if self.isEmpty {
            return nil;
        }
        return self;
    }
}

// MARK: transform

extension CGAffineTransform {
    
    func toShortString() -> String {
        return NSString(format:"[%.1f, %.1f, %.1f, %.1f, %.1f, %.1f]", self.a, self.b, self.c, self.d, self.tx, self.ty) as String;
    }
    
}

extension CGAffineTransform: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "(\(a),\(b),\(c),\(d),\(tx),\(ty))"
    }
}

// MARK: operators

/// Returns a point by adding the coordinates of another point.
public func +(p1: CGPoint, p2: CGPoint) -> CGPoint {
    return CGPoint(x: p1.x + p2.x, y: p1.y + p2.y)
}
/// Modifies the x and y values by adding the coordinates of another point.
public func +=( p1: inout CGPoint, p2: CGPoint) {
    p1.x += p2.x
    p1.y += p2.y
}
/// Returns a point by subtracting the coordinates of another point.
public func -(p1: CGPoint, p2: CGPoint) -> CGPoint {
    return CGPoint(x: p1.x - p2.x, y: p1.y - p2.y)
}
/// Modifies the x and y values by subtracting the coordinates of another points.
public func -=( p1: inout CGPoint, p2: CGPoint) {
    p1.x -= p2.x
    p1.y -= p2.y
}

/// Returns a point by adding a size to the coordinates.
public func +(point: CGPoint, size: CGSize) -> CGPoint {
    return CGPoint(x: point.x + size.width, y: point.y + size.height)
}
/// Modifies the x and y values by adding a size to the coordinates.
public func +=( point: inout CGPoint, size: CGSize) {
    point.x += size.width
    point.y += size.height
}
/// Returns a point by subtracting a size from the coordinates.
public func -(point: CGPoint, size: CGSize) -> CGPoint {
    return CGPoint(x: point.x - size.width, y: point.y - size.height)
}
/// Modifies the x and y values by subtracting a size from the coordinates.
public func -=( point: inout CGPoint, size: CGSize) {
    point.x -= size.width
    point.y -= size.height
}

/// Returns a point by adding a tuple to the coordinates.
public func +(point: CGPoint, tuple: (CGFloat, CGFloat)) -> CGPoint {
    return CGPoint(x: point.x + tuple.0, y: point.y + tuple.1)
}
/// Modifies the x and y values by adding a tuple to the coordinates.
public func +=( point: inout CGPoint, tuple: (CGFloat, CGFloat)) {
    point.x += tuple.0
    point.y += tuple.1
}
/// Returns a point by subtracting a tuple from the coordinates.
public func -(point: CGPoint, tuple: (CGFloat, CGFloat)) -> CGPoint {
    return CGPoint(x: point.x - tuple.0, y: point.y - tuple.1)
}
/// Modifies the x and y values by subtracting a tuple from the coordinates.
public func -=( point: inout CGPoint, tuple: (CGFloat, CGFloat)) {
    point.x -= tuple.0
    point.y -= tuple.1
}
/// Returns a point by multiplying the coordinates with a value.
public func *(point: CGPoint, factor: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * factor, y: point.y * factor)
}
/// Modifies the x and y values by multiplying the coordinates with a value.
public func *=( point: inout CGPoint, factor: CGFloat) {
    point.x *= factor
    point.y *= factor
}
/// Returns a point by multiplying the coordinates with a tuple.
public func *(point: CGPoint, tuple: (CGFloat, CGFloat)) -> CGPoint {
    return CGPoint(x: point.x * tuple.0, y: point.y * tuple.1)
}
/// Modifies the x and y values by multiplying the coordinates with a tuple.
public func *=( point: inout CGPoint, tuple: (CGFloat, CGFloat)) {
    point.x *= tuple.0
    point.y *= tuple.1
}
/// Returns a point by dividing the coordinates by a tuple.
public func /(point: CGPoint, tuple: (CGFloat, CGFloat)) -> CGPoint {
    return CGPoint(x: point.x / tuple.0, y: point.y / tuple.1)
}
/// Modifies the x and y values by dividing the coordinates by a tuple.
public func /=( point: inout CGPoint, tuple: (CGFloat, CGFloat)) {
    point.x /= tuple.0
    point.y /= tuple.1
}
/// Returns a point by dividing the coordinates by a factor.
public func /(point: CGPoint, factor: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / factor, y: point.y / factor)
}
/// Modifies the x and y values by dividing the coordinates by a factor.
public func /=( point: inout CGPoint, factor: CGFloat) {
    point.x /= factor
    point.y /= factor
}

/// Returns a point by adding another size.
public func +(s1: CGSize, s2: CGSize) -> CGSize {
    return CGSize(width: s1.width + s2.width, height: s1.height + s2.height)
}
/// Modifies the width and height values by adding another size.
public func +=( s1: inout CGSize, s2: CGSize) {
    s1.width += s2.width
    s1.height += s2.height
}
/// Returns a point by subtracting another size.
public func -(s1: CGSize, s2: CGSize) -> CGSize {
    return CGSize(width: s1.width - s2.width, height: s1.height - s2.height)
}
/// Modifies the width and height values by subtracting another size.
public func -=( s1: inout CGSize, s2: CGSize) {
    s1.width -= s2.width
    s1.height -= s2.height
}

/// Returns a point by adding a tuple.
public func +(size: CGSize, tuple: (CGFloat, CGFloat)) -> CGSize {
    return CGSize(width: size.width + tuple.0, height: size.height + tuple.1)
}
/// Modifies the width and height values by adding a tuple.
public func +=( size: inout CGSize, tuple: (CGFloat, CGFloat)) {
    size.width += tuple.0
    size.height += tuple.1
}
/// Returns a point by subtracting a tuple.
public func -(size: CGSize, tuple: (CGFloat, CGFloat)) -> CGSize {
    return CGSize(width: size.width - tuple.0, height: size.height - tuple.1)
}
/// Modifies the width and height values by subtracting a tuple.
public func -=( size: inout CGSize, tuple: (CGFloat, CGFloat)) {
    size.width -= tuple.0
    size.height -= tuple.1
}
/// Returns a point by multiplying the size with a factor.
public func *(size: CGSize, factor: CGFloat) -> CGSize {
    return CGSize(width: size.width * factor, height: size.height * factor)
}
/// Modifies the width and height values by multiplying them with a factor.
public func *=( size: inout CGSize, factor: CGFloat) {
    size.width *= factor
    size.height *= factor
}
/// Returns a point by multiplying the size with a tuple.
public func *(size: CGSize, tuple: (CGFloat, CGFloat)) -> CGSize {
    return CGSize(width: size.width * tuple.0, height: size.height * tuple.1)
}
/// Modifies the width and height values by multiplying them with a tuple.
public func *=( size: inout CGSize, tuple: (CGFloat, CGFloat)) {
    size.width *= tuple.0
    size.height *= tuple.1
}
/// Returns a point by dividing the size by a factor.
public func /(size: CGSize, factor: CGFloat) -> CGSize {
    return CGSize(width: size.width / factor, height: size.height / factor)
}
/// Modifies the width and height values by dividing them by a factor.
public func /=( size: inout CGSize, factor: CGFloat) {
    size.width /= factor
    size.height /= factor
}
/// Returns a point by dividing the size by a tuple.
public func /(size: CGSize, tuple: (CGFloat, CGFloat)) -> CGSize {
    return CGSize(width: size.width / tuple.0, height: size.height / tuple.1)
}
/// Modifies the width and height values by dividing them by a tuple.
public func /=( size: inout CGSize, tuple: (CGFloat, CGFloat)) {
    size.width /= tuple.0
    size.height /= tuple.1
}

/// Returns a rect by adding the coordinates of a point to the origin.
public func +(rect: CGRect, point: CGPoint) -> CGRect {
    return CGRect(origin: rect.origin + point, size: rect.size)
}
/// Modifies the x and y values by adding the coordinates of a point.
public func +=( rect: inout CGRect, point: CGPoint) {
    rect.origin += point
}
/// Returns a rect by subtracting the coordinates of a point from the origin.
public func -(rect: CGRect, point: CGPoint) -> CGRect {
    return CGRect(origin: rect.origin - point, size: rect.size)
}
/// Modifies the x and y values by subtracting the coordinates from a point.
public func -=( rect: inout CGRect, point: CGPoint) {
    rect.origin -= point
}

/// Returns a rect by adding a size to the size.
public func +(rect: CGRect, size: CGSize) -> CGRect {
    return CGRect(origin: rect.origin, size: rect.size + size)
}
/// Modifies the width and height values by adding a size.
public func +=( rect: inout CGRect, size: CGSize) {
    rect.size += size
}
/// Returns a rect by subtracting a size from the size.
public func -(rect: CGRect, size: CGSize) -> CGRect {
    return CGRect(origin: rect.origin, size: rect.size - size)
}
/// Modifies the width and height values by subtracting a size.
public func -=( rect: inout CGRect, size: CGSize) {
    rect.size -= size
}

/// Returns a point by applying a transform.
public func *(point: CGPoint, transform: CGAffineTransform) -> CGPoint {
    return point.applying(transform)
}
/// Modifies all values by applying a transform.
public func *=( point: inout CGPoint, transform: CGAffineTransform) {
    point = point.applying(transform)
}
/// Returns a size by applying a transform.
public func *(size: CGSize, transform: CGAffineTransform) -> CGSize {
    return size.applying(transform)
}
/// Modifies all values by applying a transform.
public func *=( size: inout CGSize, transform: CGAffineTransform) {
    size = size.applying(transform)
}
/// Returns a rect by applying a transform.
public func *(rect: CGRect, transform: CGAffineTransform) -> CGRect {
    return rect.applying(transform)
}
/// Modifies all values by applying a transform.
public func *=( rect: inout CGRect, transform: CGAffineTransform) {
    rect = rect.applying(transform)
}

/// Returns a transform by concatenating two transforms.
public func *(t1: CGAffineTransform, t2: CGAffineTransform) -> CGAffineTransform {
    return t1.concatenating(t2)
}
/// Modifies all values by concatenating another transform.
public func *=( t1: inout CGAffineTransform, t2: CGAffineTransform) {
    t1 = t1.concatenating(t2)
}

