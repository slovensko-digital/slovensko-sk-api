# See https://tools.ietf.org/id/draft-inadarei-api-health-check-04.html

class HealthController < ApiController
  skip_before_action(:verify_format)

  before_action { set_default_format(:health) }
  before_action { respond_to(:health) }

  def index
    status = :ok
    health = {
      description: 'slovensko.sk API',
      version: '2.1.1',
      status: 'pass',
      checks: {
        'environment:variables' => environment_variables,
        'postgresql:connection' => postgresql_connection,
        'redis:connection' => redis_connection,
        'authenticator:api' => authenticator_api,
        'authenticator:obo' => authenticator_obo,
        'eform:sync_certificate' => eform_sync_certificate,
        'eform:sync_task' => eform_sync_task,
        'sso:sp_certificate' => sso_sp_certificate,
        'sso:proxy_certificate' => sso_proxy_certificate,
        'sts:certificate' => sts_certificate,
        'sts:creation_time' => sts_creation_time,
        'sts:response_time' => sts_response_time,
      }.compact.transform_values { |v| [v] },
      links: {
        installation: URI.join(request.base_url, 'install.md'),
        documentation: URI.join(request.base_url, 'openapi.yaml'),
      }
    }

    objects = health[:checks].values.flatten
    status, health[:status] = :ok, 'warn' if objects.any? { |o| o[:status] == 'warn' }
    status, health[:status] = :service_unavailable, 'fail' if objects.any? { |o| o[:status] == 'fail' }

    render status: status, content_type: Mime[:health], json: health
  end

  private

  def environment_variables(keys = [])
    keys += %w(DATABASE_URL REDIS_URL SECRET_KEY_BASE) if Rails.env.production? || Rails.env.staging?
    keys += %w(UPVS_KS_SALT UPVS_PK_SALT) if Upvs.env.prod?
    keys += %w(SSO_SP_SUBJECT SSO_PROXY_SUBJECT LOGIN_CALLBACK_URLS LOGOUT_CALLBACK_URLS) if UpvsEnvironment.sso_support?
    unset = keys.select { |v| ENV[v].blank? }
    raise "Unset environment variables #{unset.to_sentence}" if unset.any?
    { status: 'pass' }
  rescue => error
    { status: 'fail', output: error.message }
  end

  def postgresql_connection
    ActiveRecord::Base.connection.reconnect!
    raise 'Unable to establish connection' unless ActiveRecord::Base.connected?
    { status: 'pass' }
  rescue => error
    { status: 'fail', output: error.message }
  end

  def redis_connection
    raise 'Unable to establish connection' unless ActiveSupport::Cache::RedisCacheStore.new.redis.ping
    { status: 'pass' }
  rescue => error
    { status: 'fail', output: error.message }
  end

  def authenticator_api
    Environment.api_token_authenticator
    { status: 'pass' }
  rescue => error
    { status: 'fail', output: error.message }
  end

  def authenticator_obo
    return unless UpvsEnvironment.sso_support?
    Environment.obo_token_authenticator
    { status: 'pass' }
  rescue => error
    { status: 'fail', output: error.message }
  end

  def eform_sync_certificate(sub = ENV['EFORM_SYNC_SUBJECT'])
    return unless sub.present?
    not_after = UpvsEnvironment.subject(sub)[:not_after].in_time_zone
    certificate_verification('eForm synchronization', not_after)
  rescue => error
    { status: 'fail', output: error.message }
  end

  def eform_sync_task(sub = ENV['EFORM_SYNC_SUBJECT'])
    return unless sub.present?
    updated_at = Heartbeat.find_by(name: DownloadFormTemplatesJob.name)&.updated_at
    task_verification('eForm synchronization', updated_at)
  rescue => error
    { status: 'fail', output: error.message }
  end

  def sso_sp_certificate
    return unless UpvsEnvironment.sso_support?
    not_after = OpenSSL::X509::Certificate.new(Base64.decode64(UpvsEnvironment.sso_settings[:certificate].to_s)).not_after.in_time_zone
    certificate_verification('SSO SP', not_after)
  rescue => error
    { status: 'fail', output: error.message }
  end

  def sso_proxy_certificate
    return unless UpvsEnvironment.sso_support?
    not_after = UpvsEnvironment.subject(UpvsEnvironment.sso_proxy_subject)[:not_after].in_time_zone
    certificate_verification('SSO proxy', not_after)
  rescue => error
    { status: 'fail', output: error.message }
  end

  def sts_certificate(sub = ENV['STS_HEALTH_SUBJECT'])
    return unless sub.present?
    not_after = UpvsEnvironment.subject(sub)[:not_after].in_time_zone
    certificate_verification('STS health', not_after)
  rescue => error
    { status: 'fail', output: error.message }
  end

  def sts_creation_time(sub = ENV['STS_HEALTH_SUBJECT'])
    return unless sub.present?
    upvs_properties = UpvsEnvironment.upvs_properties(sub: sub).merge('upvs.log.level' => 'off')
    time = Benchmark.realtime { UpvsProxy.new(upvs_properties) }
    { status: 'pass', observed_value: (time * 1000).round(2), observed_unit: 'ms' }
  rescue => error
    { status: 'fail', output: error.message }
  end

  def sts_response_time(sub = ENV['STS_HEALTH_SUBJECT'])
    return unless sub.present?
    eform_service = UpvsEnvironment.eform_service(sub: sub)
    time = Benchmark.realtime { eform_service.fetch_form_template_status('App.GeneralAgenda', '1.9') }
    { status: 'pass', observed_value: (time * 1000).round(2), observed_unit: 'ms' }
  rescue => error
    { status: 'fail', output: error.message }
  end

  private

  def certificate_verification(name, not_after)
    if not_after <= Time.current
      status, output = 'fail', "#{name} certificate has expired"
    elsif not_after < 2.months.from_now
      status, output = 'warn', "#{name} certificate expires in less than 2 months"
    else
      status, output = 'pass', nil
    end

    { status: status, observed_value: not_after, observed_unit: 'time', output: output }.compact
  end

  def task_verification(name, updated_at)
    late = updated_at && updated_at < 28.hours.ago
    status = late ? 'warn' : 'pass'
    output = late ? "#{name} not performed in last 28 hours" : nil
    { status: status, observed_value: updated_at, observed_unit: 'time', output: output }.tap { |check| check.delete(:output) unless output }
  end
end
