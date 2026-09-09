# frozen_string_literal: true

require 'json'
require 'pathname'
require 'spec_helper'
require 'bolt_spec/plans'

describe 'secure_env_vars' do
  include BoltSpec::Plans

  let(:env_vars)        { { 'foo' => 'bar' } }
  let(:output)          { { 'stdout' => 'success' } }
  let(:bolt_config)     { { 'modulepath' => RSpec.configuration.module_path } }
  let(:target)          { { 'targets' => 'localhost' } }
  let(:command)         { 'whoami' }
  let(:command_params)  { { 'command' => command }.merge(target) }

  before(:all) do
    BoltSpec::Plans.init
  end

  around(:each) do |example|
    original = ENV.fetch('BOLT_ENV_VARS', nil)
    ENV['BOLT_ENV_VARS'] = env_vars.to_json
    example.run
  ensure
    ENV['BOLT_ENV_VARS'] = original
  end

  it 'errors when passing command and script' do
    result = run_plan('secure_env_vars', command_params.merge({ 'script' => 'foobar' }))
    expect(result.ok?).not_to be
    expect(result.value.msg).to match(%r{Cannot specify both script and command for secure_env_vars})
  end

  it 'errors when passing neither command nor script' do
    result = run_plan('secure_env_vars', target)
    expect(result.ok?).not_to be
    expect(result.value.msg).to match(%r{Must specify either script or command for secure_env_vars})
  end

  it 'succeeds with a command' do
    expect_command(command).with_targets([target['targets']])
                           .with_params('_env_vars' => env_vars)
    result = run_plan('secure_env_vars', command_params)
    expect(result.ok?).to be
  end

  it 'succeeds with a script' do
    Tempfile.open(['script', 'rb'], File.join(Dir.pwd, 'spec', 'fixtures', 'modules', 'secure_env_vars', 'files')) do |file|
      file.binmode # Stop Ruby implicitly doing CRLF translations and breaking tests
      file.write('puts Hello')
      file.flush

      puppet_path = File.join('secure_env_vars', Pathname.new(file.path).basename)
      expect_script(puppet_path).with_targets([target['targets']])
                                .with_params('_env_vars' => env_vars)
      result = run_plan('secure_env_vars', target.merge({ 'script' => file.path }))
      expect(result.ok?).to be
    end
  end

  it 'passes an empty hash to env_vars when BOLT_ENV_VARS is not set' do
    ENV.delete('BOLT_ENV_VARS')
    expect_command(command).with_targets([target['targets']])
                           .with_params('_env_vars' => {})
    result = run_plan('secure_env_vars', command_params)
    expect(result.ok?).to be
  end
end
