class Dashing.Coverage extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue

  @accessor 'difference', ->
    if @get('last')
      last = parseInt(@get('last'))
      value = parseInt(@get('value'))
      if last != 0
        diff = Math.abs(Math.round(value - last))
        "#{diff}"
    else
      ""

  @accessor 'arrow', ->
    if @get('last')
      if parseInt(@get('value')) >= parseInt(@get('last')) then 'fa fa-arrow-up' else 'fa fa-arrow-down'

  constructor: ->
    super
    @observe 'value', (value) ->
      $(@node).find(".meter").val(value).trigger('change')

  ready: ->
    meter = $(@node).find(".meter")
    meter.attr("data-bgcolor", meter.css("background-color"))
    meter.attr("data-fgcolor", meter.css("color"))
    meter.knob()
