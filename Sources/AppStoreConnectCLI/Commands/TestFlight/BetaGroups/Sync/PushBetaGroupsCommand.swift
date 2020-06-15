// Copyright 2020 Itty Bitty Apps Pty Ltd

import ArgumentParser
import FileSystem
import Foundation
import struct Model.BetaGroup

struct PushBetaGroupsCommand: CommonParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "push",
        abstract: "Push local beta group config files to server, update server beta groups"
    )

    @OptionGroup()
    var common: CommonOptions

    @Option(
        default: "./config/betagroups",
        help: "Path to the Folder containing the information about beta groups. (default: './config/betagroups')"
    ) var inputPath: String

    @Flag(help: "Perform a dry run.")
    var dryRun: Bool

    func run() throws {
        let service = try makeService()

        let resourceProcessor = BetaGroupProcessor(path: .folder(path: inputPath))

        let serverGroups = try service.pullBetaGroups().map { $0.betaGroup }
        let localGroups = try resourceProcessor.read()

        let strategies = SyncResourceComparator(
                localResources: localGroups,
                serverResources: serverGroups
            )
            .compare()

        let renderer = Renderers.SyncResultRenderer<BetaGroup>()

        if dryRun {
            renderer.render(strategies, isDryRun: true)
        } else {
            try strategies.forEach { (strategy: SyncStrategy) in
                try syncBetaGroup(strategy: strategy, with: service)
                renderer.render(strategy, isDryRun: false)
            }

            let betaGroupWithTesters = try service.pullBetaGroups()

            try resourceProcessor.write(groupsWithTesters: betaGroupWithTesters)
        }
    }

    func syncBetaGroup(
        strategy: SyncStrategy<BetaGroup>,
        with service: AppStoreConnectService
    ) throws {
        switch strategy {
        case .create(let group):
            _ = try service.createBetaGroup(
                appBundleId: group.app.bundleId!,
                groupName: group.groupName,
                publicLinkEnabled: group.publicLinkEnabled ?? false,
                publicLinkLimit: group.publicLinkLimit
            )
        case .delete(let group):
            try service.deleteBetaGroup(with: group.id!)
        case .update(let group):
            try service.updateBetaGroup(betaGroup: group)
        }
    }

}