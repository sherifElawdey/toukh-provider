package com.toukh.provider.toukh_provider

import android.app.Application
import android.content.Context
import android.util.Log
import java.io.File
import java.security.KeyStore

/**
 * Repairs Firebase Auth's saved session before Firebase starts.
 *
 * Firebase Auth encrypts the signed-in user with an Android Keystore key. When
 * that key can't be loaded (or its keyset outlived it, e.g. restored from a
 * backup), Firebase silently stops saving the session and the user is signed
 * out every time the app is closed. Removing the broken pair lets Firebase
 * create a fresh one, so the next sign-in sticks.
 */
class ToukhApplication : Application() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        repairFirebaseAuthStorage(base)
    }

    private fun repairFirebaseAuthStorage(context: Context) {
        try {
            val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
            for (alias in keyStore.aliases().toList()) {
                if (!alias.startsWith(KEY_PREFIX)) continue
                val usable = try {
                    keyStore.getKey(alias, null) != null
                } catch (e: Exception) {
                    false
                }
                if (usable) continue
                val suffix = alias.removePrefix(KEY_PREFIX)
                Log.w(TAG, "Unreadable Firebase Auth storage key; resetting $suffix")
                keyStore.deleteEntry(alias)
                clearKeyset(context, suffix)
            }
            // A keyset whose Keystore key is gone can never be decrypted.
            val prefsDir = File(context.applicationInfo.dataDir, "shared_prefs")
            for (file in prefsDir.listFiles().orEmpty()) {
                val name = file.name
                if (!name.startsWith(PREFS_PREFIX) || !name.endsWith(".xml")) continue
                val suffix = name.removePrefix(PREFS_PREFIX).removeSuffix(".xml")
                if (keyStore.containsAlias(KEY_PREFIX + suffix)) continue
                Log.w(TAG, "Firebase Auth keyset without its key; resetting $suffix")
                clearKeyset(context, suffix)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Firebase Auth storage check failed", e)
        }
    }

    private fun clearKeyset(context: Context, suffix: String) {
        context.getSharedPreferences(PREFS_PREFIX + suffix, Context.MODE_PRIVATE)
            .edit()
            .clear()
            .commit()
    }

    private companion object {
        const val TAG = "ToukhAuthStorage"
        const val KEY_PREFIX = "firebear_main_key_id_for_storage_crypto."
        const val PREFS_PREFIX = "com.google.firebase.auth.api.crypto."
    }
}
