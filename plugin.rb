# name: GitHub docs badges
# about: Assign users badges based on GitHub contributions
# version: 0.1
# authors: Sam Saffron

module ::GithubDocsBadges
  def self.badge_grant!

    return unless SiteSetting.github_docs_badges_repo.present?

    # ensure badges exist
    unless bronze = Badge.find_by(name: 'Scribe')
      bronze = Badge.create!(name: 'Scribe',
                             description: 'Contributed to the documentation',
                             badge_type_id: 3)
    end

    unless silver = Badge.find_by(name: 'Great Scribe')
      silver = Badge.create!(name: 'Great Scribe',
                             description: 'Contributed 25 commits to the documentation',
                             badge_type_id: 2)
    end

    unless gold = Badge.find_by(name: 'Amazing Scribe')
      gold = Badge.create!(name: 'Amazing Scribe',
                             description: 'Contributed 250 commits to the documentation',
                             badge_type_id: 1)
    end

    emails = []

    path = '/tmp/github_docs_badges'

    if !Dir.exists?(path)
      Rails.logger.info `cd /tmp && git clone #{SiteSetting.github_docs_badges_repo} github_docs_badges`
    else
      Rails.logger.info `cd #{path} && git pull`
    end

    `cd #{path} && git log --pretty=format:%ae`.each_line do |m|
      emails << m.strip
    end

    email_commits = emails.group_by{|e| e}.map{|k, l|[k, l.count]}

    Rails.logger.info "#{email_commits.length} commits found!"

    email_commits.each do |email, commits|
      user = User.find_by(email: email)

      if user
        if commits < 25
          BadgeGranter.grant(bronze, user)
        elsif commits < 250
          BadgeGranter.grant(silver, user)
        else
          BadgeGranter.grant(gold, user)
        end
      end

    end

  end
end

after_initialize do
  module ::GithubDocsBadges
    class UpdateJob < ::Jobs::Scheduled
      every 1.day

      def execute(args)
        GithubDocsBadges.badge_grant!
      end
    end
  end
end
