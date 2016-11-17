class Dashing.Coverage extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue


  @accessor 'difference', ->
    if @get('delta')
      diff = Math.abs(@get('delta'))
      diff = Math.round(diff * 100)
      diff = diff / 100
      "#{diff}"
    else
      "0"

  @accessor 'arrow', ->
    if @get('delta')
      if parseInt(@get('delta')) >= 0 then 'fa fa-arrow-up' else 'fa fa-arrow-down'
    else
      'fa fa-arrow-up'

  constructor: ->
    super
    @observe 'value', (value) ->
      $(@node).find(".meter").val(value).trigger('change')

  ready: ->
    meter = $(@node).find(".meter")
    meter.attr("data-bgcolor", meter.css("background-color"))
    meter.attr("data-fgcolor", meter.css("color"))
    meter.knob()
