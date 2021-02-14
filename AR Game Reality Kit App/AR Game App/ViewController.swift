//
//  ViewController.swift
//  AR Game App
//
//  Created by Adam Jessop on 01/01/2021.
//

import UIKit
import RealityKit
import Combine

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //make an anchor entity, much like ARAnchor but with more options
        let anchor = AnchorEntity(plane: .horizontal, classification: .any, minimumBounds: [0.2, 0.2])
        //add the anchor made to the arview's scene
        arView.scene.addAnchor(anchor)
        //make an array for the cards
        var cards: [Entity] = []
        //make 4 cards for now
        for _ in 1...16 {
            //make a 'box' which is one of the many shapes MeshResource can make
            let box = MeshResource.generateBox(width: 0.04, height: 0.002, depth: 0.04)
            //make a metal material, which is one of the easiest things to make from a SimpleMaterial, can be any material though.
            let metalMaterial = SimpleMaterial(color: .gray, isMetallic: true)
            //make a model entity.  Reality Kit deals with entities, so there is the ar view, that has a scene, which has a anchor entity, then this anchor will allow for new Entities to be added into it and thus added into the 'real world' in the AR view.
            
            //the Model Entity will take the shape of the mesh of the box, and have in its array of materials the one metal material made above
            let model = ModelEntity(mesh: box, materials: [metalMaterial])
            //I think this will add it to an array of items which if their locations overlap will be considered a collision and they react accordingly, bouncing off presumably
            model.generateCollisionShapes(recursive: true)
            //add the box (which is in the shape of a card, and thus a card) to the cards array
            cards.append(model)
        }
        //use a for loop on the cards to dictate the location of each of them
        for (index, card) in cards.enumerated() {
            //how many you want in each direction width ways (x) and long ways (z)
            let x = Float(index % 4)
            let z = Float(index / 4)
            //scale it to 1/10 of the size so its not thicccccccc
            card.position = [x * 0.1, 0, z * 0.1]
            //add the card entitiy to the anchor entity
            anchor.addChild(card)
        }
        
        //make a cancellable
        var cancellable: AnyCancellable?
        //get the cancellable a load of model entitys that it will try and load async (as there are too many to load sync, as it would be waiting for ages not doing anything
        cancellable = ModelEntity
            .loadModelAsync(named: "01")
            .append(ModelEntity.loadModelAsync(named: "02"))
            .append(ModelEntity.loadModelAsync(named: "03"))
            .append(ModelEntity.loadModelAsync(named: "04"))
            .append(ModelEntity.loadModelAsync(named: "05"))
            .append(ModelEntity.loadModelAsync(named: "06"))
            .collect() //collect all the things you have added before this i.e. all the entities
            .sink(receiveCompletion: { (error) in //.sink will then pass you a completion based on what you have passed it to monitor loading
            cancellable?.cancel() //if there was an error then this whole activity can be cancelled
        }, receiveValue: { (entities) in
            //if this does give you the entities then continue on
            var objects: [ModelEntity] = []
            for entity in entities {
                //scale each of these model entities to a small size based on the cards under them, and make this relative to the anchor?
                entity.setScale(SIMD3<Float>(0.002, 0.002, 0.002), relativeTo: anchor)
                //make sure they will collide...don't know why we need to do this
                entity.generateCollisionShapes(recursive: true)
                //make two of them (as it's a matching game)
                for _ in 1...2 {
                    //add to the objects array to be put onto the cards later
                    objects.append(entity.clone(recursive: true))
                }
            }
            objects.shuffle()
            
            for (index, object) in objects.enumerated() {
                cards[index].addChild(object)
                //make sure it is flipped below the card to start
                cards[index].transform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
            }
            cancellable?.cancel()
        })
        
    }
    
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        //get the location from where they tapped (this is linked up to the arView in the storyboard
        let tapLocation = sender.location(in: arView)
        //if we can, i.e. if they clicked on the right place, then get the entity found where they are pressing and make it into a variable
        if let card = arView.entity(at: tapLocation) {
            //if the angle of the entity found is pi, then this means it has been flipped already (as we flip by pi if it isn't -- rotating by pi = a half rotation I think...cos its done in radians and Float.pi * 0.5 was what we used before to flip a quarter, so pi * 1 is half
            if card.transform.rotation.angle == .pi {
            // make a variable for how much we want to rotate, axis array has 3 values, X, Y, Z, we put a 1 in the X signifying we are just rotating the X
                var flipDownTransform = card.transform
                flipDownTransform .rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
                //move the card, using the variable we just made, and to give it a point to compare this to it looks at the parent (?)
                card.move(
                    to: flipDownTransform,
                    relativeTo: card.parent,
                    duration: 0.25,
                    timingFunction: .easeInOut
                )
                //if it isn't pi then flip it by pi to do the opposite of above
            } else {
                
                var flipUpTransform = card.transform
                
                flipUpTransform.rotation = simd_quatf(
                    angle: .pi,
                    axis: [1, 0, 0]
                )
                
                card.move(
                    to: flipUpTransform,
                    relativeTo: card.parent,
                    duration: 0.25,
                    timingFunction: .easeInOut
                )
                
            }
        }
    }
    
}
