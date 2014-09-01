require! <[ request cheerio async fs ]>
{ lists-to-obj } = require 'prelude-ls'
twhouse =
  * [ 1 to 12 ]
  * [ 13 to 19 ]
  * [20, 21] ++ [ 26 to 52]
  * [53]
  * [54 to 66]
  * [67 to 79]
  * [80 to 97]
  * [98 to 126]
  * [127 to 152]
  * [153 to 165]
  * [185 to 204]
  * [166]
  * [167 to 184]
  * [206 to 242]
  * [243 to 282]
  * [295 to 327]
  * [328 to 339]
  * [357 to 369]
  * [341 to 356]
  * [283 to 288]
  * [289 to 294]
  * [22 to 25] ++ [256, 257]

static-url = ''



table-to-obj = (body, cb)->
  $ = cheerio.load body
  data = []

  fields = $ '#ctl00_ContentPlaceHolder1_GridView1 tr' .first!children!map (,it) -> $ it .children!val!

  fields .= to-array!

  row = $ '#ctl00_ContentPlaceHolder1_GridView1 tr' .first!next!

  while row.text!
    cols = row.children!.map (i, e) -> $ e .text!
    cols .= to-array!
    data.push lists-to-obj fields, cols
    row = row.next!
  return data

local-to-obj = (url, cb) ->
  result = []
  err, response, body <- request url
  $ = cheerio.load body
  total-counts = $('span').eq(10).text!.trim!
  total-counts = $('span').eq(11).text!.trim! if total-counts is '...'
  total-price = $('span').eq(8).text!.trim!
  pages = Math.ceil total-counts / 25
  tasks = for let x from 1 to pages
    (cb) ->
      err, res, body <- request "#{url}&page=#{x}"
      cb null, table-to-obj body

  err, res <- async.series tasks
  for d in res
    result ++= d
  cb result

year-to-obj = (url, cb) ->
  result = {}
  tasks = for let year from 2003 to 2014
    (cb) ->
      result <- local-to-obj "#{url}&year=#{year}"
      cb null, result
  err, res <- async.series tasks
  for d,i in res
    result["#{i+2003}"] = d

  cb result

data = []
urls = []
for areas,county in twhouse
  for area in areas
    url = "http://www.twhouses.com.tw/netc/chhistory/result.aspx?county=#{county+1}&local=#{area}&usingtype=11"
    urls.push "#{area}": url

tasks = for u in urls
  u |> (cb) ->
    key = Object.keys(u)[0]
    result <- year-to-obj u[key]
    "#{key}": result |> JSON.stringify |> fs.write-file-sync "data/#{key}.json", _
    #cb null, true

async.series tasks
