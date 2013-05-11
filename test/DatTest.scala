import java.io.{ByteArrayOutputStream, BufferedOutputStream, BufferedInputStream}
import java.net.URL
import play.api.libs.json.Json
import play.api.libs.json.{JsArray, Json}
import scala.xml.Source

object DatTest {
  def main(args: Array[String]) {
    val DList = """var (dlist\d)=((?:(?s)(?!var).)+);""".r
    val jsons = (DList.findAllMatchIn(readJs()) map { m =>
      val a = m.group(1)
      val b = m.group(2)
      val json = Json.parse(b)
      val d = json.as[JsArray]
      d.value
    }).flatten

    val a = (jsons map { json =>
      val code = (json \ "scode").as[String]
      val name = (json \ "sname").as[String]
      val price = (json \ "sprice").as[String]
      val nav = (json \ "fprice").as[String]
      val premium = (json \ "divergence").as[String]
      code -> (name, price, nav, premium)
    }).toMap
    println(a("1309"))
    println(a("1322"))
  }


  def readJs() = {
    val os = new ByteArrayOutputStream
    val o = new BufferedOutputStream(os)

//    val url = new URL("http://www.morningstar.co.jp/etf/js/dList.js")
//
//    val conn = url.openConnection()
//    val is = conn.getInputStream
    val is = Source.fromFile("sample.js").getByteStream
    val in = new BufferedInputStream(is)

    val i = Iterator.continually(in.read()).takeWhile(-1 !=)
    i foreach o.write

    in.close()

    o.close()

//    new String(os.toByteArray, "Windows-31J")
    new String(os.toByteArray, "UTF-8")
  }
}
