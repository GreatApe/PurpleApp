//
//  Signal.swift
//  Signalist
//
//  Created by Gustaf Kugelberg on 20/03/15.
//  Copyright (c) 2015 GreatApe. All rights reserved.
//

import UIKit

protocol AnySignal {
    var name: String { get }
    var outputType: DataType { get }
    var copy: AnySignal { get }
    
    func connect(_: AnySignal) -> Bool
}

final class Signal<S>: AnySignal {
    private(set) var name: String
    let outputType = DataType(S.self)
    
    var value: S
    var driver = false
    
    private var effects = Array<S -> ()>()
    
    init(value: S, name: String = "") {
        self.value = value
        self.name = name
    }
    
    // Transform from signal
    init<T>(_ t: Signal<T>, _ f: T -> S ) {
        self.name = t.name == "" ? "" :  "f(" + t.name + ")"
        self.value = f(t.value)
        t.effect { self.send(f($0)) }
    }
    
    // Transform from signal and back
    init<T>(_ t: Signal<T>, _ f: T -> S, _ g: S -> T) {
        self.name = t.name == "" ? "" :  "g(" + t.name + ")"
        self.value = f(t.value)
        t.effect { self.send(f($0)) }
        effect { t.send(g($0)) }
    }

    var description: String {
        return "[" + outputType.rawValue + ":" + name + "]"
    }
    
    func connect(source: AnySignal) -> Bool {
        if let source = source as? Signal<S> {
            source.effect(self.send)
            return true
        }
        
        return false
    }
    
    var copy: AnySignal {
        return Signal(value: value, name: name)
    }

    func resend() {
        send(value)
    }
    
    func send(newValue: S) {
        if driver {
            return
        }
        
        value = newValue
        driver = true
        
        for effect in effects {
            effect(value)
        }
        
        driver = false
    }
    
    func name(s: String) -> Signal {
        name = s
        return self
    }
    
    // Add effect
    func effect(newEffect: S -> ()) -> Signal {
        effects.append(newEffect)
//        newEffect(value)
        
        return self
    }

    // Remove effects
    func clearEffects() {
        effects.removeAll()
    }

    // Add logging
    func log(prefix: String = "value") -> Signal {
        return effect { _ in print("\(prefix): \(self.value)") }
    }
    
    // MARK: - Return new signal
    
    // Map
    func map<T>(f: S -> T) -> Signal<T> {
        return Signal<T>(self, f)
    }
    
    // Map and map back
    func iso<T>(f: S -> T, g: T -> S) -> Signal<T> {
        return Signal<T>(self, f, g)
    }

    // Filter
    func filter(f: S -> Bool) -> Signal {
        let s = Signal(value: value)
        effect { if f($0) { s.send($0) } }
        
        return s
    }

    // Reduce
    func reduce<T>(initial: T, combine: (S, T) -> T) -> Signal<T> {
        let t = Signal<T>(value: initial)
        effect{ t.send(combine($0, t.value)) }
        
        return t
    }
    
    // All previous values as an array
    func collect() -> Signal<[S]> {
        return reduce([]){ $1 + [$0] }
    }
    
    // Counter of sent values
    func count() -> Signal<Int> {
        return reduce(0) { $1 + 1 }
    }
    
    // Only allows every n:th value to pass
    func every(n: Int) -> Signal<S> {
        return counted().filter { $0.1 % n == 0 }.map { $0.0 }
    }

    // Only allows the first n values to pass
    func stop(n: Int) -> Signal<S> {
        return counted().filter { $0.1 <= n }.map { $0.0 }
    }
    
    // Sends until seeing n cases of f being true
    func until(n: Int, f: S -> Bool) -> Signal<S> {
        return gate(filter(f).count().map{ $0 < n })
    }

    // Sends until seeing first case of f being true
    func until(f: S -> Bool) -> Signal<S> {
        return until(1, f: f)
    }

