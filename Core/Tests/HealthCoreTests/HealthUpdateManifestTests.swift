import Foundation
import XCTest
@testable import HealthCore

final class HealthUpdateManifestTests: XCTestCase {
    private let trustedHosts: Set<String> = ["updates.example.org"]

    private func json(url: String = "https://updates.example.org/install",
                      channel: String = "testflight", build: Int = 101,
                      schema: Int = 1, digest: String? = nil) -> Data {
        var payload: [String: Any] = [
            "schemaVersion": schema, "channel": channel,
            "version": "4.0.1", "build": build,
            "minimumSupportedBuild": 100,
            "releaseNotes": ["授权修复"],
            "publishedAt": "2026-11-21T00:00:00Z",
            "installPageURL": url
        ]
        if let digest { payload["artifactSHA256"] = digest }
        return try! JSONSerialization.data(withJSONObject: payload)
    }

    func testTrustedManifestAndBuildComparison() throws {
        let manifest = try HealthUpdateManifest.decodeAndValidate(
            json(), trustedHosts: trustedHosts)
        XCTAssertTrue(manifest.isNewer(thanInstalledBuild: 100))
        XCTAssertFalse(manifest.isNewer(thanInstalledBuild: 101))
    }

    func testRejectsHostSuffixSpoofing() {
        XCTAssertThrowsError(try HealthUpdateManifest.decodeAndValidate(
            json(url: "https://updates.example.org.evil.test/install"),
            trustedHosts: trustedHosts))
    }

    func testRejectsHTTPAndCredentialURL() {
        for url in ["http://updates.example.org/install",
                    "https://user:pass@updates.example.org/install"] {
            XCTAssertThrowsError(try HealthUpdateManifest.decodeAndValidate(
                json(url: url), trustedHosts: trustedHosts))
        }
    }

    func testRejectsUnsupportedSchemaAndChannel() {
        XCTAssertThrowsError(try HealthUpdateManifest.decodeAndValidate(
            json(schema: 2), trustedHosts: trustedHosts))
        XCTAssertThrowsError(try HealthUpdateManifest.decodeAndValidate(
            json(channel: "silent-install"), trustedHosts: trustedHosts))
    }

    func testRejectsDowngradedBuildAndInvalidDigest() {
        XCTAssertThrowsError(try HealthUpdateManifest.decodeAndValidate(
            json(build: 99), trustedHosts: trustedHosts))
        XCTAssertThrowsError(try HealthUpdateManifest.decodeAndValidate(
            json(digest: "not-sha256"), trustedHosts: trustedHosts))
    }

    func testDecisionDistinguishesOptionalAndUnsupportedBuilds() throws {
        let manifest = try HealthUpdateManifest.decodeAndValidate(
            json(), trustedHosts: trustedHosts)
        XCTAssertEqual(manifest.decision(forInstalledBuild: 101), .upToDate)
        XCTAssertEqual(manifest.decision(forInstalledBuild: 102), .upToDate)
        XCTAssertEqual(manifest.decision(forInstalledBuild: 100), .optionalUpdate)
        XCTAssertEqual(manifest.decision(forInstalledBuild: 99), .unsupportedInstalledBuild)
        XCTAssertEqual(manifest.decision(forInstalledBuild: 0), .unsupportedInstalledBuild)
    }

    func testAcceptsWellFormedDigest() throws {
        let manifest = try HealthUpdateManifest.decodeAndValidate(
            json(digest: String(repeating: "a", count: 64)),
            trustedHosts: trustedHosts)
        XCTAssertEqual(manifest.artifactSHA256?.count, 64)
    }
}
