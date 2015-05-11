ig.drawPrecips = ->
  years = [0 to 210].map (d, i) ->
    year = i + 1804
    data = []
    {year, data}
  precips = for line, day in ig.data.precips.split "\n"
    precips = line
      .split "\t"
      .map (precip, yearIndex) ->
        precip = parseFloat precip
        year = 1804 + yearIndex
        if !isNaN precip
          years[yearIndex].data[day] = precip
        {precip, day, year}

    {day, precips}

  len = precips.length
  cols = for i, index in [0 til len by 3]
    threeDayPrecips = precips[i].precips ++ precips[i + 1].precips ++ precips[i + 2].precips
    threeDayPrecips .= filter -> !isNaN it.precip
    threeDayPrecips.sort (a, b) -> a.precip - b.precip
    binnedPrecips = [0 to 90].map -> 0
    for {precip} in threeDayPrecips
      bin = Math.round 10 * Math.sqrt precip
      if bin > 0 => bin -= 2
      unless isNaN bin
        binnedPrecips[bin] += 1
    {precips:threeDayPrecips, index, binnedPrecips}

  color = d3.scale.quantize!
    ..range ['rgb(247,251,255)','rgb(222,235,247)','rgb(198,219,239)','rgb(158,202,225)','rgb(107,174,214)','rgb(66,146,198)','rgb(33,113,181)','rgb(8,81,156)','rgb(8,48,107)']

  zeroColor = d3.scale.quantize!
    ..range ['rgb(255,255,204)','rgb(255,237,160)','rgb(254,217,118)','rgb(254,178,76)','rgb(253,141,60)','rgb(252,78,42)','rgb(227,26,28)','rgb(189,0,38)','rgb(128,0,38)']
    ..domain d3.extent cols.map (.binnedPrecips.0)

  y = 91
  x = 122

  pointRadius = 8

  width = x * pointRadius
  height = y * pointRadius

  container = d3.select ig.containers.base
    ..classed \precip yes
  canvas = container.append \canvas
    ..attr \width "#{width}px"
    ..attr \height "#{height}px"
    ..style \margin-left \23px

  ctx = canvas.node!getContext \2d
  yScale = ->
    if it
      it * pointRadius + 6
    else
      4

  for col, xIndex in cols
    cx = xIndex * pointRadius + 4
    color.domain d3.extent col.binnedPrecips.slice 1
    for count, yIndex in col.binnedPrecips
      continue unless count
      cy = yScale yIndex
      ctx.beginPath!
      if xIndex == 121
        count = count * 633 / 422
      ctx.fillStyle = if yIndex
        cy += 1
        color count
      else
        zeroColor count
      ctx.arc cx, cy, pointRadius / 2 - 0.5, 0, 2 * Math.PI
      ctx.fill!
  drawOverlay container, width, height, cols, yScale
  months =
    * length: 31
      name: "leden"
    * length: 28
      name: "únor"
    * length: 31
      name: "březen"
    * length: 30
      name: "duben"
    * length: 31
      name: "květen"
    * length: 30
      name: "červen"
    * length: 31
      name: "červenec"
    * length: 31
      name: "srpen"
    * length: 30
      name: "září"
    * length: 31
      name: "říjen"
    * length: 30
      name: "listopad"
    * length: 31
      name: "prosinec"
  xAxis = container.append \div
    ..attr \class "axis x"
    ..selectAll \div.item .data months .enter!append \div
      ..attr \class \item
      ..style \width -> "#{it.length / 3 * pointRadius}px"
      ..html -> it.name

  drawOneYear = ->
    svg = container.append \svg
      ..attr {width: width, height}
    line = d3.svg.line!
      ..x (d, i) -> (i + 0.5) * (pointRadius / 3)
      ..y (d) ->
        if d
          1 + yScale (-2 + Math.round 10 * Math.sqrt d)
        else
          yScale d
    path = svg.append \path
    yearAxis = container.append \div
      ..attr \class \year-axis
      ..append \h2
        ..html "Vyberte rok, jehož srážky chcete zobrazit"
      ..append \ol
        ..selectAll \li .data years .enter!append \li
          ..classed \left (d, i) -> i > 204
          ..append \span
            ..html (d, i) -> d.year
          ..filter ((d, i) -> 6 == i % 20)
            ..classed \big yes
          ..on \mouseover (d, i) -> drawYear i
          ..on \touchstart (d, i) -> drawYear i
          ..on \mouseout -> undrawYear!

    drawYear = (yearIndex) ->
      path.attr \d line years[yearIndex].data

    undrawYear = ->
      path.attr \d ""

  drawOneYear!


drawOverlay = (container, width, height, cols, yScale) ->
  date = new Date!
    ..setHours 12

  toHumanDate = (dayIndex, year) ->
    startDay = dayIndex + 1
    date
      ..setMonth 0
      ..setDate startDay
      ..setFullYear year
    "#{date.getDate!}. #{date.getMonth! + 1}. #{date.getFullYear!}"
  monthContainer = container.append \div
    ..attr \class \monthContainer
    ..style \width "#{width}px"
    ..style \height "#{height}px"
    ..selectAll \div .data cols .enter!append \div
      ..attr \class (d, i) -> "col #{if i > 60 then 'right' else ''}"
      ..append \div
        ..attr \class "temp min"
        ..html ->
          day = it.precips.0
          "Prší v #{ig.utils.formatNumber (1 - it.binnedPrecips[0] / it.precips.length) * 100} % dnů"
        ..style \top "#{yScale 0}px"
      ..append \div
        ..attr \class "temp max"
        ..html ->
          day = it.precips[*-1]
          "Nejvíc srážek spadlo #{toHumanDate day.day, day.year}<br>#{ig.utils.formatNumber day.precip, 1} mm"
        ..style \top -> "#{1 + yScale (-2 + Math.round 10 * Math.sqrt it.precips[*-1].precip)}px"
