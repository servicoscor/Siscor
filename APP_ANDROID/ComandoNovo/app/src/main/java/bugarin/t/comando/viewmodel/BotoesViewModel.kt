package bugarin.t.comando.viewmodel

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class BotoesViewModel @Inject constructor() : ViewModel() {

    fun ligarDefesaCivil(context: Context) {
        try {
            val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:199"))
            context.startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            Toast.makeText(context, "Aplicativo de telefone não encontrado.", Toast.LENGTH_LONG).show()
        } catch (e: Exception) {
            Toast.makeText(context, "Erro ao tentar abrir o discador.", Toast.LENGTH_LONG).show()
        }
    }

    fun abrirInstagram(context: Context) {
        val appUri = Uri.parse("instagram://user?username=centrooperacoesrio")
        val webUri = Uri.parse("https://www.instagram.com/centrooperacoesrio")
        try {
            context.startActivity(Intent(Intent.ACTION_VIEW, appUri).setPackage("com.instagram.android"))
        } catch (e: ActivityNotFoundException) {
            context.startActivity(Intent(Intent.ACTION_VIEW, webUri))
        }
    }

    fun abrirTwitter(context: Context) {
        val appUri = Uri.parse("twitter://user?screen_name=OperacoesRio")
        val webUri = Uri.parse("https://twitter.com/OperacoesRio")
        try {
            context.startActivity(Intent(Intent.ACTION_VIEW, appUri).setPackage("com.twitter.android"))
        } catch (e: ActivityNotFoundException) {
            context.startActivity(Intent(Intent.ACTION_VIEW, webUri))
        }
    }
}