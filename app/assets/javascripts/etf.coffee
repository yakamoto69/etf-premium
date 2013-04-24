Pr = (a) ->
  if a? and a.then?
    a
  else
    $.Deferred().resolve(a).promise()

comma = (x, precision) ->
  x.toFixed(precision || 0).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")

pct = (x) -> (x - 100).toFixed(2)

toNum = (str) -> parseFloat str.split(",").join("")

dataOf = (code) ->
  switch code
    when "1309"
      # todo データをとってくる
      nav_price = {val: 20180, time: "4/24/2013 3:00pm"}
      nav = {val: 2785, time: "4/24/2013 3:00pm"}
      nav_premium = {val: 100 -4.39, time: "4/24/2013 3:00pm"}
      nav_index = {val: 1761.36, time: "4/23/2013 3:00pm"}
      nav_exchange = {val: 16.1090, time: "4/24/2013 10:00am"}
      [price, index, exchange] = [p("1309"), ix("000016.SS"), ex_chyjpy()]
    when "1322"
      nav_price = {val: 2910, time: "4/24/2013 3:00pm"}
      nav = {val: 3577, time: "4/24/2013 3:00pm"}
      nav_premium = {val: 100 -18.65, time: "4/24/2013 3:00pm"}
      nav_index = {val: 2450.09, time: "4/23/2013 3:00pm"}
      nav_exchange = {val: 16.1090, time: "4/24/2013 10:00am"}
      [price, index, exchange] = [p("1322"), ix("000300.SS"), ex_chyjpy()]

  iopv = $.when(Pr(index), Pr(exchange)).then (index, exchange) ->
    val: nav.val / (nav_index.val * nav_exchange.val) * (index.val * exchange.val)
    time: exchange.time # todo 本当は考慮した値のなかで最新の時間って感じになるはず
  premium = $.when(Pr(price), Pr(iopv)).then (price, iopv) ->
    val: (nav_premium.val * nav.val / nav_price.val) * price.val / iopv.val
    time: iopv.time # todo 本当は考慮した値のなかで最新の時間って感じになるはず

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
  $(".etf").each (i, e) ->
    d = dataOf $(e).attr("code")
    $.when(Pr(d.price), Pr(d.index), Pr(d.exchange), Pr(d.iopv), Pr(d.premium)).then (price, index, exchange, iopv, premium) ->
      commaDat = (val, precision) ->
        val: comma val.val, precision
        time: val.time

      pctDat = (val) ->
        val: pct val.val
        time: val.time

      vals =
        nav_price: commaDat d.nav_price
        nav_index: commaDat d.nav_index
        nav_exchange: commaDat d.nav_exchange, 2
        nav: commaDat d.nav
        nav_premium: pctDat d.nav_premium
        price: commaDat price
        index: commaDat index
        exchange: commaDat exchange, 2
        iopv: commaDat iopv
        premium: pctDat premium

      for name, val of vals
        $(e).find(".#{name}").html val.val
        $(e).find(".#{name}").tooltip {title: val.time}


# () -> Promise(price)
p = (code) ->
  htmlP = $.ajax
    type: 'GET'
    url: "/relay/#{code}"
    dataType: 'html'

  htmlP.then (html) ->
    d = new Date
    [yy, mm, dd, hour, min] = [d.getFullYear(), d.getMonth() + 1, d.getDate(), d.getHours(), d.getMinutes()]
    ampm = (h) -> if h >= 12 then "pm" else "am"
    val: toNum $(html).find(".stoksPrice:eq(1)").html()
    time: "#{mm}/#{dd}/#{yy} #{hour % 12}:#{min}#{ampm hour}"

# () -> Promise(index)
ix = (symbol) ->
  jsonP = query """select LastTradePriceOnly, LastTradeDate, LastTradeTime from yahoo.finance.quotes where symbol in ("#{symbol}")"""
  jsonP.then (json) ->
    q = json.query.results.quote
    val: toNum q.LastTradePriceOnly
    time: "#{q.LastTradeDate} #{q.LastTradeTime}" # todo タイムゾーンを合わせたい

# () -> Promise(exchange)
ex_chyjpy = () ->
  jsonP = query """select Rate, Date, Time from yahoo.finance.xchange where pair in ("CNYJPY")"""
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
