require 'yaml'

require_relative 'functions'

$build_data = YAML::load_file('jobs/data/unittests.yml')

SCHEDULER.every '30s' do
    json = get_teamcity_json('/builds/buildType:SortMyTux_CurrentSprint_BuildAndTest,running:false/')
    build_num = json['number'].split('.')[-1].to_i
    build_id = json['id']

    current_build_num = get_latest_build($build_data).to_i

    if (build_num > current_build_num)
        stats = get_teamcity_json('/builds/id:%s/statistics' % [build_id])['property']

        total_tests = stats[stats.index {|h| h['name'] == 'TotalTestCount' }]['value'].to_i
        passed_tests = stats[stats.index {|h| h['name'] == 'PassedTestCount' }]['value'].to_i
        ignored_tests = stats[stats.index {|h| h['name'] == 'IgnoredTestCount' }]['value'].to_i

        code_coverage_c = stats[stats.index {|h| h['name'] == 'CodeCoverageC' }]['value'].to_i
        code_coverage_m = stats[stats.index {|h| h['name'] == 'CodeCoverageM' }]['value'].to_i
        code_coverage_s = stats[stats.index {|h| h['name'] == 'CodeCoverageS' }]['value'].to_i

        send_event('unittest_count', {current: passed_tests, last: $build_data[current_build_num][:unit_tests]})
        send_event('code_coverage_c', {value: code_coverage_c, last: $build_data[current_build_num][:class_coverage]})
        send_event('code_coverage_m', {value: code_coverage_m, last: $build_data[current_build_num][:method_coverage]})
        send_event('code_coverage_s', {value: code_coverage_s, last: $build_data[current_build_num][:statement_coverage]})

        $build_data[build_num] = {
            :unit_tests => passed_tests,
            :class_coverage => code_coverage_c,
            :method_coverage => code_coverage_m,
            :statement_coverage => code_coverage_s
        }

        File.open('jobs/data/unittests.yml', 'w') {|f| f.write $build_data.to_yaml }
   end
end