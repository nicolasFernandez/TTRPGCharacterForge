//
//  SpellDetailView.swift
//  TTRPGCharacterForge
//
//  Created on 2025-10-13.
//

import SwiftUI

/// Presents the full rules text and metadata for a spell.
struct SpellDetailView: View {
    let spell: Spell
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(spell.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text(spell.levelString)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(spell.school.name.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if spell.isRitual {
                            Text(
                                NSLocalizedString("spell_ritual", comment: "")
                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(
                        title: NSLocalizedString("spell_casting_time", comment: ""),
                        value: spell.castingTime
                    )
                    DetailRow(
                        title: NSLocalizedString("spell_range", comment: ""),
                        value: spell.range
                    )
                    DetailRow(
                        title:NSLocalizedString("spell_components", comment: ""),
                        value: formatComponents()
                    )
                    DetailRow(
                        title: NSLocalizedString("spell_duration", comment: ""),
                        value: formatDuration()
                    )
                }
                
                Divider()
                
                Text(spell.levelDescription)
                    .fixedSize(horizontal: false, vertical: true)

                if let higherLevelsDescription = spell.higherLevelsDescription {
                    Text("At Higher Levels.")
                        .fontWeight(.bold)
                        .italic()
                    Text(higherLevelsDescription)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        NSLocalizedString("spell_available_to", comment: "")
                    )
                    .font(.headline)
                    
                    Text(formatClasses())
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    private func formatComponents() -> String {
        var components: [String] = []
        
        if spell.components.verbal {
            components.append("V")
        }
        
        if spell.components.somatic {
            components.append("S")
        }
        
        if spell.components.material {
            components.append("M")
            if let materialComponents = spell.components.materialComponents {
                components.append("(\(materialComponents))")
            }
        }
        
        return components.joined(separator: ", ")
    }
    
    private func formatDuration() -> String {
        if spell.requiresConcentration {
            return String(format: NSLocalizedString("spell_concentration", comment:""), spell.duration)
        } else {
            return spell.duration
        }
    }
    
    private func formatClasses() -> String {
        return spell.classes.map { "\($0.name)" }.joined(separator: ", ")
    }
}

struct SpellDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let spell = Spell(name: "Acid Arrow", level: 2, school: .evocation, castingTime: "1 action", range: "90 feet", components: SpellComponents(verbal: true, somatic: true, material: true, materialComponents: "powdered rhubarb leaf and an adder's stomach"), duration: "Instantaneous", levelDescription: "A shimmering green arrow streaks toward a target within range and bursts in a spray of acid. Make a ranged spell attack against the target. On a hit, the target takes 4d4 acid damage immediately and 2d4 acid damage at the end of its next turn. On a miss, the arrow splashes the target with acid for half as much of the initial damage and no damage at the end of its next turn.", higherLevelsDescription: "When you cast this spell using a spell slot of 3rd level or higher, the damage (both initial and later) increases by 1d4 for each slot level above 2nd.", classes: [.wizard, .druid])
        SpellDetailView(spell: spell)
    }
}
