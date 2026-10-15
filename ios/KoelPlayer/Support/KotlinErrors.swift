import Foundation
@preconcurrency import Shared

extension Error {
    var kotlinException: KotlinThrowable? {
        (self as NSError).userInfo["KotlinException"] as? KotlinThrowable
    }

    /// The HTTP status when the Koel server rejected the request.
    var httpStatus: Int? {
        (kotlinException as? HttpResponseException).map { Int($0.statusCode) }
    }
}
