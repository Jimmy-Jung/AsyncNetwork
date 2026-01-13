//
//  TraceKitViewModelLogger.swift
//  AsyncViewModel
//
//  Created by jimmy on 2025/12/29.
//

import AsyncViewModel
import Foundation
import TraceKit

extension LogLevel {
    var traceLevel: TraceLevel {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .fatal: return .fatal
        }
    }
}

@MainActor
public struct TraceKitViewModelLogger: ViewModelLogger {
    public var options: LoggingOptions = .init()

    public init() {}

    public func logAction(
        _ action: String,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        guard level.rawValue >= options.minimumLevel.rawValue else { return }

        switch options.format {
        case .compact:
            let message = "\(action)"
            TraceKit.log(
                level: level.traceLevel,
                message,
                category: viewModel,
                file: file,
                function: function,
                line: line
            )

        case .standard, .detailed:
            let message = "Action: \(action)"
            TraceKit.log(
                level: level.traceLevel,
                message,
                category: viewModel,
                metadata: [
                    "type": .init("action"),
                    "action": .init(action),
                ],
                file: file,
                function: function,
                line: line
            )
        }
    }

    public func logStateChange(
        from oldState: String,
        to newState: String,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        let message = "State changed from:\n\(oldState)\n\nto:\n\(newState)"
        TraceKit.log(
            level: .info,
            message,
            category: viewModel,
            metadata: [
                "type": .init("state_change"),
                "old_state": .init(oldState),
                "new_state": .init(newState),
            ],
            file: file,
            function: function,
            line: line
        )
    }

    public func logEffect(
        _ effect: String,
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard LogLevel.debug.rawValue >= options.minimumLevel.rawValue else { return }

        let message = "Effect: \(effect)"
        TraceKit.log(
            level: .debug,
            message,
            category: viewModel,
            metadata: [
                "type": .init("effect"),
                "effect": .init(effect),
            ],
            file: file,
            function: function,
            line: line
        )
    }

    public func logEffects(
        _ effects: [String],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard LogLevel.debug.rawValue >= options.minimumLevel.rawValue else { return }

        switch options.format {
        case .compact:
            let message = "[\(effects.count) effects]"
            TraceKit.log(
                level: .debug,
                message,
                category: viewModel,
                file: file,
                function: function,
                line: line
            )

        case .standard:
            let summary = effects.map { effect in
                effect.split(separator: "(").first.map(String.init) ?? effect
            }.joined(separator: ", ")

            let message = "Effects[\(effects.count)]: \(summary)"
            TraceKit.log(
                level: .debug,
                message,
                category: viewModel,
                metadata: ["effect_count": .init(effects.count)],
                file: file,
                function: function,
                line: line
            )

        case .detailed:
            for (index, effect) in effects.enumerated() {
                let message = "Effect \(index + 1)/\(effects.count): \(effect)"
                TraceKit.log(
                    level: .verbose,
                    message,
                    category: viewModel,
                    metadata: [
                        "type": .init("effect"),
                        "effect": .init(effect),
                        "index": .init(index),
                        "total": .init(effects.count),
                    ],
                    file: file,
                    function: function,
                    line: line
                )
            }
        }
    }

    public func logStateDiff(
        changes: [String: (old: String, new: String)],
        viewModel: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard LogLevel.info.rawValue >= options.minimumLevel.rawValue else { return }

        switch options.format {
        case .compact:
            let message = formatCompactStateDiff(changes)
            TraceKit.log(
                level: .info,
                message,
                category: viewModel,
                file: file,
                function: function,
                line: line
            )

        case .standard:
            let changeDescriptions = changes.sorted(by: { $0.key < $1.key }).map { key, values in
                "\(key): \(values.old) → \(values.new)"
            }.joined(separator: "\n  - ")

            let message = "State changed:\n  - \(changeDescriptions)"

            var metadata: [String: AnyCodable] = ["type": AnyCodable("state_change")]
            for (key, values) in changes {
                metadata["old_\(key)"] = AnyCodable(values.old)
                metadata["new_\(key)"] = AnyCodable(values.new)
            }

            TraceKit.log(
                level: .info,
                message,
                category: viewModel,
                metadata: metadata,
                file: file,
                function: function,
                line: line
            )

        case .detailed:
            let changeDescriptions = changes.sorted(by: { $0.key < $1.key }).map { key, values in
                "  \(key):\n    old: \(values.old)\n    new: \(values.new)"
            }.joined(separator: "\n")

            let message = "State changed:\n\(changeDescriptions)"

            var metadata: [String: AnyCodable] = ["type": AnyCodable("state_change")]
            for (key, values) in changes {
                metadata["old_\(key)"] = AnyCodable(values.old)
                metadata["new_\(key)"] = AnyCodable(values.new)
            }

            TraceKit.log(
                level: .info,
                message,
                category: viewModel,
                metadata: metadata,
                file: file,
                function: function,
                line: line
            )
        }
    }

