require 'rails_helper'

RSpec.describe 'Health Check' do
  def reload_environment!(services = [Environment, UpvsEnvironment])
    services.each do |service|
      if defined? service
        Object.send(:remove_const, service.name)
        load Rails.root.join('app', 'services', service.name.underscore + '.rb')
      end
    end
  end

  before(:example) do
    reload_environment!
  end

  after(:context) do
    reload_environment!
  end

  let(:environment) { ENV.map { |k, v| [k, k.end_with?('SUBJECT') ? SecureRandom.hex : v] }.to_h }

  before(:example) do
    stub_const('ENV', environment)
  end

  if obo_support?
    let(:sso_proxy_subject) { ENV['SSO_PROXY_SUBJECT'] }
    let(:sso_proxy_certificate_expires_at) { 2.years.from_now }
  end

  if sso_support?
    let(:sso_sp_subject) { ENV['SSO_SP_SUBJECT'] }
    let(:sso_sp_certificate_expires_at) { 2.years.from_now }

    let(:sso_proxy_subject) { ENV['SSO_PROXY_SUBJECT'] }
    let(:sso_proxy_certificate_expires_at) { 2.years.from_now }

    before(:example) { allow(OpenSSL::X509::Certificate).to receive_message_chain(:new, :not_after).and_return(sso_sp_certificate_expires_at) }
    before(:example) { allow(UpvsEnvironment).to receive(:subject).with(sso_proxy_subject).and_return(not_after: sso_proxy_certificate_expires_at.as_json) }
  end

  alias_method :contain, :include

  def expect_pass(checks)
    get '/health'

    expect(response.object.with_indifferent_access).to contain(status: 'pass', checks: hash_including(checks))
  end

  def expect_warn(checks)
    get '/health'

    expect(response.object.with_indifferent_access).to contain(status: 'warn', checks: hash_including(checks))
  end

  def expect_fail(checks)
    get '/health'

    expect(response.object.with_indifferent_access).to contain(status: 'fail', checks: hash_including(checks))
  end

  describe 'GET /health' do
    it 'gets health status' do
      get '/health'

      checks = ['environment:variables', 'postgresql:connection', 'redis:connection', 'authenticator:api']
      checks += ['authenticator:obo', 'sso:proxy_certificate'] if (obo_support? || sso_support?)
      checks += ['sso:sp_certificate'] if sso_support?

      expect(response.status).to eq(200)
      expect(response.object.with_indifferent_access).to match(
        description: 'slovensko.sk API',
        version: '3.4.0',
        status: 'pass',
        checks: hash_including(*checks),
        links: {
          installation: 'http://www.example.com/install.md',
          documentation: 'http://www.example.com/openapi.yaml',
        }
      )
    end

    include_examples 'API request media types', get: '/health', accept: 'application/health+json'

    it 'passes on environment:variables' do
      expect_pass('environment:variables' => [{ status: 'pass' }])
    end

    it 'passes on postgresql:connection' do
      expect_pass('postgresql:connection' => [{ status: 'pass' }])
    end

    it 'passes on redis:connection' do
      expect_pass('redis:connection' => [{ status: 'pass' }])
    end

    it 'passes on authenticator:api' do
      expect_pass('authenticator:api' => [{ status: 'pass' }])
    end

    it 'passes on authenticator:obo', if: obo_support? do
      expect_pass('authenticator:obo' => [{ status: 'pass' }])
    end

    it 'passes on authenticator:obo', if: sso_support? do
      expect_pass('authenticator:obo' => [{ status: 'pass' }])
    end

    it 'passes on sso:sp_certificate', if: sso_support? do
      expect_pass(
        'sso:sp_certificate' => [
          {
            status: 'pass',
            observed_value: sso_sp_certificate_expires_at.as_json,
            observed_unit: 'time'
          }
        ]
      )
    end

    it 'passes on sso:proxy_certificate', if: obo_support? do
      expect_pass(
        'sso:proxy_certificate' => [
          {
            status: 'pass',
            observed_value: sso_proxy_certificate_expires_at.as_json,
            observed_unit: 'time'
          }
        ]
      )
    end

    it 'passes on sso:proxy_certificate', if: sso_support? do
      expect_pass(
        'sso:proxy_certificate' => [
          {
            status: 'pass',
            observed_value: sso_proxy_certificate_expires_at.as_json,
            observed_unit: 'time'
          }
        ]
      )
    end

    context 'without environment variables' do
      let(:environment) { super().slice('SSO_SP_SUBJECT') }

      before(:example) { allow(Upvs).to receive_message_chain(:env, :prod?).and_return(true) }

      it 'fails on environment:variables' do
        expect_fail(
          'environment:variables' => [
            {
              status: 'fail',
              output: contain('Unset environment variables')
            }
          ]
        )
      end

      it 'fails on authenticator:api', if: obo_support? do
        expect_fail(
          'authenticator:api' => [
            {
              status: 'fail',
              output: contain('key not found: "SSO_PROXY_SUBJECT"')
            }
          ]
        )
      end

      it 'fails on authenticator:api', if: sso_support? do
        expect_fail(
          'authenticator:api' => [
            {
              status: 'fail',
              output: contain('key not found: "SSO_PROXY_SUBJECT"')
            }
          ]
        )
      end

      it 'fails on authenticator:obo', if: obo_support? do
        expect_fail(
          'authenticator:obo' => [
            {
              status: 'fail',
              output: contain('key not found: "SSO_PROXY_SUBJECT"')
            }
          ]
        )
      end

      it 'fails on authenticator:obo', if: sso_support? do
        expect_fail(
          'authenticator:obo' => [
            {
              status: 'fail',
              output: contain('key not found: "SSO_PROXY_SUBJECT"')
            }
          ]
        )
      end

      it 'fails on sso:proxy_certificate', if: obo_support? do
        expect_fail(
          'sso:proxy_certificate' => [
            {
              status: 'fail',
              output: contain('key not found: "SSO_PROXY_SUBJECT"')
            }
          ]
        )
      end

      it 'fails on sso:proxy_certificate', if: sso_support? do
        expect_fail(
          'sso:proxy_certificate' => [
            {
              status: 'fail',
              output: contain('key not found: "SSO_PROXY_SUBJECT"')
            }
          ]
        )
      end

      it 'passes on others' do
        expect_fail(
          'postgresql:connection' => [contain(status: 'pass')],
          'redis:connection' => [contain(status: 'pass')],
        )

        expect_fail(
          'authenticator:api' => [contain(status: 'pass')],
        ) unless (obo_support? || sso_support?)

        expect_fail(
          'sso:sp_certificate' => [contain(status: 'pass')],
        ) if sso_support?
      end
    end

    context 'without PostgreSQL connection' do
      before(:example) { allow(ActiveRecord::Base).to receive_message_chain(:connected?).and_return(false) }

      it 'fails on postgresql:connection' do
        expect_fail(
          'postgresql:connection' => [
            {
              status: 'fail',
              output: 'Unable to establish connection'
            }
          ]
        )
      end

      it 'passes on others' do
        expect_fail(
          'environment:variables' => [contain(status: 'pass')],
          'redis:connection' => [contain(status: 'pass')],
          'authenticator:api' => [contain(status: 'pass')],
        )

        expect_fail(
          'authenticator:obo' => [contain(status: 'pass')],
          'sso:proxy_certificate' => [contain(status: 'pass')],
        ) if obo_support?

        expect_fail(
          'authenticator:obo' => [contain(status: 'pass')],
          'sso:sp_certificate' => [contain(status: 'pass')],
          'sso:proxy_certificate' => [contain(status: 'pass')],
        ) if sso_support?
      end
    end

    context 'without Redis connection' do
      before(:example) { allow(ActiveSupport::Cache::RedisCacheStore).to receive_message_chain(:new, :redis, :ping).and_return(false) }

      it 'fails on redis:connection' do
        expect_fail(
          'redis:connection' => [
            {
              status: 'fail',
              output: 'Unable to establish connection'
            }
          ]
        )
      end

      it 'passes on others' do
        expect_fail(
          'environment:variables' => [contain(status: 'pass')],
          'postgresql:connection' => [contain(status: 'pass')],
          'authenticator:api' => [contain(status: 'pass')],
        )

        expect_fail(
          'authenticator:obo' => [contain(status: 'pass')],
          'sso:proxy_certificate' => [contain(status: 'pass')],
        ) if obo_support?

        expect_fail(
          'authenticator:obo' => [contain(status: 'pass')],
          'sso:sp_certificate' => [contain(status: 'pass')],
          'sso:proxy_certificate' => [contain(status: 'pass')],
        ) if sso_support?
      end
    end

    context 'without API token public key' do
      before(:example) { allow(Rails.root).to receive(:join).and_wrap_original { |m, *args| args.last.start_with?('api_token') ? '*' : m.call(*args) }}

      it 'fails on authenticator:api' do
        expect_fail(
          'authenticator:api' => [
            {
              status: 'fail',
              output: contain('No such file or directory')
            }
          ]
        )
      end

      it 'passes on others' do
        expect_fail(
          'environment:variables' => [contain(status: 'pass')],
          'postgresql:connection' => [contain(status: 'pass')],
          'redis:connection' => [contain(status: 'pass')],
        )

        expect_fail(
          'authenticator:obo' => [contain(status: 'pass')],
          'sso:proxy_certificate' => [contain(status: 'pass')],
        ) if obo_support?

        expect_fail(
          'authenticator:obo' => [contain(status: 'pass')],
          'sso:sp_certificate' => [contain(status: 'pass')],
          'sso:proxy_certificate' => [contain(status: 'pass')],
        ) if sso_support?
      end
    end

    context 'without OBO token private key', if: obo_support? do
      before(:example) { allow(Rails.root).to receive(:join).and_wrap_original { |m, *args| args.last.start_with?('obo_token') ? '*' : m.call(*args) }}

      it 'fails on authenticator:api' do
        expect_fail(
          'authenticator:api' => [
            {
              status: 'fail',
              output: contain('No such file or directory')
            }
          ]
        )
      end

      it 'fails on authenticator:obo' do
        expect_fail(
          'authenticator:obo' => [
            {
              status: 'fail',
              output: contain('No such file or directory')
            }
          ]
        )
      end

      it 'passes on others' do
        expect_fail(
          'environment:variables' => [contain(status: 'pass')],
          'postgresql:connection' => [contain(status: 'pass')],
          'redis:connection' => [contain(status: 'pass')],
        )

        expect_fail(
          'sso:proxy_certificate' => [contain(status: 'pass')],
        ) if obo_support?
      end
    end

    context 'without OBO token private key', if: sso_support? do
      before(:example) { allow(Rails.root).to receive(:join).and_wrap_original { |m, *args| args.last.start_with?('obo_token') ? '*' : m.call(*args) }}

      it 'fails on authenticator:api' do
        expect_fail(
          'authenticator:api' => [
            {
              status: 'fail',
              output: contain('No such file or directory')
            }
          ]
        )
      end

      it 'fails on authenticator:obo' do
        expect_fail(
          'authenticator:obo' => [
            {
              status: 'fail',
              output: contain('No such file or directory')
            }
          ]
        )
      end

      it 'passes on others' do
        expect_fail(
          'environment:variables' => [contain(status: 'pass')],
          'postgresql:connection' => [contain(status: 'pass')],
          'redis:connection' => [contain(status: 'pass')],
        )

        expect_fail(
          'sso:sp_certificate' => [contain(status: 'pass')],
          'sso:proxy_certificate' => [contain(status: 'pass')],
        ) if sso_support?
      end
    end

    pending 'without SSO IDP metadata', if: sso_support?

    pending 'without SSO SP metadata', if: sso_support?

    context 'without SSO SP subject', if: sso_support? do
      context 'with no certificate' do
        # TODO call original after resolving SSO settings load skip in UpvsEnvironment#sso_settings when in test environment
        before(:example) { allow(UpvsEnvironment).to receive(:sso_settings).and_raise(java.io.FileNotFoundException.new('No such file or directory')) }

        it 'fails on sso:sp_certificate' do
          expect_fail(
            'sso:sp_certificate' => [
              {
                status: 'fail',
                output: contain('No such file or directory')
              }
            ]
          )
        end

        it 'passes on others' do
          expect_fail(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          )
        end
      end

      context 'with expiring certificate' do
        let(:sso_sp_certificate_expires_at) { 2.days.from_now }

        it 'warns on sso:sp_certificate' do
          expect_warn(
            'sso:sp_certificate' => [
              {
                status: 'warn',
                observed_value: sso_sp_certificate_expires_at.as_json,
                observed_unit: 'time',
                output: 'SSO SP certificate expires in less than 2 months'
              }
            ]
          )
        end

        it 'passes on others' do
          expect_warn(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          )
        end
      end

      context 'with expired certificate' do
        let(:sso_sp_certificate_expires_at) { 2.days.ago }

        it 'fails on sso:sp_certificate' do
          expect_fail(
            'sso:sp_certificate' => [
              {
                status: 'fail',
                observed_value: sso_sp_certificate_expires_at.as_json,
                observed_unit: 'time',
                output: 'SSO SP certificate has expired'
              }
            ]
          )
        end

        it 'passes on others' do
          expect_fail(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          )
        end
      end
    end

    context 'without SSO proxy subject ', if: obo_support? do
      context 'with no certificate' do
        before(:example) { allow(UpvsEnvironment).to receive(:subject).with(sso_proxy_subject).and_call_original }

        it 'fails on sso:proxy_certificate' do
          expect_fail(
            'sso:proxy_certificate' => [
              {
                status: 'fail',
                output: contain('file does not exist')
              }
            ]
          )
        end

        it 'passes on others' do
          expect_fail(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'authenticator:obo' => [contain(status: 'pass')]
          )
        end
      end

      context 'with expiring certificate' do
        let(:sso_proxy_certificate_expires_at) { 2.days.from_now }

        it 'warns on sso:proxy_certificate' do
          expect_warn(
            'sso:proxy_certificate' => [
              {
                status: 'warn',
                observed_value: sso_proxy_certificate_expires_at.as_json,
                observed_unit: 'time',
                output: 'SSO proxy certificate expires in less than 2 months'
              }
            ]
          )
        end

        it 'passes on others' do
          expect_warn(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'authenticator:obo' => [contain(status: 'pass')]
          )
        end
      end

      context 'with expired certificate' do
        let(:sso_proxy_certificate_expires_at) { 2.days.ago }

        it 'fails on sso:proxy_certificate' do
          expect_fail(
            'sso:proxy_certificate' => [
              {
                status: 'fail',
                observed_value: sso_proxy_certificate_expires_at.as_json,
                observed_unit: 'time',
                output: 'SSO proxy certificate has expired'
              }
            ]
          )
        end

        it 'passes on others' do
          expect_fail(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'authenticator:obo' => [contain(status: 'pass')]
          )
        end
      end
    end

    context 'without SSO proxy subject ', if: sso_support? do
      context 'with no certificate' do
        before(:example) { allow(UpvsEnvironment).to receive(:subject).with(sso_proxy_subject).and_call_original }

        it 'fails on sso:proxy_certificate' do
          expect_fail(
            'sso:proxy_certificate' => [
              {
                status: 'fail',
                output: contain('file does not exist')
              }
            ]
          )
        end

        it 'passes on others' do
          expect_fail(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:sp_certificate' => [contain(status: 'pass')],
          )
        end
      end

      context 'with expiring certificate' do
        let(:sso_proxy_certificate_expires_at) { 2.days.from_now }

        it 'warns on sso:proxy_certificate' do
          expect_warn(
            'sso:proxy_certificate' => [
              {
                status: 'warn',
                observed_value: sso_proxy_certificate_expires_at.as_json,
                observed_unit: 'time',
                output: 'SSO proxy certificate expires in less than 2 months'
              }
            ]
          )
        end

        it 'passes on others' do
          expect_warn(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:sp_certificate' => [contain(status: 'pass')],
          )
        end
      end
    end

    context 'with eForm synchronization subject' do
      let(:environment) { super().merge('EFORM_SYNC_SUBJECT' => eform_sync_subject) }

      let(:eform_sync_subject) { SecureRandom.hex }
      let(:eform_sync_certificate_expires_at) { 2.years.from_now }
      let(:eform_sync_task_performed_at) { 2.hours.ago }

      before(:example) { allow(UpvsEnvironment).to receive(:subject).with(eform_sync_subject).and_return(not_after: eform_sync_certificate_expires_at.as_json) }
      before(:example) { Heartbeat.create!(name: DownloadFormTemplatesJob.name, updated_at: eform_sync_task_performed_at) }

      it 'passes on eform:sync_certificate' do
        expect_pass(
          'eform:sync_certificate' => [
            {
              status: 'pass',
              observed_value: eform_sync_certificate_expires_at.as_json,
              observed_unit: 'time'
            }
          ]
        )
      end

      it 'passes on eform:sync_task' do
        expect_pass(
          'eform:sync_task' => [
            {
              status: 'pass',
              observed_value: eform_sync_task_performed_at.as_json,
              observed_unit: 'time'
            }
          ]
        )
      end

      it 'passes on others' do
        expect_pass(
          'environment:variables' => [contain(status: 'pass')],
          'postgresql:connection' => [contain(status: 'pass')],
          'redis:connection' => [contain(status: 'pass')],
          'authenticator:api' => [contain(status: 'pass')],
        )

        expect_pass(
          'authenticator:obo' => [contain(status: 'pass')],
          'sso:proxy_certificate' => [contain(status: 'pass')],
        ) if obo_support?

        expect_pass(
          'authenticator:obo' => [contain(status: 'pass')],
          'sso:sp_certificate' => [contain(status: 'pass')],
          'sso:proxy_certificate' => [contain(status: 'pass')],
        ) if sso_support?
      end

      context 'with no certificate' do
        before(:example) { allow(UpvsEnvironment).to receive(:subject).with(eform_sync_subject).and_call_original }

        it 'fails on eform:sync_certificate' do
          expect_fail(
            'eform:sync_certificate' => [
              {
                status: 'fail',
                output: contain('file does not exist')
              }
            ]
          )
        end

        it 'passes on others' do
          expect_fail(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'eform:sync_task' => [contain(status: 'pass')],
          )

          expect_fail(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if obo_support?

          expect_fail(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:sp_certificate' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if sso_support?
        end
      end

      context 'with expiring certificate' do
        let(:eform_sync_certificate_expires_at) { 2.days.from_now }

        it 'warns on eform:sync_certificate' do
          expect_warn(
            'eform:sync_certificate' => [
              {
                status: 'warn',
                observed_value: eform_sync_certificate_expires_at.as_json,
                observed_unit: 'time',
                output: 'eForm synchronization certificate expires in less than 2 months'
              }
            ]
          )
        end

        it 'passes on others' do
          expect_warn(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'eform:sync_task' => [contain(status: 'pass')],
          )

          expect_warn(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if obo_support?

          expect_warn(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:sp_certificate' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if sso_support?
        end
      end

      context 'with expired certificate' do
        let(:eform_sync_certificate_expires_at) { 2.days.ago }

        it 'fails on eform:sync_certificate' do
          expect_fail(
            'eform:sync_certificate' => [
              {
                status: 'fail',
                observed_value: eform_sync_certificate_expires_at.as_json,
                observed_unit: 'time',
                output: 'eForm synchronization certificate has expired'
              }
            ]
          )
        end

        it 'passes on others' do
          expect_fail(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'eform:sync_task' => [contain(status: 'pass')],
          )

          expect_fail(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if obo_support?

          expect_fail(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:sp_certificate' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if sso_support?
        end
      end

      context 'with no heartbeat' do
        before(:example) { Heartbeat.first.delete }

        it 'passes on eform:sync_task' do
          expect_pass(
            'eform:sync_task' => [
              {
                status: 'pass',
                observed_value: nil,
                observed_unit: 'time'
              }
            ]
          )
        end

        it 'passes on others' do
          expect_pass(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'eform:sync_certificate' => [contain(status: 'pass')],
          )

          expect_pass(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if obo_support?

          expect_pass(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:sp_certificate' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if sso_support?
        end
      end

      context 'with late heartbeat' do
        let(:eform_sync_task_performed_at) { 2.days.ago }

        it 'warns on eform:sync_task' do
          expect_warn(
            'eform:sync_task' => [
              {
                status: 'warn',
                observed_value: eform_sync_task_performed_at.as_json,
                observed_unit: 'time',
                output: 'eForm synchronization not performed in last 28 hours'
              }
            ]
          )
        end

        it 'passes on others' do
          expect_warn(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'eform:sync_certificate' => [contain(status: 'pass')],
          )

          expect_warn(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if obo_support?

          expect_warn(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:sp_certificate' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if sso_support?
        end
      end
    end

    context 'with STS health subject' do
      let(:environment) { super().merge('STS_HEALTH_SUBJECT' => sts_health_subject) }

      let(:sts_health_subject) { SecureRandom.hex }
      let(:sts_health_certificate_expires_at) { 2.years.from_now }

      before(:example) { allow(UpvsEnvironment).to receive(:subject).with(sts_health_subject).and_return(not_after: sts_health_certificate_expires_at.as_json) }
      before(:example) { allow(UpvsEnvironment).to receive_message_chain(:eform_service, :fetch_form_template_status) }
      before(:example) { allow(UpvsProxy).to receive(:new) }

      it 'passes on sts:certificate' do
        expect_pass(
          'sts:certificate' => [
            {
              status: 'pass',
              observed_value: sts_health_certificate_expires_at.as_json,
              observed_unit: 'time'
            }
          ]
        )
      end

      it 'passes on sts:creation_time' do
        expect_pass(
          'sts:creation_time' => [
            {
              status: 'pass',
              observed_value: kind_of(Float),
              observed_unit: 'ms'
            }
          ]
        )
      end

      it 'passes on sts:response_time' do
        expect_pass(
          'sts:response_time' => [
            {
              status: 'pass',
              observed_value: kind_of(Float),
              observed_unit: 'ms'
            }
          ]
        )
      end

      it 'passes on others' do
        expect_pass(
          'environment:variables' => [contain(status: 'pass')],
          'postgresql:connection' => [contain(status: 'pass')],
          'redis:connection' => [contain(status: 'pass')],
          'authenticator:api' => [contain(status: 'pass')],
        )

        expect_pass(
          'authenticator:obo' => [contain(status: 'pass')],
          'sso:proxy_certificate' => [contain(status: 'pass')],
        ) if obo_support?

        expect_pass(
          'authenticator:obo' => [contain(status: 'pass')],
          'sso:sp_certificate' => [contain(status: 'pass')],
          'sso:proxy_certificate' => [contain(status: 'pass')],
        ) if sso_support?
      end

      context 'with no certificate' do
        before(:example) { allow(UpvsEnvironment).to receive(:subject).with(sts_health_subject).and_call_original }
        before(:example) { allow(UpvsEnvironment).to receive(:eform_service).and_call_original }
        before(:example) { allow(UpvsProxy).to receive(:new).and_call_original }

        it 'fails on sts:certificate' do
          expect_fail(
            'sts:certificate' => [
              {
                status: 'fail',
                output: contain('file does not exist')
              }
            ]
          )
        end

        it 'fails on sts:creation_time' do
          expect_fail(
            'sts:creation_time' => [
              {
                status: 'fail',
                output: contain('NoSuchFileException')
              }
            ]
          )
        end

        it 'fails on sts:response_time' do
          expect_fail(
            'sts:response_time' => [
              {
                status: 'fail',
                output: contain('NoSuchFileException')
              }
            ]
          )
        end

        it 'passes on others' do
          expect_fail(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
          )

          expect_fail(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if obo_support?

          expect_fail(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:sp_certificate' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if sso_support?
        end
      end

      context 'with expiring certificate' do
        let(:sts_health_certificate_expires_at) { 2.days.from_now }

        it 'warns on sts:certificate' do
          expect_warn(
            'sts:certificate' => [
              {
                status: 'warn',
                observed_value: sts_health_certificate_expires_at.as_json,
                observed_unit: 'time',
                output: 'STS health certificate expires in less than 2 months'
              }
            ]
          )
        end

        it 'passes on others' do
          expect_warn(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'sts:creation_time' => [contain(status: 'pass')],
            'sts:response_time' => [contain(status: 'pass')],
          )

          expect_warn(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if obo_support?

          expect_warn(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:sp_certificate' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if sso_support?
        end
      end

      context 'with expired certificate' do
        let(:sts_health_certificate_expires_at) { 2.days.ago }

        it 'fails on sts:certificate' do
          expect_fail(
            'sts:certificate' => [
              {
                status: 'fail',
                observed_value: sts_health_certificate_expires_at.as_json,
                observed_unit: 'time',
                output: 'STS health certificate has expired'
              }
            ]
          )
        end

        pending 'fails on sts:creation_time'
        pending 'fails on sts:response_time'

        it 'passes on others' do
          expect_fail(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
          )

          expect_fail(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if obo_support?

          expect_fail(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:sp_certificate' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if sso_support?
        end
      end

      context 'without STS connection' do
        before(:example) { allow(UpvsEnvironment).to receive_message_chain(:eform_service, :fetch_form_template_status).and_raise(soap_timeout_exception) }

        it 'fails on sts:response_time' do
          expect_fail(
            'sts:response_time' => [
              {
                status: 'fail',
                output: contain('connect timed out')
              }
            ]
          )
        end

        it 'passes on others' do
          expect_fail(
            'environment:variables' => [contain(status: 'pass')],
            'postgresql:connection' => [contain(status: 'pass')],
            'redis:connection' => [contain(status: 'pass')],
            'authenticator:api' => [contain(status: 'pass')],
            'sts:certificate' => [contain(status: 'pass')],
            'sts:creation_time' => [contain(status: 'pass')],
          )

          expect_fail(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if obo_support?

          expect_fail(
            'authenticator:obo' => [contain(status: 'pass')],
            'sso:sp_certificate' => [contain(status: 'pass')],
            'sso:proxy_certificate' => [contain(status: 'pass')],
          ) if sso_support?
        end
      end
    end
  end
end
