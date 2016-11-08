require 'json'
require 'net/http'
require 'yaml'

builds = {
    :ci =>      {:teamcity_id => 'BuildAndTest'},
    :dev =>     {:teamcity_id => 'DeployToDevAzure'},
    :test_uk => {:teamcity_id => 'DeployToTestUk'},
    :test_us => {:teamcity_id => 'DeployToTestAzure'},
    :live_uk => {:teamcity_id => 'DeployToLiveUk'},
    :live_us => {:teamcity_id => 'DeployToProductionUs'}
}

# URL for CI and Dev queue
# http://xedo-tfsbuild:90/httpAuth/app/rest/buildQueue?locator=buildType:SortMyTux_CurrentSprint_BuildAndTest
# http://xedo-tfsbuild:90/httpAuth/app/rest/buildQueue?locator=buildType:SortMyTux_CurrentSprint_DeployToDevAzure

def get_json_response(url)
    url = URI.parse(url)
    req = Net::HTTP::Get.new(url.to_s)
    req['Authorization'] = 'Basic amFtZXNmcmFzZXI6U3RhcmsxVWx0cm9uMUh1bGs='
    req['Accept'] = 'application/json'

    res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
    }

    return JSON.parse(res.body)
end

def format_time(time)
    return Time.parse(time).strftime("%d/%m/%y %H:%M")
end

data = YAML::load_file('jobs/data/unittests.yml')

latest_build = data['data'].keys.max
latest_unittest_count = data['data'][latest_build][:unit_tests]

SCHEDULER.every '10s' do
    builds.each { |build_name, values|
        json = get_json_response('http://xedo-tfsbuild:90/httpAuth/app/rest/builds/?count=1&locator=canceled:any,running:any,buildType:SortMyTux_CurrentSprint_%s' % [values[:teamcity_id]])
        build_id = json['build'][0]['id']
        json = get_json_response('http://xedo-tfsbuild:90/httpAuth/app/rest/builds/id:%s' % [build_id])

        if json['state'] == 'running'
            status = 'Running'
            moreinfo = 'Started: %s' % [format_time(json['startDate'])]
        else
            status = json['status'].capitalize
            moreinfo = 'Completed: %s' % [format_time(json['finishDate'])]

            if build_name == :ci && json.key?('testOccurrences')
                update_unittest_metrics(json)
            end
        end

        if status == 'Unknown'
            if json.key?('canceledInfo')
                status = 'Cancelled'
            end
        end

        send_event(build_name, {status: status, build_no: json['number'], moreinfo: moreinfo})

    }
end


def update_unittest_metrics(json)
    tc_build_id = json['number'].split('.')[-1].to_i
    if tc_build_id > latest_build
        latest_build = tc_build_id

        send_event('unittest_count', {current: json['testOccurrences']['count'], last: latest_unittest_count})
        latest_unittest_count = json['testOccurrences']['count']

        data['data'][latest_build] = {:unit_tests => latest_unittest_count}
        File.open('jobs/data/unittests.yml', 'w') {|f| f.write data.to_yaml }
   end
end