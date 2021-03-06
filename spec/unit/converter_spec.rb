require_relative 'spec_helper'

describe Converter do

  describe 'end to end' do
    let(:config) { Validator::Configuration.new("#{File.dirname(__FILE__)}/../assets/validator.yml") }
    it 'produces the expected result for the given input' do
      expected_cpi_config =  YAML.load_file("#{File.dirname(__FILE__)}/../assets/expected_cpi.json")

      allow(NetworkHelper).to receive(:next_free_ephemeral_port).and_return(11111)

      expect(Converter.to_cpi_json(config.openstack)).to eq(expected_cpi_config)
    end
  end

  describe '.to_cpi_json' do

    let(:complete_config) do
      {
          'auth_url' => 'https://auth.url/v3',
          'username' => 'username',
          'password' => 'password',
          'domain' => 'domain',
          'project' => 'project'
      }
    end

    describe 'conversions' do
      it "appends 'auth/tokens' to 'auth_url' parameter" do
        rendered_cpi_config = Converter.convert(complete_config)

        expect(rendered_cpi_config['auth_url']).to eq 'https://auth.url/v3/auth/tokens'
      end

      it "replaces 'password' key with 'api_key'" do
        rendered_cpi_config = Converter.convert(complete_config)

        expect(rendered_cpi_config['api_key']).to eq complete_config['password']
        expect(rendered_cpi_config['password']).to be_nil
      end

      context 'when connection_options' do
        let(:tmpdir) do
          Dir.mktmpdir
        end

        before(:each) do
          allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
        end

        after(:each) do
          FileUtils.rmdir(tmpdir)
        end

        context '.ca_cert is given' do
          let(:config_with_ca_cert) {
            complete_config.merge({
                'connection_options' => {
                    'ca_cert' => 'crazykey'
                }
            })
          }

          it "replaces 'ca_cert' with 'ssl_ca_file'" do
            rendered_cpi_config = Converter.convert(config_with_ca_cert)

            expect(rendered_cpi_config['connection_options']['ssl_ca_file']).to eq("#{tmpdir}/cacert.pem")
            expect(rendered_cpi_config['connection_options']['ca_cert']).to be_nil
          end
        end

        [{ name: 'nil', value: nil}, { name: 'empty', value: ''}].each do |falsy_value|

          context ".ca_cert is given #{falsy_value[:name]}" do
            let(:config_with_nil_ca_cert) {
              complete_config.merge({
                  'connection_options' => {
                      'ca_cert' => falsy_value[:value]
                  }
              })
            }

            it "removes 'ca_cert'" do
              rendered_cpi_config = Converter.convert(config_with_nil_ca_cert)

              expect(rendered_cpi_config['connection_options']['ssl_ca_file']).to be_nil
              expect(rendered_cpi_config['connection_options']['ca_cert']).to be_nil
            end
          end

        end
      end
    end

    describe 'registry configuration' do
      it "uses the next free ephemeral port" do
        expect(NetworkHelper).to receive(:next_free_ephemeral_port).and_return(60000)

        rendered_cpi_config = Converter.to_cpi_json(complete_config)

        expect(rendered_cpi_config['cloud']['properties']['registry']['endpoint']).to eq('http://localhost:60000')
      end
    end

  end
end