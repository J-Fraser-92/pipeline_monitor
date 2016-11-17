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

def get_changed_files(build_id)
    url = '/builds/id:%s' % [build_id]
    change_id = get_teamcity_json(url)['lastChanges']['change'][0]['id']

    json = get_teamcity_json('/changes?fields=change(files(count,file(file))),nextHref&locator=buildType:SortMyTux_CurrentSprint_BuildAndTest,sinceChange:(id:%s)' % [change_id])

    hasData = true
    all_changed_files = []
    while hasData do
        all_changes = json['change']

        all_changes.each do |change|
           changed_files = change['files']['file']

            changed_files.each do |file|
                if !file['file'].include? "SMT.Support"
                    all_changed_files << file['file']
                end
            end
        end

        if json.key?('nextHref')
            nextHref = json['nextHref']
            nextHref['/httpAuth/app/rest'] = ''
            json = get_teamcity_json(nextHref)
        else
            hasData = false
        end

    end

    return all_changed_files.uniq
end