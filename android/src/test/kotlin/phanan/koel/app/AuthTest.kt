package phanan.koel.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import phanan.koel.app.ui.auth.AuthenticatorCode
import phanan.koel.app.ui.auth.LoginField
import phanan.koel.app.ui.auth.authErrorMessage
import phanan.koel.shared.api.HttpResponseException

class AuthenticatorCodeTest {
    @Test
    fun keepsOnlyDigitsUpToSix() {
        assertEquals("123456", AuthenticatorCode.sanitized("12 34-56789"))
        assertEquals("42", AuthenticatorCode.sanitized("4a2"))
    }

    @Test
    fun isCompleteAtSixDigits() {
        assertTrue(AuthenticatorCode.isComplete("123456"))
        assertFalse(AuthenticatorCode.isComplete("12345"))
    }
}

class LoginFieldTest {
    @Test
    fun focusesTheFirstEmptyField() {
        assertEquals(LoginField.Host, LoginField.firstMissing(" ", "a@b.c", "secret"))
        assertEquals(LoginField.Email, LoginField.firstMissing("koel.test", "", "secret"))
        assertEquals(LoginField.Password, LoginField.firstMissing("koel.test", "a@b.c", ""))
        assertNull(LoginField.firstMissing("koel.test", "a@b.c", "secret"))
    }
}

class AuthErrorMessageTest {
    @Test
    fun unauthorizedMeansWrongCredentials() {
        assertEquals("wrong", authErrorMessage(HttpResponseException(401, ""), "wrong", "other"))
    }

    @Test
    fun anythingElseIsAGeneralProblem() {
        assertEquals("other", authErrorMessage(HttpResponseException(500, ""), "wrong", "other"))
        assertEquals("other", authErrorMessage(IllegalStateException(), "wrong", "other"))
    }
}

class ReconnectTest {
    @Test
    fun reconnectsOnceOnlineFromNoConnectionAndFromOfflineWithoutAScreen() {
        assertTrue(AppModel.reconnectsOnceOnline(AppModel.Phase.NoConnection, isScreenShown = true))
        assertTrue(AppModel.reconnectsOnceOnline(AppModel.Phase.NoConnection, isScreenShown = false))
        assertTrue(AppModel.reconnectsOnceOnline(AppModel.Phase.Offline, isScreenShown = false))
        assertFalse(AppModel.reconnectsOnceOnline(AppModel.Phase.Offline, isScreenShown = true))
        assertFalse(AppModel.reconnectsOnceOnline(AppModel.Phase.Main, isScreenShown = false))
    }
}
