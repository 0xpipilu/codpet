import AppKit
import Foundation

struct CodexApplyFeedback {
    let message: String
    let didLiveApply: Bool
}

final class CodexController {
    private enum Constants {
        static let codexBundleIdentifier = "com.openai.codex"
        static let codexAppPath = "/Applications/Codex.app"
        static let codexExecutablePath = "/Applications/Codex.app/Contents/MacOS/Codex"
        static let compatibilityFileName = "codex-compatibility.json"
        static let devToolsPorts = [9222, 9223, 9333]
    }

    private enum MainWriteStrategy: String, Codable, CaseIterable {
        case settingsWriteBridge
        case setSettingBridge
        case settingsWriteDispatch
        case setSettingDispatch
        case frontWindowSetSetting
    }

    private struct CompatibilityProfile: Codable {
        var preferredWriteStrategy: MainWriteStrategy?
        var updatedAt: Date
    }

    private struct CompatibilityStore: Codable {
        var versions: [String: CompatibilityProfile] = [:]
    }

    private struct DevToolsTarget: Decodable {
        let id: String?
        let type: String?
        let title: String?
        let url: String?
        let webSocketDebuggerUrl: String?
    }

    private struct DevToolsTargets {
        let port: Int
        let main: DevToolsTarget?
        let overlay: DevToolsTarget?
    }

    private enum BridgeExecutionError: Error {
        case message(String)
    }

    private enum ApplyResult {
        case verified(write: MainWriteStrategy?)
        case sessionMissingLiveChannel
        case configOnly
    }

    private let fileManager = FileManager.default
    private let codexAppURL = URL(fileURLWithPath: Constants.codexAppPath)
    private let codexExecutableURL = URL(fileURLWithPath: Constants.codexExecutablePath)

