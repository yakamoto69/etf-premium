P = (a) ->
  # todo Promiseかどうかを判断するにはどうするのがいいのか？
  if a? and a.then?
    a
  else
    $.Deferred().resolve(a).promise()

comma = (x, precision) ->
  x.toFixed(precision || 0).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")

pct = (x) -> (x - 100).toFixed(2)

toNum = (str) -> parseFloat str.split(",").join("")

dataOf = (code) ->
  [symbol, exSymbol] = switch code
    when "1309" then ["000016.SS", "CNYJPY"]
    when "1322" then ["000300.SS", "CNYJPY"]
    when "1572" then ["^HSI", "HKDJPY"]

  etfP = getEtfInfo(code)

  nav_price = P(etfP).then (etf) -> etf.price
  nav = P(etfP).then (etf) -> etf.nav
  nav_premium = P(etfP).then (etf) -> {val: 100 + etf.premium.val, time: etf.premium.time} # todo なんかvalを変換する感じでやりたい
  nav_index = P(etfP).then (etf) -> etf.index
  nav_exchange = P(etfP).then  (etf) -> etf.exchange
  [price, index, exchange] = [p(code), ix(symbol), getExchange(exSymbol)]

  iopv = $.when(P(nav), P(nav_index), P(nav_exchange), P(index), P(exchange)).then (nav, nav_index, nav_exchange, index, exchange) ->
    val: nav.val / (nav_index.val * nav_exchange.val) * (index.val * exchange.val)
    time: exchange.time # todo 本当は考慮した値のなかで最新の時間って感じになるはず
  premium = $.when(P(nav_price), P(nav), P(nav_premium), P(price), P(iopv)).then (nav_price, nav, nav_premium, price, iopv) ->
    val: (nav_premium.val * nav.val / nav_price.val) * price.val / iopv.val
    time: iopv.time

  nav_price: nav_price
  nav_index: nav_index
  nav_exchange: nav_exchange
  nav: nav
  nav_premium: nav_premium
  price: price
  index: index
  exchange: exchange
  iopv: iopv
  premium: premium


$ () ->
  html = (name, url) ->
    """
    <tr>
      <td>#{name} <a href="#{url}">履歴</a></td>
      <td>
        <span class="price">-</span> / <span class="nav_price">-</span>
      </td>
      <td>
        <span class="index">-</span> / <span class="nav_index">-</span>
      </td>
      <td>
        <span class="exchange">-</span> / <span class="nav_exchange">-</span>
      </td>
      <td>
        <span class="iopv">-</span> / <span class="nav">-</span>
      </td>
      <td>
        <span class="premium">-</span> / <span class="nav_premium">-</span>
      </td>
    </tr>
    """

  etfs = [
    {code: "1309"
    name: "1309 野村 上証50上投"
    url: "http://www.morningstar.co.jp/etf/jp/kairiritsu1309.html"},

    {code: "1322"
    name: "1322 日興 上場パンダ"
    url: "http://www.morningstar.co.jp/etf/jp/kairiritsu1322.html"},

    {code: "1572"
    name: "1572 SAM 中国H株ブル2ETF	ハンセン中国"
    url: "http://www.morningstar.co.jp/etf/jp/kairiritsu1572.html"}
  ]

  for etf in etfs
    e = $(html etf.name, etf.url)
    e.appendTo "#etfList"

    d = dataOf etf.code

    commaDat = (valP, precision) ->
      P(valP).then (val) ->
        # todo valだけ変換するって風にしたい
        val: comma val.val, precision
        time: val.time

    pctDat = (valP) ->
      P(valP).then (val) ->
        val: pct val.val
        time: val.time

    vals =
      nav_price: commaDat d.nav_price
      nav_index: commaDat d.nav_index
      nav_exchange: commaDat d.nav_exchange, 2
      nav: commaDat d.nav
      nav_premium: pctDat d.nav_premium
      price: commaDat d.price
      index: commaDat d.index
      exchange: commaDat d.exchange, 2
      iopv: commaDat d.iopv
      premium: pctDat d.premium

    for nameP, valP of vals
      # varつかってるせいか変数使うと容赦なく値が変わってるので、必要な分の値は全部Promise化しないとまずい
      $.when(P(nameP), P(valP), P(e)).then (name, val, e) ->
        $(e).find(".#{name}").html val.val
        $(e).find(".#{name}").tooltip {title: val.time}


# (code) -> Promise(etf)
getEtfInfo = (code) ->
  $.ajax
    type: 'GET'
    url: "/etf/" + code
    dataType: 'json'

# (code) -> Promise(price)
p = (code) ->
  htmlP = $.ajax
    type: 'GET'
    url: "/relay/#{code}"
    dataType: 'html'

  htmlP.then (html) ->
    # todo Yahoo Financeから、株価を付けた時間がとれないので仕方なく現在時刻を使う
    d = new Date
    [yy, mm, dd, hour, min] = [d.getFullYear(), d.getMonth() + 1, d.getDate(), d.getHours(), d.getMinutes()]
    ampm = (h) -> if h >= 12 then "pm" else "am"
    val: toNum $(html).find(".stoksPrice:eq(1)").html()
    time: "#{mm}/#{dd}/#{yy} #{hour % 12}:#{min}#{ampm hour}"

# (symbol) -> Promise(index)
ix = (symbol) ->
  jsonP = query """select LastTradePriceOnly, LastTradeDate, LastTradeTime from yahoo.finance.quotes where symbol in ("#{symbol}")"""
  jsonP.then (json) ->
    q = json.query.results.quote
    val: toNum q.LastTradePriceOnly
    time: "#{q.LastTradeDate} #{q.LastTradeTime}" # todo タイムゾーンを合わせたい

# (symbol) -> Promise(exchange)
getExchange = (symbol) ->
  jsonP = query """select Rate, Date, Time from yahoo.finance.xchange where pair ="#{symbol}" """
  jsonP.then (json) ->
    r = json.query.results.rate
    val: toNum r.Rate
    time: "#{r.Date} #{r.Time}" # todo タイムゾーンを合わせたい

# (query) -> Promise(json)
query = (q) ->
  $.ajax
    type: 'GET'
    url: "http://query.yahooapis.com/v1/public/yql"
    dataType: 'jsonp'
    data:
      q: q
      env: "store://datatables.org/alltableswithkeys"
      format: "json"
