/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

extension Datadog {
    internal struct Constants {
        /// Value for `ddsource` send by different features.
        static let ddsource = "ios"
    }

    /// Datadog SDK configuration.
    public struct Configuration {
        /// Determines the server for uploading logs.
        public enum LogsEndpoint {
            /// US based servers.
            /// Sends logs to [app.datadoghq.com](https://app.datadoghq.com/).
            case us
            /// Europe based servers.
            /// Sends logs to [app.datadoghq.eu](https://app.datadoghq.eu/).
            case eu
            /// Gov servers.
            /// Sends logs to [app.ddog-gov.com](https://app.ddog-gov.com/).
            case gov
            /// User-defined server.
            case custom(url: String)

            internal var url: String {
                switch self {
                case .us: return "https://mobile-http-intake.logs.datadoghq.com/v1/input/"
                case .eu: return "https://mobile-http-intake.logs.datadoghq.eu/v1/input/"
                case .gov: return "https://mobile-http-intake.logs.ddog-gov.com/v1/input/"
                case let .custom(url: url): return url
                }
            }
        }

        /// Determines the server for uploading traces.
        public enum TracesEndpoint {
            /// US based servers.
            /// Sends traces to [app.datadoghq.com](https://app.datadoghq.com/).
            case us
            /// Europe based servers.
            /// Sends traces to [app.datadoghq.eu](https://app.datadoghq.eu/).
            case eu
            /// Gov servers.
            /// Sends traces to [app.ddog-gov.com](https://app.ddog-gov.com/).
            case gov
            /// User-defined server.
            case custom(url: String)

            internal var url: String {
                switch self {
                case .us: return "https://public-trace-http-intake.logs.datadoghq.com/v1/input/"
                case .eu: return "https://public-trace-http-intake.logs.datadoghq.eu/v1/input/"
                case .gov: return "https://public-trace-http-intake.logs.ddog-gov.com/v1/input/"
                case let .custom(url: url): return url
                }
            }
        }

        /// Determines the server for uploading RUM events.
        public enum RUMEndpoint {
            /// US based servers.
            /// Sends RUM events to [app.datadoghq.com](https://app.datadoghq.com/).
            case us
            /// Europe based servers.
            /// Sends RUM events to [app.datadoghq.eu](https://app.datadoghq.eu/).
            case eu
            /// Gov servers.
            /// Sends RUM events to [app.ddog-gov.com](https://app.ddog-gov.com/).
            case gov
            /// User-defined server.
            case custom(url: String)

            internal var url: String {
                switch self {
                case .us: return "https://rum-http-intake.logs.datadoghq.com/v1/input/"
                case .eu: return "https://rum-http-intake.logs.datadoghq.eu/v1/input/"
                case .gov: return "https://rum-http-intake.logs.ddog-gov.com/v1/input/"
                case let .custom(url: url): return url
                }
            }
        }

        /// The RUM Application ID.
        private(set) var rumApplicationID: String?
        /// Either the RUM client token (which supports RUM, Logging and APM) or regular client token, only for Logging and APM.
        private(set) var clientToken: String
        private(set) var environment: String
        private(set) var loggingEnabled: Bool
        private(set) var tracingEnabled: Bool
        private(set) var rumEnabled: Bool
        private(set) var logsEndpoint: LogsEndpoint
        private(set) var tracesEndpoint: TracesEndpoint
        private(set) var rumEndpoint: RUMEndpoint
        private(set) var serviceName: String?
        private(set) var firstPartyHosts: Set<String>?
        private(set) var rumSessionsSamplingRate: Float
        private(set) var rumUIKitViewsPredicate: UIKitRUMViewsPredicate?
        private(set) var rumUIKitActionsTrackingEnabled: Bool

        /// Creates the builder for configuring the SDK to work with RUM, Logging and Tracing features.
        /// - Parameter rumApplicationID: RUM Application ID obtained on Datadog website.
        /// - Parameter clientToken: the client token (generated for the RUM Application) obtained on Datadog website.
        /// - Parameter environment: the environment name which will be sent to Datadog. This can be used
        ///  to filter events on different environments (e.g. "staging" or "production").
        public static func builderUsing(rumApplicationID: String, clientToken: String, environment: String) -> Builder {
            return Builder(rumApplicationID: rumApplicationID, clientToken: clientToken, environment: environment)
        }

        /// Creates the builder for configuring the SDK to work with Logging and Tracing features.
        /// - Parameter clientToken: client token obtained on Datadog website.
        /// - Parameter environment: the environment name which will be sent to Datadog. This can be used
        ///  to filter events on different environments (e.g. "staging" or "production").
        public static func builderUsing(clientToken: String, environment: String) -> Builder {
            return Builder(rumApplicationID: nil, clientToken: clientToken, environment: environment)
        }

