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
      [last_price, last_base, last_divergence] = [20180, 2785, 100 -4.39] # todo データをとってくる
      [last_index, last_exchange] = [1761.36, 16.1090] # todo データを取ってくる
      [price, index, exchange] = [p("1309"), ix("000016.SS"), ex_chyjpy()]
    when "1322"
      [last_price, last_base, last_divergence] = [2910, 3577, 100 -18.65] # todo データをとってくる
      [last_index, last_exchange] = [2450.09, 16.1090] # todo データを取ってくる
      [price, index, exchange] = [p("1322"), ix("000300.SS"), ex_chyjpy()]

  base = $.when(Pr(index), Pr(exchange)).then (index, exchange) ->
    last_base / (last_index * last_exchange) * (index * exchange)
  divergence = $.when(Pr(price), Pr(base)).then (price, base) ->
    (last_divergence * last_base / last_price) * price / base

  last_price: last_price
  last_index: last_index
  last_exchange: last_exchange
  last_base: last_base
  last_divergence: last_divergence
  price: price
  index: index
  exchange: exchange
  base: base
  divergence: divergence


$ () ->
  $(".etf").each (i, e) ->
    d = dataOf $(e).attr("code")
    $.when(Pr(d.price), Pr(d.index), Pr(d.exchange), Pr(d.base), Pr(d.divergence)).then (price, index, exchange, base, divergence) ->
      $(e).find(".last_price").html comma d.last_price
      $(e).find(".last_index").html comma d.last_index
      $(e).find(".last_exchange").html comma d.last_exchange, 2
      $(e).find(".last_base").html comma d.last_base
      $(e).find(".last_divergence").html pct d.last_divergence
      $(e).find(".price").html comma price
      $(e).find(".index").html comma index
      $(e).find(".exchange").html comma exchange, 2
      $(e).find(".base").html comma base
      $(e).find(".divergence").html pct divergence


# () -> Promise(price)
p = (code) ->
  htmlP = $.ajax
    type: 'GET'
    url: "/relay/#{code}"
    dataType: 'html'

  htmlP.then (html) ->
    toNum $(html).find(".stoksPrice:eq(1)").html()

# () -> Promise(index)
ix = (symbol) ->
  jsonP = query """select LastTradePriceOnly from yahoo.finance.quote where symbol in ("#{symbol}")"""
  jsonP.then (json) ->
    toNum json.query.results.quote.LastTradePriceOnly

# () -> Promise(exchange)
ex_chyjpy = () ->
  jsonP = query """select Rate from yahoo.finance.xchange where pair in ("CNYJPY")"""
  jsonP.then (json) ->
    toNum json.query.results.rate.Rate

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