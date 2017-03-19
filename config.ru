require 'rack/cors'
require_relative 'app/api'

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: :get
  end
end

run Hydra::API
