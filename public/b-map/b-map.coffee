module = angular.module 'B.Map', []

# load topojson
module.factory 'bTopojsonSvc', ($http) ->
  $http.get 'b-map/ne_110m_admin_0_countries_topojson.json'

# extend d3 w/ collission func
module.factory 'd3map', (d3) ->
  d3.collision = (alpha, nodes, radiusKey, bubblePadding, w, h) ->
    # alpha controls how hard nodes collide & how far they're pushed
    radiusKey = 'r' + radiusKey
    quadtree = d3.geom.quadtree nodes
    (node) ->
      nr = node[radiusKey] + bubblePadding
      nx1 = node.x - nr
      nx2 = node.x + nr
      ny1 = node.y - nr
      ny2 = node.y + nr
      quadtree.visit (quad, x1, y1, x2, y2) ->
        if quad.point and (quad.point isnt node)
          x = node.x - quad.point.x
          y = node.y - quad.point.y
          l = Math.sqrt x * x + y * y
          r = nr + quad.point[radiusKey] # can add even more padding here
          if l < r
            l = (l - r) / l * alpha
            node.x -= x *= l
            node.y -= y *= l
            quad.point.x += x
            quad.point.y += y
        x1 > nx2 or x2 < nx1 or y1 > ny2 or y2 < ny1

  return d3

module.factory 'bMapDataSvc', ($filter, $q, d3map, topojson, bGaSvc, bTopojsonSvc) ->
  parseData = (data) ->
    _deferred = $q.defer()

    countryData = data[0]
    topojsonData = data[1].data # $http returns other stuff w/ data

    maxUsers = d3map.max countryData, (country) -> country.users
    maxDensity = d3map.max countryData, (country) -> country.density
    minDensity = d3map.min countryData, (country) -> country.density

    colorsUsers = d3.scale.log()
      .domain [2, maxUsers] # backend excludes countries w/ users <2
      .range ["#00acee", "#EF5734"]
    colorsDensity = d3map.scale.log()
      .domain [minDensity, maxDensity]
      .range ["#00acee", "#EF5734"]
    radiusUsers = d3map.scale.sqrt()
      .domain [2, maxUsers]
      .range [2, 65]
    radiusDensity = d3map.scale.sqrt()
      .domain [minDensity, maxDensity]
      .range [2, 65]

    topo = topojson.feature topojsonData, topojsonData.objects.countries
    countryDataTopo = topo.features
      .filter (d) ->
        countryData.some (country) -> country.isoCode is d.id
      .map (d) ->
        bowerData = $filter('filter')(countryData, {isoCode: d.id})[0]
        d.data = bowerData
        d.rDensity = if bowerData then radiusDensity bowerData.density else 0
        d.rUsers = if bowerData then radiusUsers bowerData.users else 0
        d

    _deferred.resolve {
      topo: topo
      topojsonData: topojsonData
      colorsUsers: colorsUsers
      colorsDensity: colorsDensity
      radiusUsers: radiusUsers
      radiusDensity: radiusDensity
      countryDataTopo: countryDataTopo
    }
    _deferred.promise

  $q.all([bGaSvc.fetchGeo, bTopojsonSvc]).then parseData

