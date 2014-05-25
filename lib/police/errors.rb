module Police
  class PoliceError < StandardError
  end

  class NotAuthorized < PoliceError
  end

  class NotDefined < PoliceError
  end
end
