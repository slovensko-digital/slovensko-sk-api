module Integers
  def self.parse_positive(s)
    return s if s.is_a?(Integer) && s > 0
    return s.to_i if match_positive?(s)
    raise ArgumentError
  end

  def self.match_positive?(s)
    s =~ /\A[1-9]\d*\z/
  end
end
