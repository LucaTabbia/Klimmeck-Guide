package it.lordreavor.klimmeckguide.klimmeck_guide

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import com.linusu.flutter_web_auth_2.FlutterWebAuth2Plugin

/**
 * Riceve il deep link `klimmeck://auth` quando il login esce dalla scheda aperta
 * dall'app e finisce in un browser esterno (es. cambio account: l'app Twitch
 * intercetta il link e lo rimanda a Chrome).
 *
 * Sostituisce la `CallbackActivity` di flutter_web_auth_2, che consegna l'esito ma
 * lascia l'utente nel browser: qui l'esito è consegnato allo stesso modo e poi
 * l'app torna in primo piano, chiudendo la scheda di login rimasta aperta.
 */
class LoginCallbackActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        deliverCallback()
        bringAppToFront()
        finish()
    }

    private fun deliverCallback() {
        val url = intent?.data ?: return
        val scheme = url.scheme ?: return
        FlutterWebAuth2Plugin.callbacks.remove(scheme)?.success(url.toString())
    }

    private fun bringAppToFront() {
        startActivity(
            Intent(this, MainActivity::class.java).addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            ),
        )
    }
}
