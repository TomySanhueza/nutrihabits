require "test_helper"

class PlansControllerTest < ActionDispatch::IntegrationTest
  test "legacy plans route is not exposed" do
    get "/plans/123"

    assert_response :not_found
  end
end
