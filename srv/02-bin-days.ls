require! {
  fs
}

lines = fs.readFileSync "#__dirname/../data/klementinum.csv" .toString!split "\n"
  ..shift!
  ..pop!
counter = 0
lastYear = "1775"

dayTemps = [0 to 365].map -> []
dayPrecips = [0 to 365].map -> []
# dayTemps.0.map (d, i) -> i + 1
# dayPrecips.0.map (d, i) -> i + 1
for line in lines
  [year, month, day, temp, prec] = line.split "\t"
  if month == "2" and day == "29"
    continue
  counter++
  if year != lastYear
    console.log year, lastYear, counter if counter != 366
    counter = 1
  temp = parseFloat temp.replace ',' '.'
  prec = parseFloat prec.replace ',' '.'
  unless isNaN temp
    dayTemps[counter - 1].push temp
  unless isNaN prec
    dayPrecips[counter - 1].push prec
  lastYear = year
cellize = ->
  it
    .join "\t"

fs.writeFile do
  "#__dirname/../data/temps.tsv"
  dayTemps.map cellize .join "\n"

fs.writeFile do
  "#__dirname/../data/precips.tsv"
  dayPrecips.map cellize .join "\n"
