//
//  NightScene.swift
//  BlueLight
//
//  Created by Rail on 6/8/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import SpriteKit

class NightScene:SKScene {
    override func didMoveToView(view: SKView) {
        let backNode = SKSpriteNode(imageNamed: "night")
        backNode.position = CGPoint(x: frame.midX, y: frame.midY)
        backNode.size = CGSize(width: frame.width, height: frame.height)
        backNode.name = "BACKGROUND"
        addChild(backNode)
        backgroundColor = UIColor(patternImage: UIImage(named: "night")!)
        let size = frame.size
        if let starNode = SKEmitterNode(fileNamed: "TwinkleStar") {
            starNode.position = CGPoint(x: size.width / 2, y: size.height / 4 * 3)
            starNode.particlePositionRange = CGVector(dx: frame.size.width, dy: frame.size.height / 2)
            starNode.name = "TwinkleStar"
            addChild(starNode)
            
        }
        
        if let meteorNode = SKEmitterNode(fileNamed: "Meteor") {
            meteorNode.position = CGPoint(x: size.width / 4 * 3, y: size.height / 4 * 3)
            meteorNode.particlePositionRange = CGVector(dx: size.width / 4, dy: size.height / 2)
            meteorNode.name = "Meteor"
            addChild(meteorNode)
            
        }
        
        if let meteorExtraNode = SKEmitterNode(fileNamed: "Meteor_extra") {
            meteorExtraNode.position = CGPoint(x: size.width / 4, y: size.height / 4 * 3)
            meteorExtraNode.particlePositionRange = CGVector(dx: size.width / 4, dy: size.height / 2)
            meteorExtraNode.name = "Meteor_extra"
            addChild(meteorExtraNode)
            
        }
        
        
        
    }
}
