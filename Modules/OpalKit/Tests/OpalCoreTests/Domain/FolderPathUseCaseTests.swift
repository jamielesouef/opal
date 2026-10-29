//
//  FolderPathUseCaseTests.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import Foundation
import Testing
@testable import OpalCore

@Suite("FolderPathUseCase", .tags(.domain))
struct FolderPathUseCaseTests {
    // MARK: - Constants

    private let home = "/Users/jamie"

    // MARK: - Home

    @Test("a folder in the home folder starts with ~")
    func homeFolder() {
        #expect(FolderPathUseCase.short("/Users/jamie/Documents", home: home) == "~/Documents")
        #expect(FolderPathUseCase.short("/Users/jamie", home: home) == "~")
    }

    @Test("a folder beside the home folder is not under it")
    func neighbour() {
        #expect(FolderPathUseCase.short("/Users/jamie2/Notes", home: home) == "/Users/jamie2/Notes")
    }

    @Test("the real home folder is the user's, not the sandbox container")
    func realHome() {
        #expect(UserHome.path.hasPrefix("/"))
        #expect(UserHome.path.contains("/Library/Containers/") == false)
        #expect(FolderPathUseCase.short(UserHome.path + "/Notes", home: UserHome.path) == "~/Notes")
    }

    @Test("a trailing slash on the home folder changes nothing")
    func trailingSlash() {
        #expect(FolderPathUseCase.short("/Users/jamie/Notes", home: "/Users/jamie/") == "~/Notes")
    }

    // MARK: - Long paths

    @Test("a short path stays whole")
    func shortPath() {
        #expect(FolderPathUseCase.short("/Volumes/Work", home: home) == "/Volumes/Work")
    }

    @Test("a long path is cut in the middle and keeps the last folders")
    func longPath() {
        let path = "/Users/jamie/Documents/Projects/Writing/Research/Notebooks/Garden"
        let short = FolderPathUseCase.short(path, home: home, limit: 36)

        #expect(short == "~/…/Research/Notebooks/Garden")
        #expect(short.count <= 36)
    }

    @Test("an absolute path outside the home folder keeps its first folder")
    func absolutePath() {
        let short = FolderPathUseCase.short("/Volumes/S990/Developer/Clients/Acme/Vaults/Work", home: home, limit: 25)

        #expect(short == "/Volumes/…/Vaults/Work")
    }

    @Test("when even the first and last folders are too long, the last is never cut")
    func neverCutAtTheEnd() {
        let short = FolderPathUseCase.short("/Volumes/A/B/AVeryLongFolderNameThatDoesNotFitAnywhere", home: home, limit: 20)

        #expect(short == "/Volumes/…/AVeryLongFolderNameThatDoesNotFitAnywhere")
    }

    @Test("a path of two folders is never shortened")
    func twoFolders() {
        #expect(FolderPathUseCase.short("/Volumes/AVeryLongFolderNameThatDoesNotFitAnywhere", home: home, limit: 10) == "/Volumes/AVeryLongFolderNameThatDoesNotFitAnywhere")
    }
}
