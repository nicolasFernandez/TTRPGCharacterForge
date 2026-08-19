//
//  ImageGenService.swift
//  TTRPGCharacterForge
//
//  Created by Nicolás Fernández on 12-10-25.
//

import Foundation

/// Generates character artwork from a textual description.
protocol ImageGenService {
    func generatePortrait(prompt: String) throws -> URL
    func generateToken(from portraitURL: URL) throws -> URL
}