    // Starts sending after n cases of f being true
    func after(n: Int, f: S -> Bool) -> Signal<S> {
        let s = Signal<(S, Int)>(value: (value, 0))
        effect { sVal in
            if s.value.1 >= n {
                s.send(sVal, n)
            }
            else if f(sVal) {
                s.value.1 = s.value.1 + 1
            }
        }
        
        return s.filter { $0.1 >= n }.map { $0.0 }
    }
    
    // Starts sending after first case of f being true
    func after(f: S -> Bool) -> Signal<S> {
        return after(1, f: f)
    }

    // Only sends when bool signal is true
    func gate(b: Signal<Bool>) -> Signal {
        let s = Signal(value: value)
        effect { if b.value { s.send($0)} }

        return s
    }
    
    func triggered(b: Signal<Bool>) -> Signal {
        let s = Signal(value: value)
        b.effect { if $0 { s.send(self.value) } }
        
        return s
    }
    
    // Bool signal send when f is true
    func trigger(f: S -> Bool) -> Signal<Bool> {
        return filter(f).map { _ in true }
    }
    
    // Bool signal send true
    func trigger() -> Signal<Bool> {
        return map { _ in true }
    }
    
    func paced<T>(trigger: Signal<T>) -> Signal {
        let s = Signal(value: value)
        trigger.effect { _ in s.send(self.value) }
        
        return s
    }
    
    // Select one of two signals depending on the truth of f(self)
    func select<T>(t0: Signal<T>, _ t1: Signal<T>, f: S -> Bool) -> Signal<T> {
        let t = Signal<T>(value: f(value) ? t0.value : t1.value)

        t0.effect { t.send(f(self.value) ? $0 : t1.value) }
        t1.effect { t.send(f(self.value) ? t0.value : $0) }
        effect { t.send(f($0) ? t0.value : t1.value) }
        
        return t
    }
    
    // Counter of sent values
    func counted() -> Signal<(S, Int)> {
        return reduce((value, -1)) { ($0, $1.1 + 1) }
    }

    // MARK - OTHER
    
    // Split one signal in two
    func split<U, V>(f: S -> (U, V) ) -> (Signal<U>, Signal<V>) {
        let initial = f(value)
        
        let u = Signal<U>(value: initial.0)
        let v = Signal<V>(value: initial.1)

        effect {
            let value = f($0)
            u.send(value.0)
            v.send(value.1)
        }
     
        return (u, v)
    }
    
    func merge<T, U>(t: Signal<T>, f: (S, T) -> U ) -> Signal<U> {
        let u = Signal<U>(value: f(value, t.value))
        
        effect{ u.send(f($0, t.value)) }
        t.effect{ u.send(f(self.value, $0)) }

        return u
    }
}

// Use in map

func componentwise<S, T>(f: S -> T) -> [S] -> [T] {
    return { $0.map(f) }
}

func componentwiseLeft<L, R, O>(f: (L, R) -> O) -> ([L], R) -> [O] {
    return { (ll: [L], r: R) in
        ll.map { f($0, r) }
    }
}

func componentwiseRight<L, R, O>(f: (L, R) -> O) -> (L, [R]) -> [O] {
    return { (l: L, rr: [R]) in
        rr.map { f(l, $0) }
    }
}

func componentwiseBoth<L, R, O>(f: (L, R) -> O) -> ([L], [R]) -> [O] {
    return { (ll: [L], rr: [R]) in
        Array(zip(ll, rr)).map(f)
    }
}

func primo<S, T>(input: (S, T)) -> S {
    return input.0
}

func secundo<S, T>(input: (S, T)) -> T {
    return input.1
}

func primo<S, T, U>(input: (S, T, U)) -> S {
    return input.0
}

func secundo<S, T, U>(input: (S, T, U)) -> T {
    return input.1
}

func tertio<S, T, U>(input: (S, T, U)) -> U {
    return input.2
}

func getFrame(input: UIView) -> CGRect {
    return input.frame
}

func unwrap<S>(input: S?) -> S {
    return input!
}

// Use in filter

func some<S>(input: S?) -> Bool {
    return input != nil
}
