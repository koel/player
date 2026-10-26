package phanan.koel.app

import android.app.Application

class KoelApplication : Application() {
    lateinit var app: AppModel
        private set

    override fun onCreate() {
        super.onCreate()
        app = AppModel(this)
    }
}
