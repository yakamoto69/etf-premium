package controllers

import play.api.mvc._
import java.net.URL
import play.api.libs.iteratee.Enumerator
import java.io.{BufferedOutputStream, BufferedInputStream}

object Relay extends Controller {

  def index(code: String) = Action {
    val enumerator = Enumerator.outputStream { os =>
      val o = new BufferedOutputStream(os)

      val url = new URL("http://stocks.finance.yahoo.co.jp/stocks/detail/?code=%s".format(stockCode(code)))
      val conn = url.openConnection()
      val in = new BufferedInputStream(conn.getInputStream)

      val i = Iterator.continually(in.read()).takeWhile(-1 !=)
      i foreach o.write

      in.close()

      o.close()
    }

    Ok.stream(enumerator >>> Enumerator.eof).withHeaders(
      "Content-Type" -> "text/html; charset=UTF-8"
    )
  }

  private val stockCode: String => String = {
    case "1309" => "1309.o"
    case "1322" => "1322.t"
  }
}
