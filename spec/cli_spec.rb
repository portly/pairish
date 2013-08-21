require 'helper'

describe Pssh::CLI do

  describe '.parse_options' do
    it 'parses command line arguments that have been passed to it' do
      opts = double(:opts)
      args = double(:arguments)
      expect(OptionParser).to receive(:new).and_return opts
      expect(opts).to receive(:parse!).with(args)
      Pssh::CLI.parse_options(args)
    end
  end

  describe '.run' do
    it 'parses the options via parse_options' do
      allow(Pssh::Client).to receive(:start)
      args = double(:arguments)
      expect(Pssh::CLI).to receive(:parse_options).with(args).and_return []
      Pssh::CLI.run args
    end

    it 'updates the global variables that have been parsed' do
      allow(Pssh::Client).to receive(:start)
      return_args = { port: 1000 }
      allow(Pssh::CLI).to receive(:parse_options).and_return return_args
      expect(Pssh).to receive(:port=).with(1000)
      Pssh::CLI.run
    end

    it 'starts the client' do
      expect(Pssh::Client).to receive(:start)
      Pssh::CLI.run
    end
  end

end

