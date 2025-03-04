require 'json'
require 'open-uri'

module GitUtils
  # Returns true if file is different from the committed version in git.
  def self.file_changed_from_git?(file)
    !`git status --porcelain #{file}`.strip.empty?
  end

  # Returns whether any files in this branch or locally changed from base version
  def self.changed_in_branch_or_local?(base_branch, glob_patterns)
    files_changed_in_branch_or_local(base_branch, glob_patterns).empty?
  end

  def self.files_changed_in_branch_or_local(base_branch, glob_patterns, ignore_patterns: [])
    files = files_changed_branch_or_local(base_branch)
    files_matching_globs(files, glob_patterns, ignore_patterns: ignore_patterns)
  end

  def self.files_matching_globs(files, glob_patterns, ignore_patterns: [])
    files = files.reject do |file_path|
      ignore_patterns.any? do |glob|
        RakeUtils.glob_matches_file_path?(glob, file_path)
      end
    end
    files.select do |file_path|
      glob_patterns.any? do |glob|
        RakeUtils.glob_matches_file_path?(glob, file_path)
      end
    end
  end

  def self.files_changed_branch_or_local(base_branch)
    files_changed_locally.concat(files_changed_in_branch(base_branch)).uniq
  end

  def self.files_changed_in_branch(base_branch)
    current_branch = self.current_branch
    # via http://stackoverflow.com/a/25071749
    `git --no-pager diff --name-only #{current_branch} $(git merge-base #{current_branch} #{base_branch})`.split("\n")
  end

  def self.files_changed_locally
    staged_changes = `git diff --cached --name-only`.split("\n")
    unstaged_changes = `git diff --name-only`.split("\n")
    staged_changes.concat(unstaged_changes).uniq
  end

  def self.current_branch
    `git rev-parse --abbrev-ref HEAD`.strip
  end

  def self.get_latest_commit_merged_branch
    get_branch_commit_merges(git_revision)
  end

  def self.git_revision
    `git rev-parse HEAD`.strip
  end

  def self.git_revision_short(project_directory=Dir.pwd)
    return nil if project_directory.nil?
    # Cron jobs execute as root and may not be in the current project directory, preventing git commands from working.
    # Eventually other (or all) GitUtils methods may need to explicitly change to the project root, but currently
    # only this call to a GitUtils method is executed when a cron job runs:
    # https://github.com/code-dot-org/code-dot-org/blob/7863f6bdc4d275536754bbce8f88400c96de48db/deployment.rb#L41
    Dir.chdir(project_directory) do
      `git rev-parse --short=8 HEAD`.strip
    end
  end

  def self.git_revision_branch(branch)
    `git rev-parse #{branch}`.strip
  end

  def self.get_branch_commit_merges(commit)
    commit_json = JSON.parse(open("https://api.github.com/repos/code-dot-org/code-dot-org/commits/#{commit}").read)
    commit_json['commit']['message'].match(/from code-dot-org\/(.*)\n\n/)[1]
  rescue => _
    nil
  end

  def self.current_branch_base
    branch_to_base(current_branch)
  end

  def self.current_branch_base_no_origin
    branch_to_base(current_branch).gsub('origin/', '')
  end

  def self.pr_base_branch_or_default_no_origin
    circle_pr_branch_base_no_origin || current_branch_base_no_origin
  end

  def self.circle_pr_branch_base_no_origin
    pr_number = ENV['CI_PULL_REQUEST'].gsub('https://github.com/code-dot-org/code-dot-org/pull/', '')
    pr_json = JSON.parse(open("https://api.github.com/repos/code-dot-org/code-dot-org/pulls/#{pr_number}").read)
    pr_json['base']['ref']
  rescue => _
    nil
  end

  # Given a branch name, returns its likely base branch / merge destination
  def self.branch_to_base(branch_name)
    case branch_name
      when 'staging'
        'origin/test'
      when 'test'
        'origin/production'
      else # levelbuilder, feature branches, etc.
        'origin/staging'
    end
  end

  def self.valid_commit?(hash_or_branch)
    `git cat-file commit #{hash_or_branch}`
    $?.success?
  end

  def self.merge_branch
    "origin/#{pr_base_branch_or_default_no_origin}"
  end

  CIRCLE_CONFIG_FILE = '.circleci/config.yml'.freeze

  def self.circle_yml_changed
    system("git fetch origin #{pr_base_branch_or_default_no_origin}")
    !`git diff ...#{merge_branch} -- #{CIRCLE_CONFIG_FILE}`.empty?
  end

  # Most changes can be merged from the base branch (usually staging) into the
  # feature branch under test here and the build can proceed as usual.
  # Changes to the CircleCI configuration file are a special case though, because
  # it can control how the Circle container is created, and by the time we run
  # this merge step we're already _in_ the container itself - so the only way
  # to guarantee we're accurately testing the merge result is to have the config
  # change in our feature branch from the moment the build starts.  Therefore we
  # must stop and ask the user to manually merge the base branch into their own.
  def self.ensure_latest_circle_yml
    if circle_yml_changed
      raise "#{CIRCLE_CONFIG_FILE} has changed.\nPlease merge the #{merge_branch} branch into your branch and try again."
    end
  end
end
