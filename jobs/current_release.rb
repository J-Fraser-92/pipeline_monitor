require 'time'

require_relative 'functions'

builds = {
    :ci =>      {:teamcity_id => 'BuildAndTest'},
    :dev =>     {:teamcity_id => 'DeployToDevAzure'},
    :test_uk => {:teamcity_id => 'DeployToTestUk'},
    :test_us => {:teamcity_id => 'DeployToTestAzure'},
    :live_uk => {:teamcity_id => 'DeployToLiveUk'},
    :live_us => {:teamcity_id => 'DeployToProductionUs'}
}

SCHEDULER.every '10s' do

        ci_json = get_latest_completed_build_json(builds[:ci][:teamcity_id])
        live_uk_json = get_latest_completed_build_json(builds[:live_uk][:teamcity_id])
        live_us_json = get_latest_completed_build_json(builds[:live_us][:teamcity_id])
        live_uk_ci_json = get_ci_build_json(builds[:live_uk][:teamcity_id])
        live_us_ci_json = get_ci_build_json(builds[:live_us][:teamcity_id])


        ci_changeset = ci_json['number'].split('.')[-2].to_i
        live_uk_changeset = live_uk_ci_json['number'].split('.')[-2].to_i
        live_us_changeset = live_us_ci_json['number'].split('.')[-2].to_i

        uk_commit_delta = (ci_changeset - live_uk_changeset)
        us_commit_delta = (ci_changeset - live_us_changeset)

        send_event('uk_commit_delta', {current: uk_commit_delta})
        send_event('us_commit_delta', {current: us_commit_delta})


        ci_test_count = ci_json['testOccurrences']['passed'].to_i
        live_uk_test_count = live_uk_ci_json['testOccurrences']['passed'].to_i
        live_us_test_count = live_us_ci_json['testOccurrences']['passed'].to_i

        uk_test_count_delta = (ci_test_count - live_uk_test_count)
        us_test_count_delta = (ci_test_count - live_us_test_count)

        send_event('uk_test_count_delta', {current: uk_test_count_delta})
        send_event('us_test_count_delta', {current: us_test_count_delta})


        now = Time.new
        live_uk_deploy_time = Time.parse(live_uk_json['finishDate'])
        live_us_deploy_time = Time.parse(live_us_json['finishDate'])

        uk_deploy_delta = seconds_to_string((now - live_uk_deploy_time).to_i)
        us_deploy_delta = seconds_to_string((now - live_us_deploy_time).to_i)

        send_event('uk_deploy_delta', {text: uk_deploy_delta})
        send_event('us_deploy_delta', {text: us_deploy_delta})


        mins_since_uk_deploy = (now - live_uk_deploy_time).to_i / 60
        mins_since_us_deploy = (now - live_us_deploy_time).to_i / 60

        send_event('uk_fixed_bugs_delta', {current: get_number_of_fixed_bugs_since(mins_since_uk_deploy)})
        send_event('us_fixed_bugs_delta', {current: get_number_of_fixed_bugs_since(mins_since_us_deploy)})

end