        /// `Datadog.Configuration` builder.
        ///
        /// Usage (to enable RUM, Logging and Tracing):
        ///
        ///     Datadog.Configuration.builderUsing(rumApplicationID:clientToken:environment:)
        ///                           ... // customize using builder methods
        ///                          .build()
        ///
        /// or (to only enable Logging and Tracing):
        ///
        ///     Datadog.Configuration.builderUsing(clientToken:environment:)
        ///                           ... // customize using builder methods
        ///                          .build()
        ///
        public class Builder {
            internal var configuration: Configuration

            /// Private initializer providing default configuration values.
            init(rumApplicationID: String?, clientToken: String, environment: String) {
                self.configuration = Configuration(
                    rumApplicationID: rumApplicationID,
                    clientToken: clientToken,
                    environment: environment,
                    loggingEnabled: true,
                    tracingEnabled: true,
                    rumEnabled: rumApplicationID != nil,
                    logsEndpoint: .us,
                    tracesEndpoint: .us,
                    rumEndpoint: .us,
                    serviceName: nil,
                    firstPartyHosts: nil,
                    rumSessionsSamplingRate: 100.0,
                    rumUIKitViewsPredicate: nil,
                    rumUIKitActionsTrackingEnabled: false
                )
            }

            // MARK: - Logging Configuration

            /// Enables or disables the logging feature.
            ///
            /// This option is meant to opt-out from using Datadog Logging entirely, no matter of your environment or build configuration. If you need to
            /// disable logging only for certain scenarios (e.g. in `DEBUG` build configuration), use `sendLogsToDatadog(false)` available
            /// on `Logger.Builder`.
            ///
            /// If `enableLogging(false)` is set, the SDK won't instantiate underlying resources required for
            /// running the logging feature. This will give you additional performance optimization if you only use RUM or tracing.
            ///
            /// **NOTE**: If you use logging for tracing (`span.log(fields:)`) keep the logging feature enabled. Otherwise the logs
            /// you send for `span` objects won't be delivered to Datadog.
            ///
            /// - Parameter enabled: `true` by default
            public func enableLogging(_ enabled: Bool) -> Builder {
                configuration.loggingEnabled = enabled
                return self
            }

            /// Sets the server endpoint to which logs are sent.
            /// - Parameter logsEndpoint: server endpoint (default value is `LogsEndpoint.us`)
            public func set(logsEndpoint: LogsEndpoint) -> Builder {
                configuration.logsEndpoint = logsEndpoint
                return self
            }

            // MARK: - Tracing Configuration

            /// Enables or disables the tracing feature.
            ///
            /// This option is meant to opt-out from using Datadog Tracing entirely, no matter of your environment or build configuration. If you need to
            /// disable tracing only for certain scenarios (e.g. in `DEBUG` build configuration), do not set `Global.sharedTracer` to `Tracer`,
            /// and your app will be using the no-op tracer instance.
            ///
            /// If `enableTracing(false)` is set, the SDK won't instantiate underlying resources required for
            /// running the tracing feature. This will give you additional performance optimization if you only use RUM or logging.
            ///
            /// - Parameter enabled: `true` by default
            public func enableTracing(_ enabled: Bool) -> Builder {
                configuration.tracingEnabled = enabled
                return self
            }

            /// Sets the server endpoint to which traces are sent.
            /// - Parameter tracesEndpoint: server endpoint (default value is `TracesEndpoint.us` )
            public func set(tracesEndpoint: TracesEndpoint) -> Builder {
                configuration.tracesEndpoint = tracesEndpoint
                return self
            }

            /// Configures network requests monitoring for Tracing and RUM features. **Must be used together with** `DDURLSessionDelegate` set as the `URLSession` delegate.
            @available(*, deprecated, message: "This option is replaced by `track(firstPartyHosts:)`. Refer to the new API comment for important details.")
            public func set(tracedHosts: Set<String>) -> Builder {
                return track(firstPartyHosts: tracedHosts)
            }

            /// Configures network requests monitoring for Tracing and RUM features. **It must be used together with** `DDURLSessionDelegate` set as the `URLSession` delegate.
            ///
            /// If set, the SDK will intercept all network requests made by `URLSession` instances which use `DDURLSessionDelegate`.
            ///
            /// Each request will be classified as 1st- or 3rd-party based on the host comparison, i.e.:
            /// * if `firstPartyHosts` is `["example.com"]`:
            ///     - 1st-party URL examples: https://example.com/, https://api.example.com/v2/users
            ///     - 3rd-party URL examples: https://foo.com/
            /// * if `firstPartyHosts` is `["api.example.com"]`:
            ///     - 1st-party URL examples: https://api.example.com/, https://api.example.com/v2/users
            ///     - 3rd-party URL examples: https://example.com/, https://foo.com/
            ///
            /// If RUM feature is enabled, the SDK will send RUM Resources for all intercepted requests.
            ///
            /// If Tracing feature is enabled, the SDK will send tracing Span for each 1st-party request. It will also add extra HTTP headers to further propagate the trace - it means that
            /// if your backend is instrumented with Datadog agent you will see the full trace (e.g.: client → server → database) in your dashboard, thanks to Datadog Distributed Tracing.
            ///
            /// If both RUM and Tracing features are enabled, the SDK will be sending RUM Resources for 1st- and 3rd-party requests and tracing Spans for 1st-parties.
            ///
            /// Until `firstPartyHosts` is set, network requests monitoring is disabled.
            ///
            /// **NOTE 1:** Setting `firstPartyHosts` will install swizzlings on some methods of the `URLSession`. Refer to `URLSessionSwizzler.swift`
            /// for implementation details.
            ///
            /// **NOTE 2:** The `firstPartyHosts` instrumentation will NOT work without using `DDURLSessionDelegate`.
            ///
            /// - Parameter firstPartyHosts: not set by default
            public func track(firstPartyHosts: Set<String>) -> Builder {
                configuration.firstPartyHosts = firstPartyHosts
                return self
            }

