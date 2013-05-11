import java.text.NumberFormat

object NumTest {
  def main(args: Array[String]) {
    val NumFmt = """\+?(.+)""".r

    println(parse("21,524"))
    println(parse("-5.36%"))
    val NumFmt(num) = "+0.23%"
    println(parse(num))
  }

  def parse(str: String): BigDecimal = {
    val num = NumberFormat.getInstance().parse(str)
    BigDecimal.valueOf(num.doubleValue())
  }
}
