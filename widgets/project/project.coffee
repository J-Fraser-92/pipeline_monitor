class Dashing.Project extends Dashing.Widget

  onData: (data) ->
    if data.status
      if data.status == 'Running'
        $(@node).css('background-color', '#00BFFF')
      else if data.status == 'Success'
        $(@node).css('background-color', '#228b22')
      else if data.status == 'Failure'
        $(@node).css('background-color', '#ff4500')
      else
        $(@node).css('background-color', '#555')
