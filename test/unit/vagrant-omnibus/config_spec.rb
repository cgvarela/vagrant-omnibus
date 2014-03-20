# We have to use `require_relative` until RSpec 2.14.0. As non-standard RSpec
# default paths are not on the $LOAD_PATH.
#
# More info here:
# https://github.com/rspec/rspec-core/pull/831
#
require_relative '../spec_helper'

# rubocop:disable LineLength

describe VagrantPlugins::Omnibus::Config do
  let(:machine) { double('machine') }
  let(:instance) { described_class.new }

  subject(:config) do
    instance.tap do |o|
      o.chef_version = chef_version if defined?(chef_version)
      o.install_script = install_script if defined?(install_script)
      o.cache_packages = cache_packages if defined?(cache_packages)
      o.finalize!
    end
  end

  describe 'defaults' do
    its(:chef_version) { should be_nil }
    its(:install_script) { should be_nil }
    its(:cache_packages) { should be_true }
  end

  describe 'resolving `:latest` to a real Chef version' do
    let(:chef_version) { :latest }
    its(:chef_version) { should be_a(String) }
    its(:chef_version) { should match(/\d*\.\d*\.\d*/) }
  end

  describe 'setting a custom `install_script`' do
    let(:install_script) { 'http://some_path.com/install.sh' }
    its(:install_script) { should eq('http://some_path.com/install.sh') }
  end

  describe 'the `cache_packages` config option behaves truthy' do
    [true, 'bla', 1, 0, Object].each do |obj|
      describe "when `#{obj.to_s}` (#{obj.class})" do
        let(:cache_packages) { obj }
        its(:cache_packages) { should be_true }
      end
    end
    [nil, false].each do |obj|
      describe "when `#{obj.to_s}` (#{obj.class})" do
        let(:cache_packages) { obj }
        its(:cache_packages) { should be_false }
      end
    end
  end

  describe 'validate' do
    it 'should be no-op' do
      expect(subject.validate(machine)).to eq('VagrantPlugins::Omnibus::Config' => [])
    end
  end

  describe '#validate!' do
    describe 'chef_version validation' do
      {
        '11.4.0' => {
          description: 'valid Chef version string',
          valid: true
        },
        '10.99.99' => {
          description: 'invalid Chef version string',
          valid: false
        },
        'FUFUFU' => {
          description: 'invalid RubyGems version string',
          valid: false
        }
      }.each_pair do |version_string, opts|
        context "#{opts[:description]}: #{version_string}" do
          let(:chef_version) { version_string }
          if opts[:valid]
            it 'passes' do
              expect { subject.validate!(machine) }.to_not raise_error
            end
          else
            it 'fails' do
              expect { subject.validate!(machine) }.to raise_error(Vagrant::Errors::ConfigInvalid)
            end
          end
        end
      end
    end # describe chef_version
  end # describe #validate

end
