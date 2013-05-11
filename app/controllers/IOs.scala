package controllers

import java.net.URL
import java.io.{ByteArrayOutputStream, BufferedInputStream, BufferedOutputStream, OutputStream}
import scala.io.Source

object IOs {
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

  def readStr(url: URL, enc: String) = {
    val os = new ByteArrayOutputStream
    IOs.read(url, os)
    new String(os.toByteArray, enc)
  }
}
