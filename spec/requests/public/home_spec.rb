require 'rails_helper'

RSpec.describe "Public::Home", type: :request do
  describe "GET /" do
    it "is accessible without authentication" do
      get public_root_path
      expect(response).to have_http_status(:ok)
    end
  end
end
