Redmine::Plugin.register :redmine_silencer do
  name 'Redmine Silencer'
  author 'igloonet (fork of paginagmbh/redmine_silencer)'
  description 'Suppress email notifications when updating issues'
  version '2.0.0'
  url 'https://git.igloonet.cz/redmine/redmine_silencer'
  requires_redmine version_or_higher: '6.0'

  permission :suppress_mail_notifications, {}

  settings default: {
    'silencer_default' => '0'
  }, partial: 'settings/redmine_silencer_settings'
end

# No Journal patching needed -- R6 has Journal#notify? and Journal#notify= natively!
# We only need hook listeners for UI and controller behavior.
require_relative 'lib/redmine_silencer/issue_hooks'
require_relative 'lib/redmine_silencer/view_hooks'
