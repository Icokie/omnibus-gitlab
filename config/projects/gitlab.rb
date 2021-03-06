#
## Copyright:: Copyright (c) 2013, 2014 GitLab.com
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

require "#{Omnibus::Config.project_root}/lib/gitlab/build_iteration"
require "#{Omnibus::Config.project_root}/lib/gitlab/build/info"
require "#{Omnibus::Config.project_root}/lib/gitlab/version"

ee = system("#{Omnibus::Config.project_root}/support/is_gitlab_ee.sh")

if ee
  name 'gitlab-ee'
  description 'GitLab Enterprise Edition '\
    '(including NGINX, Postgres, Redis)'
  replace 'gitlab-ce'
  conflict 'gitlab-ce'
else
  name 'gitlab-ce'
  description 'GitLab Community Edition '\
    '(including NGINX, Postgres, Redis)'
  replace 'gitlab-ee'
  conflict 'gitlab-ee'
end

maintainer 'GitLab, Inc. <support@gitlab.com>'
homepage 'https://about.gitlab.com/'

license 'MIT'
license_compiled_output true

# Replace older omnibus-gitlab packages
replace         'gitlab'
conflict        'gitlab'

install_dir     '/opt/gitlab'

# This is a hack to make a distinction between nightly versions
# See https://gitlab.com/gitlab-org/omnibus-gitlab/issues/1500
#
# This will be resolved as part of
# https://gitlab.com/gitlab-org/omnibus-gitlab/issues/1007
#
# Also check lib/gitlab/build.rb for Docker version forming
build_version Build::Info.semver_version
build_iteration Gitlab::BuildIteration.new.build_iteration

# Openssh needs to be installed

if suse?
  runtime_dependency 'openssh'
else
  runtime_dependency 'openssh-server'
end

runtime_dependency 'policycoreutils-python' if rhel?

# creates required build directories
dependency 'preparation'
dependency 'package-scripts'

dependency 'git'
dependency 'jemalloc'
dependency 'redis'
dependency 'nginx'
dependency 'mixlib-log'
dependency 'chef-zero'
dependency 'ohai'
dependency 'chef-gem'
dependency 'remote-syslog'
dependency 'logrotate'
dependency 'runit'
if ee
  dependency 'consul'
  dependency 'gitlab-ctl-ee'
  dependency 'gitlab-geo-psql'
end
dependency 'gitlab-ctl'
dependency 'gitlab-psql'
dependency 'gitlab-healthcheck'
dependency 'gitlab-cookbooks'
dependency 'gitlab-selinux'
dependency 'gitlab-scripts'
dependency 'gitlab-config-template'
dependency 'mattermost'
dependency 'prometheus'
dependency 'node-exporter'
dependency 'redis-exporter'
dependency 'postgres-exporter'
dependency 'gitlab-monitor'
dependency 'gitlab-workhorse'
dependency 'gitlab-shell'

# gitaly needs grpc to work correctly. These native extensions are built as part
# of gitlab-rails build. So, gitlab-rails has to be built before gitaly. But
# making gitaly depend on gitlab-rails will cause it to be built earlier,
# because of the way omnibus-gitlab detects and builds transitive depends. So
# we have to maintain this order of requirement here.
dependency 'gitlab-rails'
dependency 'gitaly'

# version manifest file
dependency 'version-manifest'

exclude "\.git*"
exclude "bundler\/git"

# Enable signing packages
package :rpm do
  signing_passphrase ENV['GPG_PASSPHRASE']
end

package :deb do
  signing_passphrase ENV['GPG_PASSPHRASE']
end

# Our package scripts are generated from .erb files,
# so we will grab them from an excluded folder
package_scripts_path "#{install_dir}/.package_util/package-scripts"
exclude '.package_util'

package_user 'root'
package_group 'root'
