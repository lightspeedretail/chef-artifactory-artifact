default_action :create

property :artifactory_url, :kind_of => String
property :artifactoryonline, :kind_of => String
property :repository, :kind_of => String, :required => true
property :repository_path, :kind_of => String, :required => true
property :artifactory_username, :kind_of => String
property :artifactory_password, :kind_of => String

property :group, :kind_of => [Integer, String]
property :mode, :kind_of => [Integer, String]
property :owner, :kind_of => [Integer, String]

action_class do
  require 'uri'

  include ::ArtifactoryArtifact::Helper

  def manage_resource(new_resource)
    request_headers = artifactory_headers(
      :username => new_resource.artifactory_username,
      :password => new_resource.artifactory_password
    )

    if new_resource.artifactory_url
      artifactory_url = ::URI.parse(new_resource.artifactory_url)
    elsif new_resource.artifactoryonline
      artifactory_url = ::URI.parse(artifactoryonline_url(new_resource.artifactoryonline))
    else
      raise('Artifactory URL is not specified')
    end

    repository_path = "#{new_resource.repository.sub(/\A\/+/, '')}/#{new_resource.repository_path}"
    artifact_url = ::URI.join("#{artifactory_url}/", repository_path.sub(/\A\/+/, ''))
    storage_url = ::URI.join("#{artifactory_url}/", "api/storage/#{repository_path}")

    # Retrieve Artifact's SHA256 checksum via Artifactory REST API
    # https://www.jfrog.com/confluence/display/RTF/Artifactory+REST+API#ArtifactoryRESTAPI-FileInfo
    artifact_sha256sum = nil
    begin
      data = artifactory_rest_get(storage_url, request_headers)
      if data['checksums'] && data['checksums']['sha256']
        artifact_sha256sum = data['checksums']['sha256']
      end
    rescue => error
      ::Chef::Log.warn(error)
    end

    directory ::File.dirname(new_resource.name) do
      recursive true
    end

    remote_file new_resource.name do
      backup false
      checksum artifact_sha256sum
      headers request_headers
      source artifact_url.to_s
      action new_resource.action

      group new_resource.group if new_resource.group
      mode new_resource.mode if new_resource.mode
      owner new_resource.owner if new_resource.owner
    end
  end
end

action :create do
  manage_resource(new_resource)
end

action :create_if_missing do
  manage_resource(new_resource)
end

action :delete do
  manage_resource(new_resource)
end
