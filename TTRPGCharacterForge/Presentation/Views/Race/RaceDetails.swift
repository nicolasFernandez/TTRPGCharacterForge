//
//  RaceDetails.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 13-01-23.
//

import SwiftUI

/// Presents the traits and rules for a playable ancestry.
struct RaceDetails: View {
    var raceType: RaceType
    var body: some View {
        VStack (alignment: .leading, spacing: 8) {
            Text(raceType.name)
                .font(.title)
                .fontWeight(.bold)
                .padding(.trailing, 30)
                .padding(.leading, 30)
            Text(raceType.description)
                .padding(.leading, 30)
                .padding(.trailing, 30)
                .padding(.bottom, 8)
                .padding(.top, 8)
            Text(
                String(format: NSLocalizedString("traits_format", comment:""), raceType.name)
            )
                .fontWeight(.bold)
                .padding(.leading, 30)
                .padding(.trailing, 30)
            Text(raceType.racialTraits)
                .padding(.leading, 30)
                .padding(.trailing, 30)
            Image("\(raceType.rawValue)_large")
                .resizable()
                .scaledToFit()
        }
    }
}

struct RaceDetails_Previews: PreviewProvider {
    static var previews: some View {
        RaceDetails(raceType: .gnome)
    }
}
