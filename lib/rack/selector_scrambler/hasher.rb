class Rack::SelectorScrambler::Hasher
  def initialize(*salts)
    @salt = salts.join
  end

  def djb2(str)
    _djb2(@salt + str)
  end

  def _djb2(str)
    hash = 5381

    str.unpack('c*').map do |c|
      hash = ((hash << 5) + hash) + c
    end

    hash
  end

  def djb3(str)
    _djb3(@salt + str)
  end

  def _djb3(str)
    hash = 5381
    min  = 65
    diff = 51

    str.unpack('C*').map do |c|
      hash = ((hash << 5) + hash) + c
      c = (hash%diff) + min
      c += 6 if c > 90
      c
    end.pack('C*')
  end
end
