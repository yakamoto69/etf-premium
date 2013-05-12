package controllers

import play.api.mvc._
import play.api.libs.json.{JsArray, JsValue, Json}
import java.io.File
import java.text.NumberFormat
import java.net.URL

object Etf extends Controller {

  lazy val etfInfos: Map[String, EtfInfo] = {
    val DList = """var (?:dlist\d)=((?:(?s)(?!var).)+);""".r  // 余計なjavascript部分を削除してjsonだけを取り出す

    val etfs_json = (DList.findAllMatchIn(readJs()) map { m =>
      val array = Json.parse(m.group(1))
      array.as[JsArray].value
    }).flatten

    val NumFmt = """\+?(.+)""".r // "+" があるとparseがうまくいかないので外す

    (etfs_json map { json =>
      val code = (json \ "scode").as[String]
      val name = (json \ "sname").as[String]
      val price = (json \ "sprice").as[String]
      val nav = (json \ "fprice").as[String]
      val NumFmt(premium) = (json \ "divergence").as[String]
      val (sdate, fdate, ddate) = ((json \ "sdate").as[String], (json \ "fdate").as[String], (json \ "ddate").as[String])
      // todo 日付のフォーマットを変換したい

      code -> EtfInfo(
        code = code,
        name = name,
        price = (parseNum(price), sdate),
        nav = (parseNum(nav), fdate),
        premium = (parseNum(premium), ddate))
    }).toMap
  }


  private def parseNum(str: String): BigDecimal = {
    if (str == "-") return BigDecimal(0)

    val num = NumberFormat.getInstance().parse(str)
    BigDecimal.valueOf(num.doubleValue())
  }

  private def readJs() = {
//    val (url, enc) = (new File("sample.js").toURL, "utf-8")
    val (url, enc) = (new URL("http://www.morningstar.co.jp/etf/js/dList.js"), "windows-31j")
    IOs.readStr(url, enc)
  }


  def index(code: String) = Action {
    Ok(etfInfos(code).toJson)
  }


  type Value = (BigDecimal, String)

  case class EtfInfo(code: String, name: String, price: Value, nav: Value, premium: Value) {

    // todo RSSを使って本物データをとってくるようにしたい
    val cnyjpy: Value = (16.4505, "5/10/2013 10:00am")
    val hkdjpy: Value = (12.996, "5/10/2013 10:00am")
    lazy val (index, exchange): (Value, Value) = code match {
      case "1309" => ((1808.40, "5/09/2013 3:00pm"), cnyjpy)
      case "1322" => ((2527.89, "5/09/2013 3:00pm"), cnyjpy)
      case "1572" => ((23211.48, "5/09/2013 3:00pm"), hkdjpy)
    }

    def toJson = {
      Json.toJson(Map[String, JsValue](
        "code" -> code,
        "name" -> name,
        "price" -> price,
        "nav" -> nav,
        "premium" -> premium,
        "index" -> index,
        "exchange" -> exchange
      ))
    }
  }

  implicit def value2JsVal(v: Value): JsValue = {
    Json.toJson(Map[String, JsValue](
      "val" -> v._1,
      "time" -> v._2
    ))
  }
  implicit def str2JsVal(str: String): JsValue = Json.toJson(str)
  implicit def num2JsVal(num: BigDecimal): JsValue = Json.toJson(num)
}
