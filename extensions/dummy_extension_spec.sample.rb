# copy to ./dummy_extension_spec.rb to see it run
describe 'My extension' do

  it 'is true' do
    expect(true).to be(true)
  end

  context 'when requiring custom configuration' do
    let(:config) { CfValidator.configuration.extensions }
    it 'is available' do
      expect(config['custom-config-key']).to eq('custom-config-value')
    end
  end

  context 'when accessing OpenStack API' do

    context 'compute' do
      let(:compute) { Validator::Api::FogOpenStack.compute }

      it 'is provided by the validator' do
        expect(compute.servers).to be_a(Fog::Compute::OpenStack::Servers)
      end
    end

    context 'network' do
      let(:network) { Validator::Api::FogOpenStack.network }

      it 'is provided by the validator' do
        expect(network.networks).to be_a(Fog::Network::OpenStack::Networks)
      end
    end
  end

  context 'when using resource management' do
    let(:compute) { Validator::Api::FogOpenStack.compute }

    before(:all) do
      @resources = Validator::Api::ResourceTracker.create
    end

    it 'produces a resource' do
      resource_id = @resources.produce(:volumes, provide_as: :test_volume) {
        compute.volumes.create({
            :name => 'validator-test-volume',
            :description => '',
            :size => 1
        }).id
      }

      expect(resource_id).to_not be_nil
    end

    it 'consumes an existing resource' do
      resource_id = @resources.consumes(:test_volume)

      expect(resource_id).to_not be_nil
    end

    it 'consumes a non-existing resource' do
      @resources.consumes(:non_existing_resource)

      fail('Test should have been marked pending')
    end
  end
end