# See https://tools.ietf.org/id/draft-inadarei-api-health-check-02.html

class HealthController < ApplicationController
  def index
    case params[:check]
    when 'worker'
      check_worker_status
    when 'upvs'
      check_ez_service
      check_sktalk_service
    else
      check_environment_variables
      check_database_connection

      check_api_token_key
      check_obo_token_key

      check_sp_certificate
      check_sts_certificate
    end

    render status: :ok, json: { status: 'pass' }
  rescue => error
    render status: :internal_server_error, json: { status: 'fail', output: error.message }
  end

  private

  def check_environment_variables
    variables = Rails.root.join('.env').read.lines.map { |v| v.split('=', 2).first if v.present? }.compact
    variables << 'DATABASE_URL'
    unset = variables.select { |v| ENV[v].blank? }
    raise "Unset environment variables #{unset.to_sentence}" if unset.any?
  end

  def check_database_connection
    ActiveRecord::Base.establish_connection
    raise 'Unable to establish database connection' unless ActiveRecord::Base.connected?
  end

  def check_worker_status
    beat = Heartbeat.find_by(name: DownloadAllFormTemplatesJob.name)
    raise "Unbeaten #{beat.job_class} with last beat at #{beat.updated_at}" if beat && beat.updated_at < 28.hours.ago
  end

  def check_api_token_key
    Environment.api_token_authenticator # initializes API token authenticator with identifier cache and RSA public key
  end

  def check_obo_token_key
    Environment.obo_token_authenticator # initializes OBO token authenticator with assertion store and RSA key pair
  end

  def check_sp_certificate
    sp_ks = KeyStore.new(ENV.fetch('UPVS_SP_KS_FILE'), ENV.fetch('UPVS_SP_KS_PASSWORD'))
    sp_na = Time.parse(sp_ks.certificate(ENV.fetch('UPVS_SP_KS_ALIAS')).not_after.to_s)
    raise "SP certificate expires at #{sp_na}" if sp_na < 2.months.from_now
  end

  def check_sts_certificate
    sts_ks = KeyStore.new(ENV.fetch('UPVS_STS_KS_FILE'), ENV.fetch('UPVS_STS_KS_PASSWORD'))
    sts_na = Time.parse(sts_ks.certificate(ENV.fetch('UPVS_STS_KS_ALIAS')).not_after.to_s)
    raise "STS certificate expires at #{sp_na}" if sts_na < 2.months.from_now
  end

  def check_ez_service
    UpvsEnvironment.upvs_proxy.ez # initializes EZ service with STS certificate
  end

  def check_sktalk_service
    UpvsEnvironment.upvs_proxy.sktalk # initializes SKTalk service with STS certificate
  end
end
