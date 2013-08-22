require 'spec_helper'

describe Pssh::Web do

  before do
    @web = Pssh::Web.new
  end

  describe '#call' do
    it 'should set the username if HTTP Basic Auth is used' do
      expect(Pssh).to receive(:create_session).with('encrypted_username')
      @web.call({ 'HTTP_AUTHORIZATION' => "basic #{Base64.encode64('encrypted_username:password')}" })
    end
    it 'renders index' do
      allow(Pssh).to receive(:create_session).and_return 'id'
      expect(@web).to receive(:render).with('index', hash_including(:unique_id => 'id'))
      @web.call({})
    end
  end

end
