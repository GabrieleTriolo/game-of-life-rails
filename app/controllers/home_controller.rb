class HomeController < ApplicationController
    before_action :authenticate_user!
    
    def upload; end
  end
  