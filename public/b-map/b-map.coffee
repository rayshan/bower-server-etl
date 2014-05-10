module = angular.module 'B.Map', []

module.directive "bMap", (d3, bGaSvc) ->
  templateUrl: 'b-map/b-map.html'
  restrict: 'E'
  link: (scope, ele) ->
    render = (data) ->
      canvas = ele[0].querySelector(".b-map")
      # d3.select(canvas).node().offsetWidth doesn't work in FF
      wOrig = canvas.clientWidth
      hOrig = canvas.clientHeight
      marginBase = 30
      margin =
        t: marginBase
        l: marginBase, r: marginBase
        b: marginBase
      w = wOrig - margin.l - margin.r
      h = hOrig - margin.t - margin.b

      maxUsers = d3.max data, (country) -> country.bUsers
      maxDensity = d3.max data, (country) -> country.bDensity
      minDensity = d3.min data, (country) -> country.bDensity
      colorsUsers = d3.scale.linear()
        .domain [1, maxUsers]
        .range ["#00acee", "#EF5734"]
      colorsDensity = d3.scale.log()
        .domain [minDensity, maxDensity]
        .range ["#00acee", "#EF5734"]

      chartData = {}
      data.forEach (country) ->
        chartData[country.isoCode] =
          users: country.bUsers
          density: country.bDensity

      colorDataUsers = {}
      data.forEach (country) ->
        colorDataUsers[country.isoCode] = colorsUsers country.bUsers
      colorDataDensity = {}
      data.forEach (country) ->
        colorDataDensity[country.isoCode] = colorsDensity country.bDensity

      map = new Datamap {
        element: canvas
        fills:
          defaultFill: '#cecece'
        geographyConfig:
          popupOnHover: true
          popupTemplate: (geo, data) ->
            "<div class=\"hoverinfo\">\n  #{geo.properties.name}\n  <br/>\n  #{data.density}\n</div>"
        data: chartData
        setProjection: (ele, options) ->
          projection = d3.geo.mercator()
            .scale 135
            .translate [ele.offsetWidth / 2, ele.offsetHeight / 1.6]
          path = d3.geo.path().projection projection
          path: path
          projection: projection
      }

#      map.updateChoropleth colorDataDensity
      map.updateChoropleth colorDataUsers

      return

    bGaSvc.fetchGeo.then render
    return