    private var codexDir: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".codex", isDirectory: true)
    }

    private var configTomlURL: URL {
        codexDir.appendingPathComponent("config.toml")
    }

    private var compatibilityStoreURL: URL {
        let appSupport = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("CodpetPersonal", isDirectory: true)
        return appSupport.appendingPathComponent(Constants.compatibilityFileName)
    }

    func currentActiveSlug() -> String? {
        guard let content = try? String(contentsOf: configTomlURL, encoding: .utf8) else {
            return nil
        }
        return parseSelectedAvatarSlug(from: content)
    }

    func openCodex() {
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: Constants.codexBundleIdentifier).first {
            app.activate(options: [.activateAllWindows])
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: codexAppURL, configuration: configuration) { _, _ in }
    }

    func apply(slug: String, mode: ApplyMode) async -> CodexApplyFeedback {
        do {
            try writeSelectedPet(slug: slug)
        } catch {
            return CodexApplyFeedback(
                message: "Couldn't update Codex config: \(error.localizedDescription)",
                didLiveApply: false
            )
        }

        guard mode == .immediate else {
            return CodexApplyFeedback(
                message: "Updated config for \(slug). Codex will pick it up the next time it refreshes.",
                didLiveApply: false
            )
        }

        let result = await performImmediateApply(slug: slug, versionKey: currentCodexVersionKey())

        switch result {
        case .verified:
            return CodexApplyFeedback(
                message: "Applied \(slug) to Codex.",
                didLiveApply: true
            )
        case .sessionMissingLiveChannel:
            return CodexApplyFeedback(
                message: "Updated \(slug) in config, but this Codex session didn't expose a live refresh bridge, so the running desktop pet stayed unchanged.",
                didLiveApply: false
            )
        case .configOnly:
            return CodexApplyFeedback(
                message: "Updated \(slug) in config, but Codpet still couldn't confirm the running Codex overlay refreshed right away.",
                didLiveApply: false
            )
        }
    }

    func restartCodexOnceForPetRefresh() async -> String {
        let repaired = await restartCodexWithDebugPortIfNeeded()
        guard repaired else {
            return "Codpet couldn't restart Codex automatically."
        }

        let targets = await waitForDevToolsTargets(timeoutSeconds: 6.0)
        guard targets != nil else {
            return "Codex restarted, but its live apply channel still didn't come up."
        }

        return "Codex restarted once. You can keep working in this session and test pet apply again when convenient."
    }

    func prewarmCompatibilityIfNeeded(for slug: String) async {
        guard !slug.isEmpty else { return }
        guard isCodexRunning else { return }

        let versionKey = currentCodexVersionKey()
        guard loadCompatibilityStore().versions[versionKey] == nil else { return }

        _ = await performImmediateApply(slug: slug, versionKey: versionKey)
    }

    private var isCodexRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: Constants.codexBundleIdentifier).isEmpty
    }

    private func performImmediateApply(slug: String, versionKey: String) async -> ApplyResult {
        let storedProfile = loadCompatibilityStore().versions[versionKey]

        if applyFrontWindowBridge(slug: slug) {
            if let targets = await discoverDevToolsTargets() {
                if await verifyAppliedSlug(slug, using: targets) {
                    persistCompatibilityProfile(
                        versionKey: versionKey,
                        writeStrategy: .frontWindowSetSetting
                    )
                    return .verified(write: .frontWindowSetSetting)
                }
            } else {
                persistCompatibilityProfile(
                    versionKey: versionKey,
                    writeStrategy: .frontWindowSetSetting
                )
                return .verified(write: .frontWindowSetSetting)
            }
        }

        let targets = await discoverDevToolsTargets()

        return await performImmediateApplyWithTargets(
            slug: slug,
            versionKey: versionKey,
            storedProfile: storedProfile,
            targets: targets
        )
    }

    private func performImmediateApplyWithTargets(
        slug: String,
        versionKey: String,
        storedProfile: CompatibilityProfile?,
        targets: DevToolsTargets?
    ) async -> ApplyResult {
        let candidateTargets = [targets?.main, targets?.overlay].compactMap { $0 }
        guard !candidateTargets.isEmpty else { return .configOnly }

        for target in candidateTargets {
            for strategy in orderedWriteStrategies(preferred: storedProfile?.preferredWriteStrategy) {
                if await applyWriteStrategy(strategy, slug: slug, to: target) {
                    if await verifyAppliedSlug(slug, using: targets)
                        || target.webSocketDebuggerUrl == targets?.overlay?.webSocketDebuggerUrl {
                        persistCompatibilityProfile(
                            versionKey: versionKey,
                            writeStrategy: strategy
                        )
                        return .verified(write: strategy)
                    }
                    break
                }
            }
        }

        return .configOnly
    }

    private func orderedWriteStrategies(preferred: MainWriteStrategy?) -> [MainWriteStrategy] {
        var strategies: [MainWriteStrategy] = [
            .frontWindowSetSetting,
            .setSettingBridge,
            .settingsWriteBridge,
            .setSettingDispatch,
            .settingsWriteDispatch
        ]

        if let preferred, let index = strategies.firstIndex(of: preferred) {
            strategies.remove(at: index)
            strategies.insert(preferred, at: 0)
        }

        return strategies
    }

    private func applyWriteStrategy(_ strategy: MainWriteStrategy, slug: String, to target: DevToolsTarget) async -> Bool {
        let expression = makeDevToolsWriteExpression(slug: slug, strategy: strategy)
        do {
            let value = try await evaluateJavaScript(on: target, expression: expression)
            return decodeBridgeSuccess(from: value)
        } catch {
            return false
        }
    }

    private func verifyAppliedSlug(_ slug: String, using targets: DevToolsTargets?) async -> Bool {
        let expectedTokens = verificationTokens(for: slug)
        let candidates = [targets?.overlay, targets?.main].compactMap { $0 }

        for target in candidates {
            if await targetContainsAnyToken(target, tokens: expectedTokens) {
                return true
            }
        }

        return false
    }

    private func targetContainsAnyToken(_ target: DevToolsTarget, tokens: [String]) async -> Bool {
        do {
            let value = try await evaluateJavaScript(on: target, expression: inspectOverlayExpression)
            guard let haystack = flattenInspectionValue(value) else { return false }
            return tokens.contains(where: { haystack.localizedCaseInsensitiveContains($0) })
        } catch {
            return false
        }
    }

    private func verificationTokens(for slug: String) -> [String] {
        let lowered = slug.lowercased()
        return [
            "custom:\(lowered)",
            "/pets/\(lowered)/",
            "\(lowered)/spritesheet",
            "\"\(lowered)\""
        ]
    }

    private func flattenInspectionValue(_ value: Any?) -> String? {
        if let string = value as? String {
            return string.lowercased()
        }
        if let dictionary = value as? [String: Any] {
            let joined = dictionary.values.map { String(describing: $0) }.joined(separator: " ")
            return joined.lowercased()
        }
        return value.map { String(describing: $0).lowercased() }
    }

    private func makeDevToolsWriteExpression(slug: String, strategy: MainWriteStrategy) -> String {
        let requestId = "codpet-" + UUID().uuidString
        let payload: String
        let url: String

        switch strategy {
        case .settingsWriteBridge:
            url = "vscode://codex/settings-write"
            payload = #"{"settings":{"selected-avatar-id":"custom:\#(slug)"}}"#
        case .setSettingBridge:
            url = "vscode://codex/set-setting"
            payload = #"{"key":"selected-avatar-id","value":"custom:\#(slug)"}"#
        case .settingsWriteDispatch:
            url = "vscode://codex/settings-write"
            payload = #"{"settings":{"selected-avatar-id":"custom:\#(slug)"}}"#
        case .setSettingDispatch:
            url = "vscode://codex/set-setting"
            payload = #"{"key":"selected-avatar-id","value":"custom:\#(slug)"}"#
        case .frontWindowSetSetting:
            url = "vscode://codex/set-setting"
            payload = #"{"key":"selected-avatar-id","value":"custom:\#(slug)"}"#
        }

        let escapedPayload = escapeForJavaScript(payload)

        return """
        (async () => {
          try {
            const bridge = window.electronBridge;
            const requestId = "\(requestId)";
            const postLocalMessage = (message) => {
              try {
                window.postMessage(message, window.location.origin);
                return true;
              } catch (error) {
                try {
                  window.dispatchEvent(new MessageEvent("message", {
                    data: message,
                    origin: window.location.origin,
                    source: window
                  }));
                  return true;
                } catch {
                  return false;
                }
              }
            };
            const postToHost = async (message) => {
              if (bridge && typeof bridge.sendMessageFromView === "function") {
                await bridge.sendMessageFromView(message);
                return "bridge";
              }
              window.dispatchEvent(new CustomEvent("codex-message-from-view", { detail: message }));
              return "dispatch";
            };
            const sendFetch = async (requestURL, body) => {
              const fetchRequestId = requestId + "-fetch";
              return await new Promise(async (resolve, reject) => {
                let settled = false;
                const timeout = setTimeout(() => {
                  if (settled) return;
                  settled = true;
                  window.removeEventListener("message", onMessage);
                  reject(new Error("fetch-timeout"));
                }, 3000);
                const onMessage = (event) => {
                  const data = event?.data;
                  if (!data || data.type !== "fetch-response" || data.requestId !== fetchRequestId) return;
                  if (settled) return;
                  settled = true;
                  clearTimeout(timeout);
                  window.removeEventListener("message", onMessage);
                  if (data.responseType === "success" && data.status >= 200 && data.status < 300) {
                    resolve(data);
                    return;
                  }
                  reject(new Error(data.error || data.bodyJsonString || "fetch-failed"));
                };
                window.addEventListener("message", onMessage);
                try {
                  await postToHost({
                    type: "fetch",
                    requestId: fetchRequestId,
                    url: requestURL,
                    method: "POST",
                    body
                  });
                } catch (error) {
                  clearTimeout(timeout);
                  window.removeEventListener("message", onMessage);
                  reject(error);
                }
              });
            };
            const invalidateQuery = async (queryKey) => {
              const message = { type: "query-cache-invalidate", queryKey };
              postLocalMessage(message);
              try {
                await postToHost(message);
              } catch {}
            };

            await sendFetch("\(url)", "\(escapedPayload)");
            await invalidateQuery(["vscode", "get-settings"]);
            await invalidateQuery(["custom-avatars"]);
            await new Promise(resolve => setTimeout(resolve, 180));

            return JSON.stringify({
              ok: true,
              url: "\(url)",
              requestId,
              invalidated: [["vscode", "get-settings"], ["custom-avatars"]]
            });
          } catch (error) {
            return JSON.stringify({ ok: false, code: "js-error", error: String(error) });
          }
        })()
        """
    }

    private var inspectOverlayExpression: String {
        """
        (() => {
          const avatar = document.querySelector('[data-testid="codex-avatar"]')
            || document.querySelector('[data-avatar-asset-ref]')
            || document.querySelector('[style*="spritesheet"]');
          const bodySample = document.body ? document.body.innerHTML.slice(0, 5000) : "";
          const outer = avatar ? avatar.outerHTML.slice(0, 5000) : "";
          const assetRef = avatar && avatar.getAttribute ? avatar.getAttribute('data-avatar-asset-ref') : null;
          const backgroundImage = avatar ? getComputedStyle(avatar).backgroundImage : "";
          return {
            title: document.title || "",
            url: location.href || "",
            assetRef: assetRef || "",
            backgroundImage,
            outer,
            bodySample
          };
        })()
        """
    }

    private func decodeBridgeSuccess(from value: Any?) -> Bool {
        guard let string = value as? String else {
            return false
        }
        guard let data = string.data(using: .utf8),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return string.contains("\"ok\":true")
        }
        return payload["ok"] as? Bool == true
    }

    private func applyFrontWindowBridge(slug: String) -> Bool {
        let javascript = makeDevToolsWriteExpression(slug: slug, strategy: .frontWindowSetSetting)
        switch executeInCodexActiveTab(javascript: javascript) {
        case .success(let raw):
            guard let data = raw.data(using: String.Encoding.utf8),
                  let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return raw.contains("\"ok\":true")
            }
            return payload["ok"] as? Bool == true
        case .failure:
            return false
        }
    }

    private func reloadCodexWindow() -> Bool {
        let scriptText = """
        tell application "Codex" to activate
        delay 0.12
        tell application "System Events"
            if exists process "Codex" then
                keystroke "r" using {command down}
                return true
            end if
            return false
        end tell
        """

        var error: NSDictionary?
        guard let script = NSAppleScript(source: scriptText) else {
            return false
        }

        let output = script.executeAndReturnError(&error)
        return error == nil && output.booleanValue
    }

    private func executeInCodexActiveTab(javascript: String) -> Result<String, BridgeExecutionError> {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: Constants.codexBundleIdentifier).first else {
            return .failure(.message("Codex is not running."))
        }

        app.activate(options: [.activateAllWindows])
        Thread.sleep(forTimeInterval: 0.15)

        let scriptText = """
        tell application id "\(Constants.codexBundleIdentifier)"
            if (count of windows) is 0 then return "{\\"ok\\":false,\\"code\\":\\"no-windows\\"}"
            set bridgeScript to "\(appleScriptEscaped(javascript))"
            return execute active tab of front window javascript bridgeScript
        end tell
        """

        var error: NSDictionary?
        guard let script = NSAppleScript(source: scriptText) else {
            return .failure(.message("Couldn't create the AppleScript bridge."))
        }

        let descriptor = script.executeAndReturnError(&error)
        if let error {
            return .failure(.message(codexBridgeErrorMessage(from: error)))
        }

        return .success(descriptor.stringValue ?? "")
    }

    private func codexBridgeErrorMessage(from error: NSDictionary) -> String {
        let code = error[NSAppleScript.errorNumber] as? Int
        let message = error[NSAppleScript.errorMessage] as? String

        switch code {
        case -1728:
            return "No scriptable Codex window was available."
        case -1743:
            return "Automation permission for Codex hasn't been granted yet."
        default:
            if let message, !message.isEmpty {
                return message
            }
            if let code {
                return "AppleScript error \(code)."
            }
            return "Unknown AppleScript bridge failure."
        }
    }

    private func appleScriptEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private func escapeForJavaScript(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private func discoverDevToolsTargets() async -> DevToolsTargets? {
        for port in Constants.devToolsPorts {
            guard let targets = try? await fetchDevToolsTargets(port: port) else { continue }
            let main = selectMainTarget(from: targets)
            let overlay = selectOverlayTarget(from: targets)
            if main != nil || overlay != nil {
                return DevToolsTargets(port: port, main: main, overlay: overlay)
            }
        }
        return nil
    }

    private func waitForDevToolsTargets(timeoutSeconds: TimeInterval) async -> DevToolsTargets? {
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while Date() < deadline {
            if let targets = await discoverDevToolsTargets() {
                return targets
            }
            try? await Task.sleep(nanoseconds: 350_000_000)
        }
        return nil
    }

    private func restartCodexWithDebugPortIfNeeded() async -> Bool {
        terminateCodexSessionHard()
        guard launchCodexWithDebugPort() else {
            return false
        }

        return await waitForDevToolsTargets(timeoutSeconds: 8.0) != nil
    }

    private func launchCodexWithDebugPort() -> Bool {
        guard fileManager.fileExists(atPath: codexExecutableURL.path) else {
            return false
        }

        let process = Process()
        process.executableURL = codexExecutableURL
        process.arguments = ["--remote-debugging-port=9222"]

        if let nullOutput = FileHandle(forWritingAtPath: "/dev/null") {
            process.standardOutput = nullOutput
            process.standardError = nullOutput
        }

        do {
            try process.run()
        } catch {
            return false
        }

        let deadline = Date().addingTimeInterval(4.0)
        while Date() < deadline {
            if let app = NSRunningApplication.runningApplications(withBundleIdentifier: Constants.codexBundleIdentifier).first {
                app.activate(options: [.activateAllWindows])
            }

            if hasCodexProcessesRunning() {
                return true
            }

            Thread.sleep(forTimeInterval: 0.12)
        }

        return process.isRunning || hasCodexProcessesRunning()
    }

    private func terminateCodexSessionHard() {
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: Constants.codexBundleIdentifier)
        for app in runningApps {
            _ = app.terminate()
        }

        waitForMainCodexAppToExit(timeout: 2.5)

        if hasCodexProcessesRunning() {
            runBestEffort("/usr/bin/pkill", arguments: ["-TERM", "-f", "/Applications/Codex.app/Contents/"])
            Thread.sleep(forTimeInterval: 0.8)
        }

        if hasCodexProcessesRunning() {
            runBestEffort("/usr/bin/pkill", arguments: ["-KILL", "-f", "/Applications/Codex.app/Contents/"])
            Thread.sleep(forTimeInterval: 0.8)
        }

        waitUntilCodexProcessesDisappear(timeout: 4.0)
    }

    private func waitForMainCodexAppToExit(timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if NSRunningApplication.runningApplications(withBundleIdentifier: Constants.codexBundleIdentifier).isEmpty {
                return
            }
            Thread.sleep(forTimeInterval: 0.12)
        }

        for app in NSRunningApplication.runningApplications(withBundleIdentifier: Constants.codexBundleIdentifier) {
            _ = app.forceTerminate()
        }
    }

    private func waitUntilCodexProcessesDisappear(timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !hasCodexProcessesRunning() {
                return
            }
            Thread.sleep(forTimeInterval: 0.15)
        }
    }

    private func hasCodexProcessesRunning() -> Bool {
        let output = runProcessAndCaptureOutput("/usr/bin/pgrep", arguments: ["-f", "/Applications/Codex.app/Contents/"])
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    private func runBestEffort(_ launchPath: String, arguments: [String]) -> Int32? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            return nil
        }
    }

    private func runProcessAndCaptureOutput(_ launchPath: String, arguments: [String]) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return ""
        }

        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(decoding: data, as: UTF8.self)
    }

    private func fetchDevToolsTargets(port: Int) async throws -> [DevToolsTarget] {
        let url = URL(string: "http://127.0.0.1:\(port)/json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([DevToolsTarget].self, from: data)
    }

    private func selectMainTarget(from targets: [DevToolsTarget]) -> DevToolsTarget? {
        targets
            .filter { ($0.type ?? "") == "page" }
            .sorted { lhs, rhs in
                scoreMainTarget(lhs) > scoreMainTarget(rhs)
            }
            .first(where: { scoreMainTarget($0) > 0 })
    }

    private func scoreMainTarget(_ target: DevToolsTarget) -> Int {
        let url = (target.url ?? "").lowercased()
        let title = (target.title ?? "").lowercased()
        if url == "app://-/index.html" { return 100 }
        if url.hasPrefix("app://-/index.html") { return 90 }
        if url.hasPrefix("app://-/") && !url.contains("avatar-overlay") { return 70 }
        if title.contains("codex") && !url.contains("avatar-overlay") { return 50 }
        return 0
    }

    private func selectOverlayTarget(from targets: [DevToolsTarget]) -> DevToolsTarget? {
        targets
            .filter { ($0.type ?? "") == "page" }
            .sorted { lhs, rhs in
                scoreOverlayTarget(lhs) > scoreOverlayTarget(rhs)
            }
            .first(where: { scoreOverlayTarget($0) > 0 })
    }

    private func scoreOverlayTarget(_ target: DevToolsTarget) -> Int {
        let url = (target.url ?? "").lowercased()
        let title = (target.title ?? "").lowercased()
        if url.contains("avatar-overlay") { return 100 }
        if title.contains("avatar") && title.contains("overlay") { return 80 }
        if url.contains("overlay") && title.contains("avatar") { return 70 }
        return 0
    }

    private func evaluateJavaScript(on target: DevToolsTarget, expression: String) async throws -> Any? {
        guard let urlString = target.webSocketDebuggerUrl,
              let websocketURL = URL(string: urlString) else {
            return nil
        }

        let task = URLSession.shared.webSocketTask(with: websocketURL)
        task.resume()

        let messageID = Int.random(in: 10_000...999_999)
        let payload: [String: Any] = [
            "id": messageID,
            "method": "Runtime.evaluate",
            "params": [
                "expression": expression,
                "awaitPromise": true,
                "returnByValue": true
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: payload)
        let message = URLSessionWebSocketTask.Message.string(String(decoding: data, as: UTF8.self))
        try await task.send(message)

        defer {
            task.cancel(with: .goingAway, reason: nil)
        }

        while true {
            let incoming = try await task.receive()
            guard case .string(let text) = incoming,
                  let jsonData = text.data(using: .utf8),
                  let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let incomingID = json["id"] as? Int,
                  incomingID == messageID else {
                continue
            }

            if let result = json["result"] as? [String: Any],
               let resultObject = result["result"] as? [String: Any] {
                if let value = resultObject["value"] {
                    return value
                }
                if let description = resultObject["description"] {
                    return description
                }
                return resultObject
            }

            if let error = json["error"] as? [String: Any] {
                throw NSError(
                    domain: "CodexController.CDP",
                    code: (error["code"] as? Int) ?? -1,
                    userInfo: [NSLocalizedDescriptionKey: error["message"] as? String ?? "Unknown CDP error"]
                )
            }

            return nil
        }
    }

    private func writeSelectedPet(slug: String) throws {
        if !fileManager.fileExists(atPath: codexDir.path) {
            try fileManager.createDirectory(at: codexDir, withIntermediateDirectories: true)
        }

        var lines: [String] = []
        if fileManager.fileExists(atPath: configTomlURL.path) {
            let content = try String(contentsOf: configTomlURL, encoding: .utf8)
            lines = content.components(separatedBy: .newlines)
        }

        var desktopSectionIndex: Int?
        var avatarLineIndex: Int?
        var nextSectionIndex: Int?

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "[desktop]" {
                desktopSectionIndex = index
                continue
            }

            guard desktopSectionIndex != nil else { continue }

            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                nextSectionIndex = index
                break
            }

            if trimmed.hasPrefix("selected-avatar-id") {
                avatarLineIndex = index
            }
        }

        let newLine = #"selected-avatar-id = "custom:\#(slug)""#

        if let avatarLineIndex {
            lines[avatarLineIndex] = newLine
        } else if let desktopSectionIndex {
            let insertIndex = min((nextSectionIndex ?? lines.count), desktopSectionIndex + 1)
            lines.insert(newLine, at: insertIndex)
        } else {
            if !lines.isEmpty, lines.last?.isEmpty == false {
                lines.append("")
            }
            lines.append("[desktop]")
            lines.append(newLine)
        }

        let updated = lines.joined(separator: "\n")
        try updated.write(to: configTomlURL, atomically: false, encoding: .utf8)
    }

    private func parseSelectedAvatarSlug(from content: String) -> String? {
        let lines = content.components(separatedBy: .newlines)
        var inDesktopSection = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "[desktop]" {
                inDesktopSection = true
                continue
            }

            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                inDesktopSection = false
            }

            guard inDesktopSection, trimmed.hasPrefix("selected-avatar-id") else { continue }

            let pieces = trimmed.split(separator: "=", maxSplits: 1).map(String.init)
            guard pieces.count == 2 else { continue }
            let rawValue = pieces[1]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "'", with: "")
            if rawValue.hasPrefix("custom:") {
                return String(rawValue.dropFirst("custom:".count))
            }
            return rawValue
        }

        return nil
    }

    private func currentCodexVersionKey() -> String {
        guard let bundle = Bundle(url: codexAppURL) else {
            return "codex-unknown"
        }

        let shortVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildVersion = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (shortVersion, buildVersion) {
        case let (.some(shortVersion), .some(buildVersion)):
            return "codex-\(shortVersion)-\(buildVersion)"
        case let (.some(shortVersion), nil):
            return "codex-\(shortVersion)"
        case let (nil, .some(buildVersion)):
            return "codex-build-\(buildVersion)"
        default:
            return "codex-unknown"
        }
    }

    private func loadCompatibilityStore() -> CompatibilityStore {
        guard let data = try? Data(contentsOf: compatibilityStoreURL),
              let decoded = try? JSONDecoder().decode(CompatibilityStore.self, from: data) else {
            return CompatibilityStore()
        }
        return decoded
    }

    private func persistCompatibilityProfile(
        versionKey: String,
        writeStrategy: MainWriteStrategy?
    ) {
        var store = loadCompatibilityStore()
        store.versions[versionKey] = CompatibilityProfile(
            preferredWriteStrategy: writeStrategy,
            updatedAt: Date()
        )

        let parent = compatibilityStoreURL.deletingLastPathComponent()
        try? fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(store) {
            try? data.write(to: compatibilityStoreURL, options: .atomic)
        }
    }
}
