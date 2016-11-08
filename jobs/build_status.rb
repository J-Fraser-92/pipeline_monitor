require_relative 'functions'

# URL for CI and Dev queue
# http://xedo-tfsbuild:90/httpAuth/app/rest/buildQueue?locator=buildType:SortMyTux_CurrentSprint_BuildAndTest
# http://xedo-tfsbuild:90/httpAuth/app/rest/buildQueue?locator=buildType:SortMyTux_CurrentSprint_DeployToDevAzure

builds = {
    :ci =>      {:teamcity_id => 'BuildAndTest'},
    :dev =>     {:teamcity_id => 'DeployToDevAzure'},
    :test_uk => {:teamcity_id => 'DeployToTestUk'},
    :test_us => {:teamcity_id => 'DeployToTestAzure'},
    :live_uk => {:teamcity_id => 'DeployToLiveUk'},
    :live_us => {:teamcity_id => 'DeployToProductionUs'}
}

SCHEDULER.every '30s' do
    builds.each { |build_name, values|
        json = get_latest_build_json(values[:teamcity_id])

        if json['state'] == 'running'
            status = 'Running'
            moreinfo = 'Started: %s' % [format_time(json['startDate'])]
        else
            status = json['status'].capitalize
            moreinfo = 'Completed: %s' % [format_time(json['finishDate'])]
        end

        if status == 'Unknown'
            if json.key?('canceledInfo')
                status = 'Cancelled'
            end
        end

        send_event(build_name, {status: status, build_no: json['number'], moreinfo: moreinfo})
    }
end


