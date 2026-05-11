class Core::BaseController < ApplicationController
  layout "core"
  before_action :authenticate_user!
end
