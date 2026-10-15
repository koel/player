import Foundation
@preconcurrency import Shared

extension Error {
    var kotlinException: KotlinThrowable? {
        (self as NSError).userInfo["KotlinException"] as? KotlinThrowable
    }

    /// A request abandoned because its screen went away, which isn't a failure to report.
    var isCancellation: Bool {
        self is CancellationError || kotlinException is KotlinCancellationException
    }

    /// The HTTP status when the Koel server rejected the request.
    var httpStatus: Int? {
        (kotlinException as? HttpResponseException).map { Int($0.statusCode) }
    }
}
