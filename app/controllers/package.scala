import java.io.{OutputStream, BufferedInputStream, BufferedOutputStream}
import java.net.URL

package object controllers {
  def read(url: URL, os: OutputStream) {
    val o = new BufferedOutputStream(os)

    val conn = url.openConnection()
    val is = conn.getInputStream
    val in = new BufferedInputStream(is)

    val i = Iterator.continually(in.read()).takeWhile(-1 !=)
    i foreach o.write

    in.close()

    o.close()
  }
}
