require 'securerandom'
require 'spec_helper.rb'



##############################################################################
# Tests
##############################################################################

describe Hoodoo::Client do

  before :all do
    # Start our services in background threads
    spec_helper_start_svc_app_in_thread_for( RSpecNumberService )
    spec_helper_start_svc_app_in_thread_for( RSpecRemoteNumberService)
    #spec_helper_start_svc_app_in_thread_for( RSpecNonHoodooService, skip_hoodoo_middleware: true)
  end

  before :each do
    @client = Hoodoo::Client.new({
      drb_port:     URI.parse( Hoodoo::Services::Discovery::ByDRb::DRbServer.uri() ).port,
      auto_session: false
    })
  end

  context 'happy path behaviour' do

    let( :resources ) { [
      {
        description:  'Client -> RSpecNumber',
        endpoint:     @client.resource( :RSpecNumber, 1),
        data:         (0..999).to_a
      },
      {
        description:  'Client -> RSpecEvenNumber -> local service call -> RSpecNumber',
        endpoint:     @client.resource( :RSpecEvenNumber, 1),
        data:         (0..999).step(2).to_a
      },
      {
        description:  'Client -> RSpecOddNumber -> remote service call -> RSpecNumber',
        endpoint:     @client.resource( :RSpecOddNumber, 1),
        data:         (1..999).step(2).to_a
      },
    ] }

    it 'returns every single result with the correct value' do

      resources.each do | resource |
        numbers = []
        resource[ :endpoint ].list.enumerate_all do | result |
          expect( result.platform_errors.errors ).to eq( [] )
          break if result.platform_errors.has_errors?
          numbers << result[ 'number' ]
        end

        expect( numbers ).to eq( resource[ :data ] )
      end

    end

    context 'different batch sizes' do

      let(:limits) {
        [ 25, 250, 500, 750, 999, 1000, 1001 ]
      }

      it 'enumerates correctly with different batch sizes' do

        resources.each do | resource |
          limits.each do | limit |
            numbers = []
            resource[ :endpoint ].list( { 'limit' => limit } ).enumerate_all do | result |
              expect( result.platform_errors.errors ).to eq( [] )
              break if result.platform_errors.has_errors?
              numbers << result[ 'number' ]
            end
            expect( numbers ).to eq( resource[ :data ] )
          end
        end

      end

    end
  #
  # context 'error handling behaviour' do
  #
  #   # Test with different batch sizes
  #   let(:expected_results) {
  #     [
  #       {
  #         limit: 10,
  #         results: 500,
  #       },
  #       {
  #         limit: 250,
  #         results: 500,
  #       },
  #       {
  #         limit: 499,
  #         results: 499,
  #       },
  #       {
  #         limit: 500,
  #         results: 500,
  #       },
  #       {
  #         limit: 501,
  #         results: 0,
  #       },
  #     ]
  #   }
  #
  #   it 'returns values until an error occurs in the batch' do
  #
  #     expected_results.each do | expected |
  #       results = 0
  #       errors  = 0
  #       @imploder_endpoint.list( { limit: expected[:limit] } ).enumerate_all do | result |
  #         results += 1 if result.has_key? 'number'
  #         errors  += 1 if result.platform_errors.has_errors?
  #       end
  #       # Check delivered the correct number of results - note
  #       # client returns errors or resources, never both
  #       expect( results ).to eq( expected[ :results ] )
  #       # Check that an error is returned
  #       expect( errors ).to eq( 1 )
  #     end
  #
  #   end
  #
  #   it 'raises an exception if no block supplied' do
  #     expect {
  #       @imploder_endpoint.list.enumerate_all
  #     }.to raise_exception( RuntimeError, 'Must provide a block to enumerate_all' )
  #
  #   end
  #
  end

end
