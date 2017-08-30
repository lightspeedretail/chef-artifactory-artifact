require 'json'
require 'net/http'
require 'uri'

module ArtifactoryArtifact
  module Helper
    def artifactoryonline_url(server_name)
      File.join('https://', server_name + '.jfrog.io', server_name)
    end

    def artifactory_headers(options = {})
      if options[:username] || options[:password]
        {
          'Authorization' => [
            'Basic',
            ["#{options[:username]}:#{options[:password]}"].pack('m0')
          ].join(' ')
        }
      else
        {}
      end
    end

    def artifactory_rest_delete(artifactory_url, headers = {})
      artifactory_rest(:DELETE, artifactory_url, nil, headers)
    end

    def artifactory_rest_head(artifactory_url, headers = {})
      artifactory_rest(:HEAD, artifactory_url, nil, headers)
    end

    def artifactory_rest_get(artifactory_url, headers = {})
      artifactory_rest(:GET, artifactory_url, nil, headers)
    end

    def artifactory_rest_post(artifactory_url, data, headers = {})
      headers = { 'Content-Type' => 'application/json' }.merge(headers)
      body = headers['Content-Type'] =~ /\Aapplication\/json(?:;(.*))?\z/ ? ::JSON.dump(data) : data
      artifactory_rest(:POST, artifactory_url, body, { 'Content-Type' => 'application/json' }.merge(headers))
    end

    def artifactory_rest_put(artifactory_url, body, headers = {})
      headers = { 'Content-Type' => 'application/octet-stream' }.merge(headers)
      artifactory_rest(:PUT, artifactory_url, body, headers)
    end

    def artifactory_rest(method, artifactory_url, body, headers = {})
      uri = if ::URI == artifactory_url
              artifactory_url
            else
              ::URI.parse(artifactory_url)
            end
      request_class = ::Net::HTTP.const_get(method.to_s.capitalize)
      request_has_body = begin
                           request_class.const_get(:REQUEST_HAS_BODY)
                         rescue
                           false
                         end
      response_has_body = begin
                            request_class.const_get(:RESPONSE_HAS_BODY)
                          rescue
                            false
                          end
      ::Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = request_class.new(uri.path)
        headers.each do |key, value|
          request[key] = value
        end

        request.body = body if request_has_body && body
        response = http.request(request)
        if ::Net::HTTPSuccess == response
          if response_has_body
            case response['Content-Type']
            when /\Aapplication\/json(?:;(.*))?\z/, /\Aapplication\/[^;]+\+json\z/
              return JSON.parse(response.body)
            else
              Chef::Log.warn("Artifactory REST API: warning: #{uri}: Unknown Content-Type: #{response['Content-Type']}")
              return response.body
            end
          end
        end
      end
    end
  end
end
