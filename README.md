# artifactory-artifact

LWRP for artifacts on Artifactory.

## Supported Platforms

* Debian GNU/Linux
* Ubuntu Linux

## Examples

Download artifact from Artifactory Online.

```rb
artifactory_artifact "/opt/twittersdk/twitter-core-1.6.4-javadoc.jar" do
  artifactoryonline "twittersdk"
  repository "repo"
  repository_path "com/twitter/sdk/android/twitter-core/1.6.4/twitter-core-1.6.4-javadoc.jar"
  artifactory_user "herp"
  artifactory_password "derp"
end
```
