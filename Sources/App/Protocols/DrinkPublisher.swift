import Vapor

public typealias DrinkID = Int
public typealias ShotAmount = Int

/**
    - Summary: The bare minimum for a Drink Machine
 */
public protocol DrinkMachine: EventLoop {
    func pour(drink: DrinkID, amount: ShotAmount)
}
/*
public class Machine {
    var imp: DrinkMachine
    
    init(){}
    
    init (imp: DrinkMachine)
    {
        self.imp = imp
    }
}

public var machine = Machine()
*/
