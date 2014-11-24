class APILogger < Grape::Middleware::Base
  def before
    API.logger.info [
      "[api] Requested: #{request_log_data.to_json}",
      [ "[api]",
        response_log_data[:description],
        "#{response_log_data[:source_file]}:",
        response_log_data[:source_line]
      ].join(' ')
    ].join("\n")
  end

  private

  def request_log_data
    {
      method: env['REQUEST_METHOD'],
      path:   env['PATH_INFO'],
      query:  env['QUERY_STRING']
    }
  end

  def response_log_data
    {
      description: env['api.endpoint'].options[:route_options][:description],
      source_file: env['api.endpoint'].block.source_location[0][(Rails.root.to_s.length+1)..-1],
      source_line: env['api.endpoint'].block.source_location[1]
    }
  end
end
