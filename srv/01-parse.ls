require! {
  fs
  xml: xml2js
  async
}
(err, files) <~ fs.readdir "#__dirname/../data/raw"

# files.length = 2
lineNo = 0
outData = {}
dates = []
<~ async.eachSeries files, (file, cb) ->
  console.log file
  (err, buff) <~ fs.readFile "#__dirname/../data/raw/#file"
  (err, data) <~ xml.parseString buff
  # data.records.record.length = 2
  dates.push data.records.$.datetime
  if data.records.record
    for region in data.records.record
      name         = region.point.0
      outData[name] ?= []

      outData[name][lineNo] = {}
      if region.phenomenon.0.description
        outData[name][lineNo].phenomenon = region.phenomenon.0.description.0
      if region.cloudiness.0.description
        outData[name][lineNo].cloudiness = region.cloudiness.0.description.0
      if region.cloudiness.0.chmuId
        outData[name][lineNo].cloudinessId = region.cloudiness.0.chmuId.0
      if region.temperature.0.value
        outData[name][lineNo].temperature = region.temperature.0.value.0
  ++lineNo
  cb!

lineCount = lineNo


regions = for region of outData => region
metrics = <[phenomenon cloudiness cloudinessId temperature]>

lines = for line in [0 til lineCount]
  lineData = [dates[line]]
  for region in regions
    for metric in metrics
      lineData.push outData[region][line]?[metric] || ""

  lineData.join "\t"


header = ["date"]
for region in regions
  for metric in metrics
    header.push "#region-#metric"

lines.unshift header.join "\t"
tsv = lines.join "\n"

fs.writeFile "#__dirname/../data/meteo.tsv", tsv

