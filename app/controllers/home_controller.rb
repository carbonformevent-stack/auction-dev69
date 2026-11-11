class HomeController < ApplicationController
  skip_before_action :authenticate_user!

  layout "landing"

  def show
    @landing = LandingPage.new
  end
end
