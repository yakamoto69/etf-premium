package controllers

import play.api.mvc._
import java.net.URL
import play.api.libs.iteratee.Enumerator

object Relay extends Controller {

  def index(code: String) = Action {
    val enumerator = Enumerator.outputStream { os =>
      val url = new URL("http://stocks.finance.yahoo.co.jp/stocks/detail/?code=%s".format(stockCode(code)))
      IOs.read(url, os)
    }

    Ok.stream(enumerator >>> Enumerator.eof).withHeaders(
      "Content-Type" -> "text/html; charset=UTF-8"
    )
  }

  private val stockCode: String => String = { code =>
    val seCode = Map(
      "1309" -> "o",
      "1322" -> "t",
      "1572" -> "t")

    code + "." + seCode(code)
  }
}
