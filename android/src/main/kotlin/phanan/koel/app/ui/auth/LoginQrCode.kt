package phanan.koel.app.ui.auth

import android.content.Context
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.codescanner.GmsBarcodeScannerOptions
import com.google.mlkit.vision.codescanner.GmsBarcodeScanning
import kotlinx.coroutines.suspendCancellableCoroutine
import org.json.JSONObject
import java.util.Base64
import kotlin.coroutines.resume

/** What Koel's web UI encodes in its login QR code: base64 of `{"host": …, "token": …}`. */
data class LoginQrPayload(val host: String, val token: String) {
    companion object {
        fun parse(scanned: String): LoginQrPayload? = runCatching {
            val decoded = JSONObject(Base64.getMimeDecoder().decode(scanned.trim()).decodeToString())
            LoginQrPayload(decoded.getString("host"), decoded.getString("token"))
        }.getOrNull()
    }
}

/**
 * Scans the login QR code with Google's code scanner, which needs no camera permission. Null
 * when the user backs out or the code isn't a Koel login code.
 */
suspend fun scanLoginQrCode(context: Context): LoginQrPayload? = suspendCancellableCoroutine { continuation ->
    val options = GmsBarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_QR_CODE).build()
    GmsBarcodeScanning.getClient(context, options).startScan()
        .addOnSuccessListener { barcode -> continuation.resume(barcode.rawValue?.let(LoginQrPayload::parse)) }
        .addOnCanceledListener { continuation.resume(null) }
        .addOnFailureListener { continuation.resume(null) }
}
