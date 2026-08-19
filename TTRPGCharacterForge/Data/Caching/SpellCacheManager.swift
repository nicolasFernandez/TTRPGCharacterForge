//
//  SpellCacheManager.swift
//  TTRPGCharacterForge
//
//  Created on 2025-10-13.
//

import Foundation

// Caching logic for spell data
/// Coordinates memory and disk caching for spell data.
final class SpellCacheManager {
    private var spellCache: [Spell] = []
    private let expirationTime: TimeInterval = 3600 // 1 hour
    private var lastCacheTime: Date?
    
    func getCachedSpells() -> [Spell]? {
        guard !spellCache.isEmpty, isCacheValid() else {
            return nil
        }
        
        return spellCache
    }
    
    func getCachedSpell(withID id: UUID) -> Spell? {
        guard isCacheValid() else {
            return nil
        }
        
        return spellCache.first { $0.id == id }
    }
    
    func cacheSpells(_ spells: [Spell]) {
        spellCache = spells
        lastCacheTime = Date()
    }
    
    func addSpellToCache(_ spell: Spell) {
        if let index = spellCache.firstIndex(where: { $0.id == spell.id }) {
            spellCache[index] = spell
        } else {
            spellCache.append(spell)
        }
        lastCacheTime = Date()
    }
    
    func clearCache() {
        spellCache = []
        lastCacheTime = nil
    }
    
    private func isCacheValid() -> Bool {
        guard let lastCacheTime = lastCacheTime else {
            return false
        }
        
        let currentTime = Date()
        let timeSinceLastCache = currentTime.timeIntervalSince(lastCacheTime)
        
        return timeSinceLastCache < expirationTime
    }
}
