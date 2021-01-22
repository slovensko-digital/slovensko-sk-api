module FixtureNames
  def fixture_names(pattern)
    Dir[File.join(file_fixture_path, pattern)].sort.map { |name| name.remove(file_fixture_path) }
  end

  def fixture_name_to_human(name)
    fixes = { 'ed' => 'ED', 'edesk' => 'eDesk', 'egov' => 'eGov' }
    File.basename(name, '.*').remove('_response').split('_').map { |p| fixes[p] || p }.join(' ')
  end
end

RSpec.configure do |config|
  config.extend FixtureNames
end
