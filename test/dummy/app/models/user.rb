class User < ApplicationRecord
  include Events::Trackable
end
