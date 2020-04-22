// Copyright 2020 Itty Bitty Apps Pty Ltd

import AppStoreConnect_Swift_SDK
import ArgumentParser
import Combine
import Foundation

struct CreateCertificateCommand: CommonParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new certificate using a certificate signing request.")

    @OptionGroup()
    var common: CommonOptions

    @Argument(help: "The type of certificate to create \(CertificateType.allCases).")
    var certificateType: CertificateType

    @Argument(help: "The Certificate Signing Request (CSR) file path.")
    var csrFile: String

    func run() throws {
        let api = try makeService()

        let csrContent = try String(contentsOfFile: csrFile, encoding: .utf8)

        let endpoint = APIEndpoint.create(
            certificateWithCertificateType: certificateType,
            csrContent: csrContent
        )

        _ = api
            .request(endpoint)
            .map { Certificate($0.data) }
            .renderResult(format: common.outputFormat)
    }
}