module.directive "bMap", (d3map, topojson, bMapDataSvc) ->
  templateUrl: 'b-map/b-map.html'
  restrict: 'E'
  link: (scope, ele) ->
    tick = null
    scope.chartType = "Density"
    scope.$watch 'chartType', (chartType, chartTypeOld) ->
      if chartType != chartTypeOld
        radiusKey = 'r' + chartType

        svg.selectAll ".label"
          .text (d) -> d.data.isoCode if d[radiusKey] >= bubbleRBreaks.sm
          .attr "class", "label" # removes all other classes
          # TODO: change text size here so transition works, vs. doing it in CSS
          .classed "sm", (d) -> d[radiusKey] <= bubbleRBreaks.md
          .classed "md", (d) -> d[radiusKey] > bubbleRBreaks.md and d[radiusKey] <= bubbleRBreaks.lg
          .classed "lg", (d) -> d[radiusKey] > bubbleRBreaks.lg

        svg.selectAll ".bubble"
          .transition().duration transitionDuration
          .attr "r", (d) -> d[radiusKey]
          .attr "fill", (d) -> scope.data["colors" + chartType] d.data[chartType.toLowerCase()]

        force.start()

      return

    bubblePadding = 1 # for collision detection
    bubbleOverBorder = 5 # allow bubbles to go out of bounding box a bit but not too much, see tick()
    bubbleRBreaks = sm: 10, md: 15, lg: 20 # for setting font sizes in bubbles

    transitionDuration = 250

    canvas = ele[0].querySelector ".b-map"
    # d3.select(canvas).node().offsetWidth doesn't work in FF
    w = canvas.clientWidth
    h = canvas.clientHeight
    svg = d3map.select(canvas).append("svg").attr("width", w).attr("height", h)

    projection = d3map.geo.equirectangular()
      .scale 160 # default to 150
      .translate [w / 2.1, h / 1.55] # move a little to the left & down to accommodate for europe
      # .precision(.1) # default Math.SQRT(1/2) = .5
    path = d3map.geo.path().projection projection

    force = d3map.layout.force()
      .gravity 0 # disable, implemented elsewhere
      .size [w * 2, h * 2]

    # custom gravity function to draw nodes to original x0/y0 position instead of center of chart
    gravity = (k) -> (d) ->
      d.x += (d.x0 - d.x) * k
      d.y += (d.y0 - d.y) * k

    render = (data) ->
      scope.data = data
      # compute centroid for each country, can't do it in data due to not having path func
      data.countryDataTopo = data.countryDataTopo.map (d) ->
        centroid = path.centroid d.geometry # returns x/y
        d.x = centroid[0]; d.y = centroid[1]
        d.x0 = centroid[0]; d.y0 = centroid[1]
        d

      landContainer = svg.append("g").attr "class", "container land"
      # land polygon
      landContainer.append("path").datum(data.topo).attr("class", "land").attr "d", path
      # country boundary mesh
      landContainer.append("path")
        .datum topojson.mesh data.topojsonData, data.topojsonData.objects.countries, (a, b) -> a isnt b
        .attr "class", "country-boundary"
        .attr "d", path

      countryContainer = svg.append("g").attr "class", "container countries"
      countries = countryContainer.selectAll "g"
          .data data.countryDataTopo
        .enter().append "g"
          .attr "class", "country"
          .attr "id", (d) -> d.data.isoCode
      countryBubbles = countries.append("circle")
        .attr "class", "bubble"
        .attr "r", (d) -> d.rDensity
        .attr "fill", (d) -> data.colorsDensity d.data.density
      countryLabels = countries.append "text"
        .text (d) -> d.data.isoCode if d.rDensity >= bubbleRBreaks.sm
        .attr "class", "label"
        .classed "sm", (d) -> d.rDensity <= bubbleRBreaks.md
        .classed "md", (d) -> d.rDensity > bubbleRBreaks.md and d.rDensity <= bubbleRBreaks.lg
        .classed "lg", (d) -> d.rDensity > bubbleRBreaks.lg

      tick = (e) ->
        radiusKey = 'r' + scope.chartType
        # cx / cy constrained so bubbles go out of bounding box a bit (10) but not too much
        countryBubbles
          .each gravity e.alpha * .1 # custom gravity function to draw nodes to original x0/y0 position instead of center of chart
          .each d3map.collision .2, scope.data.countryDataTopo, scope.chartType, bubblePadding
          .attr "cx", (d) -> Math.max d[radiusKey], (Math.min w - d[radiusKey], d.x) + bubbleOverBorder
          .attr "cy", (d) -> Math.max d[radiusKey] - bubbleOverBorder, Math.min h - d[radiusKey], d.y
        countryLabels
          .attr "x", (d) -> Math.max d[radiusKey], (Math.min w - d[radiusKey], d.x) + bubbleOverBorder
          .attr "y", (d) ->
            res = Math.max d[radiusKey] - bubbleOverBorder, Math.min h - d[radiusKey], d.y
            if d[radiusKey] <= bubbleRBreaks.md then res + 3 else if d[radiusKey] > bubbleRBreaks.md and d[radiusKey] <= bubbleRBreaks.lg then res + 4 else res + 6
        return

      force.nodes(countryBubbles[0]).on("tick", tick).start()
      return

    bMapDataSvc.then render
    return