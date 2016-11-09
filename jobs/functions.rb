require 'json'
require 'net/http'
require 'net/https'

def format_time(time)
    return Time.parse(time).strftime("%d/%m/%y %H:%M")
end

def get_latest_build(build_data)
    return build_data.keys.max
end

def get_jira_json(json_body)
    uri = URI.parse('https://xedosoftware.atlassian.net/rest/api/2/search/')

    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Post.new(uri.path)
    req['Authorization'] = 'Basic amFtZXMuZnJhc2VyQHhlZG9zb2Z0d2FyZS5jb206U3RhcmsxVWx0cm9uMUh1bGs='
    req['Accept'] = 'application/json'
    req['Content-Type'] = 'application/json'

    req.body = json_body

    res = https.request(req)

    return JSON.parse(res.body)
end

def get_teamcity_json(url)
    uri = URI.parse('http://xedo-tfsbuild:90/httpAuth/app/rest' + url)
    req = Net::HTTP::Get.new(uri.to_s)
    req['Authorization'] = 'Basic amFtZXNmcmFzZXI6U3RhcmsxVWx0cm9uMUh1bGs='
    req['Accept'] = 'application/json'

    res = Net::HTTP.start(uri.host, uri.port) {|http|
        http.request(req)
    }

    return JSON.parse(res.body)
end

def get_latest_completed_build_json(build_type)
    json = get_teamcity_json('/builds/?count=1&locator=canceled:any,running:false,buildType:SortMyTux_CurrentSprint_%s' % [build_type])
    build_id = json['build'][0]['id']
    return get_teamcity_json('/builds/id:%s' % [build_id])
end

def get_latest_running_build_json(build_type)
    json = get_teamcity_json('/builds/?count=1&locator=canceled:any,running:true,buildType:SortMyTux_CurrentSprint_%s' % [build_type])
    build_id = json['build'][0]['id']
    return get_teamcity_json('/builds/id:%s' % [build_id])
end

def get_latest_build_json(build_type)
    json = get_teamcity_json('/builds/?count=1&locator=canceled:any,running:any,buildType:SortMyTux_CurrentSprint_%s' % [build_type])
    build_id = json['build'][0]['id']
    return get_teamcity_json('/builds/id:%s' % [build_id])
end

def get_ci_build_json(build_type)
    json = get_teamcity_json('/builds/?count=1&locator=canceled:any,running:false,buildType:SortMyTux_CurrentSprint_%s' % [build_type])
    build_num = json['build'][0]['number']
    ci_json = get_teamcity_json('/builds/?&locator=buildType:SortMyTux_CurrentSprint_BuildAndTest,number:%s' % [build_num])
    build_id = ci_json['build'][0]['id']
    return get_teamcity_json('/builds/id:%s' % [build_id])
end

def get_number_of_fixed_bugs_since(minutes)

    jql = "issuetype=Bug&status changed from ('Backlog', 'Bucket', 'In Progress') to ('Release Ready', 'Done', 'Bug Vault') after -%sm" % [minutes]
    json_body = {
        "jql": jql,
        "startAt": 0,
        "fields": ["key"]
    }

    json = get_jira_json(JSON.generate(json_body))
    return json['total']
end

def seconds_to_string(seconds)
    one_minute = 60
    one_hour = 60 * one_minute
    one_day = 24 * one_hour
    one_week = 7 * one_day

    if seconds >= one_week
        weeks = (seconds / one_week).floor
        seconds -= (weeks * one_week)
        days = (seconds / one_day).floor

        str = '%s week' % [weeks]
        if weeks > 1
            str += 's'
        end
        if days > 1
            str += ' %s days' % [days]
        elsif days ==1
            str += ' %s day' % [days]
        end
        return str
    elsif seconds >= one_day
        days = (seconds / one_day).floor
        if days > 1
            return '%s days' % [days]
        elsif days == 1
            return '%s day' % [days]
        end
    else
        hours = (seconds / one_hour).floor
        if hours > 1
            return '%s hours' % [hours]
        elsif hours == 1
            return '1 hour'
        else
            return '<1 hour'
        end
    end
end