            // MARK: - RUM Configuration

            /// Enables or disables the RUM feature.
            ///
            /// This option is meant to opt-out from using Datadog RUM entirely, no matter of your environment or build configuration. If you need to
            /// disable RUM only for certain scenarios (e.g. in `DEBUG` build configuration), you may prefer to not register `RUMMonitor` on `Global.rum`
            /// and let your app use the no-op monitor instance.
            ///
            /// If `enableRUM(false)` is set, the SDK won't instantiate underlying resources required for
            /// running the RUM feature. This will give you additional performance optimization if you only use logging and/or tracing.
            ///
            /// **NOTE**: This setting only applies if you use `Datadog.Configuration.builderUsing(rumApplicationID:rumClientToken:environment:)`.
            /// When using other constructors for obtaining the builder, RUM is disabled by default.
            ///
            /// - Parameter enabled: `true` by default when using `Datadog.Configuration.builderUsing(rumApplicationID:rumClientToken:environment:)`.
            /// `false` otherwise.
            public func enableRUM(_ enabled: Bool) -> Builder {
                configuration.rumEnabled = enabled
                return self
            }

            /// Sets the server endpoint to which RUM events are sent.
            /// - Parameter rumEndpoint: server endpoint (default value is `RUMEndpoint.us` )
            public func set(rumEndpoint: RUMEndpoint) -> Builder {
                configuration.rumEndpoint = rumEndpoint
                return self
            }

            /// Sets the sampling rate for RUM Sessions.
            ///
            /// - Parameter rumSessionsSamplingRate: the sampling rate must be a value between `0.0` and `100.0`. A value of `0.0`
            /// means no RUM events will be sent, `100.0` means all sessions will be kept (default value is `100.0`).
            public func set(rumSessionsSamplingRate: Float) -> Builder {
                configuration.rumSessionsSamplingRate = rumSessionsSamplingRate
                return self
            }

            /// Sets the predicate for automatically tracking `UIViewControllers` as RUM Views.
            ///
            /// When the app is running, the SDK will ask provided `predicate` if any noticed `UIViewController` should be considered
            /// as the RUM View. The `predicate` implementation should return RUM View parameters if the `UIViewController` indicates
            /// the RUM View or `nil` otherwise.
            ///
            /// **NOTE:** Enabling this option will install swizzlings on `UIViewController's` lifecycle methods. Refer
            /// to `UIViewControllerSwizzler.swift` for implementation details.
            ///
            /// By default, automatic tracking of `UIViewControllers` is disabled and no swizzlings are installed on the `UIViewController` class.
            ///
            /// - Parameter predicate: the predicate deciding if a given `UIViewController` marks the beginning or end of the RUM View.
            public func trackUIKitRUMViews(using predicate: UIKitRUMViewsPredicate) -> Builder {
                configuration.rumUIKitViewsPredicate = predicate
                return self
            }

            /// Enables or disables automatic tracking of `UITouch` events as RUM Actions.
            ///
            /// When enabled, the SDK will track `UIEvents` send to the application and capture `UIViews` and `UIControls` that user interacted with.
            /// It will send RUM Action for each recognized element. Any touch events on the keyboard are ignored for privacy.
            ///
            /// The RUM Action will be named by the name of the interacted element's class and will be extended with `accessibilityIdentifier` (if set) for more context.
            ///
            /// **NOTE:** Enabling this option will install swizzlings on `UIApplication.sendEvent(_:)` method. Refer
            /// to `UIApplicationSwizzler.swift` for implementation details.
            ///
            /// By default, automatic tracking of `UIEvents` is disabled and no swizzling is installed on the `UIApplication` class.
            ///
            /// - Parameter enabled: `false` by default
            public func trackUIKitActions(_ enabled: Bool) -> Builder {
                configuration.rumUIKitActionsTrackingEnabled = enabled
                return self
            }

            // MARK: - Features Common Configuration

            /// Sets the default service name associated with data send to Datadog.
            /// NOTE: The `serviceName` can be also overwriten by each `Logger` instance.
            /// - Parameter serviceName: the service name (default value is set to application bundle identifier)
            public func set(serviceName: String) -> Builder {
                configuration.serviceName = serviceName
                return self
            }

            /// Builds `Datadog.Configuration` object.
            public func build() -> Configuration {
                return configuration
            }
        }
    }
}
