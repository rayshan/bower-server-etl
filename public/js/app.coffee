app = angular.module 'BApp', [
  'B.Chart.Users'
  'B.Table.Commands'
  'ngResource'
]

app.controller 'BMainCtrl', () ->
  return

app.factory 'd3', ->
  d3.legend = ->
    # `this` should be classed legend, = current node wrapped by d3
    items = {}

    chart = d3.select(@.node().parentNode) # select parent chart

    lBox = @.selectAll(".box").data([true])
    lItems = @.selectAll(".items").data([true])

    lBox.enter().append("rect").classed "box", true # .class true assigns class
    lItems.enter().append("g").classed "items", true

    chart.selectAll("[data-legend]").each ->
      # css selector of all paths w/ attr named data-legend using brackets; data- is html5 standard; this = path
      path = d3.select(@)

      # returns .attr that's the name of series of the only element; b/c 2nd arg == null
      items[path.attr("data-legend")] =
        pos: path.attr("data-legend-pos") or @getBBox().y
        # getBBox() is w3 svg spec, gets bounding box of path, .y sorts by whatever has highest max value
        color: path.attr("data-legend-color") || if path.style("fill") isnt "none" then path.style("fill") else path.style("stroke")
      return

    items = d3.entries(items).sort((a, b) -> a.value.pos - b.value.pos)
    # array.sort compare function takes 1st & 2nd, then 2nd & 3rd... if compare function returns
    # < 0 a before b
    # == 0 order unchanged
    # > 0 b before a

    lItems.selectAll("text")
      .data(items, (d) -> d.key)
      .call((d) -> d.enter().append "text")
      .call((d) -> d.exit().remove())
      .attr "x", "1em"
      .attr "y", (d, i) -> i * 1.25 + "em"
      .text (d) -> switch d.key # override key name to full name
        when 'N' then 'New'
        when 'E' then 'Returning'
        else d.key

    lItems.selectAll("circle")
      .data(items, (d) -> d.key)
      .call((d) -> d.enter().append "circle")
      .call((d) -> d.exit().remove())
      .attr "cx", 0
      .attr "cy", (d, i) -> i - 0.25 + "em"
      .attr "r", "0.4em"
      .style("fill", (d) -> d.value.color)

    return

  d3

app.factory 'bGaSvc', ($resource) ->
  ga = $resource '/data/:type', null, {
    getUsers:
      method: 'GET'
      params: {type: 'users'}
      isArray: true
    getCommands:
      method: 'GET'
      params: {type: 'commands'}
      isArray: true
  }

  fetchUsersP = ga.getUsers().$promise
  fetchCommandsP = ga.getCommands().$promise

  fetchUsers: fetchUsersP
  fetchCommands: fetchCommandsP

app.filter 'pct', ->
  (input) ->
    input *= 100
    inputAbs = Math.abs input
    neg = if input < 0 then '- ' else '' # force a space b/t sign & num
    decimal = if inputAbs < 10 then 1 else 0
    if input is 0 then null
    else neg + inputAbs.toFixed(decimal) + ' %'

app.filter 'round', ->
  (input) ->
    if input >= 1000
      (input / 1000).toFixed(1) + ' k'
    else input.toFixed(1)