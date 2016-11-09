class Dashing.Elapsedtime extends Dashing.Widget

    @accessor 'text', ->
      if @get('seconds')
        secs = parseInt(@get('seconds'))

        one_minute = 60
        one_hour = (60 * one_minute)
        one_day = (24 * one_hour)
        one_week = (7 * one_day)

        if secs >= one_week
          weeks = Math.floor(secs / one_week)
          secs -= (weeks * one_week)
          days = Math.floor(secs / one_day)

          str = "#{weeks} week"
          if weeks > 1
            str += "s"

          if days > 1
            str += " #{days} days"
          else if days == 1
            str += " 1 day"

          "#{str}"
        else if secs >= one_day
          days = Math.floor(secs / one_day)
          if days > 1
            "#{days} days"
          else if days == 1
            "1 day"
        else
          hours = Math.floor(secs / one_hour)
          if hours > 1
            "#{hours} hours"
          else if hours == 1
            "1 hour"
          else
            "<1 hour"
