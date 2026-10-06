//
//  Weapon.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 26-12-22.
//


struct Weapon: Equipment {
    let name: String
    let weight: Float
    let cost: Int

    let range: Int?
    let disadvantageRange: Int?
    let reach: Int
    let damage: String
    let damageType: DamageType
}
