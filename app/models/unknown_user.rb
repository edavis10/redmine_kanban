class UnknownUser
  include Singleton

  def id
    0
  end

  def name
    "Unknown User"
  end
end
