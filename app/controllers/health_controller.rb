# See https://tools.ietf.org/id/draft-inadarei-api-health-check-02.html

class HealthController < ApplicationController
  def index
    case params[:check]
    when 'heartbeats'
      check_heartbeats
    when 'upvs'
      check_ez_service
      check_sktalk_service
    else
      check_environment_variables

      check_postgresql_connection
      check_redis_connection

      check_api_token_authenticator
      check_obo_token_authenticator

      check_sp_certificate
      check_sts_certificate
    end

    render status: :ok, json: { status: 'pass' }
  rescue => error
    render status: :service_unavailable, json: { status: 'fail', output: error.message }
  end

  private

  def check_environment_variables
    environment = UpvsEnvironment.sso_support? ? '.env' : '.env.without-upvs-sso-support'
    template = Rails.root.join('doc', 'templates', environment)
    variables = template.read.lines.map { |v| v.split('=', 2).first if v.present? }.compact
    variables += ['DATABASE_URL', 'REDIS_URL'] if Rails.env.production? || Rails.env.staging?
    unset = variables.select { |v| ENV[v].blank? }
    raise "Unset environment variables #{unset.to_sentence}" if unset.any?
  end

  def check_postgresql_connection
    ActiveRecord::Base.connection.reconnect!
    raise 'Unable to establish PostgreSQL connection' unless ActiveRecord::Base.connected?
  end

  def check_redis_connection
    raise 'Unable to establish Redis connection' unless ActiveSupport::Cache::RedisCacheStore.new.redis.ping
  end

  def check_api_token_authenticator
    Environment.api_token_authenticator # initializes API token authenticator with identifier cache and RSA public key
  end

  def check_obo_token_authenticator
    return unless UpvsEnvironment.sso_support?
    Environment.obo_token_authenticator # initializes OBO token authenticator with assertion store and RSA key pair
  end

  def check_sp_certificate
    return unless UpvsEnvironment.sso_support?
    sp_ks = KeyStore.new(ENV.fetch('UPVS_SP_KS_FILE'), ENV.fetch('UPVS_SP_KS_PASSWORD'))
    sp_na = Time.parse(sp_ks.certificate(ENV.fetch('UPVS_SP_KS_ALIAS')).not_after.to_s)
    raise "SP certificate expires at #{sp_na}" if sp_na < 2.months.from_now
  end

  def check_sts_certificate
    sts_ks = KeyStore.new(ENV.fetch('UPVS_STS_KS_FILE'), ENV.fetch('UPVS_STS_KS_PASSWORD'))
    sts_na = Time.parse(sts_ks.certificate(ENV.fetch('UPVS_STS_KS_ALIAS')).not_after.to_s)
    raise "STS certificate expires at #{sts_na}" if sts_na < 2.months.from_now
  end

  def check_heartbeats
    beat = Heartbeat.find_by(name: DownloadFormTemplatesJob.name)
    raise "Unbeaten #{beat.name} with last beat at #{beat.updated_at}" if beat && beat.updated_at < 28.hours.ago
  end

  def check_ez_service
    eform_service = UpvsEnvironment.eform_service # initializes EZ service with STS certificate
    eform_service.fetch_xsd_schema('App.GeneralAgenda', '1.9') # invokes EZ service with STS certificate
  end

  def check_sktalk_service
    UpvsEnvironment.upvs_proxy.sktalk # initializes SKTalk service with STS certificate
  end
end