    public func logPerformance(
        operation: String,
        duration: TimeInterval,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        guard level.rawValue >= options.minimumLevel.rawValue else { return }

        let (threshold, shouldWarn) = calculatePerformanceThreshold(operation: operation, duration: duration)

        if !options.showZeroPerformance, duration < threshold {
            return
        }

        let finalLevel = shouldWarn ? LogLevel.warning.traceLevel : level.traceLevel

        switch options.format {
        case .compact:
            let icon = shouldWarn ? "⚠️" : "⚡️"
            let message = "\(icon) \(String(format: "%.3f", duration))s"
            TraceKit.log(
                level: finalLevel,
                message,
                category: viewModel,
                file: file,
                function: function,
                line: line
            )

        case .standard, .detailed:
            let prefix = shouldWarn ? "⚠️ SLOW" : "Performance"
            let message = "\(prefix) - \(operation): \(String(format: "%.3f", duration))s (threshold: \(String(format: "%.3f", threshold))s)"
            TraceKit.log(
                level: finalLevel,
                message,
                category: viewModel,
                metadata: [
                    "type": .init("performance"),
                    "operation": .init(operation),
                    "duration": .init(duration),
                    "threshold": .init(threshold),
                    "exceeded": .init(shouldWarn),
                ],
                file: file,
                function: function,
                line: line
            )
        }
    }

    public func logError(
        _ error: SendableError,
        viewModel: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        let message = "Error: \(error.localizedDescription) [\(error.domain):\(error.code)]"
        TraceKit.log(
            level: level.traceLevel,
            message,
            category: viewModel,
            metadata: [
                "type": .init("error"),
                "error_description": .init(error.localizedDescription),
                "error_domain": .init(error.domain),
                "error_code": .init(error.code),
            ],
            file: file,
            function: function,
            line: line
        )
    }

    // MARK: - Private Helpers

    private func formatCompactStateDiff(_ changes: [String: (old: String, new: String)]) -> String {
        let sortedChanges = changes.sorted(by: { $0.key < $1.key })

        let simpleChanges = sortedChanges.filter { _, values in
            !values.old.contains("(") && !values.new.contains("(")
        }

        let complexChanges = sortedChanges.filter { _, values in
            values.old.contains("(") || values.new.contains("(")
        }

        var messageParts: [String] = []

        if !simpleChanges.isEmpty {
            let simpleSummary = simpleChanges.map { key, values in
                "\(key): \(values.old) → \(values.new)"
            }.joined(separator: ", ")
            messageParts.append(simpleSummary)
        }

        if !complexChanges.isEmpty {
            let complexSummary = complexChanges.map { key, _ in
                "\(key) changed"
            }.joined(separator: ", ")
            messageParts.append("[\(complexSummary)]")
        }

        return messageParts.joined(separator: " ")
    }

    private func calculatePerformanceThreshold(operation: String, duration: TimeInterval) -> (threshold: TimeInterval, shouldWarn: Bool) {
        let threshold: TimeInterval
        let shouldWarn: Bool

        if let performanceThreshold = options.performanceThreshold {
            threshold = performanceThreshold.threshold
            shouldWarn = duration >= threshold
        } else {
            let operationType = PerformanceThreshold.infer(from: operation)
            threshold = operationType.recommendedThreshold
            shouldWarn = duration >= threshold
        }

        return (threshold, shouldWarn)
    }
}
